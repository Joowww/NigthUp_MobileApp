import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class UserProfile extends StatefulWidget {
  final VoidCallback onSettingsOpen;
  final VoidCallback onCalendarOpen;
  final VoidCallback onPanicOpen;
  final VoidCallback onMapOpen;

  const UserProfile({
    super.key,
    required this.onSettingsOpen,
    required this.onCalendarOpen,
    required this.onPanicOpen,
    required this.onMapOpen,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.find<AuthController>();
  final ApiService _apiService = Get.find<ApiService>();

  User? get user => _authController.currentUser;

  final RxList<Map<String, dynamic>> _userEvents = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _pendingRequests =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _userGroups = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _userReviews =
      <Map<String, dynamic>>[].obs;

  final RxBool _loadingRequests = false.obs;
  final RxBool _loadingStats = true.obs;

  final RxDouble _trustScore = 0.0.obs;
  final RxInt _totalRatings = 0.obs;
  final RxInt _friendsCount = 0.obs;
  final RxInt _groupsCount = 0.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchUserEvents(),
      _fetchPendingRequests(),
      _fetchUserStats(),
      _fetchUserGroups(),
      _fetchUserReviews(),
    ]);
  }

  Future<void> _fetchUserStats() async {
    _loadingStats.value = true;
    try {
      final user = _authController.currentUser;
      if (user == null) return;

      try {
        final trustResponse = await _apiService.get(
          '/user-trust/user/summary/${user.id}',
        );
        if (trustResponse.data is Map) {
          _trustScore.value = (trustResponse.data['averageTrust'] ?? 0.0)
              .toDouble();
          _totalRatings.value = trustResponse.data['totalRatings'] ?? 0;
        }
      } catch (e) {
        logger.e('Error fetching trust score: $e');
      }

      try {
        final friendsResponse = await _apiService.get('/friendship/friends');
        if (friendsResponse.data is List) {
          final acceptedFriends = (friendsResponse.data as List).where((
            friendship,
          ) {
            return friendship is Map && friendship['status'] == 'accepted';
          }).toList();
          _friendsCount.value = acceptedFriends.length;
          logger.d('Friends count: ${_friendsCount.value}');
        } else {
          _friendsCount.value = 0;
        }
      } catch (e) {
        logger.e('Error fetching friends count: $e');
        _friendsCount.value = 0;
      }
    } catch (e) {
      logger.e('Error fetching user stats: $e');
    } finally {
      _loadingStats.value = false;
    }
  }

  Future<void> _fetchUserGroups() async {
    try {
      final response = await _apiService.get('/group/my-groups');

      if (response.data is List) {
        _userGroups.value = List<Map<String, dynamic>>.from(response.data);
        _groupsCount.value = _userGroups.length;
      } else if (response.data is Map && response.data['groups'] is List) {
        _userGroups.value = List<Map<String, dynamic>>.from(
          response.data['groups'],
        );
        _groupsCount.value = _userGroups.length;
      } else {
        _userGroups.clear();
        _groupsCount.value = 0;
      }
    } catch (e) {
      logger.e('Error fetching user groups: $e');
      _userGroups.clear();
      _groupsCount.value = 0;
    }
  }

  Future<void> _fetchUserReviews() async {
    try {
      final user = _authController.currentUser;
      if (user == null) return;

      final response = await _apiService.get(
        '/user-trust/user/ratings/${user.id}',
      );

      if (response.data is List) {
        _userReviews.value = List<Map<String, dynamic>>.from(response.data);
      } else {
        _userReviews.clear();
      }
    } catch (e) {
      logger.e('Error fetching user reviews: $e');
      _userReviews.clear();
    }
  }

  Future<void> _fetchPendingRequests() async {
    _loadingRequests.value = true;
    try {
      final response = await _apiService.get('/friendship/pending');

      if (response.data is List) {
        _pendingRequests.value = List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['pending'] is List) {
        _pendingRequests.value = List<Map<String, dynamic>>.from(
          response.data['pending'],
        );
      } else if (response.data is Map && response.data['received'] is List) {
        _pendingRequests.value = List<Map<String, dynamic>>.from(
          response.data['received'],
        );
      } else {
        _pendingRequests.clear();
      }
    } catch (e) {
      logger.e('Error fetching pending requests: $e');
      _pendingRequests.clear();
    } finally {
      _loadingRequests.value = false;
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      await _apiService.patch('/friendship/request/$friendshipId/accept');
      Get.snackbar('Solicitud aceptada', 'Ahora son amigos.');
      await _fetchPendingRequests();
      await _fetchUserStats();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo aceptar la solicitud.');
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      await _apiService.delete('/friendship/request/$friendshipId/reject');
      Get.snackbar('Solicitud rechazada', 'Solicitud eliminada.');
      await _fetchPendingRequests();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo rechazar la solicitud.');
    }
  }

  Future<void> _fetchUserEvents() async {
    final user = _authController.currentUser;
    if (user == null) return;

    try {
      final response = await _apiService.get(
        '/event/by-participant/${user.id}',
      );

      if (response.data is Map && response.data['events'] is List) {
        _userEvents.value = List<Map<String, dynamic>>.from(
          response.data['events'],
        );
      } else if (response.data is List) {
        _userEvents.value = List<Map<String, dynamic>>.from(response.data);
      } else {
        _userEvents.clear();
      }
    } catch (e) {
      logger.e('Error fetching user events: $e');
      _userEvents.clear();
    }
  }

  String safeString(dynamic value, {String mapKey = 'name'}) {
    if (value == null) return '';
    if (value is String) return value;

    if (value is Map) {
      if (value[mapKey] != null) return value[mapKey].toString();
      if (value['title'] != null) return value['title'].toString();
      if (value['username'] != null) return value['username'].toString();
      if (value['address'] != null) return value['address'].toString();
    }

    return value.toString();
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inDays == 0) return 'Hoy';
      if (diff.inDays == 1) return 'Ayer';
      if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
      if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
      return 'Hace ${(diff.inDays / 30).floor()} meses';
    } catch (e) {
      return '';
    }
  }

  Widget _buildProfileHeader(User user) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ImageWithFallback(
            imageUrl: user.safeCoverPhoto,
            fallbackAsset: 'assets/images/default-cover.jpg',
            fit: BoxFit.cover,
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ImageWithFallback(
                  imageUrl: user.safeProfilePictureUrl,
                  width: 80,
                  height: 80,
                  isCircle: true,
                  fallbackAsset: 'assets/images/default-avatar.png',
                ),
              ),

              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => _loadingStats.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _totalRatings.value > 0
                                    ? '${_trustScore.value.toStringAsFixed(1)} (${_totalRatings.value})'
                                    : 'Sin valoraciones',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Obx(
                () => _loadingStats.value
                    ? const SizedBox(
                        width: 100,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          _buildStatItem(
                            _friendsCount.value.toString(),
                            'Amigos',
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            _userEvents.length.toString(),
                            'Eventos',
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            _groupsCount.value.toString(),
                            'Grupos',
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoTab(User user) {
    int? age;
    if (user.birthday != null) {
      final now = DateTime.now();
      age = now.year - user.birthday!.year;
      if (now.month < user.birthday!.month ||
          (now.month == user.birthday!.month && now.day < user.birthday!.day)) {
        age--;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sobre mí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.bio ?? 'Sin biografía',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (user.city != null && user.city!.isNotEmpty)
                    _buildInfoItem(
                      Icons.location_on,
                      '${user.city}${user.country != null && user.country!.isNotEmpty ? ", ${user.country}" : ""}',
                    )
                  else if (user.country != null && user.country!.isNotEmpty)
                    _buildInfoItem(Icons.location_on, user.country!)
                  else
                    _buildInfoItem(Icons.location_on, 'Sin ubicación'),

                  if (age != null) _buildInfoItem(Icons.cake, '$age años'),
                ],
              ),

              const SizedBox(height: 16),

              if (user.interests != null && user.interests!.isNotEmpty) ...[
                const Text(
                  'Intereses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.interests!.take(10).map((interest) {
                    return _buildPreferenceChip(interest);
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildPreferenceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.primary, fontSize: 12),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Obx(() {
      if (_userEvents.isEmpty) {
        return const Center(
          child: Text(
            'No participas en ningún evento',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userEvents.length,
        itemBuilder: (context, i) {
          final event = _userEvents[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: ImageWithFallback(
                          imageUrl: safeString(event['image']),
                          fallbackAsset: 'assets/images/default-event.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safeString(event['name']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            safeString(event['location']),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
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
        },
      );
    });
  }

  Widget _buildReviewsTab() {
    return Obx(() {
      if (_userReviews.isEmpty) {
        return const Center(
          child: Text(
            'No tienes valoraciones todavía',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userReviews.length,
        itemBuilder: (context, i) {
          final review = _userReviews[i];
          final rater = review['rater'] is Map ? review['rater'] : null;
          final username = rater != null
              ? rater['username']?.toString()
              : 'Usuario';
          final avatar = rater != null ? rater['avatar']?.toString() : null;
          final score = review['score'] is int ? review['score'] as int : 0;
          final comment = review['comment']?.toString() ?? '';
          final date = _formatDate(review['createdAt']);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: ImageWithFallback(
                              imageUrl: avatar ?? '',
                              fallbackAsset: 'assets/images/default-avatar.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (s) {
                                  return Icon(
                                    Icons.star,
                                    color: s < score
                                        ? Colors.yellow
                                        : Colors.white30,
                                    size: 14,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        comment,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildPendingRequestsTab() {
    return Obx(() {
      if (_loadingRequests.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_pendingRequests.isEmpty) {
        return const Center(
          child: Text(
            'No tienes solicitudes pendientes',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, i) {
          final req = _pendingRequests[i];
          final user = req['requester'] is Map ? req['requester'] : null;
          final username = user != null
              ? user['username']?.toString()
              : 'Usuario';
          final avatar = user != null ? user['avatar']?.toString() : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : const AssetImage('assets/images/default-avatar.jpg')
                            as ImageProvider,
                ),
                title: Text(
                  username!,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Te ha enviado una solicitud de amistad',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptRequest(req['_id'] ?? ''),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectRequest(req['_id'] ?? ''),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _iconButton(
            icon: Icons.settings,
            label: 'Ajustes',
            onTap: widget.onSettingsOpen,
          ),
          _iconButton(
            icon: Icons.calendar_today,
            label: 'Calendario',
            onTap: widget.onCalendarOpen,
          ),
          _iconButton(icon: Icons.map, label: 'Mapa', onTap: widget.onMapOpen),
          _iconButton(
            icon: Icons.warning,
            label: 'Emergencia',
            onTap: widget.onPanicOpen,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color ?? AppColors.primary, width: 2),
              ),
              child: Icon(icon, color: color ?? Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color ?? Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = _authController.currentUser;

      if (user == null) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                collapsedHeight: 100,
                pinned: true,
                floating: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: Obx(
                  () => _buildProfileHeader(_authController.currentUser!),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Eventos'),
                      Tab(text: 'Reseñas'),
                      Tab(text: 'Solicitudes'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(user),
              _buildEventsTab(),
              _buildReviewsTab(),
              _buildPendingRequestsTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildActionButtons(),
      );
    });
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
