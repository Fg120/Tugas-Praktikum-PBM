import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

abstract class ApiService {
  static const String baseUrl = 'https://task.itprojects.web.id/api';
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> buildHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .get(uri, headers: buildHeaders(token: token))
          .timeout(_timeout);
      return handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet. Periksa jaringan kamu.');
    } on HttpException {
      throw const ApiException('Terjadi kesalahan jaringan. Coba lagi.');
    } on FormatException {
      throw const ApiException('Format response tidak valid dari server.');
    }
  }

  static Future<dynamic> post(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: buildHeaders(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet. Periksa jaringan kamu.');
    } on HttpException {
      throw const ApiException('Terjadi kesalahan jaringan. Coba lagi.');
    } on FormatException {
      throw const ApiException('Format response tidak valid dari server.');
    }
  }

  static Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .delete(uri, headers: buildHeaders(token: token))
          .timeout(_timeout);
      return handleResponse(response);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet. Periksa jaringan kamu.');
    } on HttpException {
      throw const ApiException('Terjadi kesalahan jaringan. Coba lagi.');
    } on FormatException {
      throw const ApiException('Format response tidak valid dari server.');
    }
  }

  static dynamic handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'Terjadi kesalahan (${response.statusCode})';
    if (body != null && body is Map) {
      errorMessage = body['message'] as String? ??
          body['error'] as String? ??
          body['msg'] as String? ??
          errorMessage;
    }

    switch (response.statusCode) {
      case 401:
        throw ApiException('Sesi habis. Silakan login kembali.', statusCode: 401);
      case 403:
        throw ApiException('Akses ditolak.', statusCode: 403);
      case 404:
        throw ApiException('Data tidak ditemukan.', statusCode: 404);
      case 422:
        throw ApiException(errorMessage, statusCode: 422);
      case 500:
        throw ApiException('Server error. Coba lagi nanti.', statusCode: 500);
      default:
        throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}
