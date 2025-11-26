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
import 'widgets/bottom_navigation.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppScreen _currentScreen = AppScreen.splash;
  int _currentTab = 0;

  // Estados para navegación entre pantallas
  int _selectedEventId = 1;

  void _changeScreen(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
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
        return SplashScreen(onComplete: () => _changeScreen(AppScreen.login));
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
          eventId: _selectedEventId.toString(),
        );
      case AppScreen.panic:
        return PanicScreen(onBack: () => _changeScreen(AppScreen.main));
      case AppScreen.calendar:
        return EventCalendarScreen(onBack: () => _changeScreen(AppScreen.main));
      case AppScreen.fullMap:
        return FullMapScreen(onBack: () => _changeScreen(AppScreen.main));
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
              setState(() {
                _selectedEventId = int.tryParse(eventId) ?? 0;
                _currentScreen = AppScreen.eventDetail;
              });
            },
          ),
          SearchScreen(),
          Container(color: Colors.black), // Camera placeholder
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
}