import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use localhost for dev (requires adb reverse on Android)
  // Use a real production URL for release builds
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.tu-dominio-produccion.com/api'; // CAMBIAR ESTO
    }
    return 'http://localhost:3000/api';
  }

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}

class StorageKeys {
  static const String token = 'token';
  static const String refreshToken = 'refreshToken';
  static const String user = 'user';
}
