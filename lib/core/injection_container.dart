import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Auth
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/datasources/order_remote_data_source.dart';
import '../features/auth/data/datasources/product_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/order_repository.dart';
import '../features/auth/domain/repositories/order_repository_impl.dart';
import '../features/auth/domain/repositories/product_repository.dart';
import '../features/auth/domain/repositories/product_repository_impl.dart';
import '../features/auth/domain/usecases/create_order.dart';
import '../features/auth/domain/usecases/get_all_orders.dart';
import '../features/auth/domain/usecases/get_current_user.dart';
import '../features/auth/domain/usecases/get_my_orders.dart';
import '../features/auth/domain/usecases/get_products.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/logout_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/domain/usecases/reset_password.dart';
import '../features/auth/domain/usecases/update_order_status.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/cubit/cart_cubit.dart';
import '../features/auth/presentation/cubit/order_cubit.dart';
import '../features/auth/presentation/cubit/products_cubit.dart';
final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(
        () => FirebaseAuth.instance,
  );

  sl.registerLazySingleton<FirebaseFirestore>(
        () => FirebaseFirestore.instance,
  );

  // ==================== AUTH ====================

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<RegisterUser>(
        () => RegisterUser(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<LoginUser>(
        () => LoginUser(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<LogoutUser>(
        () => LogoutUser(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<ResetPassword>(
        () => ResetPassword(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<GetCurrentUser>(
        () => GetCurrentUser(sl<AuthRepository>()),
  );

  sl.registerFactory<AuthCubit>(
        () => AuthCubit(
      registerUser: sl<RegisterUser>(),
      loginUser: sl<LoginUser>(),
      logoutUser: sl<LogoutUser>(),
      resetPasswordUseCase: sl<ResetPassword>(),
      getCurrentUser: sl<GetCurrentUser>(),
    ),
  );

  // ==================== PRODUCTS ====================

  sl.registerLazySingleton<ProductRemoteDataSource>(
        () => ProductRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  sl.registerLazySingleton<ProductRepository>(
        () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<GetProducts>(
        () => GetProducts(sl<ProductRepository>()),
  );

  sl.registerFactory<ProductsCubit>(
        () => ProductsCubit(sl<GetProducts>()),
  );

  // ==================== CART ====================

  sl.registerLazySingleton<CartCubit>(
        () => CartCubit(),
  );

  // ==================== ORDERS ====================

  sl.registerLazySingleton<OrderRemoteDataSource>(
        () => OrderRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(
      remoteDataSource: sl<OrderRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<CreateOrder>(
        () => CreateOrder(sl<OrderRepository>()),
  );

  sl.registerLazySingleton<GetMyOrders>(
        () => GetMyOrders(sl<OrderRepository>()),
  );

  sl.registerLazySingleton<UpdateOrderStatus>(
        () => UpdateOrderStatus(sl<OrderRepository>()),
  );

  sl.registerFactory<OrdersCubit>(
        () => OrdersCubit(
      createOrder: sl<CreateOrder>(),
      getMyOrders: sl<GetMyOrders>(),
      getAllOrders: sl<GetAllOrders>(),
      updateOrderStatus: sl<UpdateOrderStatus>(),
    ),
  );
  sl.registerLazySingleton<GetAllOrders>(
        () => GetAllOrders(sl<OrderRepository>()),
  );
}
