import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';

import 'Bindings/initial_binding.dart';
import 'Screen/login_screen.dart';
import 'Screen/register_screen.dart';
import 'Screen/home.dart';
import 'Screen/eventos_list.dart';
import 'Screen/user_list.dart';
import 'Screen/settings_screen.dart';
import 'Screen/eventos_detail.dart';
import 'Screen/user_detail.dart';
import 'Screen/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar internacionalización
  var delegate = await LocalizationDelegate.create(
    fallbackLocale: 'es',
    supportedLocales: ['es', 'en'],
  );

  runApp(MyApp(delegate));
}

class MyApp extends StatelessWidget {
  final LocalizationDelegate delegate;

  const MyApp(this.delegate, {super.key});

  @override
  Widget build(BuildContext context) {
    return LocalizedApp(
      delegate,
      GetMaterialApp(
        title: 'NightUp',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667EEA),
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          delegate
        ],
        supportedLocales: delegate.supportedLocales,
        locale: delegate.currentLocale,
        initialBinding: InitialBinding(),
        home: const LoginScreen(),
        getPages: [
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/register', page: () => const RegisterScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
          GetPage(name: '/eventos', page: () => const EventosListScreen()),
          GetPage(name: '/users', page: () => const UserListScreen()),
          GetPage(name: '/settings', page: () => SettingsScreen()),
          GetPage(name: '/profile', page: () => EditProfileScreen()),
          GetPage(
            name: '/evento/:id', 
            page: () => EventosDetailScreen(eventoId: Get.parameters['id']!),
          ),
          GetPage(
            name: '/user/:id', 
            page: () => UserDetailScreen(userId: Get.parameters['id']!),
          ),
        ],
        defaultTransition: Transition.cupertino,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}