import 'package:NightUp_MobileApp/Controllers/user_controller.dart';
import 'package:NightUp_MobileApp/Services/user_services.dart';
import 'package:get/get.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
     Get.lazyPut<UserServices>(() => UserServices());
     Get.lazyPut<UserController>(() => UserController(Get.find<UserServices>()));
  }
}