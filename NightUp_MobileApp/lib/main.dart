// main.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart'; // 👈 AÑADIR
import 'controllers/auth_controller.dart';
import 'controllers/interestSelection_controller.dart';
import 'controllers/home_feed_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar dependencias en orden correcto
  await Get.putAsync<StorageService>(() => StorageService().init());
  Get.put<http.Client>(http.Client());
  Get.put<ApiService>(ApiService());
  // Inicializar controladores principales
  Get.put<AuthController>(AuthController());
  Get.put<InterestSelectionController>(InterestSelectionController());
  Get.put<HomeFeedController>(HomeFeedController());

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
      home: const App(),
    );
  }
}