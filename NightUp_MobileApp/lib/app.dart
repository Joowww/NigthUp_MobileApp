import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgotPassword_screen.dart';
import 'screens/home_feed.dart';
import 'screens/search_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/user_profile.dart';
import 'screens/settings_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/panic_screen.dart';
import 'screens/event_calendar.dart'; // ✅ CAMBIADO
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
    await FcmService.initializeFCM();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final AuthController authController = Get.find<AuthController>();
    final status = await authController.checkAuthStatus();

    print('🔐 Auth status: $status');

    if (status['isLoggedIn'] == true) {
      // BYPASS: Siempre ir al main, ignorar onboarding por ahora
      changeScreen(AppScreen.main);
    } else {
      changeScreen(AppScreen.login);
    }
  }

  // ✅ CAMBIADO: Quitar guion bajo para hacerlo público
  void changeScreen(AppScreen screen) {
    if (screen == AppScreen.main) {
      _initPrivateControllers();
    }
    setState(() {
      _currentScreen = screen;
    });
  }

  void _initPrivateControllers() {
    if (!Get.isRegistered<SocketService>()) {
      Get.put(SocketService());
    }
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
          onLogin: () => changeScreen(AppScreen.main),
          onRegister: () => changeScreen(AppScreen.register),
          onForgotPassword: () => changeScreen(AppScreen.forgotPassword),
        );
      case AppScreen.register:
        return RegisterScreen(
          onBack: () => changeScreen(AppScreen.login),
          onRegister: () => changeScreen(AppScreen.main),
        );
      case AppScreen.forgotPassword:
        return ForgotPasswordScreen(
          onBack: () => changeScreen(AppScreen.login),
        );
      case AppScreen.main:
        return _buildMainContent();
      case AppScreen.settings:
        return SettingsScreen(onBack: () => changeScreen(AppScreen.main));
      case AppScreen.eventDetail:
        return EventDetailScreen(
          onBack: () => changeScreen(AppScreen.main),
          eventId: _selectedEventId ?? '',
        );
      case AppScreen.panic:
        return PanicScreen(onBack: () => changeScreen(AppScreen.main));
      case AppScreen.calendar:
        return const EventsCalendar();
      case AppScreen.fullMap:
        return const FullMapScreen();
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
              log('   Type: ${eventId.runtimeType}');
              log('   Length: ${eventId.length}');
              setState(() {
                _selectedEventId = eventId;
                _currentScreen = AppScreen.eventDetail;
              });
            },
          ),
          SearchScreen(),
          Container(
            color: Colors.black,
            child: const Center(
              child: Text('Camera', style: TextStyle(color: Colors.white)),
            ),
          ),
          ChatScreen(),
          UserProfile(
            onSettingsOpen: () => changeScreen(AppScreen.settings),
            onCalendarOpen: () => changeScreen(AppScreen.calendar),
            onPanicOpen: () => changeScreen(AppScreen.panic),
            onMapOpen: () => changeScreen(AppScreen.fullMap),
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
  forgotPassword,
  main,
  settings,
  eventDetail,
  panic,
  calendar,
  fullMap,
  menuModal,
}
