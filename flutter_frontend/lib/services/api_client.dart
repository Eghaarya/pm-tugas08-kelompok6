import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl =
      'https://semisentimentalized-scornedly-tate.ngrok-free.dev/api';

  static Map<String, String> headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<http.Response> get(String endpoint, {String? token}) {
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers(token: token),
    );
  }

  static Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body, String? token}) {
    return http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers(token: token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body, String? token}) {
    return http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers(token: token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint, {String? token}) {
    return http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers(token: token),
    );
  }
}
