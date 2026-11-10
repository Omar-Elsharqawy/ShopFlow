
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../../domain/entities/order_status.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().fetchAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - Orders'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is OrdersError) {
            return Center(
              child: Text(state.message),
            );
          }

          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return const Center(
                child: Text('No orders found.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Customer ID: ${order.userId}'),
                        Text('Status: ${order.status}'),
                        Text(
                          'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                        ),
                        Text(
                          'Date: ${order.createdAt.toLocal().toString().split('.')[0]}',
                        ),
                        const Divider(),
                        const Text(
                          'Products:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...order.items.map(
                              (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.product.name),
                            subtitle: Text(
                              'Quantity: ${item.quantity}',
                            ),
                            trailing: Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: OrderStatus.values
                              .where(
                                (status) =>
                            status.value == order.status,
                          )
                              .map((status) => status.value)
                              .firstOrNull,
                          decoration: const InputDecoration(
                            labelText: 'Update Order Status',
                            border: OutlineInputBorder(),
                          ),
                          items: OrderStatus.values.map((status) {
                            return DropdownMenuItem<String>(
                              value: status.value,
                              child: Text(status.displayName),
                            );
                          }).toList(),
                          onChanged: (newStatus) {
                            if (newStatus == null ||
                                newStatus == order.status) {
                              return;
                            }

                            context
                                .read<OrdersCubit>()
                                .changeOrderStatus(
                              orderId: order.id,
                              status: newStatus,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: Text('No orders available.'),
          );
        },
      ),
    );
  }
}
