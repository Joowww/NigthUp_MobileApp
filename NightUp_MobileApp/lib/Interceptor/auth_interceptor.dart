import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Controllers/auth_controller.dart';

class AuthInterceptor extends http.BaseClient {
  final http.Client _inner = http.Client();
  final AuthController _authController = Get.find<AuthController>();

  static const String baseUri = 'http://localhost:3000/api';

  Completer<bool>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Añade token si está disponible
    final token = _authController.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'application/json';

    print('🔄 [INTERCEPTOR] Sending request to: ${request.url}');
    print('🔄 [INTERCEPTOR] Headers: ${request.headers}');

    var response = await _inner.send(request);

    // Si el token expiró, intentar refrescar
    if (response.statusCode == 401) {
      print('🔄 [INTERCEPTOR] Token expired, attempting refresh...');
      final success = await _refreshAccessToken();
      if (success) {
        // Reintentar la request original con el nuevo token
        final newToken = _authController.token;
        if (newToken != null && newToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $newToken';
          return await _inner.send(request);
        }
      } else {
        // Si el refresh falla, hacer logout
        _authController.logout();
        Get.offAllNamed('/login');
      }
    }

    return response;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshing != null) {
      return await _refreshing!.future;
    }

    _refreshing = Completer<bool>();

    try {
      final refreshToken = _authController.refreshToken;
      final userId = _authController.currentUser.value?.id;

      if (refreshToken == null || refreshToken.isEmpty || userId == null) {
        print('❌ [INTERCEPTOR] No refresh token or user ID available');
        _refreshing!.complete(false);
        _refreshing = null;
        return false;
      }

      print('🔄 [INTERCEPTOR] Refreshing token for user: $userId');

      final response = await http.post(
        Uri.parse('$baseUri/user/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
          'userId': userId,
        }),
      );

      print('🔄 [INTERCEPTOR] Refresh response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          _authController.token = newToken;
          
          // Actualizar en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', newToken);

          _refreshing!.complete(true);
          _refreshing = null;
          return true;
        }
      }

      _refreshing!.complete(false);
      _refreshing = null;
      return false;
    } catch (e) {
      print('❌ [INTERCEPTOR] Error refreshing token: $e');
      _refreshing!.complete(false);
      _refreshing = null;
      return false;
    }
  }

  // Métodos auxiliares para compatibilidad
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return await _sendUnstreamed('GET', url, headers);
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _sendUnstreamed('POST', url, headers, body, encoding);
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _sendUnstreamed('PUT', url, headers, body, encoding);
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _sendUnstreamed('PATCH', url, headers, body, encoding);
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return await _sendUnstreamed('DELETE', url, headers, body, encoding);
  }

  Future<http.Response> _sendUnstreamed(
      String method, Uri url, Map<String, String>? headers,
      [Object? body, Encoding? encoding]) async {
    var request = http.Request(method, url);
    
    if (headers != null) {
      request.headers.addAll(headers);
    }
    
    // Añadir token si está disponible
    final token = _authController.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'application/json';

    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.body = jsonEncode(body);
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    var streamedResponse = await send(request);
    return await http.Response.fromStream(streamedResponse);
  }
}