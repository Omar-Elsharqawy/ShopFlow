import 'package:e_app/features/auth/presentation/cubit/product_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_products.dart';
class ProductsCubit extends Cubit<ProductsState> {
  final GetProducts getProducts;

  ProductsCubit(this.getProducts)
      : super(const ProductsInitial());

  Future<void> fetchProducts() async {
    emit(const ProductsLoading());

    try {
      final products = await getProducts();
      emit(ProductsLoaded(products));
    } catch (e, stackTrace) {
  debugPrint('Products error: $e');
  debugPrintStack(stackTrace: stackTrace);

  emit(ProductsError('تعذر تحميل المنتجات: $e'));
}
  }
}