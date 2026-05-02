import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/user_model.dart';
import '../../Api/api_controller.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  UserModel? _user;

  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;


Future<bool> tryAutoLogin() async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('saved_email');
  final password = prefs.getString('saved_password');

  if (email == null || password == null) return false;

  final result = await ApiController.login(email, password, 'Y');
  if (result['success'] == true) {
    final data = result['data'];
    _user = UserModel.fromJson(data['user']);
    await prefs.setString('token', data['token']);
    await prefs.setString('refresh_token', data['refresh_token']);
    await prefs.setString('user', jsonEncode(data['user']));
    notifyListeners();
    return true;
  }

  return false;
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

      // For Auto Login
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);

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
  await ApiController.logout();
  _user = null;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('refresh_token');
  await prefs.remove('user');
  await prefs.remove('saved_email');
  await prefs.remove('saved_password');
  notifyListeners();
}
}