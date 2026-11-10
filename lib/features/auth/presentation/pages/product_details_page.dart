import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_entity.dart';
import '../cubit/cart_cubit.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;

  void _addToCart() {
    for (int i = 0; i < quantity; i++) {
      context.read<CartCubit>().addToCart(widget.product);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$quantity item(s) added to cart')));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isAvailable = product.stock > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: product.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFF0F0F0),
                      child: Icon(Icons.shopping_bag_outlined, size: 80),
                    )
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return const ColoredBox(
                          color: Color(0xFFF0F0F0),
                          child: Icon(Icons.broken_image_outlined, size: 80),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            product.category.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty
                ? 'No description available.'
                : product.description,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined),
              const SizedBox(width: 8),
              Text(
                isAvailable
                    ? '${product.stock} items available'
                    : 'Out of stock',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isAvailable) ...[
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: quantity < product.stock
                      ? () => setState(() => quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(
                  'Total: \$${(product.price * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isAvailable ? _addToCart : null,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(isAvailable ? 'Add to Cart' : 'Out of Stock'),
            ),
          ),
        ],
      ),
    );
  }
}
