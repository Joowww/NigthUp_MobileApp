import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_drawer.dart'; // <-- IMPORT AÑADIDO
import '../controllers/home_controller.dart';
import '../widgets/event_card.dart';
import '../widgets/user_avatar_card.dart';
import '../widgets/stats_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: AppColors.neonPink,
              size: 28,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'NightUp',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: AppColors.neonGreen,
            ),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppColors.neonPink,
        backgroundColor: AppColors.darkCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Welcome Section
              Obx(() => _buildWelcomeSection(controller)),

              const SizedBox(height: 30),

              // Stats Cards
              _buildStatsSection(controller),

              const SizedBox(height: 30),

              // Featured Events Section
              _buildFeaturedEventsSection(controller),

              const SizedBox(height: 30),

              // Recent Users Section
              _buildRecentUsersSection(controller),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(HomeController controller) {
    final user = controller.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translate('home.welcome'),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user?.username ?? 'Usuario',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        if (user?.role != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user?.role == 'admin'
                  ? AppColors.neonPink.withOpacity(0.2)
                  : AppColors.neonBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: user?.role == 'admin'
                    ? AppColors.neonPink
                    : AppColors.neonBlue,
                width: 1,
              ),
            ),
            child: Text(
              (user?.role ?? '').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: user?.role == 'admin'
                    ? AppColors.neonPink
                    : AppColors.neonBlue,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection(HomeController controller) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Eventos',
                value: '${controller.totalEvents.value}',
                icon: Icons.event,
                color: AppColors.neonPink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatsCard(
                title: 'Participantes',
                value: '${controller.totalUsers.value}',
                icon: Icons.people,
                color: AppColors.neonBlue,
              ),
            ),
          ],
        ));
  }

  Widget _buildFeaturedEventsSection(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Eventos Destacados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () => controller.changeTab(1),
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  color: AppColors.neonPink,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonPink),
            );
          }

          if (controller.featuredEvents.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay eventos disponibles',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            height: 255,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.featuredEvents.length,
              itemBuilder: (context, index) {
                final event = controller.featuredEvents[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(
                    right:
                        index == controller.featuredEvents.length - 1 ? 0 : 16,
                  ),
                  child: EventCard(
                    event: event,
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.eventDetail,
                        arguments: event.id,
                      );
                    },
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentUsersSection(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Usuarios Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () => controller.changeTab(2),
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  color: AppColors.neonPink,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.recentUsers.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay usuarios recientes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            height: 95,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.recentUsers.length,
              itemBuilder: (context, index) {
                final user = controller.recentUsers[index];
                return Container(
                  margin: EdgeInsets.only(
                    right: index == controller.recentUsers.length - 1 ? 24 : 16,
                  ),
                  child: UserAvatarCard(
                    user: user,
                    onTap: () {
                      Get.toNamed('/user-profile', parameters: {'userId': user.id});
                    },
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
