import 'package:get/get.dart';
import '../controllers/interestSelection_controller.dart';

class InterestBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InterestSelectionController());
  }
}