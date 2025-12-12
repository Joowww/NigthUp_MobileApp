//menu_modal_controller.dart
import 'package:get/get.dart';
import 'dart:developer';
import '../models/business.dart';
import '../models/event.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

class MenuModalController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  var currentTab = 0.obs;
  var isLoadingBusinesses = false.obs;
  var isLoadingEvents = false.obs;
  var isLoadingFriends = true.obs;

  var businesses = <Business>[].obs;
  var events = <Event>[].obs;
  var friends = <Friend>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBusinesses();
    fetchEvents();
    fetchFriends();
  }

  void changeTab(int index) {
    currentTab.value = index;
  }

  Future<void> fetchBusinesses() async {
    isLoadingBusinesses.value = true;
    try {
      final response = await _apiService.get('/business');
      
      // ✅ CORREGIDO: Conversión segura con manejo de errores
      if (response.data is List) {
        businesses.value = (response.data as List)
            .map((json) => Business.fromJson(json))
            .toList();
        print('✅ Loaded ${businesses.length} businesses');
      } else if (response.data is Map && response.data['businesses'] is List) {
        businesses.value = (response.data['businesses'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
        print('✅ Loaded ${businesses.length} businesses');
      } else {
        // ✅ FALLBACK: Datos de ejemplo
        businesses.value = [
          Business(
            id: 'business_1',
            name: 'Bar Ejemplo',
            address: 'Calle Principal 123',
            phone: '666777888',
            avatar: '',
            events: [],
            managers: [],
            active: true,
          )
        ];
        print('⚠️ Using fallback businesses data');
      }
    } catch (e) {
      print('❌ Error loading businesses: $e');
      businesses.value = [];
    } finally {
      isLoadingBusinesses.value = false;
    }
  }

  Future<void> fetchEvents() async {
    isLoadingEvents.value = true;
    try {
      final response = await _apiService.get('/event');
      
      // ✅ CORREGIDO: Conversión segura con manejo de errores
      if (response.data is List) {
        events.value = (response.data as List)
            .map((json) => Event.fromJson(json))
            .toList();
        print('✅ Loaded ${events.length} events');
      } else if (response.data is Map && response.data['events'] is List) {
        events.value = (response.data['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();
        print('✅ Loaded ${events.length} events');
      } else {
        // ✅ FALLBACK: Datos de ejemplo
        events.value = [
          Event(
            id: 'event_1',
            title: 'Fiesta de Ejemplo',
            venue: 'Sala Principal',
            description: 'Una gran fiesta',
            image: '',
            price: 15.0,
            date: DateTime.now().add(Duration(days: 1)),
            tags: ['Techno', 'Electrónica'],
            likes: 42,
            participantsCount: 120,
          )
        ];
        print('⚠️ Using fallback events data');
      }
    } catch (e) {
      print('❌ Error loading events: $e');
      events.value = [];
    } finally {
      isLoadingEvents.value = false;
    }
  }

  // Nuevo: Actualizar estado de amistad de cada amigo usando la ruta /friendship/status/{userId}
  Future<void> updateFriendsStatus() async {
    final ApiService apiService = _apiService;
    for (var friend in friends) {
      try {
        final response = await apiService.get('/friendship/status/${friend.id}');
        if (response.data is Map && response.data['status'] != null) {
          // Puedes guardar el status en un nuevo campo si lo necesitas
          // Ejemplo: friend.friendshipStatus = response.data['status'];
          log('🔗 Estado amistad de ${friend.username}: ${response.data['status']}');
        }
      } catch (e) {
        log('❌ Error obteniendo estado de amistad de ${friend.username}: $e');
      }
    }
  }

  Future<void> fetchFriends() async {
    isLoadingFriends.value = true;
    try {
      final response = await _apiService.get('/friendship/friends');
      // Log para depuración de datos recibidos
      log('🔍 Friends API response: \n${response.data}');
      if (response.data is List) {
        friends.value = (response.data as List)
            .map((json) => Friend.fromJson(json))
            .toList();
        for (var f in friends) {
          log('👤 ${f.username} online: ${f.isOnline}');
        }
        log('✅ Loaded ${friends.length} friends from backend');
        // Actualizar estado de amistad de cada amigo
        await updateFriendsStatus();
      } else if (response.data is Map && response.data['friends'] is List) {
        friends.value = (response.data['friends'] as List)
            .map((json) => Friend.fromJson(json))
            .toList();
        for (var f in friends) {
          log('👤 ${f.username} online: ${f.isOnline}');
        }
        log('✅ Loaded ${friends.length} friends from backend');
        // Actualizar estado de amistad de cada amigo
        await updateFriendsStatus();
      } else {
        // ✅ FALLBACK: Datos de ejemplo
        friends.value = [
          Friend(
            id: 'friend_1',
            username: 'Amigo Ejemplo',
            profilePictureUrl: '',
            isOnline: true,
            distance: 2.5,
          )
        ];
        log('⚠️ Using fallback friends data');
      }
    } catch (e) {
      log('❌ Error loading friends: $e');
      friends.value = [];
    } finally {
      isLoadingFriends.value = false;
    }
  }

  void refreshData() {
    if (currentTab.value == 0) fetchBusinesses();
    if (currentTab.value == 1) fetchEvents();
    if (currentTab.value == 2) fetchFriends();
  }
}