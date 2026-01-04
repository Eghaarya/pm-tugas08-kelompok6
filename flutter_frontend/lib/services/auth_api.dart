import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthApi {
  static Future<String?> login(String username, String password) async {
    final res = await ApiClient.post(
      '/login',
      body: {
        'username': username,
        'password': password,
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['token'];
    }
    return null;
  }

  static Future<http.Response> me(String token) {
    return ApiClient.get('/me', token: token);
  }

  static Future<void> logout(String token) async {
    await ApiClient.post('/logout', token: token);
  }
}
