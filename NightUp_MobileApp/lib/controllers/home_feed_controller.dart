import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class HomeFeedController extends GetxController with GetSingleTickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();

  // Estado del TabBar y PageView
  late TabController tabController;
  final PageController pageController = PageController();
  
  // Datos reactivos (observables)
  var discoverEvents = <Event>[].obs;
  var friendsPosts = <Post>[].obs;
  var isLoadingDiscover = true.obs;
  var isLoadingFriends = true.obs;
  var currentPage = 0.obs;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    
    // LISTENER CORREGIDO: Forzar actualización cuando cambia el tab
    tabController.addListener(_handleTabChange);

    fetchDiscoverEvents();
    fetchFriendsPosts();
    super.onInit();
  }

  // NUEVO: Manejar cambio de tabs
  void _handleTabChange() {
    if (tabController.indexIsChanging) {
      update(['tab_selection', 'discover_feed', 'friends_feed']); // Actualizar múltiples IDs
    }
  }

  // Obtener eventos para el feed Discover (Para Ti)
  void fetchDiscoverEvents() async {
    isLoadingDiscover.value = true;
    try {
      print('🔄 Fetching events from /event endpoint...');
      
      // Usar el endpoint general de eventos que YA TIENES
      final response = await _apiService.get('/event?limit=20');
      
      print('✅ Events response: ${response.data}');
      
      // Tu endpoint devuelve { events: [], pagination: {} }
      if (response.data is Map && response.data['events'] is List) {
        discoverEvents.value = (response.data['events'] as List)
            .map((i) => Event.fromJson(i))
            .toList();
        
        print('✅ Loaded ${discoverEvents.length} events from /event endpoint');
      } else {
        print('❌ Unexpected response format: ${response.data}');
        discoverEvents.value = [];
      }
      
    } catch (e) {
      print('❌ Error loading events: $e');
      Get.snackbar(
        'Error', 
        'No se pudo cargar los eventos: $e', 
        snackPosition: SnackPosition.BOTTOM
      );
      discoverEvents.value = [];
    } finally {
      isLoadingDiscover.value = false;
      update(['discover_feed']); // Asegurar actualización
    }
  }

  // Obtener posts de amigos
  void fetchFriendsPosts() async {
    isLoadingFriends.value = true;
    try {
      print('🔄 Fetching friends posts from backend...');
      
      // Usar el endpoint real de tu backend para el feed de amigos
      final response = await _apiService.get('/post/feed/friends');
      
      print('✅ Friends posts response: ${response.data}');
      
      friendsPosts.value = (response.data as List)
          .map((i) => Post.fromFriendPostJson(i))
          .toList();

      print('✅ Loaded ${friendsPosts.length} posts from friends');
    } catch (e) {
      print('❌ Error loading friends posts: $e');
      Get.snackbar(
        'Error', 
        'No se pudo cargar el feed de Amigos: $e', 
        snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoadingFriends.value = false;
      update(['friends_feed']); // Asegurar actualización
    }
  }

  // Refresh ambos feeds
  void refreshAllFeeds() {
    fetchDiscoverEvents();
    fetchFriendsPosts();
  }

  // Cambiar tab manualmente
  void changeTab(int index) {
    tabController.animateTo(index);
    update(['tab_selection', 'discover_feed', 'friends_feed']);
  }

  @override
  void onClose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    pageController.dispose();
    super.onClose();
  }
}