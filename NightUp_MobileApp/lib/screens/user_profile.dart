import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_with_fallback.dart';

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

class _UserProfileState extends State<UserProfile> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              collapsedHeight: 100,
              floating: false,
              pinned: true,
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
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildProfileHeader(user) {
    return Stack(
      children: [
        // Cover photo - usar coverPhoto del backend
        Container(
          width: double.infinity,
          height: double.infinity,
          child: ImageWithFallback(
            imageUrl: user.coverPhoto ?? 'https://images.unsplash.com/photo-1641203251058-3eb0ad540780',
            fit: BoxFit.cover,
          ),
        ),
        // Gradiente overlay
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
        // Información del perfil
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: AppColors.primary, size: 14),
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
                  Text(
                    'Trust Score: 4.8⭐', // Esto vendrá del backend
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatItem('234', 'Friends'), // TODO: Conectar con friends count
                  const SizedBox(width: 16),
                  _buildStatItem('45', 'Events'), // TODO: Conectar con events count
                  const SizedBox(width: 16),
                  _buildStatItem('12', 'Groups'), // TODO: Conectar con groups count
                ],
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
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
                  user.bio ?? 'No bio yet', // Bio del backend
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(Icons.location_on, user.location ?? 'Location not set'),
                    const SizedBox(width: 16),
                    if (user.birthday != null)
                      _buildInfoItem(Icons.cake, '${user.birthday!.year} years old'),
                  ],
                ),
              ],
            ),
          ),
        ),
        // ... resto del código
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
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
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    final events = [
      {
        'title': 'Neon Techno Nights',
        'date': 'Nov 21, 2025',
        'venue': 'Opium Club',
        'image': 'https://images.unsplash.com/photo-1713885462557-12b5c41f22cd',
      },
      {
        'title': 'Saturday House Sessions',
        'date': 'Nov 22, 2025',
        'venue': 'The Basement',
        'image': 'https://images.unsplash.com/photo-1641203251058-3eb0ad540780',
      },
      {
        'title': 'EDM Festival Weekend',
        'date': 'Nov 23, 2025',
        'venue': 'Skybar Rooftop',
        'image': 'https://images.unsplash.com/photo-1689783101582-98feb9393a57',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImageWithFallback(
                        imageUrl: event['image']!,
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
                          event['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['date']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event['venue']!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final reviews = [
      {
        'user': 'Sarah M.',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'rating': 5,
        'date': '2 days ago',
        'comment': 'Great person to party with! Always knows the best spots.',
      },
      {
        'user': 'Mike R.',
        'avatar': 'https://i.pravatar.cc/150?img=12',
        'rating': 4,
        'date': '1 week ago',
        'comment': 'Awesome vibes and great taste in music.',
      },
      {
        'user': 'Emma W.',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'rating': 5,
        'date': '2 weeks ago',
        'comment': 'Met at the techno night, had an amazing time!',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
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
                      Container(
                        width: 40,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: ImageWithFallback(
                            imageUrl: review['avatar']! as String,
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
                              review['user']! as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                ...List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.star,
                                    color: starIndex < (review['rating']! as int)
                                        ? Colors.yellow 
                                        : Colors.white30,
                                    size: 14,
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        review['date']! as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review['comment']! as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onSettingsOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.glassBorder),
                backgroundColor: AppColors.glassWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, size: 16),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCalendarOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.glassBorder),
                backgroundColor: AppColors.glassWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 16),
                  SizedBox(width: 8),
                  Text('Calendar'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onMapOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.glassBorder),
                backgroundColor: AppColors.glassWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 16),
                  SizedBox(width: 8),
                  Text('Map'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}