import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../app/widgets/gradient_button.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cambiar Contraseña',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.secondaryGradient,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Actualiza tu contraseña de forma segura',
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
              
              // Campo de contraseña actual
              const Text(
                'Contraseña actual',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => CustomTextField(
                controller: controller.currentPasswordController,
                label: 'Ingrese su contraseña actual',
                prefixIcon: const Icon(Icons.lock_outline),
                isPassword: !controller.showCurrentPassword.value,
                suffixIcon: IconButton(
                  onPressed: controller.toggleCurrentPasswordVisibility,
                  icon: Icon(
                    controller.showCurrentPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: controller.validateCurrentPassword,
              )),
              
              const SizedBox(height: 24),
              
              // Campo de nueva contraseña
              const Text(
                'Nueva contraseña',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => CustomTextField(
                controller: controller.newPasswordController,
                label: 'Ingrese su nueva contraseña',
                prefixIcon: const Icon(Icons.lock_reset),
                isPassword: !controller.showNewPassword.value,
                suffixIcon: IconButton(
                  onPressed: controller.toggleNewPasswordVisibility,
                  icon: Icon(
                    controller.showNewPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: controller.validateNewPassword,
              )),
              
              const SizedBox(height: 24),
              
              // Campo de confirmar contraseña
              const Text(
                'Confirmar nueva contraseña',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => CustomTextField(
                controller: controller.confirmPasswordController,
                label: 'Confirme su nueva contraseña',
                prefixIcon: const Icon(Icons.lock_reset),
                isPassword: !controller.showConfirmPassword.value,
                suffixIcon: IconButton(
                  onPressed: controller.toggleConfirmPasswordVisibility,
                  icon: Icon(
                    controller.showConfirmPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                ),
                validator: controller.validateConfirmPassword,
              )),
              
              const SizedBox(height: 40),
              
              // Botón de cambiar contraseña
              Obx(() => GradientButton(
                onPressed: controller.isLoading.value ? null : () {
                  controller.changePassword();
                },
                text: controller.isLoading.value ? 'Cambiando...' : 'Cambiar Contraseña',
              )),
              
              const SizedBox(height: 20),
              
              // Requisitos de contraseña
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.neonGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: AppColors.neonGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Requisitos de seguridad',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Mínimo 8 caracteres\n'
                      '• Al menos 1 letra mayúscula\n'
                      '• Al menos 1 letra minúscula\n'
                      '• Al menos 1 número\n'
                      '• Diferente a la contraseña actual',
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
      ),
    );
  }
}