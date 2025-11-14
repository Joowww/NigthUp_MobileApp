import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/themes/app_colors.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void showSnackbar({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = AppColors.error;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = AppColors.warning;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor = AppColors.info;
        icon = Icons.info;
        break;
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      icon: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      shouldIconPulse: false,
      barBlur: 10,
    );
  }

  void showSuccess(String message, {String title = '¡Éxito!'}) {
    showSnackbar(
      title: title,
      message: message,
      type: NotificationType.success,
    );
  }

  void showError(String message, {String title = 'Error'}) {
    showSnackbar(
      title: title,
      message: message,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
    );
  }

  void showWarning(String message, {String title = 'Atención'}) {
    showSnackbar(
      title: title,
      message: message,
      type: NotificationType.warning,
    );
  }

  void showInfo(String message, {String title = 'Información'}) {
    showSnackbar(
      title: title,
      message: message,
      type: NotificationType.info,
    );
  }
}