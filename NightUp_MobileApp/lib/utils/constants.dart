import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://ea1-api.upc.edu/';
    }
    return 'http://172.20.10.2:3000/api';
    //return 'http://localhost:3000/api';
  }

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}

class StorageKeys {
  static const String token = 'token';
  static const String refreshToken = 'refreshToken';
  static const String user = 'user';
}
