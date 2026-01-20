import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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

    if (userId == null) {
      isLoadingDiscover.value = false;
      return;
    }
    isLoadingDiscover.value = true;
    try {
      final response = await _apiService.get('/event?limit=1000&page=1');

      if (response.data is Map && response.data['events'] is List) {
        final eventsList = response.data['events'] as List;

        discoverEvents.value = eventsList.map((i) {
          return Event.fromJson(i);
        }).toList();
        await loadLikeStatusForEvents();
      } else if (response.data is List) {
        final eventsList = response.data as List;
        discoverEvents.value = eventsList
            .map((i) => Event.fromJson(i))
            .toList();
        await loadLikeStatusForEvents();
      } else {
        discoverEvents.value = [];
      }
    } catch (e) {
      discoverEvents.value = [];
    } finally {
      isLoadingDiscover.value = false;
      update(['discover_feed', 'bottom_actions']);
    }
  }

  void fetchFriendsPosts() async {
    final userId = _apiService.getUserId();
    if (userId == null) {
      isLoadingFriends.value = false;
      return;
    }
    isLoadingFriends.value = true;
    try {
      final response = await _apiService.get('/post/feed/friends');

      List<dynamic> postsData = [];
      if (response.data is List) {
        postsData = response.data;
      } else if (response.data is Map && response.data['posts'] is List) {
        postsData = response.data['posts'];
      } else if (response.data is Map && response.data['data'] is List) {
        postsData = response.data['data'];
      }

      friendsPosts.value = postsData
          .where((i) => i != null)
          .map((i) => Post.fromFriendPostJson(i))
          .toList();
    } catch (e) {
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
    } catch (e) {}
  }

  Future<void> toggleLikeEvent(Event event) async {
    try {
      final apiService = Get.find<ApiService>();
      final userId = apiService.getUserId();

      if (userId == null) {
        return;
      }

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
      } else {
        await apiService.post('/event/${event.id}/like', data: {});
      }
    } catch (e) {
      final index = discoverEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        discoverEvents[index] = event;
        update(['discover_feed', 'bottom_actions']);
      }
    }
  }

  Future<void> shareEvent(Event event) async {
    try {
      final shareText =
          '¡Mira este evento: ${event.title} en ${event.venue}!\n${event.displayPrice} - ${event.formattedDate}';
      final eventUrl = 'https://nightup.com/events/${event.id}';

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppColors.neonGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Copia el texto para compartir:',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: SelectableText(
                          '$shareText\n$eventUrl',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selecciona y copia el texto arriba',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(fontWeight: FontWeight.w600),
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
    } catch (e) {}
  }

  Future<void> sharePost(Post post) async {
    try {
      final shareText =
          '¡Mira el nuevo post de @${post.user?.username ?? "user"} en NightUp!\n"${post.caption ?? ""}"';
      final postUrl = 'https://nightup.com/posts/${post.id}';

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppColors.neonGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Compartir Publicación',
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Copia el texto para compartir:',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: SelectableText(
                          '$shareText\n$postUrl',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Podrás compartirlo en tus chats o redes',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {}
  }

  Future<void> loadLikeStatusForEvents() async {
    try {
      final apiService = Get.find<ApiService>();
      final userId = apiService.getUserId();

      if (userId == null) {
        return;
      }

      final eventsToLoad = discoverEvents.length > 20
          ? 20
          : discoverEvents.length;

      for (int i = 0; i < eventsToLoad; i++) {
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
        } catch (e) {}
      }

      update(['discover_feed', 'bottom_actions']);
    } catch (e) {}
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
  }

  void restoreLastPage() {
    if (discoverEvents.isNotEmpty &&
        lastViewedPage.value < discoverEvents.length) {
      currentPage.value = lastViewedPage.value;
      if (pageController.hasClients) {
        pageController.jumpToPage(lastViewedPage.value);
      }
      update(['current_page', 'bottom_actions']);
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
