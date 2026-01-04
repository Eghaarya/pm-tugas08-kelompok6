import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/token_helper.dart';

class BackupApi {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<bool> backup(List<Map<String, dynamic>> transactions) async {
    final token = await TokenHelper.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/backup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'transactions': transactions}),
    );

    print('BACKUP STATUS: ${response.statusCode}');
    print('BACKUP BODY: ${response.body}');

    return response.statusCode == 200;
  }
}
