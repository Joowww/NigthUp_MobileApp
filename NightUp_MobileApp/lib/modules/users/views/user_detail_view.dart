import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/widgets/gradient_button.dart';
import '../controllers/user_detail_controller.dart';
import '../../../data/models/user_model.dart';

class UserDetailView extends StatelessWidget {
  final String userId;

  const UserDetailView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserDetailController());
    controller.loadUserDetail(userId);

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.neonBlue,
            ),
          );
        }

        final user = controller.user.value;
        if (user == null) {
          return const Center(
            child: Text(
              'Usuario no encontrado',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // AppBar con perfil
            _buildAppBar(context, user),
            
            // Contenido
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información principal
                  _buildMainInfo(user),
                  
                  // Detalles
                  _buildDetails(user),
                  
                  // Botón valorar confianza
                  _buildTrustButton(controller),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel user) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.darkBackground,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.neonBlue.withOpacity(0.3),
                AppColors.darkBackground,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.secondaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonBlue.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildRoleBadge(user.role),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    IconData icon;
    
    switch (role.toLowerCase()) {
      case 'admin':
        color = AppColors.error;
        icon = Icons.admin_panel_settings;
        break;
      case 'manager':
        color = AppColors.neonOrange;
        icon = Icons.business;
        break;
      default:
        color = AppColors.neonBlue;
        icon = Icons.person;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildDetailItem(
            icon: Icons.person_outline,
            title: 'Usuario',
            value: user.username,
            color: AppColors.neonPink,
          ),
          const SizedBox(height: 12),
          
          _buildDetailItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: user.email,
            color: AppColors.neonBlue,
          ),
          
          if (user.birthday != null) ...[
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.cake_outlined,
              title: 'Fecha de nacimiento',
              value: user.birthday!,
              color: AppColors.neonPurple,
            ),
          ],
          
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.calendar_today,
            title: 'Miembro desde',
            value: _formatDate(user.createdAt),
            color: AppColors.neonGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
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

  Widget _buildTrustButton(UserDetailController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GradientButton(
        text: 'Valorar confianza',
        onPressed: () => _showTrustDialog(controller),
        gradient: AppColors.secondaryGradient,
      ),
    );
  }

  void _showTrustDialog(UserDetailController controller) {
    int trustLevel = 3;
    final contextController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Valorar confianza',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Qué nivel de confianza le otorgas?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: trustLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: trustLevel.toString(),
                  activeColor: AppColors.neonGreen,
                  inactiveColor: AppColors.darkInput,
                  onChanged: (value) {
                    setState(() {
                      trustLevel = value.toInt();
                    });
                  },
                ),
                Text(
                  'Nivel: $trustLevel/5',
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: contextController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contexto (opcional)',
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontFamily: 'Poppins',
                    ),
                    filled: true,
                    fillColor: AppColors.darkInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
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
                onPressed: () {
                  controller.rateTrust(
                    trustLevel,
                    contextController.text.isNotEmpty ? contextController.text : null,
                  );
                },
                child: const Text(
                  'Enviar',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}