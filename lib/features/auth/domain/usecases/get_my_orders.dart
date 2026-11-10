import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetMyOrders {
  final OrderRepository repository;

  GetMyOrders(this.repository);

  Future<List<OrderEntity>> call(String userId) {
    return repository.getMyOrders(userId);
  }
}