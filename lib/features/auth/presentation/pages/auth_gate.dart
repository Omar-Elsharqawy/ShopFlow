
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'admin_dashboard_page.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const String adminUid =
      'mA8ged6wjhNOsPb1NQQ76Wpstth1';

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = FirebaseAuth.instance.currentUser;

          // Admin goes to Admin Dashboard.
          if (user?.uid == adminUid) {
            return const AdminDashboardPage();
          }

          // Regular customers go to HomePage.
          return const HomePage();
        }

        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const LoginPage();
      },
    );
  }
}
