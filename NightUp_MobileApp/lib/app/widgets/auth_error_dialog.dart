import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_colors.dart';

class AuthErrorDialog {
  static void show({
    required String title,
    required String message,
    bool canRetry = true,
    VoidCallback? onRetry,
    VoidCallback? onLogin,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Consejo: Si el problema persiste, cierra la aplicación completamente y vuelve a abrirla.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (canRetry && onRetry != null)
            TextButton(
              onPressed: () {
                Get.back();
                onRetry();
              },
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Get.back();
                if (onLogin != null) {
                  onLogin();
                } else {
                  Get.offAllNamed('/auth');
                }
              },
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showTokenExpired() {
    show(
      title: 'Sesión Expirada',
      message: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente para continuar usando todas las funcionalidades de la aplicación.',
      canRetry: false,
    );
  }

  static void showNetworkError() {
    show(
      title: 'Error de Conexión',
      message: 'No se pudo conectar con el servidor. Verifica tu conexión a internet e inténtalo de nuevo.',
      onRetry: () {
        // Recargar la página actual
        Get.forceAppUpdate();
      },
    );
  }

  static void showGenericAuthError(String details) {
    show(
      title: 'Error de Autenticación',
      message: 'Ha ocurrido un problema de autenticación: $details\n\nPor favor, inicia sesión nuevamente.',
      canRetry: false,
    );
  }
}