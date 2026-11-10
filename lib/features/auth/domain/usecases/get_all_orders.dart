
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class GetAllOrders {
  final OrderRepository repository;

  GetAllOrders(this.repository);

  Future<List<OrderEntity>> call() {
    return repository.getAllOrders();
  }
}
