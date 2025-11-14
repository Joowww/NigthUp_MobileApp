import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../themes/app_colors.dart';
import '../routes/app_routes.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/home/controllers/home_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Drawer(
      backgroundColor: AppColors.darkCard,
      child: SafeArea(
        child: Column(
          children: [
            // Header con perfil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Obx(() {
                final user = authController.currentUser.value;
                return Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Text(
                          user?.username[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.username ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                );
              }),
            ),
            
            // Opciones del menú
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.home,
                    title: translate('home.title'),
                    onTap: () {
                      Get.back();
                      Get.offAllNamed(AppRoutes.home);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.nightlife,
                    title: translate('home.events'),
                    onTap: () {
                      Get.back();
                      _navigateToTab(1);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.people,
                    title: translate('home.users'),
                    onTap: () {
                      Get.back();
                      _navigateToTab(2);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.business,
                    title: 'Negocios',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.business);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.label,
                    title: 'Tags',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.tags);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.interests,
                    title: 'Intereses',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.interests);
                    },
                  ),
                  const Divider(
                    color: AppColors.textHint,
                    height: 24,
                    thickness: 0.5,
                  ),
                  _buildMenuItem(
                    icon: Icons.person,
                    title: translate('home.my_profile'),
                    onTap: () {
                      Get.back();
                      _navigateToTab(3);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Configuración',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/settings'); // Navegar a settings
                    },
                  ),
                ],
              ),
            ),
            
            // Cerrar sesión
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildMenuItem(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                color: AppColors.error,
                onTap: () => _showLogoutDialog(context, authController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int tabIndex) {
    try {
      final homeController = Get.find<HomeController>();
      homeController.changeTab(tabIndex);
    } catch (e) {
      print('Error navigating to tab: $e');
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.neonPink,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
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
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              Get.back(); // Cerrar drawer
              await authController.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
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