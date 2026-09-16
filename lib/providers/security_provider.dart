import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  static const _key = 'is_app_locked';
  bool _isSecure = false;

  bool get isSecure => _isSecure;

  SecurityProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isSecure = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggleSecurity(bool value) async {
    _isSecure = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isSecure);
    notifyListeners();
  }
}