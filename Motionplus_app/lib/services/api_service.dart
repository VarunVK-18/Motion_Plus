import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/port.dart';

class ApiService {
  static String get baseUrl => PortConstants.apiUrl; 
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer \$token';
      }
    }
    return headers;
  }

  // Generic POST Request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http.post(
        Uri.parse('\$baseUrl\$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  // Generic GET Request
  static Future<dynamic> get(String endpoint, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http.get(
        Uri.parse('\$baseUrl\$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  // Generic PUT Request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http.put(
        Uri.parse('\$baseUrl\$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  // Generic DELETE Request
  static Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final response = await http.delete(
        Uri.parse('\$baseUrl\$endpoint'),
        headers: headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  // Helper method to process responses
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String errorMessage = 'Error \${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error occurred';
      }
      throw Exception(errorMessage);
    }
  }
}
