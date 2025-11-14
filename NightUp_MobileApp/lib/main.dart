import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/user_service.dart';
import 'modules/auth/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await StorageService().init();
  ApiService().init();
  
  // Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar traducción
  var delegate = await LocalizationDelegate.create(
    fallbackLocale: 'es',
    supportedLocales: ['es', 'en', 'fr', 'de', 'it', 'pt'],
  );

  runApp(LocalizedApp(delegate, const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var localizationDelegate = LocalizedApp.of(context).delegate;

    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: GetMaterialApp(
        title: 'NightUp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          localizationDelegate,
        ],
        supportedLocales: localizationDelegate.supportedLocales,
        locale: localizationDelegate.currentLocale,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
        initialBinding: BindingsBuilder(() {
          Get.put(AuthController());
          Get.put(UserService());
        }),
      ),
    );
  }
}