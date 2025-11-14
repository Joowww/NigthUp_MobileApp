import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neonPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.neonPurple,
              size: 20,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.currentUser.value == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.neonPurple,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
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
                            (controller.currentUser.value?.username != null && 
                             controller.currentUser.value!.username.isNotEmpty) 
                                ? controller.currentUser.value!.username[0].toUpperCase() 
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Actualiza tu información personal',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Campo de nombre de usuario
                const Text(
                  'Nombre de usuario',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.usernameController,
                  label: 'Ingrese su nombre de usuario',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: controller.validateUsername,
                ),
                
                const SizedBox(height: 24),
                
                // Campo de email
                const Text(
                  'Correo electrónico',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.emailController,
                  label: 'Ingrese su email (opcional)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),
                
                const SizedBox(height: 24),
                
                // Campo de fecha de nacimiento
                const Text(
                  'Fecha de nacimiento',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: controller.selectDate,
                  child: CustomTextField(
                    controller: controller.birthdayController,
                    label: 'DD/MM/YYYY (opcional)',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    enabled: false,
                    validator: controller.validateBirthday,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Botón de guardar
                Obx(() => GradientButton(
                  onPressed: controller.isLoading.value ? null : () {
                    controller.updateProfile();
                  },
                  text: controller.isLoading.value ? 'Guardando...' : 'Guardar Cambios',
                )),
                
                const SizedBox(height: 20),
                
                // Información adicional
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.neonBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.neonBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Información',
                            style: TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• El nombre de usuario debe ser único\n'
                        '• Solo letras, números y guiones bajos permitidos\n'
                        '• El email y fecha de nacimiento son opcionales',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}