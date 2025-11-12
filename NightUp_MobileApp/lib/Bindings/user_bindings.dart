import 'package:nightup_mobile_app/Controllers/user_controller.dart';
import 'package:nightup_mobile_app/Services/user_services.dart';
import 'package:get/get.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
     Get.lazyPut<UserServices>(() => UserServices());
     Get.lazyPut<UserController>(() => UserController(Get.find<UserServices>()));
  }
}