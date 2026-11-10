import '../../data/datasources/order_remote_data_source.dart';
import '../../data/datasources/models/order_model.dart';
import '../entities/order_entity.dart';
import 'order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<String> createOrder(OrderEntity order) async {
    final orderModel = OrderModel.fromEntity(order);

    return remoteDataSource.createOrder(orderModel);
  }

  @override
  Future<List<OrderEntity>> getMyOrders(String userId) {
    return remoteDataSource.getMyOrders(userId);
  }

  @override
  Future<List<OrderEntity>> getAllOrders() {
    return remoteDataSource.getAllOrders();
  }

  @override
  Future<void> updateOrderStatus(
      String orderId,
      String status,
      ) {
    return remoteDataSource.updateOrderStatus(orderId, status);
  }
}
