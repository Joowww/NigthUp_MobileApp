import 'package:get/get.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/register_view.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/events/views/events_detail_view.dart';
import '../../modules/users/views/user_detail_view.dart';
import '../../modules/users/views/user_profile_view.dart';
import '../../modules/users/bindings/user_profile_binding.dart';
import '../../modules/profile/views/edit_profile_view.dart';
import '../../modules/profile/views/change_password_view.dart';
import '../../modules/profile/bindings/edit_profile_binding.dart';
import '../../modules/profile/bindings/change_password_binding.dart';
import '../../modules/business/views/business_view.dart';
import '../../modules/business/views/business_detail_view.dart';
import '../../modules/tags/views/tags_view.dart';
import '../../modules/interests/views/interests_view.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: AppRoutes.eventDetail,
      page: () => EventDetailView(
        eventId: Get.arguments as String,
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.userDetail,
      page: () => UserDetailView(
        userId: Get.arguments as String,
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.userProfile,
      page: () => const UserProfileView(),
      binding: UserProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.business,
      page: () => const BusinessView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.businessDetail,
      page: () => BusinessDetailView(
        businessId: Get.arguments as String,
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.tags,
      page: () => const TagsView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.interests,
      page: () => const InterestsView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}