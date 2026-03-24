import 'package:dio/dio.dart';
import 'token_storage.dart';

/// Global nav key — wire this up in your MaterialApp:
///   MaterialApp(navigatorKey: ApiClient.navigatorKey, ...)
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  static final Dio _dio = _create();

  static Dio get dio => _dio;

  static Dio _create() {
    final dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired or revoked — clear local session and redirect to login
            await TokenStorage.clear();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }
}
