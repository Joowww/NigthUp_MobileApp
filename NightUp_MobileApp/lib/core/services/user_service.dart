import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'storage_service.dart';

class UserService extends GetxService {
  final UserRepository _userRepository = UserRepository();
  final StorageService _storageService = StorageService();
  
  Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  UserModel? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final user = await _userRepository.getProfile();
        _currentUser.value = user;
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser.value == null) {
      await _loadCurrentUser();
    }
    return _currentUser.value;
  }

  void setCurrentUser(UserModel user) {
    _currentUser.value = user;
  }

  void clearCurrentUser() {
    _currentUser.value = null;
  }

  bool get isLoggedIn => _currentUser.value != null;

  String? get currentUsername => _currentUser.value?.username;

  Future<void> refreshCurrentUser() async {
    try {
      final user = await _userRepository.getProfile();
      _currentUser.value = user;
    } catch (e) {
      print('Error refreshing user: $e');
      clearCurrentUser();
    }
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<bool> refreshToken() async {
    // Por ahora simplemente limpiar token y redirigir al login
    try {
      await logout();
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    clearCurrentUser();
  }
}