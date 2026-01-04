import 'dart:convert';
import 'api_client.dart';

class TransactionApi {
  static Future<List> fetchTransactions(String token) async {
    final res = await ApiClient.get('/transactions', token: token);
    return jsonDecode(res.body);
  }

  static Future<bool> createTransaction(
      Map<String, dynamic> data, String token) async {
    final res = await ApiClient.post(
      '/transactions',
      body: data,
      token: token,
    );
    return res.statusCode == 201 || res.statusCode == 200;
  }

  static Future<bool> updateTransaction(
      int id, Map<String, dynamic> data, String token) async {
    final res = await ApiClient.put(
      '/transactions/$id',
      body: data,
      token: token,
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteTransaction(int id, String token) async {
    final res = await ApiClient.delete(
      '/transactions/$id',
      token: token,
    );
    return res.statusCode == 200;
  }
}
