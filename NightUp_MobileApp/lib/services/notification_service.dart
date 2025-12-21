import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final RxBool isInitialized = false.obs;

  Future<NotificationService> init() async {
    if (isInitialized.value) return this;

    log('🔔 Initializing NotificationService...');

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
      log('✅ NotificationService initialized');
    } catch (e) {
      log('❌ Error initializing notifications: $e');
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
      log('❌ Error requesting permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    log('🔔 Notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final conversationId = response.payload!;

        Get.toNamed('/chat', arguments: {'conversationId': conversationId});
      } catch (e) {
        log('❌ Error navigating from notification: $e');
      }
    }
  }

  Future<void> showMessageNotification({
    String? title,
    String? body,
    String? conversationId,
    String? senderName,
    String? message,
    bool? isGroup,
  }) async {
    if (!isInitialized.value) {
      log('⚠️ Notifications not initialized yet');
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

      log('✅ Notification shown: $notificationTitle - $displayBody');
    } catch (e) {
      log('❌ Error showing notification: $e');
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    log('🔕 All notifications cancelled');
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    log('🔕 Notification $id cancelled');
  }
}
