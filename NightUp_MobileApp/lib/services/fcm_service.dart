import 'notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

/// Servicio para inicializar y gestionar Firebase Cloud Messaging (FCM)
/// en la app Flutter. Llama a [initializeFCM] una sola vez al arranque.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Inicializa FCM y registra listeners para mensajes en foreground.
  /// Llama solo una vez al arranque de la app.
  static Future<void> initializeFCM() async {
    if (_initialized) return;
    _initialized = true;
    // Inicializar notificaciones locales
    await NotificationService().init();
    // Inicializa Firebase solo si no está inicializado
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase ya estaba inicializado
    }
    NotificationSettings settings = await _messaging.requestPermission();
    log('User granted FCM permission: ${settings.authorizationStatus}', name: 'FCM');
    // Listener para mensajes en foreground
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

  /// Obtiene el token FCM del dispositivo (para backend/push)
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
