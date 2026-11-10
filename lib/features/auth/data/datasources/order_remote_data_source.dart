
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<String> createOrder(OrderModel order);

  Future<List<OrderModel>> getMyOrders(String userId);

  Future<List<OrderModel>> getAllOrders();

  Future<void> updateOrderStatus(
      String orderId,
      String status,
      );
}

class OrderRemoteDataSourceImpl
    implements OrderRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  static const String workerBaseUrl =
      'https://shopflow-api.alsharqawymr926.workers.dev';

  static const String _pendingOrderPrefix =
      'shopflow_pending_order_v1_';

  OrderRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  Map<String, dynamic> _buildPayload(
      String requestId,
      List<Map<String, dynamic>> items,
      ) {
    return {
      'requestId': requestId,
      'items': items,
    };
  }

  List<Map<String, dynamic>> _buildItems(
      OrderModel order,
      ) {
    final quantities = <String, int>{};

    for (final item in order.items) {
      final productId = item.product.id;
      final quantity = item.quantity;

      if (productId.isEmpty || quantity <= 0) {
        throw Exception('Invalid cart item.');
      }

      quantities[productId] =
          (quantities[productId] ?? 0) + quantity;
    }

    final productIds = quantities.keys.toList()..sort();

    return productIds.map((productId) {
      return <String, dynamic>{
        'productId': productId,
        'quantity': quantities[productId]!,
      };
    }).toList();
  }

  @override
  Future<String> createOrder(OrderModel order) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception(
        'Please login before placing an order.',
      );
    }

    final items = _buildItems(order);

    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final prefs = await SharedPreferences.getInstance();

    final storageKey =
        '$_pendingOrderPrefix${user.uid}';

    final currentItemsJson = jsonEncode(items);
    final savedPending = prefs.getString(storageKey);

    late final String requestId;

    if (savedPending != null) {
      final Map<String, dynamic> pending;

      try {
        pending = Map<String, dynamic>.from(
          jsonDecode(savedPending) as Map,
        );
      } catch (_) {
        throw Exception(
          'Saved pending order is invalid. '
              'Please resolve it before ordering again.',
        );
      }

      final savedRequestId = pending['requestId'];
      final savedItems = pending['items'];

      if (savedRequestId is! String ||
          savedRequestId.isEmpty ||
          savedItems is! String) {
        throw Exception(
          'Saved pending order is incomplete. '
              'Please resolve it before ordering again.',
        );
      }

      if (savedItems != currentItemsJson) {
        throw Exception(
          'You have a pending order with different items. '
              'Please resolve that order before creating another.',
        );
      }

      requestId = savedRequestId;
    } else {
      requestId =
          firestore.collection('orders').doc().id;

      final saved = await prefs.setString(
        storageKey,
        jsonEncode({
          'requestId': requestId,
          'items': currentItemsJson,
        }),
      );

      if (!saved) {
        throw Exception(
          'Could not save the pending order locally.',
        );
      }
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Unable to get Firebase authentication token.',
      );
    }

    late final http.Response response;

    try {
      response = await http
          .post(
        Uri.parse('$workerBaseUrl/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
          _buildPayload(requestId, items),
        ),
      )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw Exception(
        'Could not confirm the order. '
            'Retry with the same cart to check its status.',
      );
    }

    late final Map<String, dynamic> data;

    try {
      data = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
    } catch (_) {
      throw Exception(
        'Invalid response from order server. '
            'Retry with the same cart.',
      );
    }

    if (response.statusCode != 200 ||
        data['success'] != true) {
      final message = data['message'] is String
          ? data['message'] as String
          : 'Failed to create order.';

      throw Exception(message);
    }

    final orderId = data['orderId'];

    if (orderId is! String || orderId.isEmpty) {
      throw Exception(
        'The server did not return an order ID.',
      );
    }

    final removed = await prefs.remove(storageKey);

    if (!removed) {
    }

    return orderId;
  }

  @override
  Future<List<OrderModel>> getMyOrders(
      String userId,
      ) async {
    final snapshot = await firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return OrderModel.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  @override
  Future<List<OrderModel>> getAllOrders() async {
    final snapshot = await firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return OrderModel.fromMap(
        doc.id,
        doc.data(),
      );
    }).toList();
  }

  @override
  Future<void> updateOrderStatus(
      String orderId,
      String status,
      ) async {
    await firestore
        .collection('orders')
        .doc(orderId)
        .update({
      'status': status,
    });
  }
}
