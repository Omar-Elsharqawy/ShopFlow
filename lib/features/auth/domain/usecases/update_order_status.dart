
import '../repositories/order_repository.dart';

class UpdateOrderStatus {
  final OrderRepository repository;

  UpdateOrderStatus(this.repository);

  Future<void> call({
    required String orderId,
    required String status,
  }) {
    return repository.updateOrderStatus(orderId, status);
  }
}
