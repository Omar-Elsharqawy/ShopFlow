import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/product_entity.dart';
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.totalPrice,
    required super.status,
    required super.createdAt,
  });

  factory OrderModel.fromEntity(OrderEntity order) {
    return OrderModel(
      id: order.id,
      userId: order.userId,
      items: order.items,
      totalPrice: order.totalPrice,
      status: order.status,
      createdAt: order.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) {
        return {
          'productId': item.product.id,
          'name': item.product.name,
          'description': item.product.description,
          'imageUrl': item.product.imageUrl,
          'category': item.product.category,
          'price': item.product.price,
          'stock': item.product.stock,
          'quantity': item.quantity,
          'subtotal': item.totalPrice,
        };
      }).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrderModel.fromMap(
      String documentId,
      Map<String, dynamic> map,
      ) {
    final itemsData = map['items'] as List<dynamic>? ?? [];

    return OrderModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      items: itemsData.map((item) {
        final data = Map<String, dynamic>.from(item as Map);

        final product = ProductEntity(
          id: data['productId'] as String? ?? '',
          name: data['name'] as String? ?? '',
          description: data['description'] as String? ?? '',
          imageUrl: data['imageUrl'] as String? ?? '',
          category: data['category'] as String? ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0,
          stock: (data['stock'] as num?)?.toInt() ?? 0,
        );

        return CartItem(
          product: product,
          quantity: (data['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}