
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/reset_password.dart';

import '../cubit/cart_cubit.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUser registerUser;
  final LoginUser loginUser;
  final LogoutUser logoutUser;
  final ResetPassword resetPasswordUseCase;
  final GetCurrentUser getCurrentUser;
  final CartCubit cartCubit;

  AuthCubit({
    required this.registerUser,
    required this.loginUser,
    required this.logoutUser,
    required this.resetPasswordUseCase,
    required this.getCurrentUser,
    required this.cartCubit,
  }) : super(AuthInitial());

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AuthLoading());

    try {
      final UserEntity user = await registerUser(
        email: email,
        password: password,
        name: name,
      );

      cartCubit.clearCart();

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      final UserEntity user = await loginUser(
        email: email,
        password: password,
      );

      cartCubit.clearCart();

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());

    try {
      await logoutUser();

      cartCubit.clearCart();

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    emit(AuthLoading());

    try {
      await resetPasswordUseCase(
        email: email,
      );

      emit(AuthPasswordReset());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkCurrentUser() async {
    emit(AuthLoading());

    try {
      final UserEntity? user = await getCurrentUser();

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        cartCubit.clearCart();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
