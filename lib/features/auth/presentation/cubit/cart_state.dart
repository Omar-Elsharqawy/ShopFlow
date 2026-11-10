import 'package:equatable/equatable.dart';

import '../../domain/entities/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get totalPrice {
    return items.fold(
      0.0,
          (total, item) => total + item.totalPrice,
    );
  }

  int get totalItems {
    return items.fold(
      0,
          (total, item) => total + item.quantity,
    );
  }

  @override
  List<Object?> get props => [items];
}