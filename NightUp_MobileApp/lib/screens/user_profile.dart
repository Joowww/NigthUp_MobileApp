import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';
import '../models/user.dart';
import '../services/api_service.dart';

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
  final RxList<Map<String, dynamic>> _userEvents =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _pendingRequests =
      <Map<String, dynamic>>[].obs;
  final RxBool _loadingRequests = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserEvents();
    _fetchPendingRequests();
  }

  // -------------------- FETCH METHODS --------------------

  Future<void> _fetchPendingRequests() async {
    _loadingRequests.value = true;
    try {
      final response =
          await Get.find<ApiService>().get('/friendship/pending');

      if (response.data is List) {
        _pendingRequests.value =
            List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map &&
          response.data['pending'] is List) {
        _pendingRequests.value =
            List<Map<String, dynamic>>.from(response.data['pending']);
      } else {
        _pendingRequests.clear();
      }
    } catch (e) {
      _pendingRequests.clear();
    } finally {
      _loadingRequests.value = false;
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      await Get.find<ApiService>()
          .patch('/friendship/request/$friendshipId/accept');
      Get.snackbar('Solicitud aceptada', 'Ahora son amigos.');
      await _fetchPendingRequests();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo aceptar la solicitud.');
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      await Get.find<ApiService>()
          .delete('/friendship/request/$friendshipId/reject');
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
      final response = await Get.find<ApiService>()
          .get('/event/by-participant/${user.id}');

      if (response.data is Map &&
          response.data['events'] is List) {
        _userEvents.value =
            List<Map<String, dynamic>>.from(response.data['events']);
      } else if (response.data is List) {
        _userEvents.value =
            List<Map<String, dynamic>>.from(response.data);
      } else {
        _userEvents.clear();
      }
    } catch (e) {
      _userEvents.clear();
    }
  }

  // -------------------- UTILS --------------------

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

  // -------------------- UI SECTIONS --------------------

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
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified,
                            color: AppColors.primary, size: 14),
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
                  const Text(
                    'Trust Score: 4.8⭐',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  _buildStatItem('234', 'Friends'),
                  const SizedBox(width: 16),
                  _buildStatItem('45', 'Events'),
                  const SizedBox(width: 16),
                  _buildStatItem('12', 'Groups'),
                ],
              ),
            ],
          ),
        )
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About Me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.bio ?? 'No bio yet',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 16),

              // ✅ CORREGIDO: Wrap en vez de Row con Expanded
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoItem(
                      Icons.location_on,
                      safeString(user.safeLocationString)),
                  if (user.birthday != null)
                    _buildInfoItem(
                        Icons.cake,
                        '${user.birthday!.year} years old'),
                ],
              ),

              const SizedBox(height: 16),

              if (user.interests != null &&
                  user.interests!.isNotEmpty) ...[
                const Text(
                  'Interests',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.interests!
                      .take(5)
                      .map((i) =>
                          _buildPreferenceChip(safeString(i)))
                      .toList(),
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
        Text(
          text,
          style: const TextStyle(
              color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPreferenceChip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
        ),
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
                          fallbackAsset:
                              'assets/images/default-event.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            safeString(event['title']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            safeString(event['formattedDate']),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            safeString(event['venue']),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
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
    final reviews = [
      {
        'user': 'Sarah M.',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'rating': 5,
        'date': '2 days ago',
        'comment':
            'Great person to party with! Always knows the best spots.',
      },
      {
        'user': 'Mike R.',
        'avatar': 'https://i.pravatar.cc/150?img=12',
        'rating': 4,
        'date': '1 week ago',
        'comment':
            'Awesome vibes and great taste in music.',
      },
      {
        'user': 'Emma W.',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'rating': 5,
        'date': '2 weeks ago',
        'comment':
            'Met at the techno night, had an amazing time!',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, i) {
        final review = reviews[i];
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
                            imageUrl:
                                safeString(review['avatar']),
                            fallbackAsset:
                                'assets/images/default-avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              safeString(review['user']),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: List.generate(5, (s) {
                                final rating =
                                    review['rating'] is int
                                        ? review['rating'] as int
                                        : 0;
                                return Icon(Icons.star,
                                    color: s < rating
                                        ? Colors.yellow
                                        : Colors.white30,
                                    size: 14);
                              }),
                            )
                          ],
                        ),
                      ),
                      Text(
                        safeString(review['date']),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    safeString(review['comment']),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    return Obx(() {
      if (_loadingRequests.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_pendingRequests.isEmpty) {
        return const Center(
            child: Text('No tienes solicitudes pendientes',
                style: TextStyle(color: Colors.white70)));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, i) {
          final req = _pendingRequests[i];
          final user =
              req['requester'] is Map ? req['requester'] : null;

          final username =
              user != null ? user['username']?.toString() : 'Usuario';

          final avatar =
              user != null ? user['avatar']?.toString() : null;

          return GlassCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : const AssetImage(
                            'assets/images/default-avatar.jpg')
                        as ImageProvider,
              ),
              title: Text(username!,
                  style: const TextStyle(color: Colors.white)),
              subtitle: const Text(
                  'Te ha enviado una solicitud de amistad',
                  style: TextStyle(color: Colors.white70)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        _acceptRequest(req['_id'] ?? ''),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.red),
                    onPressed: () =>
                        _rejectRequest(req['_id'] ?? ''),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // -------------------- BOTTOM ACTION BUTTONS --------------------

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          _actionButton(
              icon: Icons.settings,
              text: 'Settings',
              onTap: widget.onSettingsOpen),
          const SizedBox(width: 12),
          _actionButton(
              icon: Icons.calendar_today,
              text: 'Calendar',
              onTap: widget.onCalendarOpen),
          const SizedBox(width: 12),
          _actionButton(
              icon: Icons.map,
              text: 'Map',
              onTap: widget.onMapOpen),
          const SizedBox(width: 12),
          _panicButton(),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.glassBorder),
          backgroundColor: AppColors.glassWhite,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _panicButton() {
    return Expanded(
      child: OutlinedButton(
        onPressed: widget.onPanicOpen,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          backgroundColor: Colors.red.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 16),
            SizedBox(width: 8),
            Text('Emergency'),
          ],
        ),
      ),
    );
  }

  // -------------------- MAIN BUILD --------------------

  @override
  Widget build(BuildContext context) {
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
              flexibleSpace: _buildProfileHeader(user),
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
                    Tab(text: 'Events'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'Solicitudes'),
                  ],
                ),
              ),
            )
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
  }
}

// -------------------- TAB BAR DELEGATE --------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}