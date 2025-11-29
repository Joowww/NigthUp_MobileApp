import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgotPassword_screen.dart';
import 'screens/home_feed.dart';
import 'screens/search_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/user_profile.dart';
import 'screens/interestSelection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/panic_screen.dart';
import 'screens/event_calendar_screen.dart';
import 'screens/full_map_screen.dart';
import 'widgets/menu_modal.dart';
import 'widgets/bottom_navigation.dart';
import 'controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'dart:developer';
import 'services/socket_service.dart';
import 'services/fcm_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppScreen _currentScreen = AppScreen.splash;
  int _currentTab = 0;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    // Inicializar FCM solo una vez al arranque
    await FcmService.initializeFCM();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final AuthController authController = Get.find<AuthController>();
    final status = await authController.checkAuthStatus();
    
    print('🔐 Auth status: $status');
    
    if (status['isLoggedIn'] == true) {
      if (status['onboardingComplete'] == true) {
        _changeScreen(AppScreen.main);
      } else {
        _changeScreen(AppScreen.interestSelection);
      }
    } else {
      _changeScreen(AppScreen.login);
    }
  }

  void _changeScreen(AppScreen screen) {
    // Inicializa controladores privados solo al entrar a la app principal
    if (screen == AppScreen.main) {
      _initPrivateControllers();
    }
    setState(() {
      _currentScreen = screen;
    });
  }

  void _initPrivateControllers() {
    // Los controladores y servicios se inicializan ahora solo vía Bindings
    if (!Get.isRegistered<SocketService>()) {
      Get.put(SocketService());
    }
    // Otros controladores se gestionan por Bindings
  }

  void _changeTab(int index) {
    setState(() {
      _currentTab = index;
      _currentScreen = AppScreen.main;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.splash:
        return SplashScreen(onComplete: () => _checkAuthStatus());
      case AppScreen.login:
        return LoginScreen(
          onLogin: () => _changeScreen(AppScreen.main),
          onRegister: () => _changeScreen(AppScreen.register),
          onForgotPassword: () => _changeScreen(AppScreen.forgotPassword),
        );
      case AppScreen.register:
        return RegisterScreen(
          onBack: () => _changeScreen(AppScreen.login),
          onRegister: () => _changeScreen(AppScreen.interestSelection),
        );
      case AppScreen.interestSelection:
        return const InterestSelectionScreen();
      case AppScreen.forgotPassword:
        return ForgotPasswordScreen(
          onBack: () => _changeScreen(AppScreen.login),
        );
      case AppScreen.main:
        return _buildMainContent();
      case AppScreen.settings:
        return SettingsScreen(onBack: () => _changeScreen(AppScreen.main));
      case AppScreen.eventDetail:
        return EventDetailScreen(
          onBack: () => _changeScreen(AppScreen.main),
          eventId: _selectedEventId ?? '',
        );
      case AppScreen.panic:
        return PanicScreen(onBack: () => _changeScreen(AppScreen.main));
      case AppScreen.calendar:
        return EventCalendarScreen(onBack: () => _changeScreen(AppScreen.main));
      case AppScreen.fullMap:
        return FullMapScreen(onBack: () => _changeScreen(AppScreen.main));
      case AppScreen.menuModal:
        return const MenuModal();
    }
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeFeed(
            onEventClick: (eventId) {
              log('🚀 NAVIGATING TO EVENT DETAIL:');
              log('   Original eventId: $eventId');
              log('   Type: [33m[1m[4m${eventId.runtimeType}[0m');
              log('   Length: ${eventId.length}');
              // Forzar nueva instancia con UniqueKey y navegación directa
              setState(() {
                _selectedEventId = eventId;
                _currentScreen = AppScreen.eventDetail;
              });
            },
          ),
          SearchScreen(),
          Container(color: Colors.black, child: Center(child: Text('Camera', style: TextStyle(color: Colors.white)))), // Camera placeholder
          ChatScreen(),
          UserProfile(
            onSettingsOpen: () => _changeScreen(AppScreen.settings),
            onCalendarOpen: () => _changeScreen(AppScreen.calendar),
            onPanicOpen: () => _changeScreen(AppScreen.panic),
            onMapOpen: () => _changeScreen(AppScreen.fullMap),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentTab,
        onTabChanged: _changeTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }
}

enum AppScreen {
  splash,
  login,
  register,
  interestSelection,
  forgotPassword,
  main,
  settings,
  eventDetail,
  panic,
  calendar,
  fullMap,
  menuModal,
}
