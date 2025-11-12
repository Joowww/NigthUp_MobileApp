import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/business.dart';

class BusinessServices {
  final String baseUrl = 'http://localhost:3000/api/business';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<Business>> fetchBusinesses() async {
    try {
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> businessesData = data['businesses'] ?? [];
        
        List<Business> businesses = businessesData.map((dynamic item) => Business.fromJson(item)).toList();
        return businesses;
      } else {
        throw Exception('Failed to load businesses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchBusinesses: $e');
      throw Exception('Error loading businesses: $e');
    }
  }

  Future<Business> fetchBusinessById(String id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Business.fromJson(data);
      } else {
        throw Exception('Error loading business: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchBusinessById: $e');
      throw Exception('Error loading business: $e');
    }
  }

  Future<List<Business>> fetchAllBusinessesWithInactive() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/all/inactive-included'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> businessesData = data['businesses'] ?? [];
        
        List<Business> businesses = businessesData.map((dynamic item) => Business.fromJson(item)).toList();
        return businesses;
      } else {
        throw Exception('Failed to load businesses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAllBusinessesWithInactive: $e');
      throw Exception('Error loading businesses: $e');
    }
  }

  Future<Business> createBusiness(Map<String, dynamic> businessData) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(businessData),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Business.fromJson(data);
      } else {
        throw Exception('Failed to create business: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createBusiness: $e');
      throw Exception('Error creating business: $e');
    }
  }

  Future<Business> updateBusiness(String businessId, Map<String, dynamic> businessData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/$businessId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(businessData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Business.fromJson(data);
      } else {
        throw Exception('Failed to update business: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateBusiness: $e');
      throw Exception('Error updating business: $e');
    }
  }
}