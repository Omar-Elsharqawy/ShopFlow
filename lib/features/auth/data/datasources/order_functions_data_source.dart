
import 'package:cloud_functions/cloud_functions.dart';

class OrderFunctionsDataSource {
  final FirebaseFunctions functions;

  OrderFunctionsDataSource({
    required this.functions,
  });

  Future<String> createOrder({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final callable = functions.httpsCallable('createOrder');

      final result = await callable.call({
        'items': items,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      return data['orderId'] as String;
    } on FirebaseFunctionsException {
      rethrow;
    }
  }
}
