import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/map_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/home_feed_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/interestSelection_controller.dart';
import '../controllers/menu_modal_controller.dart';
import '../controllers/rating_controller.dart';
import 'package:http/http.dart' as http;

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => http.Client());

    Get.putAsync<StorageService>(() => StorageService().init());

    Get.lazyPut(() => ApiService());

    Get.lazyPut(() => AuthController());

    Get.lazyPut(() => InterestSelectionController());

    Get.lazyPut(() => HomeFeedController());

    Get.lazyPut(() => ChatController());

    Get.lazyPut(() => MapController());

    Get.lazyPut(() => SettingsController());

    Get.lazyPut(() => MenuModalController());

    Get.lazyPut(() => RatingController());
  }
}
