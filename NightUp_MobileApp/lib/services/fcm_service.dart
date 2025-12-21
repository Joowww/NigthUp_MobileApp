import 'notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> initializeFCM() async {
    if (_initialized) return;
    _initialized = true;

    await NotificationService().init();

    try {
      await Firebase.initializeApp();
    } catch (e) {}
    NotificationSettings settings = await _messaging.requestPermission();
    log(
      'User granted FCM permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received FCM message: ${message.notification?.title}', name: 'FCM');
      final notification = message.notification;
      if (notification != null) {
        NotificationService().showMessageNotification(
          title: notification.title ?? 'Notificación',
          body: notification.body ?? '',
        );
      }
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
