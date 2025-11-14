import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/trust_model.dart';
import '../../../data/repositories/trust_repository.dart';
import '../../../data/repositories/user_repository.dart';

class UserProfileController extends GetxController {
  final TrustRepository _trustRepository = TrustRepository();
  final UserRepository _userRepository = UserRepository();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxList<TrustModel> receivedRatings = <TrustModel>[].obs;
  final RxList<TrustModel> givenRatings = <TrustModel>[].obs;
  final RxBool isLoading = false.obs;
  
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalReceivedRatings = 0.obs;

  String? userId;

  @override
  void onInit() {
    super.onInit();
    userId = Get.parameters['userId'];
    if (userId != null) {
      loadUserProfile();
    }
  }

  void setUser(UserModel userModel) {
    user.value = userModel;
    userId = userModel.id;
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    if (userId == null) return;
    
    try {
      isLoading.value = true;
      
      // Cargar información del usuario si no está disponible
      if (user.value == null) {
        await loadUserData();
      }
      
      // Cargar valoraciones recibidas
      await loadReceivedRatings();
      
      // Cargar valoraciones dadas
      await loadGivenRatings();
      
      // Calcular estadísticas
      calculateStats();
      
    } catch (e) {
      print('Error loading user profile: $e');
      Get.snackbar(
        'Error',
        'No se pudo cargar el perfil del usuario',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserData() async {
    if (userId == null) return;
    
    try {
      final userData = await _userRepository.getUserById(userId!);
      user.value = userData;
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> loadReceivedRatings() async {
    if (userId == null) return;
    
    try {
      final ratings = await _trustRepository.getUserReceivedRatings(userId!);
      receivedRatings.value = ratings;
    } catch (e) {
      print('Error loading received ratings: $e');
      receivedRatings.clear();
    }
  }

  Future<void> loadGivenRatings() async {
    if (userId == null) return;
    
    try {
      final ratings = await _trustRepository.getUserGivenRatings(userId!);
      givenRatings.value = ratings;
    } catch (e) {
      print('Error loading given ratings: $e');
      givenRatings.clear();
    }
  }

  void calculateStats() {
    if (receivedRatings.isEmpty) {
      averageRating.value = 0.0;
      totalReceivedRatings.value = 0;
      return;
    }

    final total = receivedRatings.fold<int>(
      0,
      (sum, rating) => sum + rating.score,
    );
    
    averageRating.value = total / receivedRatings.length;
    totalReceivedRatings.value = receivedRatings.length;
  }

  Future<void> refreshProfile() async {
    await loadUserProfile();
  }
}