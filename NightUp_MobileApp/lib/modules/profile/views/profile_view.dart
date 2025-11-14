import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../app/themes/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con perfil
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.neonPurple.withOpacity(0.3),
                      AppColors.darkBackground,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Obx(() {
                    final user = authController.currentUser.value;
                    if (user == null) return const SizedBox.shrink();
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonPink.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.darkCard,
                            ),
                            child: Center(
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neonPink,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nombre
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Email
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          
          // Contenido
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Información personal
                _buildSectionTitle(translate('profile.personal_info')),
                const SizedBox(height: 12),
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user == null) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        title: translate('profile.username'),
                        value: user.username,
                        color: AppColors.neonPink,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: translate('profile.email'),
                        value: user.email,
                        color: AppColors.neonBlue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.cake_outlined,
                        title: translate('profile.birthday'),
                        value: user.birthday.toString().split(' ')[0],
                        color: AppColors.neonPurple,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.admin_panel_settings_outlined,
                        title: translate('profile.role'),
                        value: user.role.toUpperCase(),
                        color: AppColors.neonOrange,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 30),
                
                // Cerrar sesión
                _buildSectionTitle(translate('profile.account')),
                const SizedBox(height: 12),
                _buildOptionCard(
                  icon: Icons.logout,
                  title: translate('profile.logout'),
                  subtitle: translate('profile.logout_subtitle'),
                  color: AppColors.error,
                  onTap: () => _showLogoutDialog(context, authController),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          translate('profile.logout'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          translate('profile.logout_confirm'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              translate('common.cancel'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await authController.logout();
              Get.offAllNamed('/login');
            },
            child: Text(
              translate('profile.logout'),
              style: const TextStyle(
                color: AppColors.error,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}