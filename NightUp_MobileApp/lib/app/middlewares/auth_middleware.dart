import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.login);
    }
    
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    return page;
  }
}