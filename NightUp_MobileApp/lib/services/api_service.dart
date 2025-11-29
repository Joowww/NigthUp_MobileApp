import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ApiService extends GetxService {
  late dio.Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();

    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Función auxiliar para refrescar token y guardar
    Future<bool> refreshTokenAndSave(String refreshToken, String userId) async {
      try {
        final resp = await this.refreshToken(refreshToken, userId);
        _storageService.write(StorageKeys.token, resp.token);
        _storageService.write(StorageKeys.refreshToken, resp.refreshToken);
        _storageService.write(StorageKeys.user, resp.user.toJson());
          log('🔄 Token refrescado automáticamente');
        return true;
      } catch (e) {
          log('❌ Error refrescando token: $e');
        return false;
      }
    }

    // Función auxiliar para cerrar sesión y limpiar storage
    Future<void> logoutAndClearStorage() async {
      try {
        await _storageService.remove(StorageKeys.token);
        await _storageService.remove(StorageKeys.refreshToken);
        await _storageService.remove(StorageKeys.user);
          log('🚪 Sesión cerrada por token inválido');
      } catch (e) {
          log('❌ Error limpiando storage al cerrar sesión: $e');
      }
    }

    // Interceptor para logging, auth y refresco automático de token
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Añadir token automáticamente
          final token = _storageService.read(StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

            log('🌐 API Request: ${options.method} ${options.uri}');
          if (options.data != null && options.data is Map) {
            final data = Map<String, dynamic>.from(options.data as Map);
            // Ocultar token en logs por seguridad
            if (data.containsKey('token')) {
              final t = data['token'];
              data['token'] = '[HIDDEN:${t.toString().length} chars]';
            }
              log('📤 Body: $data');
          } else if (options.data != null) {
              log('📤 Body: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
           log('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) async {
            log('❌ API Error: ${error.type} - ${error.message}');
          if (error.response != null) {
              log('📥 Error Response: ${error.response?.statusCode} - ${error.response?.data}');
          }

          // Manejo automático de refresco de token si es 401
          if (error.response?.statusCode == 401) {
            try {
              // Intentar refrescar el token
              final refreshToken = _storageService.read(StorageKeys.refreshToken);
              final userJson = _storageService.read(StorageKeys.user);
              if (refreshToken != null && userJson != null) {
                final userMap = userJson is String ? json.decode(userJson) : userJson;
                final userId = userMap['id'] ?? userMap['userId'] ?? userMap['uid'];
                if (userId != null) {
                  final refreshed = await refreshTokenAndSave(refreshToken, userId.toString());
                  if (refreshed) {
                    // Reintentar la petición original con el nuevo token
                    final newToken = _storageService.read(StorageKeys.token);
                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newToken';
                    final cloneReq = await _dio.request(
                      opts.path,
                      data: opts.data,
                      queryParameters: opts.queryParameters,
                      options: dio.Options(
                        method: opts.method,
                        headers: opts.headers,
                        contentType: opts.contentType,
                        responseType: opts.responseType,
                        followRedirects: opts.followRedirects,
                        validateStatus: opts.validateStatus,
                        receiveDataWhenStatusError: opts.receiveDataWhenStatusError,
                        extra: opts.extra,
                      ),
                    );
                    return handler.resolve(cloneReq);
                  }
                }
              }
              // Si no se pudo refrescar, cerrar sesión
              await logoutAndClearStorage();
            } catch (e) {
                log('❌ Error al refrescar token automáticamente: $e');
              await logoutAndClearStorage();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ========== AUTH METHODS ==========
  Future<AuthResponse> login(LoginRequest request) async {
      log('🔐 Sending login request for: ${request.username}');
    final response = await _dio.post(
      '/user/auth/login',
      data: request.toJson(),
    );
      log('✅ Login successful');
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
      log('👤 Sending register request for: ${request.username}');
    final response = await _dio.post(
      '/user',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> googleAuth(String googleToken) async {
      log('🔐 Sending Google auth request');
    final response = await _dio.post(
      '/user/auth/google',
      data: {'token': googleToken},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<SecurityQuestionResponse> getSecurityQuestions() async {
    final response = await _dio.get('/user/security-questions');
    return SecurityQuestionResponse.fromJson(response.data);
  }

  Future<ForgotPasswordResponse> forgotPassword(String email) async {
    final response = await _dio.post(
      '/user/forgot-password',
      data: {'email': email},
    );
    return ForgotPasswordResponse.fromJson(response.data);
  }

  Future<VerifySecurityAnswerResponse> verifySecurityAnswer(
    String email,
    String securityAnswer,
  ) async {
    final response = await _dio.post(
      '/user/verify-security-answer',
      data: {
        'email': email,
        'securityAnswer': securityAnswer,
      },
    );
    return VerifySecurityAnswerResponse.fromJson(response.data);
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    await _dio.post(
      '/user/reset-password',
      data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );
  }

  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await _dio.get(
      '/user/auth/verify',
      options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<AuthResponse> refreshToken(String refreshToken, String userId) async {
    final response = await _dio.post(
      '/user/auth/refresh',
      data: {
        'refreshToken': refreshToken,
        'userId': userId,
      },
    );
    if (response.data == null || response.data is! Map<String, dynamic>) {
        log('❌ Respuesta inesperada al refrescar token: ${response.data}');
      throw Exception('Respuesta inesperada al refrescar token');
    }
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ========== INTEREST & TAGS METHODS ==========
  Future<List<dynamic>> getTagsByType(String type) async {
     log('🔍 Getting tags for type: $type');
    final response = await _dio.get('/tag/type/$type');
    return response.data;
  }

  Future<void> saveInitialInterests(Map<String, dynamic> interests) async {
      log('💾 Saving initial interests: $interests');
    await _dio.post(
      '/initial-interest/initial-selection',
      data: interests,
    );
  }

  // ========== FILE UPLOAD METHODS ==========
  Future<dio.Response> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? data,
    dio.ProgressCallback? onSendProgress,
  }) async {
    final formData = dio.FormData.fromMap({
      fieldName: await dio.MultipartFile.fromFile(filePath),
      ...?data,
    });

    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  Future<dio.Response> uploadMultipleFiles(
    String path, {
    required List<String> filePaths,
    String fieldName = 'files',
    Map<String, dynamic>? data,
    dio.ProgressCallback? onSendProgress,
  }) async {
    final files = await Future.wait(
      filePaths.map((filePath) => dio.MultipartFile.fromFile(filePath)),
    );

    final formData = dio.FormData.fromMap({
      fieldName: files,
      ...?data,
    });

    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  // ========== GENERIC METHODS ==========
  Future<dio.Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<dio.Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<dio.Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<dio.Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<dio.Response> delete(String path) async {
    return await _dio.delete(path);
  }

  String? getUserId() {
  final token = _storageService.read(StorageKeys.token);
  if (token != null) {
    try {
      // Decodificar el token JWT para obtener el user ID
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Añadir padding si es necesario para base64Url
      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      
      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = json.decode(decoded);
      return payloadMap['id']?.toString();
    } catch (e) {
      log('❌ Error decoding token: $e');
      return null;
    }
  }
  return null;
}

  // Cancelar requests
  void cancelRequests({dio.CancelToken? token}) {
    token?.cancel('Cancelled by user');
  }
}