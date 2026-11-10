import '../../data/datasources/product_remote_data_source.dart';
import '../entities/product_entity.dart';
import 'product_repository.dart';
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<ProductEntity>> getProducts() {
    return remoteDataSource.getProducts();
  }
}