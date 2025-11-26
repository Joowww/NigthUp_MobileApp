import 'package:dio/dio.dart' as dio;
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

    // Interceptor para logging y auth
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Añadir token automáticamente
          final token = _storageService.read(StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('🌐 API Request: ${options.method} ${options.uri}');
          if (options.data != null && options.data is Map) {
            final data = Map<String, dynamic>.from(options.data as Map);
            // Ocultar token en logs por seguridad
            if (data.containsKey('token')) {
              final t = data['token'];
              data['token'] = '[HIDDEN:${t.toString().length} chars]';
            }
            print('📤 Body: $data');
          } else if (options.data != null) {
            print('📤 Body: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.type} - ${error.message}');
          if (error.response != null) {
            print('📥 Error Response: ${error.response?.statusCode} - ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ========== AUTH METHODS ==========
  Future<AuthResponse> login(LoginRequest request) async {
    print('🔐 Sending login request for: ${request.username}');
    final response = await _dio.post(
      '/user/auth/login',
      data: request.toJson(),
    );
    print('✅ Login successful');
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    print('👤 Sending register request for: ${request.username}');
    final response = await _dio.post(
      '/user',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> googleAuth(String googleToken) async {
    print('🔐 Sending Google auth request');
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
    return AuthResponse.fromJson(response.data);
  }

  // ========== INTEREST & TAGS METHODS ==========
  Future<List<dynamic>> getTagsByType(String type) async {
    print('🔍 Getting tags for type: $type');
    final response = await _dio.get('/tag/type/$type');
    return response.data;
  }

  Future<void> saveInitialInterests(Map<String, dynamic> interests) async {
    print('💾 Saving initial interests: $interests');
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

  // Cancelar requests
  void cancelRequests({dio.CancelToken? token}) {
    token?.cancel('Cancelled by user');
  }
}