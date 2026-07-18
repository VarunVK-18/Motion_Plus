import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/port.dart';

class ApiService {
  static String get baseUrl => PortConstants.apiUrl;
  static const _storage = FlutterSecureStorage();

  static Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
  }

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
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Generic POST Request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    try {
      await _checkConnectivity();
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = '$baseUrl$endpoint';
      // ignore: avoid_print
      debugPrint('API POST: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('API POST ERROR: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic GET Request
  static Future<dynamic> get(String endpoint, {bool includeAuth = true}) async {
    try {
      await _checkConnectivity();
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = '$baseUrl$endpoint';
      // ignore: avoid_print
      debugPrint('API GET: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('API GET ERROR: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT Request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    try {
      await _checkConnectivity();
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = '$baseUrl$endpoint';
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE Request
  static Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      await _checkConnectivity();
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = '$baseUrl$endpoint';
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method to process responses
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          try {
            // Attempt to cast to List<Map<String, dynamic>> if possible
            if (decoded.isEmpty) return <Map<String, dynamic>>[];
            if (decoded.first is Map) {
              return List<Map<String, dynamic>>.from(
                decoded.map((e) => Map<String, dynamic>.from(e as Map))
              );
            }
          } catch (_) {
            // Fallback if elements aren't maps
          }
        }
        return decoded;
      }
      return null;
    } else {
      String errorMessage = 'Error ${response.statusCode}';
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
