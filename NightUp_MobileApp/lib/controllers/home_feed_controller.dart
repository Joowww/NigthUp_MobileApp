import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:developer';
import '../models/post.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class HomeFeedController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();

  late TabController tabController;
  final PageController pageController = PageController();

  var discoverEvents = <Event>[].obs;
  var friendsPosts = <Post>[].obs;
  var isLoadingDiscover = true.obs;
  var isLoadingFriends = true.obs;
  var currentPage = 0.obs;

  var lastViewedPage = 0.obs;

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);

    fetchDiscoverEvents();
    fetchFriendsPosts();
    super.onInit();
  }

  void _handleTabChange() {
    if (tabController.indexIsChanging) {
      update([
        'tab_selection',
        'discover_feed',
        'friends_feed',
        'bottom_actions',
      ]);
    }
  }

  void fetchDiscoverEvents() async {
    final userId = _apiService.getUserId();
    log('👤 User ID from token: $userId');

    if (userId == null) {
      log('⚠️ No token or User ID invalid, no se cargan eventos');
      isLoadingDiscover.value = false;
      return;
    }
    isLoadingDiscover.value = true;
    try {
      log('🔄 Fetching events from /event endpoint...');

      final response = await _apiService.get('/event');

      log('📦 Raw API Response: ${response.data}');

      if (response.data is Map && response.data['events'] is List) {
        final eventsList = response.data['events'] as List;
        log('📋 Found ${eventsList.length} events in list');

        discoverEvents.value = eventsList.map((i) {
          return Event.fromJson(i);
        }).toList();

        await loadLikeStatusForEvents();
      } else if (response.data is List) {
        log('📋 Response is a direct List, converting...');
        final eventsList = response.data as List;
        discoverEvents.value = eventsList
            .map((i) => Event.fromJson(i))
            .toList();
        await loadLikeStatusForEvents();
      } else {
        log('❌ Unexpected response format: ${response.data.runtimeType}');
        discoverEvents.value = [];
      }
    } catch (e) {
      log('❌ Error loading events: $e');
      discoverEvents.value = [];
    } finally {
      isLoadingDiscover.value = false;
      update(['discover_feed', 'bottom_actions']);
    }
  }

  void fetchFriendsPosts() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      log('⚠️ No token, no se cargan posts de amigos');
      isLoadingFriends.value = false;
      return;
    }
    isLoadingFriends.value = true;
    try {
      log('🔄 Fetching friends posts from backend...');
      final response = await _apiService.get('/post/feed/friends');

      log('📦 Friends API Response Raw: ${response.data}');

      List<dynamic> postsData = [];

      if (response.data is List) {
        postsData = response.data;
      } else if (response.data is Map && response.data['posts'] is List) {
        postsData = response.data['posts'];
      } else if (response.data is Map && response.data['data'] is List) {
        postsData = response.data['data'];
      }

      friendsPosts.value = postsData
          .map((i) => Post.fromFriendPostJson(i))
          .toList();

      log('✅ Loaded ${friendsPosts.length} posts from friends');
    } catch (e) {
      log('❌ Error loading friends posts: $e');
      Get.snackbar(
        'Error',
        'No se pudo cargar el feed de Amigos: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingFriends.value = false;
      update(['friends_feed']);
    }
  }

  Future<void> toggleLikePost(Post post) async {
    try {
      final index = friendsPosts.indexWhere((p) => p.id == post.id);
      if (index == -1) return;

      if (!post.isLiked) {
        await _apiService.post('/post/${post.id}/like', data: {});
        friendsPosts[index] = post.copyWith(
          isLiked: true,
          likes: post.likes + 1,
        );
      } else {
        await _apiService.post('/post/${post.id}/unlike', data: {});
        friendsPosts[index] = post.copyWith(
          isLiked: false,
          likes: post.likes - 1,
        );
      }
      update(['friends_feed']);
    } catch (e) {
      log('❌ Error toggling post like: $e');
    }
  }

  Future<void> toggleLikeEvent(Event event) async {
    try {
      final apiService = Get.find<ApiService>();
      final userId = apiService.getUserId();

      if (userId == null) {
        Get.snackbar('Error', 'Usuario no identificado');
        return;
      }

      log('🎯 Toggling like for event: ${event.id}');
      log('📊 Current state - Liked: ${event.isLiked}, Likes: ${event.likes}');

      final index = discoverEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        if (event.isLiked) {
          discoverEvents[index] = event.copyWith(
            isLiked: false,
            likes: event.likes - 1,
          );
        } else {
          discoverEvents[index] = event.copyWith(
            isLiked: true,
            likes: event.likes + 1,
          );
        }
        update(['discover_feed', 'bottom_actions']);
      }

      if (event.isLiked) {
        await apiService.post('/event/${event.id}/unlike', data: {});
        log('✅ Like removed from event: ${event.id}');
      } else {
        await apiService.post('/event/${event.id}/like', data: {});
        log('✅ Like added to event: ${event.id}');
      }
    } catch (e) {
      log('❌ Error toggling like: $e');

      final index = discoverEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        discoverEvents[index] = event;
        update(['discover_feed', 'bottom_actions']);
      }

      Get.snackbar(
        'Error',
        'No se pudo actualizar el like: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> shareEvent(Event event) async {
    try {
      final shareText =
          '¡Mira este evento: ${event.title} en ${event.venue}! ${event.displayPrice} - ${event.formattedDate}';
      final eventUrl = 'https://nightup.com/events/${event.id}';

      log('📤 Sharing event: ${event.id}');

      await Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.neonGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Compartir Evento',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Copia el texto para compartir:',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: SelectableText(
                          '$shareText\n$eventUrl',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Selecciona y copia el texto',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cerrar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: true,
      );
    } catch (e) {
      log('❌ Error sharing event: $e');
      Get.snackbar(
        'Compartir',
        'Texto listo para compartir: ${event.title}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> loadLikeStatusForEvents() async {
    try {
      final apiService = Get.find<ApiService>();
      final userId = apiService.getUserId();

      if (userId == null) {
        log('⚠️ No user ID found for loading like status');
        return;
      }

      log('🔄 Loading like status for ${discoverEvents.length} events...');

      for (int i = 0; i < discoverEvents.length; i++) {
        final event = discoverEvents[i];
        try {
          final response = await apiService.get(
            '/event/${event.id}/like-status',
          );
          final isLiked = response.data['liked'] ?? false;
          final likesCount = response.data['likesCount'] ?? event.likes;

          final isJoined = await _checkUserParticipation(event.id, userId);

          discoverEvents[i] = event.copyWith(
            isLiked: isLiked,
            likes: likesCount,
            isJoined: isJoined,
          );

          log(
            '   ✅ Event ${event.id}: Liked=$isLiked, Likes=$likesCount, Joined=$isJoined',
          );
        } catch (e) {
          debugPrint('❌ Error loading like status for event ${event.id}: $e');
        }
      }

      update(['discover_feed', 'bottom_actions']);
      log('✅ Like status loaded for all events');
    } catch (e) {
      debugPrint('❌ Error loading like status: $e');
    }
  }

  Future<bool> _checkUserParticipation(String eventId, String userId) async {
    try {
      final response = await _apiService.get('/event/$eventId');
      if (response.data['participants'] is List) {
        final participants = response.data['participants'] as List;
        return participants.any(
          (participant) =>
              participant != null && participant.toString() == userId,
        );
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking user participation: $e');
      return false;
    }
  }

  void refreshAllFeeds() {
    fetchDiscoverEvents();
    fetchFriendsPosts();
  }

  void changeTab(int index) {
    tabController.animateTo(index);
    update([
      'tab_selection',
      'discover_feed',
      'friends_feed',
      'bottom_actions',
    ]);
  }

  void refreshEventStates() {
    if (discoverEvents.isNotEmpty) {
      loadLikeStatusForEvents();
    }
  }

  void saveCurrentPage() {
    lastViewedPage.value = currentPage.value;
    log('💾 Saved current page: ${lastViewedPage.value}');
  }

  void restoreLastPage() {
    if (discoverEvents.isNotEmpty &&
        lastViewedPage.value < discoverEvents.length) {
      currentPage.value = lastViewedPage.value;
      if (pageController.hasClients) {
        pageController.jumpToPage(lastViewedPage.value);
      }
      log('📖 Restored to page: ${lastViewedPage.value}');
      update(['current_page', 'bottom_actions']);
    } else {
      log(
        '⚠️ Cannot restore page - events: ${discoverEvents.length}, last page: ${lastViewedPage.value}',
      );
    }
  }

  @override
  void onClose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    pageController.dispose();
    super.onClose();
  }
}
