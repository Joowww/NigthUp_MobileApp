import 'package:get/get.dart';
import '../Controllers/auth_controller.dart';
import '../Controllers/user_controller.dart';
import '../Controllers/eventos_controller.dart';
import '../Controllers/business_controller.dart';
import '../Controllers/rating_controller.dart';
import '../Controllers/tag_controller.dart';
import '../Controllers/user_interest_controller.dart';
import '../Controllers/user_trust_controller.dart';

import '../Services/user_services.dart';
import '../Services/eventos_services.dart';
import '../Services/business_services.dart';
import '../Services/rating_services.dart';
import '../Services/tag_services.dart';
import '../Services/user_interest_services.dart';
import '../Services/user_trust_services.dart';

import '../Interceptor/auth_interceptor.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Limpiar todas las dependencias anteriores
    Get.reset();
    
    // Servicios PRIMERO
    Get.lazyPut<UserServices>(() => UserServices(), fenix: true);
    Get.lazyPut<EventosServices>(() => EventosServices(), fenix: true);
    Get.lazyPut<BusinessServices>(() => BusinessServices(), fenix: true);
    Get.lazyPut<RatingServices>(() => RatingServices(), fenix: true);
    Get.lazyPut<TagServices>(() => TagServices(), fenix: true);
    Get.lazyPut<UserInterestServices>(() => UserInterestServices(), fenix: true);
    Get.lazyPut<UserTrustServices>(() => UserTrustServices(), fenix: true);
    
    // AuthInterceptor después
    Get.lazyPut<AuthInterceptor>(() => AuthInterceptor(), fenix: true);
    
    // Controladores
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<UserController>(() => UserController(Get.find<UserServices>()), fenix: true);
    Get.lazyPut<EventoController>(() => EventoController(Get.find<EventosServices>()), fenix: true);
    Get.lazyPut<BusinessController>(() => BusinessController(Get.find<BusinessServices>()), fenix: true);
    Get.lazyPut<RatingController>(() => RatingController(Get.find<RatingServices>()), fenix: true);
    Get.lazyPut<TagController>(() => TagController(Get.find<TagServices>()), fenix: true);
    Get.lazyPut<UserInterestController>(() => UserInterestController(Get.find<UserInterestServices>()), fenix: true);
    Get.lazyPut<UserTrustController>(() => UserTrustController(Get.find<UserTrustServices>()), fenix: true);
  }
}