import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:async';
import '../Controllers/auth_controller.dart';

class AuthInterceptor extends http.BaseClient {
  final http.Client _inner = http.Client();
  final AuthController _auth = Get.find<AuthController>();

  static const String baseUri = 'http://localhost:3000/api';

  Future<bool>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Añade token si hay
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'application/json';
    final token = _auth.token;
    print('el token es $token');
    if (token != null && token.isNotEmpty) {
      
      request.headers['Authorization'] = 'Bearer $token';
    }

    var response = await _inner.send(request);

    // Si expira, refresca y reintenta 1 vez
    if (response.statusCode == 401) {
      final ok = await _refreshToken();
      if (ok) {
        final retried = await _retry(request);
        return retried;
      }
    }

    return response;
  }

  Future<http.StreamedResponse> _retry(http.BaseRequest original) async {
    // Reconstruye la Request con el nuevo token
    final newReq = _cloneRequestWithNewToken(original, _auth.token);
    return _inner.send(newReq);
  }

  http.BaseRequest _cloneRequestWithNewToken(http.BaseRequest original, String? newToken) {
    if (original is http.Request) {
      final r = http.Request(original.method, original.url);
      r.headers.addAll(original.headers);
      if (newToken != null && newToken.isNotEmpty) {
        r.headers['Authorization'] = 'Bearer $newToken';
      }
      r.bodyBytes = original.bodyBytes;
      return r;
    } else if (original is http.MultipartRequest) {
      final r = http.MultipartRequest(original.method, original.url);
      r.headers.addAll(original.headers);
      if (newToken != null && newToken.isNotEmpty) {
        r.headers['Authorization'] = 'Bearer $newToken';
      }
      r.fields.addAll(original.fields);
      r.files.addAll(original.files);
      return r;
    } else {
      // Caso genérico
      final r = http.Request(original.method, original.url);
      r.headers.addAll(original.headers);
      if (newToken != null && newToken.isNotEmpty) {
        r.headers['Authorization'] = 'Bearer $newToken';
      }
      return r;
    }
  }

  Future<bool> _refreshToken() async {
    if (_refreshing != null) return await _refreshing!;
    final completer = Completer<bool>();
    _refreshing = completer.future;

    try {
      final refreshToken = _auth.refreshToken;
      final userId = _auth.currentUser.value?.id; 

      if (refreshToken == null || refreshToken.isEmpty || userId == null) {
        completer.complete(false);
        _refreshing = null;
        return false;
      }

      final res = await http.post(
        Uri.parse('$baseUri/user/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken, 
          'userId': userId,             
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newAccess = data['token'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newAccess == null || newAccess.isEmpty) {
          completer.complete(false);
          _refreshing = null;
          return false;
        }

        _auth.token = newAccess;
        if (newRefresh != null && newRefresh.isNotEmpty) {
          _auth.refreshToken = newRefresh;
        }
        completer.complete(true);
        _refreshing = null;
        return true;
      } else {
        _auth.logout();
        Get.offAllNamed('/login');
        completer.complete(false);
        _refreshing = null;
        return false;
      }
    } catch (e) {
      // Error de red
      completer.complete(false);
      _refreshing = null;
      return false;
    }
  }
}
