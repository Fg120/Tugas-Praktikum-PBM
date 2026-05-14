import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<UserModel> login({
    required String nim,
    required String password,
  }) async {
    final data = await ApiService.post(
      '/auth/login',
      body: {'username': nim, 'password': password},
    );

    if (data == null) {
      throw const ApiException('Response kosong dari server saat login.');
    }

    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> logout({required String token}) async {
    try {
      await ApiService.post('/logout', token: token);
    } catch (_) {
    }
  }
}
