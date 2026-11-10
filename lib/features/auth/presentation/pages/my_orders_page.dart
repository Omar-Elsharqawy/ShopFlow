
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import 'order_details_page.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      context.read<OrdersCubit>().fetchMyOrders(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
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
                child: Text('You have no orders yet.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailsPage(order: order),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Status: ${order.status}'),
                          Text(
                            'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Date: ${order.createdAt.toLocal().toString().split('.')[0]}',
                          ),
                          const Divider(),
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
                        ],
                      ),
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
