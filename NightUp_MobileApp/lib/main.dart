import 'bindings/auth_binding.dart';
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
import 'services/cloudinary_service.dart'; // ✅ NUEVO
import 'services/notification_service.dart'; // ✅ NUEVO
import 'services/jitsi_service.dart'; // ✅ NUEVO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase con opciones multiplataforma (obligatorio en web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar servicios globales
  await Get.putAsync<StorageService>(() => StorageService().init());
  Get.put<http.Client>(http.Client());
  Get.put<ApiService>(ApiService());
  Get.put<PollService>(PollService());
  Get.put<CloudinaryService>(CloudinaryService()); // ✅ NUEVO
  Get.put<JitsiService>(JitsiService()); // ✅ NUEVO
  await Get.putAsync<NotificationService>(
    () => NotificationService().init(),
  ); // ✅ NUEVO

  // Controladores se inicializan vía Bindings o en _initPrivateControllers

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
      home: const App(),
    );
  }
}
