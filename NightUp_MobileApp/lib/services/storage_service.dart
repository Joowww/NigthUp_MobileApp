import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<bool> write(String key, dynamic value) async {
    try {
      if (value is String) {
        return await _prefs.setString(key, value);
      } else if (value is int) {
        return await _prefs.setInt(key, value);
      } else if (value is bool) {
        return await _prefs.setBool(key, value);
      } else if (value is double) {
        return await _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        return await _prefs.setStringList(key, value);
      } else if (value is Map) {
        return await _prefs.setString(key, json.encode(value));
      }
      return false;
    } catch (e) {
      print('Error writing to storage: $e');
      return false;
    }
  }

  dynamic read(String key) {
    try {
      return _prefs.get(key);
    } catch (e) {
      print('Error reading from storage: $e');
      return null;
    }
  }

  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      print('Error removing from storage: $e');
      return false;
    }
  }

  bool containsKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      print('Error checking key in storage: $e');
      return false;
    }
  }

  // Nuevo método para leer JSON
  Map<String, dynamic>? readJson(String key) {
    try {
      final value = _prefs.getString(key);
      if (value != null) {
        return json.decode(value);
      }
      return null;
    } catch (e) {
      print('Error reading JSON from storage: $e');
      return null;
    }
  }
}