
import 'package:e_app/features/auth/presentation/pages/products_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/injection_container.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/order_cubit.dart';
import 'admin_dashboard_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String adminUid =
      'mA8ged6wjhNOsPb1NQQ76Wpstth1';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.uid == adminUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShopFlow'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const AdminDashboardPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
              ),
            ),


          IconButton(
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<OrdersCubit>(),
                    child: const MyOrdersPage(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
          ),

          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'Shopping cart',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(),
                    ),
                  );
                },
                icon: Badge(
                  label: Text('${state.totalItems}'),
                  isLabelVisible: state.totalItems > 0,
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                  ),
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const ProductsPage(),
    );
  }
}
