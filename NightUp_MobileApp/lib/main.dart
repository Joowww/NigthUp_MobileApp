import 'bindings/auth_binding.dart';
import 'bindings/main_binding.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/poll_service.dart';
import 'services/cloudinary_service.dart';
import 'services/notification_service.dart';
import 'services/jitsi_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Get.putAsync<StorageService>(() => StorageService().init());
  Get.put<http.Client>(http.Client());
  Get.put<ApiService>(ApiService());
  Get.put<PollService>(PollService());
  Get.put<CloudinaryService>(CloudinaryService());
  Get.put<JitsiService>(JitsiService());
  await Get.putAsync<NotificationService>(() => NotificationService().init());

  var delegate = await LocalizationDelegate.create(
    fallbackLocale: 'es',
    supportedLocales: ['es', 'en', 'de', 'fr', 'pt', 'it'],
    basePath: 'assets/i18n/',
  );

  runApp(LocalizedApp(delegate, const NightUpApp()));
}

class NightUpApp extends StatelessWidget {
  const NightUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    var localizationDelegate = LocalizedApp.of(context).delegate;

    return GetMaterialApp(
      title: 'NightUp',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        localizationDelegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: localizationDelegate.supportedLocales,
      locale: localizationDelegate.currentLocale,
      initialBinding: AuthBinding(),
      getPages: [
        GetPage(name: '/', page: () => const App()),
        GetPage(name: '/home', page: () => const App(), binding: MainBinding()),
        GetPage(
          name: '/login',
          page: () => LoginScreen(
            onLogin: () => Get.offAllNamed('/home'),
            onRegister: () => Get.to(
              () => RegisterScreen(onBack: Get.back, onRegister: () {}),
            ),
            onForgotPassword: () {},
          ),
        ),
      ],
    );
  }
}
