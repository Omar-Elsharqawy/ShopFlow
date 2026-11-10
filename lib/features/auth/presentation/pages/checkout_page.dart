import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../../domain/entities/order_status.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return BlocConsumer<OrdersCubit, OrdersState>(
            listener: (context, state) {
              if (state is OrderCreated) {
                context.read<CartCubit>().clearCart();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order created successfully: ${state.orderId}',
                    ),
                  ),
                );

                Navigator.pop(context);
              }

              if (state is OrdersError) {
                final message = state.message.contains('Not enough stock')
                    ? 'الكمية المطلوبة غير متاحة في المخزون'
                    : state.message;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, orderState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartState.items.length,
                        itemBuilder: (context, index) {
                          final item = cartState.items[index];

                          return ListTile(
                            title: Text(item.product.name),
                            subtitle: Text(
                              'Quantity: ${item.quantity}',
                            ),
                            trailing: Text(
                              '${item.totalPrice.toStringAsFixed(2)} USD',
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Total: ${cartState.totalPrice.toStringAsFixed(2)} USD',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: orderState is OrdersLoading
                            ? null
                            : () {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login first'),
                              ),
                            );
                            return;
                          }

                          final order = OrderEntity(
                            id: '',
                            userId: user.uid,
                            items: cartState.items,
                            totalPrice: cartState.totalPrice,
                            status: OrderStatus.pending.value,
                            createdAt: DateTime.now(),
                          );

                          context
                              .read<OrdersCubit>()
                              .submitOrder(order);
                        },
                        child: orderState is OrdersLoading
                            ? const CircularProgressIndicator()
                            : const Text('Confirm Order'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
