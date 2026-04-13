import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/user_model.dart';
import '../../api/api_controller.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  UserModel? _user;

  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  // Called from SplashScreen to check saved session
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token == null || userJson == null) return false;

    try {
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password, String rememberMe) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiController.login(email, password, rememberMe);

    if (result['success'] == true) {
      final data = result['data'];

      _user = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('refresh_token', data['refresh_token']);
      await prefs.setString('user', jsonEncode(data['user']));

      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } else {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': result['message']};
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    notifyListeners();
  }
}