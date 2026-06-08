import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _role;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get role => _role;
  Map<String, dynamic>? get user => _user;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        final response = await _apiService.client.get('/auth/me');
        _user = response.data;
        _role = _user?['role'];
        _isAuthenticated = true;
      } catch (e) {
        await _clearAuth();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.client.post(
        '/auth/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );

      final token = response.data['access_token'];
      _role = response.data['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      await checkAuthStatus();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _clearAuth();
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _isAuthenticated = false;
    _role = null;
    _user = null;
  }
}
