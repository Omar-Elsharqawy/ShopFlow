
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {
  onCall,
  HttpsError,
} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();

interface OrderItemInput {
  productId: string;
  quantity: number;
}

export const createOrder = onCall(async (request) => {
  // 1. Check authentication.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must sign in before creating an order.",
    );
  }

  const userId = request.auth.uid;
  const items = request.data.items as OrderItemInput[];

  // 2. Validate input.
  if (
    !Array.isArray(items) ||
    items.length === 0 ||
    items.length > 50
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid order items.",
    );
  }

  const quantities = new Map<string, number>();

  for (const item of items) {
    if (
      typeof item.productId !== "string" ||
      item.productId.trim().length === 0 ||
      !Number.isSafeInteger(item.quantity) ||
      item.quantity <= 0
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid product ID or quantity.",
      );
    }

    quantities.set(
      item.productId,
      (quantities.get(item.productId) ?? 0) + item.quantity,
    );
  }

  const productIds = Array.from(quantities.keys());
  const orderRef = db.collection("orders").doc();

  // 3. Execute all reads and writes atomically.
  const result = await db.runTransaction(async (transaction) => {
    const productRefs = productIds.map(
      (productId) => db.collection("products").doc(productId),
    );

    const snapshots = [];

    // Read every product before writing.
    for (const ref of productRefs) {
      snapshots.push(await transaction.get(ref));
    }

    const orderItems = [];
    let totalPrice = 0;

    // Validate stock and calculate prices from Firestore.
    for (let i = 0; i < snapshots.length; i++) {
      const snapshot = snapshots[i];
      const productId = productIds[i];
      const quantity = quantities.get(productId);

      if (quantity === undefined) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid product quantity.",
        );
      }

      if (!snapshot.exists) {
        throw new HttpsError(
          "not-found",
          "A product in this order was not found.",
        );
      }

      const product = snapshot.data();

      if (!product) {
        throw new HttpsError(
          "not-found",
          "Product data was not found.",
        );
      }

      const stock = product.stock;
      const price = product.price;

      if (
        typeof stock !== "number" ||
        !Number.isInteger(stock) ||
        typeof price !== "number" ||
        !Number.isFinite(price) ||
        price < 0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Invalid product stock or price.",
        );
      }

      if (stock < quantity) {
        const productName = product.name ?? productId;
        const errorMessage =
          `Not enough stock for ${productName}. ` +
          `Available: ${stock}`;

        throw new HttpsError("failed-precondition", errorMessage);
      }

      totalPrice += price * quantity;

      orderItems.push({
        productId,
        name: product.name ?? "",
        description: product.description ?? "",
        imageUrl: product.imageUrl ?? "",
        category: product.category ?? "",
        price,
        stock,
        quantity,
        subtotal: price * quantity,
      });
    }

    // Decrease stock.
    for (let i = 0; i < productRefs.length; i++) {
      const productId = productIds[i];
      const quantity = quantities.get(productId);
      const snapshot = snapshots[i];
      const product = snapshot.data();

      if (quantity === undefined || !product) {
        throw new HttpsError(
          "failed-precondition",
          "Unable to update product stock.",
        );
      }

      const currentStock = product.stock as number;

      transaction.update(productRefs[i], {
        stock: currentStock - quantity,
      });
    }

    // Create the order using trusted server-side values.
    transaction.set(orderRef, {
      userId,
      items: orderItems,
      totalPrice,
      status: "pending",
      createdAt: Timestamp.now(),
    });

    return {totalPrice};
  });

  return {
    orderId: orderRef.id,
    totalPrice: result.totalPrice,
  };
});
