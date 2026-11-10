
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<String> createOrder(OrderEntity order);

  Future<List<OrderEntity>> getMyOrders(String userId);

  Future<List<OrderEntity>> getAllOrders();

  Future<void> updateOrderStatus(
      String orderId,
      String status,
      );
}
