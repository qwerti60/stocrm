import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String defaultApiBase() {
  const fromEnv = String.fromEnvironment('API_BASE');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) {
    final origin = Uri.base.origin;
    if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
      return 'http://127.0.0.1:8080';
    }
    return origin;
  }
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
  return 'http://127.0.0.1:8080';
}

class ApiClient {
  ApiClient({String? base}) : base = base ?? defaultApiBase();
  final String base;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$base$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final r = await http.get(Uri.parse('$base$path'), headers: _headers).timeout(const Duration(seconds: 20));
    return _decode(r);
  }

  Map<String, dynamic> _decode(http.Response r) {
    final data = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw ApiException(r.statusCode, data is Map ? '${data['detail'] ?? data}' : r.body);
    }
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}
