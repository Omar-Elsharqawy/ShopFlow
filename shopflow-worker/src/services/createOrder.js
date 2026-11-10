
function json(data, status = 200) {
  return Response.json(data, { status });
}

function decodeField(field) {
  if (!field) return null;

  if ("stringValue" in field) return field.stringValue;
  if ("integerValue" in field) return Number(field.integerValue);
  if ("doubleValue" in field) return Number(field.doubleValue);
  if ("booleanValue" in field) return field.booleanValue;
  if ("timestampValue" in field) return field.timestampValue;
  if ("nullValue" in field) return null;

  if ("arrayValue" in field) {
    return (field.arrayValue.values || []).map(decodeField);
  }

  if ("mapValue" in field) {
    return Object.fromEntries(
      Object.entries(field.mapValue.fields || {}).map(
        ([key, value]) => [key, decodeField(value)]
      )
    );
  }

  return null;
}

function encodeField(value) {
  if (value === null) {
    return { nullValue: null };
  }

  if (typeof value === "string") {
    return { stringValue: value };
  }

  if (typeof value === "boolean") {
    return { booleanValue: value };
  }

  if (typeof value === "number") {
    if (!Number.isFinite(value)) {
      throw new Error("Invalid numeric value");
    }

    return Number.isSafeInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }

  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map(encodeField),
      },
    };
  }

  if (typeof value === "object") {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(
            ([key, item]) => [key, encodeField(item)]
          )
        ),
      },
    };
  }

  throw new Error("Unsupported Firestore value");
}

function encodeDocument(data) {
  return {
    fields: Object.fromEntries(
      Object.entries(data).map(
        ([key, value]) => [key, encodeField(value)]
      )
    ),
  };
}

function createFirestoreError(response, result) {
  const error = new Error("Firestore request failed");

  error.status = response.status;
  error.code = result?.error?.status || "UNKNOWN";

  return error;
}

async function firestoreRequest(url, token, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });

  const result = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw createFirestoreError(response, result);
  }

  return result;
}

// Firestore batchGet can return multiple JSON objects.
// Parse a JSON array, a single object, or a JSON stream.
function parseBatchGet(text) {
  const input = text.trim();

  if (!input) {
    throw new Error("Empty Firestore batchGet response");
  }

  try {
    const parsed = JSON.parse(input);
    return Array.isArray(parsed) ? parsed : [parsed];
  } catch {
    // Multiple JSON values: continue with stream parsing.
  }

  const records = [];
  let depth = 0;
  let start = -1;
  let inString = false;
  let escaped = false;

  for (let i = 0; i < input.length; i++) {
    const char = input[i];

    if (start === -1) {
      if (/\s/.test(char)) continue;

      if (char !== "{") {
        throw new Error("Invalid Firestore JSON stream");
      }

      start = i;
      depth = 1;
      continue;
    }

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === '"') {
        inString = false;
      }

      continue;
    }

    if (char === '"') {
      inString = true;
    } else if (char === "{") {
      depth++;
    } else if (char === "}") {
      depth--;

      if (depth === 0) {
        records.push(
          JSON.parse(input.slice(start, i + 1))
        );

        start = -1;
      }

      if (depth < 0) {
        throw new Error("Invalid Firestore JSON depth");
      }
    }
  }

  if (start !== -1 || records.length === 0) {
    throw new Error("Incomplete Firestore JSON stream");
  }

  return records;
}

async function batchGetDocuments({
  root,
  accessToken,
  documentNames,
  transaction,
}) {
  const response = await fetch(
    `${root}/documents:batchGet`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        documents: documentNames,
        transaction,
      }),
    }
  );

  const responseText = await response.text();

  if (!response.ok) {
    let errorResult = {};

    try {
      errorResult = JSON.parse(responseText);
    } catch {
      // Do not expose Firestore response bodies.
    }

    throw createFirestoreError(response, errorResult);
  }

  const records = parseBatchGet(responseText);
  const found = new Map();
  const returnedNames = new Set();

  for (const record of records) {
    if (record.found?.name) {
      found.set(record.found.name, record.found);
      returnedNames.add(record.found.name);
    } else if (record.missing) {
      returnedNames.add(record.missing);
    }
  }

  for (const name of documentNames) {
    if (!returnedNames.has(name)) {
      throw new Error("Incomplete Firestore batchGet");
    }
  }

  return found;
}

async function hashString(value) {
  const bytes = new TextEncoder().encode(value);

  const digest = await crypto.subtle.digest(
    "SHA-256",
    bytes
  );

  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function canonicalItems(quantities) {
  return [...quantities.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([productId, quantity]) => ({
      productId,
      quantity,
    }));
}

function validProductId(value) {
  return (
    typeof value === "string" &&
    /^[a-zA-Z0-9_-]{1,128}$/.test(value)
  );
}

function validPrice(value) {
  return (
    typeof value === "number" &&
    Number.isFinite(value) &&
    value >= 0 &&
    Number.isSafeInteger(Math.round(value * 100)) &&
    Math.abs(value * 100 - Math.round(value * 100)) <
      0.000001
  );
}

export async function createOrder({
  env,
  uid,
  body,
  accessToken,
}) {
  if (!uid || typeof uid !== "string") {
    return json(
      {
        success: false,
        message: "Unauthorized",
      },
      401
    );
  }

  const requestId = body?.requestId;
  const rawItems = body?.items;

  if (
    typeof requestId !== "string" ||
    !/^[a-zA-Z0-9_-]{8,128}$/.test(requestId) ||
    !Array.isArray(rawItems) ||
    rawItems.length === 0 ||
    rawItems.length > 50
  ) {
    return json(
      {
        success: false,
        message: "Invalid order request",
      },
      400
    );
  }

  const quantities = new Map();

  for (const item of rawItems) {
    if (
      !item ||
      !validProductId(item.productId) ||
      !Number.isSafeInteger(item.quantity) ||
      item.quantity < 1 ||
      item.quantity > 100
    ) {
      return json(
        {
          success: false,
          message: "Invalid cart item",
        },
        400
      );
    }

    const quantity =
      (quantities.get(item.productId) || 0) +
      item.quantity;

    if (quantity > 100) {
      return json(
        {
          success: false,
          message: "Quantity limit exceeded",
        },
        400
      );
    }

    quantities.set(item.productId, quantity);
  }

  const items = canonicalItems(quantities);

  if (
    !env.FIREBASE_PROJECT_ID ||
    !accessToken
  ) {
    return json(
      {
        success: false,
        message: "Server configuration error",
      },
      500
    );
  }

  const projectId = env.FIREBASE_PROJECT_ID;

  const root =
    `https://firestore.googleapis.com/v1/projects/` +
    `${encodeURIComponent(projectId)}/databases/(default)`;

  const orderId = await hashString(
    `${uid}:${requestId}`
  );

  const requestHash = await hashString(
    JSON.stringify(items)
  );

  const orderName =
    `projects/${projectId}/databases/(default)/` +
    `documents/orders/${orderId}`;

  const productNames = items.map(
    (item) =>
      `projects/${projectId}/databases/(default)/` +
      `documents/products/${item.productId}`
  );

  let transaction = null;
  let transactionFinished = false;

  try {
    // Start read/write transaction.
    const started = await firestoreRequest(
      `${root}/documents:beginTransaction`,
      accessToken,
      {
        method: "POST",
        body: JSON.stringify({
          options: {
            readWrite: {},
          },
        }),
      }
    );

    transaction = started.transaction;

    if (!transaction) {
      throw new Error("Firestore transaction missing");
    }

    // Read order and products in the same transaction.
    const found = await batchGetDocuments({
      root,
      accessToken,
      documentNames: [
        orderName,
        ...productNames,
      ],
      transaction,
    });

    // Check idempotency before changing stock.
    const existingOrder = found.get(orderName);

    if (existingOrder) {
      const fields = existingOrder.fields || {};

      const existingUid = decodeField(fields.userId);
      const existingHash = decodeField(
        fields.requestHash
      );

      if (
        existingUid !== uid ||
        existingHash !== requestHash
      ) {
        return json(
          {
            success: false,
            message:
              "Request ID already used for a different order",
          },
          409
        );
      }

      return json({
        success: true,
        orderId,
        alreadyCreated: true,
      });
    }

    const orderItems = [];
    const writes = [];

    let totalCents = 0;

    for (const item of items) {
      const productName =
        `projects/${projectId}/databases/(default)/` +
        `documents/products/${item.productId}`;

      const product = found.get(productName);

      if (!product) {
        return json(
          {
            success: false,
            message: "Product not found",
            productId: item.productId,
          },
          404
        );
      }

      const fields = product.fields || {};

      const name = decodeField(fields.name);
      const imageUrl = decodeField(fields.imageUrl);
      const price = decodeField(fields.price);
      const stock = decodeField(fields.stock);

      if (
        !validPrice(price) ||
        !Number.isSafeInteger(stock) ||
        stock < 0
      ) {
        return json(
          {
            success: false,
            message: "Invalid product data",
            productId: item.productId,
          },
          409
        );
      }

      if (stock < item.quantity) {
        return json(
          {
            success: false,
            message: "Insufficient stock",
            productId: item.productId,
          },
          409
        );
      }

      const priceCents = Math.round(price * 100);
      const subtotalCents =
        priceCents * item.quantity;

      if (
        !Number.isSafeInteger(subtotalCents) ||
        !Number.isSafeInteger(
          totalCents + subtotalCents
        )
      ) {
        return json(
          {
            success: false,
            message: "Order amount exceeds limit",
          },
          400
        );
      }

      totalCents += subtotalCents;

      orderItems.push({
        productId: item.productId,
        name: typeof name === "string" ? name : "",
        imageUrl:
          typeof imageUrl === "string"
            ? imageUrl
            : "",
        price: priceCents / 100,
        quantity: item.quantity,
      });

      // Update only stock, preserving other fields.
      writes.push({
        update: {
          name: productName,
          fields: {
            stock: {
              integerValue: String(
                stock - item.quantity
              ),
            },
          },
        },
        updateMask: {
          fieldPaths: ["stock"],
        },
        currentDocument: {
          updateTime: product.updateTime,
        },
      });
    }

    // Create order with server timestamp in ONE write.
    writes.push({
      update: {
        name: orderName,
        ...encodeDocument({
          userId: uid,
          requestId,
          requestHash,
          items: orderItems,
          totalPrice: totalCents / 100,
          status: "pending",
        }),
      },
      currentDocument: {
        exists: false,
      },
      updateTransforms: [
        {
          fieldPath: "createdAt",
          setToServerValue: "REQUEST_TIME",
        },
      ],
    });

    // Commit all changes atomically.
    await firestoreRequest(
      `${root}/documents:commit`,
      accessToken,
      {
        method: "POST",
        body: JSON.stringify({
          writes,
          transaction,
        }),
      }
    );

    transactionFinished = true;

    return json({
      success: true,
      orderId,
      alreadyCreated: false,
    });
  } catch (error) {
    console.error("Create order failed:", {
      code: error.code || "UNKNOWN",
      status: error.status || 500,
    });

    if (
      error.code === "ABORTED" ||
      error.code === "ALREADY_EXISTS" ||
      error.code === "FAILED_PRECONDITION"
    ) {
      return json(
        {
          success: false,
          message:
            "Order conflict. Retry using the same requestId.",
          retryable: true,
        },
        409
      );
    }

    if (error.code === "RESOURCE_EXHAUSTED") {
      return json(
        {
          success: false,
          message:
            "Service temporarily busy. Try again later.",
          retryable: true,
        },
        503
      );
    }

    return json(
      {
        success: false,
        message:
          "Unable to confirm order. Retry using the same requestId.",
        retryable: true,
      },
      500
    );
  } finally {
    // Roll back transactions that were not committed.
    if (transaction && !transactionFinished) {
      try {
        await firestoreRequest(
          `${root}/documents:rollback`,
          accessToken,
          {
            method: "POST",
            body: JSON.stringify({
              transaction,
            }),
          }
        );
      } catch {
        // Transaction may already be closed or committed.
      }
    }
  }
}
