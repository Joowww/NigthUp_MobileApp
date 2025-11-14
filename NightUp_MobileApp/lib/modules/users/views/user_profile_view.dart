import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/user_profile_controller.dart';
import '../../../data/models/trust_model.dart';

class UserProfileView extends GetView<UserProfileController> {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.darkBackground,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  onPressed: () => Get.offAllNamed('/home'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Obx(() {
                    if (controller.isLoading.value) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.neonPurple.withOpacity(0.2),
                              AppColors.neonPink.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.neonPurple,
                          ),
                        ),
                      );
                    }

                    final user = controller.user.value;
                    if (user == null) {
                      return Container(
                        color: AppColors.darkBackground,
                        child: const Center(
                          child: Text(
                            'Usuario no encontrado',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.neonPurple.withOpacity(0.2),
                            AppColors.neonPink.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    user.username[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: AppColors.neonPurple,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.role.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.neonPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                'Confianza Promedio',
                                controller.averageRating.value.toStringAsFixed(1),
                                Icons.star,
                                AppColors.neonGreen,
                              ),
                              _buildStatCard(
                                'Total Valoraciones',
                                '${controller.totalReceivedRatings.value}',
                                Icons.thumb_up,
                                AppColors.neonBlue,
                              ),
                            ],
                          )),
                        ],
                      ),
                      ),
                    );
                  }),
                ),
                bottom: const TabBar(
                  indicatorColor: AppColors.neonPurple,
                  labelColor: AppColors.neonPurple,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(text: 'Valoraciones Recibidas'),
                    Tab(text: 'Valoraciones Dadas'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildReceivedRatingsTab(),
              _buildGivenRatingsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReceivedRatingsTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.neonPurple,
          ),
        );
      }

      if (controller.receivedRatings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_border,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay valoraciones recibidas',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.receivedRatings.length,
        itemBuilder: (context, index) {
          final rating = controller.receivedRatings[index];
          return _buildRatingCard(rating, isReceived: true);
        },
      );
    });
  }

  Widget _buildGivenRatingsTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.neonPurple,
          ),
        );
      }

      if (controller.givenRatings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No ha dado valoraciones',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.givenRatings.length,
        itemBuilder: (context, index) {
          final rating = controller.givenRatings[index];
          return _buildRatingCard(rating, isReceived: false);
        },
      );
    });
  }

  Widget _buildRatingCard(TrustModel rating, {required bool isReceived}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.secondaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      (isReceived ? rating.rater : rating.rated)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived 
                            ? 'De: ${rating.rater}' 
                            : 'Para: ${rating.rated}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        rating.context,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating.score).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: _getRatingColor(rating.score),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.score}',
                        style: TextStyle(
                          color: _getRatingColor(rating.score),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkInput,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rating.comment!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Hace ${_getTimeAgo(rating.createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int score) {
    if (score >= 4) return AppColors.neonGreen;
    if (score >= 3) return AppColors.neonBlue;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos';
    } else {
      return 'ahora';
    }
  }
}