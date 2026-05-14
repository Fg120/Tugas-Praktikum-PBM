import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  static const String _keyToken = 'auth_token';
  static const String _keyName = 'auth_name';
  static const String _keyNim = 'auth_nim';

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String get token => _currentUser?.token ?? '';

  Future<void> loadSession() async {
    _setStatus(AuthStatus.loading);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final name = prefs.getString(_keyName);
      final nim = prefs.getString(_keyNim);

      if (token != null && token.isNotEmpty) {
        _currentUser = UserModel(
          token: token,
          name: name ?? '',
          nim: nim ?? '',
        );
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String nim, required String password}) async {
    _errorMessage = null;
    _setStatus(AuthStatus.loading);

    try {
      final user = await AuthService.login(nim: nim, password: password);
      _currentUser = user;
      await _saveSession(user);
      _setStatus(AuthStatus.authenticated);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan yang tidak diketahui. Coba lagi.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await AuthService.logout(token: _currentUser!.token);
    }
    await _clearSession();
    _currentUser = null;
    _errorMessage = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, user.token);
    await prefs.setString(_keyName, user.name);
    await prefs.setString(_keyNim, user.nim);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyNim);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
