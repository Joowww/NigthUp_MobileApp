import 'notification_service.dart';
import '../screens/chat_screen.dart';
import 'package:get/get.dart';
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

      String? title;
      String? body;
      String? imageUrl;
      String? conversationId;

      // 1. Try to get data from Notification object
      if (message.notification != null) {
        title = message.notification!.title;
        body = message.notification!.body;
        imageUrl =
            message.notification!.android?.imageUrl ??
            message.notification!.apple?.imageUrl;
      }

      // 2. Fallback to Data object
      final data = message.data;
      if (data.isNotEmpty) {
        title ??= data['title'] ?? 'Nuevo Mensaje';
        body ??= data['body'] ?? data['message'] ?? data['text'] ?? '';
        imageUrl ??= data['imageUrl'] ?? data['image'];
        conversationId = data['conversationId'];
      }

      // 3. Show Notification if we have content
      if (title != null && body != null && body.isNotEmpty) {
        NotificationService().showInAppNotification(
          title: title,
          message: body,
          imageUrl: imageUrl,
          onTap: () {
            if (conversationId != null) {
              Get.to(
                () => const ChatScreen(),
                arguments: {'conversationId': conversationId},
              );
            }
          },
        );
      }
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
