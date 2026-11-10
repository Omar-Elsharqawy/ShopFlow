import 'package:flutter/material.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_status.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderEntity order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            Text('Status: ${order.status}'),
            Text(
              'Date: ${order.createdAt.toLocal().toString().split('.')[0]}',
            ),
            const SizedBox(height: 24),

            const Text(
              'Order Tracking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildOrderTimeline(order.status),

            const Divider(height: 32),

            const Text(
              'Ordered Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...order.items.map(
                  (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Image.network(
                    item.product.imageUrl,
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported),
                  ),
                  title: Text(item.product.name),
                  subtitle: Text(
                    'Quantity: ${item.quantity}',
                  ),
                  trailing: Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                  ),
                ),
              ),
            ),

            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOrderTimeline(String currentStatus) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];

    final currentIndex = statuses.indexWhere(
          (status) => status.value == currentStatus,
    );

    if (currentStatus == OrderStatus.cancelled.value) {
      return const ListTile(
        leading: Icon(
          Icons.cancel,
          color: Colors.red,
        ),
        title: Text('Order Cancelled'),
      );
    }

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted =
            currentIndex != -1 && index <= currentIndex;

        return ListTile(
          leading: Icon(
            isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          title: Text(
            status.displayName,
            style: TextStyle(
              fontWeight:
              isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}