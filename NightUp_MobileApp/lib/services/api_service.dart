import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ApiService extends GetxService {
  late dio.Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();
  String get baseUrl => ApiConstants.baseUrl;

  @override
  void onInit() {
    super.onInit();

    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    Future<bool> refreshTokenAndSave(String refreshToken, String userId) async {
      try {
        final resp = await this.refreshToken(refreshToken, userId);
        _storageService.write(StorageKeys.token, resp.token);
        _storageService.write(StorageKeys.refreshToken, resp.refreshToken);
        _storageService.write(StorageKeys.user, resp.user.toJson());
        return true;
      } catch (e) {
        return false;
      }
    }

    Future<void> logoutAndClearStorage() async {
      try {
        await _storageService.remove(StorageKeys.token);
        await _storageService.remove(StorageKeys.refreshToken);
        await _storageService.remove(StorageKeys.user);
      } catch (e) {}
    }

    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storageService.read(StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final refreshToken = _storageService.read(
                StorageKeys.refreshToken,
              );
              final userJson = _storageService.read(StorageKeys.user);
              if (refreshToken != null && userJson != null) {
                final userMap = userJson is String
                    ? json.decode(userJson)
                    : userJson;
                final userId =
                    userMap['id'] ?? userMap['userId'] ?? userMap['uid'];
                if (userId != null) {
                  final refreshed = await refreshTokenAndSave(
                    refreshToken,
                    userId.toString(),
                  );
                  if (refreshed) {
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
                        receiveDataWhenStatusError:
                            opts.receiveDataWhenStatusError,
                        extra: opts.extra,
                      ),
                    );
                    return handler.resolve(cloneReq);
                  }
                }
              }
              await logoutAndClearStorage();
            } catch (e) {
              await logoutAndClearStorage();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/user/auth/login',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post('/user', data: request.toJson());
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> googleAuth(String googleToken) async {
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
      data: {'email': email, 'securityAnswer': securityAnswer},
    );
    return VerifySecurityAnswerResponse.fromJson(response.data);
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    await _dio.post(
      '/user/reset-password',
      data: {'resetToken': resetToken, 'newPassword': newPassword},
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
      data: {'refreshToken': refreshToken, 'userId': userId},
    );
    if (response.data == null || response.data is! Map<String, dynamic>) {
      throw Exception('Respuesta inesperada al refrescar token');
    }
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String?> uploadToCloudinary(
    XFile file,
    String folder, {
    String resourceType = 'image',
  }) async {
    try {
      final response = await uploadFile(
        '/files/upload',
        file: file,
        fieldName: 'image',
        data: {'folder': folder, 'resourceType': resourceType},
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['status'] == 'success') {
          return data['file_url'] ??
              data['image_url'] ??
              data['url'] ??
              data['secure_url'];
        }
      }
      throw Exception(
        'Error en respuesta del servidor: ${response.statusCode}',
      );
    } catch (e) {
      if (e is dio.DioException) {
        final errorMessage = e.response?.data?['message'] ?? e.message;
        throw Exception('Error del servidor: $errorMessage');
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getTagsByType(String type) async {
    final response = await _dio.get('/tag/type/$type');
    return response.data;
  }

  Future<void> saveInitialInterests(Map<String, dynamic> interests) async {
    await _dio.post('/initial-interest/initial-selection', data: interests);
  }

  Future<dio.Response> uploadFile(
    String path, {
    required XFile file,
    String fieldName = 'file',
    Map<String, dynamic>? data,
    dio.ProgressCallback? onSendProgress,
  }) async {
    dio.MultipartFile multipartFile;

    String? contentType;
    String finalFileName = file.name;

    final lowerName = finalFileName.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (lowerName.endsWith('.png')) {
      contentType = 'image/png';
    } else if (lowerName.endsWith('.webp')) {
      contentType = 'image/webp';
    } else if (lowerName.endsWith('.mp3')) {
      contentType = 'audio/mpeg';
    } else if (lowerName.endsWith('.m4a')) {
      contentType = 'audio/mp4';
    } else if (lowerName.endsWith('.wav')) {
      contentType = 'audio/wav';
    } else if (lowerName.endsWith('.aac')) {
      contentType = 'audio/aac';
    } else if (lowerName.endsWith('.webm')) {
      contentType = 'audio/webm';
    } else if (lowerName.endsWith('.ogg')) {
      contentType = 'audio/ogg';
    }

    if (kIsWeb) {
      if (finalFileName.isEmpty ||
          finalFileName == 'blob' ||
          !finalFileName.contains('.')) {
        final String resourceType = data?['resourceType'] ?? 'image';
        if (resourceType == 'video' || resourceType == 'audio') {
          finalFileName =
              'upload_${DateTime.now().millisecondsSinceEpoch}.webm';
        } else {
          finalFileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
        }
      }
      contentType ??= 'application/octet-stream';
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      multipartFile = dio.MultipartFile.fromBytes(
        bytes,
        filename: finalFileName,
        contentType: contentType != null ? MediaType.parse(contentType) : null,
      );
    } else {
      multipartFile = await dio.MultipartFile.fromFile(
        file.path,
        filename: finalFileName,
        contentType: contentType != null ? MediaType.parse(contentType) : null,
      );
    }

    final formData = dio.FormData.fromMap({fieldName: multipartFile, ...?data});

    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  Future<dio.Response> uploadMultipleFiles(
    String path, {
    required List<XFile> files,
    String fieldName = 'files',
    Map<String, dynamic>? data,
    dio.ProgressCallback? onSendProgress,
  }) async {
    final multipartFiles = <dio.MultipartFile>[];

    for (var file in files) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFiles.add(
          dio.MultipartFile.fromBytes(bytes, filename: file.name),
        );
      } else {
        multipartFiles.add(
          await dio.MultipartFile.fromFile(file.path, filename: file.name),
        );
      }
    }

    final formData = dio.FormData.fromMap({
      fieldName: multipartFiles,
      ...?data,
    });

    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on dio.DioException catch (e) {
      if (_shouldRetryWithLocalhost(e)) {
        final dioLocal = dio.Dio(
          dio.BaseOptions(
            baseUrl: 'http://localhost:3000/api',
            connectTimeout: const Duration(
              milliseconds: ApiConstants.connectTimeout,
            ),
            receiveTimeout: const Duration(
              milliseconds: ApiConstants.receiveTimeout,
            ),
            headers: {'Content-Type': 'application/json'},
          ),
        );
        try {
          return await dioLocal.get(path, queryParameters: queryParameters);
        } on dio.DioException {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<dio.Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on dio.DioException catch (e) {
      if (_shouldRetryWithLocalhost(e)) {
        final dioLocal = dio.Dio(
          dio.BaseOptions(
            baseUrl: 'http://localhost:3000/api',
            connectTimeout: const Duration(
              milliseconds: ApiConstants.connectTimeout,
            ),
            receiveTimeout: const Duration(
              milliseconds: ApiConstants.receiveTimeout,
            ),
            headers: {'Content-Type': 'application/json'},
          ),
        );
        try {
          return await dioLocal.post(path, data: data);
        } on dio.DioException {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<dio.Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on dio.DioException catch (e) {
      if (_shouldRetryWithLocalhost(e)) {
        final dioLocal = dio.Dio(
          dio.BaseOptions(
            baseUrl: 'http://localhost:3000/api',
            connectTimeout: const Duration(
              milliseconds: ApiConstants.connectTimeout,
            ),
            receiveTimeout: const Duration(
              milliseconds: ApiConstants.receiveTimeout,
            ),
            headers: {'Content-Type': 'application/json'},
          ),
        );
        try {
          return await dioLocal.put(path, data: data);
        } on dio.DioException {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<dio.Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on dio.DioException catch (e) {
      if (_shouldRetryWithLocalhost(e)) {
        final dioLocal = dio.Dio(
          dio.BaseOptions(
            baseUrl: 'http://localhost:3000/api',
            connectTimeout: const Duration(
              milliseconds: ApiConstants.connectTimeout,
            ),
            receiveTimeout: const Duration(
              milliseconds: ApiConstants.receiveTimeout,
            ),
            headers: {'Content-Type': 'application/json'},
          ),
        );
        try {
          return await dioLocal.patch(path, data: data);
        } on dio.DioException {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<dio.Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on dio.DioException catch (e) {
      if (_shouldRetryWithLocalhost(e)) {
        final dioLocal = dio.Dio(
          dio.BaseOptions(
            baseUrl: 'http://localhost:3000/api',
            connectTimeout: const Duration(
              milliseconds: ApiConstants.connectTimeout,
            ),
            receiveTimeout: const Duration(
              milliseconds: ApiConstants.receiveTimeout,
            ),
            headers: {'Content-Type': 'application/json'},
          ),
        );
        try {
          return await dioLocal.delete(path);
        } on dio.DioException {
          rethrow;
        }
      }
      rethrow;
    }
  }

  bool _shouldRetryWithLocalhost(dio.DioException e) {
    return e.type == dio.DioExceptionType.connectionError ||
        e.type == dio.DioExceptionType.unknown;
  }

  String? getUserId() {
    final token = _storageService.read(StorageKeys.token);
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return null;

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
        return null;
      }
    }
    return null;
  }

  String? getUsername() {
    final token = _storageService.read(StorageKeys.token);
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return null;

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

        return payloadMap['username']?.toString() ??
            payloadMap['name']?.toString() ??
            payloadMap['email']?.toString()?.split('@')[0] ??
            'Usuario';
      } catch (e) {
        return 'Usuario';
      }
    }
    return 'Usuario';
  }

  Map<String, dynamic>? getUserFromToken() {
    final token = _storageService.read(StorageKeys.token);
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return null;

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
        return json.decode(decoded) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void cancelRequests({dio.CancelToken? token}) {
    token?.cancel('Cancelled by user');
  }
}
