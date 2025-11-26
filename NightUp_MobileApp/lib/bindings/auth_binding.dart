import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/map_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/home_feed_controller.dart';
import '../controllers/interestSelection_controller.dart';
import 'package:http/http.dart' as http;

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    // ================== SERVICIOS ==================
    
    // Cliente HTTP compartido
    Get.lazyPut(() => http.Client());

    // Servicio de almacenamiento local (async init)
    Get.putAsync<StorageService>(() => StorageService().init());

    // Servicio de API
    Get.lazyPut(() => ApiService());

    // Servicio de WebSockets - CORREGIDO: usar put en lugar de lazyPut
    Get.put(SocketService());

    // ================== CONTROLADORES ==================

    // Controlador de autenticación
    Get.lazyPut(() => AuthController());

    // Controlador de selección de intereses
    Get.lazyPut(() => InterestSelectionController());

    // Controlador de feed principal
    Get.lazyPut(() => HomeFeedController());

    // Controlador de chat - CORREGIDO: Usar put en lugar de lazyPut para asegurar inicialización
    Get.put(ChatController());

    // Controlador de mapa
    Get.lazyPut(() => MapController());

    // Controlador de settings
    Get.lazyPut(() => SettingsController());
  }
}