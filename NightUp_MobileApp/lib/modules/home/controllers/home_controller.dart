import 'package:get/get.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeController extends GetxController {
  final EventRepository _eventRepository = EventRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxList<EventModel> featuredEvents = <EventModel>[].obs;
  final RxList<EventModel> myEvents = <EventModel>[].obs;
  final RxList<UserModel> recentUsers = <UserModel>[].obs;
  
  // Estadísticas
  final RxInt totalEvents = 0.obs;
  final RxInt totalUsers = 0.obs;
  final RxInt activeEvents = 0.obs;
  final RxInt activeUsers = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadHomeData();
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  Future<void> loadHomeData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        loadFeaturedEvents(),
        loadMyEvents(),
        loadRecentUsers(),
        loadStats(),
      ]);
    } catch (e) {
      print('Error loading home data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFeaturedEvents() async {
    try {
      final result = await _eventRepository.getEvents(limit: 5);
      final events = result['events'] as List<EventModel>;
      featuredEvents.value = events;
    } catch (e) {
      print('Error loading featured events: $e');
    }
  }

  Future<void> loadMyEvents() async {
    try {
      // Temporalmente usar eventos normales hasta que se implemente myEvents en el backend
      final result = await _eventRepository.getEvents(limit: 5);
      final events = result['events'] as List<EventModel>;
      // Filtrar eventos del usuario actual si es necesario
      myEvents.value = events.where((event) => 
        // Por ahora mostrar todos los eventos, se puede filtrar cuando se implemente
        true
      ).toList();
    } catch (e) {
      print('Error loading my events: $e');
    }
  }

  Future<void> loadRecentUsers() async {
    try {
      // Ahora todos los usuarios pueden ver la lista de usuarios
      final result = await _userRepository.getUsers(limit: 10);
      final users = result['users'] as List<UserModel>;
      recentUsers.value = users;
    } catch (e) {
      print('Error loading recent users: $e');
      recentUsers.value = [];
    }
  }

  Future<void> loadStats() async {
    try {
      // Cargar estadísticas de eventos
      final eventStats = await _eventRepository.getEventStats();
      totalEvents.value = eventStats['total'] ?? 0;
      activeEvents.value = eventStats['active'] ?? 0;
      
      // Cargar estadísticas de usuarios
      final userStats = await _userRepository.getUserStats();
      totalUsers.value = userStats['total'] ?? 0;
      activeUsers.value = userStats['active'] ?? 0;
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> refreshData() async {
    await loadHomeData();
  }

  UserModel? get currentUser => _authController.currentUser.value;
}