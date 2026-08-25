
import 'package:dio/dio.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.15:8082/api",

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type" : "application/json"
      }
    )
  )..interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true
    )
  );
}