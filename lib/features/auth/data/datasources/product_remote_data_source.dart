import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/product_model.dart';
abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl
    implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;

  ProductRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<List<ProductModel>> getProducts() async {
    final snapshot = await firestore
        .collection('products')
        .get();

    return snapshot.docs
        .map(ProductModel.fromFirestore)
        .toList();
  }
}