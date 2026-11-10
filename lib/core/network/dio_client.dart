import 'package:dio/dio.dart';

class DioClient {
  final Dio dio;

  DioClient()
  : dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
}