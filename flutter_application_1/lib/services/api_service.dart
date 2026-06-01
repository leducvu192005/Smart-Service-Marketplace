import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    // WEB
    if (kIsWeb) {
      return "http://localhost:8000";
    }

    // ANDROID EMULATOR
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8000";
    }

    // IOS SIMULATOR
    if (Platform.isIOS) {
      return "http://localhost:8000";
    }

    // DESKTOP (Windows/Mac/Linux)
    return "http://127.0.0.1:8000";
  }
}

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
      ),
    );
  }

  Dio get client => _dio;
}
