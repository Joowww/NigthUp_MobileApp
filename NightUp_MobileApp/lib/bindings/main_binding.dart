import 'package:get/get.dart';
import '../controllers/home_feed_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/map_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/menu_modal_controller.dart';
import '../controllers/rating_controller.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeFeedController());
    Get.lazyPut(() => ChatController());
    Get.lazyPut(() => MapController());
    Get.lazyPut(() => SettingsController());
    Get.lazyPut(() => MenuModalController());
    Get.lazyPut(() => RatingController());
  }
}
