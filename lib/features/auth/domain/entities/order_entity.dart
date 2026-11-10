import 'cart_item.dart';

class OrderEntity {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });
}
