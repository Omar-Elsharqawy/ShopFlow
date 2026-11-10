import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product_entity.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addToCart(ProductEntity product) {
    if (product.stock <= 0) return;

    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere(
          (item) => item.product.id == product.id,
    );

    if (index != -1) {
      final currentItem = items[index];

      if (currentItem.quantity >= product.stock) return;

      items[index] = currentItem.copyWith(
        quantity: currentItem.quantity + 1,
      );
    } else {
      items.add(
        CartItem(product: product, quantity: 1),
      );
    }

    emit(CartState(items: List.unmodifiable(items)));
  }

  void increaseQuantity(String productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere(
          (item) => item.product.id == productId,
    );

    if (index == -1) return;

    final item = items[index];

    if (item.quantity >= item.product.stock) return;

    items[index] = item.copyWith(
      quantity: item.quantity + 1,
    );

    emit(CartState(items: List.unmodifiable(items)));
  }

  void decreaseQuantity(String productId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere(
          (item) => item.product.id == productId,
    );

    if (index == -1) return;

    final item = items[index];

    if (item.quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = item.copyWith(
        quantity: item.quantity - 1,
      );
    }

    emit(CartState(items: List.unmodifiable(items)));
  }

  void removeFromCart(String productId) {
    final items = state.items
        .where((item) => item.product.id != productId)
        .toList();

    emit(CartState(items: List.unmodifiable(items)));
  }

  void clearCart() {
    emit(const CartState());
  }
}