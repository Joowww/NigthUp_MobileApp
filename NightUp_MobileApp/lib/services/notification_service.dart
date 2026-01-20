import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../screens/chat_screen.dart';

class AppColors {
  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFFEC4899);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final RxBool isInitialized = false.obs;

  Future<NotificationService> init() async {
    if (isInitialized.value) return this;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();

      isInitialized.value = true;
    } catch (e) {
      //nothing
    }

    return this;
  }

  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      //nothing
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final conversationId = response.payload!;
        Get.to(
          () => const ChatScreen(),
          arguments: {'conversationId': conversationId},
        );
      } catch (e) {
        //nothing
      }
    }
  }

  void showInAppNotification({
    required String title,
    required String message,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.grey[900]!.withOpacity(0.95),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: const Duration(milliseconds: 500),
      icon: imageUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 20)
          : const Icon(Icons.message, color: AppColors.primary, size: 28),
      shouldIconPulse: true,
      onTap: (_) {
        if (onTap != null) onTap();
      },
      boxShadows: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // ==================== NOTIFICACIÓN DEL SISTEMA ====================

  Future<void> showMessageNotification({
    String? title,
    String? body,
    String? conversationId,
    String? senderName,
    String? message,
    bool? isGroup,
  }) async {
    if (!isInitialized.value) {
      return;
    }

    try {
      final notificationTitle =
          title ??
          (isGroup == true ? '📱 $senderName en grupo' : '💬 $senderName');

      final notificationBody = body ?? message ?? '';

      const androidDetails = AndroidNotificationDetails(
        'messages_channel',
        'Mensajes',
        channelDescription: 'Notificaciones de mensajes nuevos',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final displayBody = notificationBody.length > 100
          ? '${notificationBody.substring(0, 100)}...'
          : notificationBody;

      final notificationId =
          conversationId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

      await _notifications.show(
        notificationId,
        notificationTitle,
        displayBody,
        notificationDetails,
        payload: conversationId,
      );
    } catch (e) {
      //nothing
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
