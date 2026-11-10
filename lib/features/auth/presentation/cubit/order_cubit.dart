
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/create_order.dart';
import '../../domain/usecases/get_my_orders.dart';
import '../../domain/usecases/get_all_orders.dart';
import '../../domain/usecases/update_order_status.dart';
import 'order_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final CreateOrder createOrder;
  final GetMyOrders getMyOrders;
  final GetAllOrders getAllOrders;
  final UpdateOrderStatus updateOrderStatus;

  bool _isSubmitting = false;

  OrdersCubit({
    required this.createOrder,
    required this.getMyOrders,
    required this.getAllOrders,
    required this.updateOrderStatus,
  }) : super(OrdersInitial());

  Future<void> submitOrder(OrderEntity order) async {
    if (_isSubmitting) return;

    _isSubmitting = true;
    emit(OrdersLoading());

    try {
      final orderId = await createOrder(order);
      emit(OrderCreated(orderId));
    } catch (e) {
      emit(OrdersError(e.toString()));
    } finally {
      _isSubmitting = false;
    }
  }

  Future<void> fetchMyOrders(String userId) async {
    emit(OrdersLoading());

    try {
      final orders = await getMyOrders(userId);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> fetchAllOrders() async {
    emit(OrdersLoading());

    try {
      final orders = await getAllOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> changeOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await updateOrderStatus(
        orderId: orderId,
        status: status,
      );

      await fetchAllOrders();
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }
}
