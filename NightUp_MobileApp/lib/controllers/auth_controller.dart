import 'package:get/get.dart';
import '../services/api_service.dart';
import '../app.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/google_service.dart';
import 'dart:convert';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxString _token = ''.obs;
  final RxString _refreshToken = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  User? get currentUser => _currentUser.value;
  String get token => _token.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isLoggedIn => _token.isNotEmpty;

  void setToken(String token) => _token.value = token;
  void setRefreshToken(String refreshToken) =>
      _refreshToken.value = refreshToken;
  void setUser(User user) => _currentUser.value = user;
  void clearError() => _error.value = '';

  Future<bool> login(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _apiService.login(
        LoginRequest(username: email, password: password),
      );
      _token.value = response.token;
      _refreshToken.value = response.refreshToken;
      _currentUser.value = response.user;

      await _saveAuthData();

      final storage = Get.find<StorageService>();
      if (response.user.username == 'JoelMoreno' ||
          response.user.username == 'MINIM2ok') {
        await storage.write('onboarding_complete', true);
      } else {
        final onboardingComplete = storage.read('onboarding_complete');
        if (onboardingComplete == true) {
          await storage.write('onboarding_complete', true);
        }
      }

      await _navigateAfterLogin();

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> googleLoginWeb(String idToken) async {
    return {'success': false, 'isNewUser': false};
  }

  Future<bool> googleLogin() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final googleToken = await GoogleSignInService.getGoogleToken();
      if (googleToken != null) {
        final response = await _apiService.googleAuth(googleToken);
        _token.value = response.token;
        _refreshToken.value = response.refreshToken;
        _currentUser.value = response.user;
        await _saveAuthData();

        await _navigateAfterLogin();

        return true;
      }

      final account = await GoogleSignInService.signIn();
      if (account == null) {
        _error.value = 'Google Sign-In cancelado';
        return false;
      }

      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null) {
        _error.value = 'Error al obtener el token de Google';
        return false;
      }

      final response = await _apiService.googleAuth(token);
      _token.value = response.token;
      _refreshToken.value = response.refreshToken;
      _currentUser.value = response.user;
      await _saveAuthData();

      await _navigateAfterLogin();

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
    required DateTime birthday,
    required String securityQuestionKey,
    required String securityAnswer,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _apiService.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
          phoneNumber: phoneNumber,
          birthday: birthday,
          securityQuestionKey: securityQuestionKey,
          securityAnswer: securityAnswer,
        ),
      );

      // _token.value = response.token;
      // _refreshToken.value = response.refreshToken;
      // _currentUser.value = response.user;

      // await _saveAuthData();

      // Get.offAll(() => const App());

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _navigateAfterLogin() async {
    try {
      Get.offAllNamed('/home');
    } catch (e) {
      Get.offAll(() => const App());
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    try {
      final storage = Get.find<StorageService>();
      final onboardingComplete = storage.read('onboarding_complete');
      return onboardingComplete == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> markOnboardingComplete() async {
    try {
      final storage = Get.find<StorageService>();
      await storage.write('onboarding_complete', true);
    } catch (e) {}
  }

  Future<bool> saveInitialInterests({
    required String musicType,
    required String musician,
    required String eventType,
    required String childhoodIdol,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final dataToSend = {
        'musicType': musicType,
        'musician': musician,
        'eventType': eventType,
        'childhoodIdol': childhoodIdol,
      };

      await _apiService.saveInitialInterests(dataToSend);
      await markOnboardingComplete();

      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<List<dynamic>> getTagsByType(String type) async {
    try {
      return await _apiService.getTagsByType(type);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPasswordFlow({
    required String email,
    String? securityAnswer,
    String? newPassword,
    String? resetToken,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      if (securityAnswer == null && newPassword == null) {
        final response = await _apiService.forgotPassword(email);
        return {
          'success': true,
          'securityQuestionKey': response.securityQuestionKey,
          'email': response.email,
        };
      } else if (newPassword == null && securityAnswer != null) {
        final response = await _apiService.verifySecurityAnswer(
          email,
          securityAnswer,
        );
        return {'success': true, 'resetToken': response.resetToken};
      } else if (newPassword != null && resetToken != null) {
        await _apiService.resetPassword(resetToken, newPassword);
        return {'success': true};
      } else {
        throw Exception('Parámetros de flujo inválidos');
      }
    } catch (e) {
      _error.value = e.toString();
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> verifyToken() async {
    try {
      if (_token.isEmpty) return false;
      final response = await _apiService.verifyToken(_token.value);
      return response['valid'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshAuthToken() async {
    try {
      if (_refreshToken.value.isEmpty) return false;
      final response = await _apiService.refreshToken(
        _refreshToken.value,
        _currentUser.value?.id ?? '',
      );
      _token.value = response.token;
      _refreshToken.value = response.refreshToken;
      await _saveAuthData();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      await loadAuthData();
      if (!isLoggedIn) {
        return {'isLoggedIn': false, 'onboardingComplete': false};
      }
      final onboardingComplete = await hasCompletedOnboarding();
      return {
        'isLoggedIn': true,
        'onboardingComplete': onboardingComplete,
        'user': _currentUser.value,
      };
    } catch (e) {
      return {'isLoggedIn': false, 'onboardingComplete': false};
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignInService.signOut();
    } catch (e) {
    } finally {
      _token.value = '';
      _refreshToken.value = '';
      _currentUser.value = null;

      await _clearAuthData();
      await _clearOnboardingData();
    }
  }

  Future<void> _clearOnboardingData() async {
    try {
      final storage = Get.find<StorageService>();
      await storage.remove('onboarding_complete');
    } catch (e) {}
  }

  Future<void> _clearAuthData() async {
    try {
      final storage = Get.find<StorageService>();
      await storage.remove('token');
      await storage.remove('refreshToken');
      await storage.remove('user');
    } catch (e) {}
  }

  Future<void> _saveAuthData() async {
    try {
      final storage = Get.find<StorageService>();
      await storage.write('token', _token.value);
      await storage.write('refreshToken', _refreshToken.value);
      if (_currentUser.value != null) {
        await storage.write('user', _currentUser.value!.toJson());
      }
    } catch (e) {}
  }

  Future<void> loadAuthData() async {
    try {
      final storage = Get.find<StorageService>();
      final token = await storage.read('token');
      final refreshToken = await storage.read('refreshToken');
      final userData = await storage.read('user');
      if (token != null && token.isNotEmpty) {
        _token.value = token;
        _refreshToken.value = refreshToken ?? '';
        if (userData != null) {
          try {
            if (userData is String) {
              final decoded = jsonDecode(userData);
              _currentUser.value = User.fromJson(decoded);
            } else if (userData is Map<String, dynamic>) {
              _currentUser.value = User.fromJson(userData);
            } else {}
          } catch (e) {}
        }
      }
    } catch (e) {}
  }
}
