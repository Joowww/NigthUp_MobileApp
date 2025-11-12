import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/tag.dart';

class TagServices {
  final String baseUrl = 'http://localhost:3000/api/tag';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<Tag>> fetchTags() async {
    try {
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> tagsData = data['tags'] ?? [];
        
        List<Tag> tags = tagsData.map((dynamic item) => Tag.fromJson(item)).toList();
        return tags;
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTags: $e');
      throw Exception('Error loading tags: $e');
    }
  }

  Future<Tag> fetchTagById(String id) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Tag.fromJson(data);
      } else {
        throw Exception('Error loading tag: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchTagById: $e');
      throw Exception('Error loading tag: $e');
    }
  }

  Future<List<Tag>> fetchAllTagsWithInactive() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/all/inactive-included'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> tagsData = data['tags'] ?? [];
        
        List<Tag> tags = tagsData.map((dynamic item) => Tag.fromJson(item)).toList();
        return tags;
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchAllTagsWithInactive: $e');
      throw Exception('Error loading tags: $e');
    }
  }

  Future<Tag> createTag(Map<String, dynamic> tagData) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(tagData),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Tag.fromJson(data);
      } else {
        throw Exception('Failed to create tag: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createTag: $e');
      throw Exception('Error creating tag: $e');
    }
  }

  Future<Tag> updateTag(String tagId, Map<String, dynamic> tagData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/$tagId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(tagData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Tag.fromJson(data);
      } else {
        throw Exception('Failed to update tag: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateTag: $e');
      throw Exception('Error updating tag: $e');
    }
  }

  Future<Map<String, dynamic>> getTagStats() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/stats'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {'success': true, 'stats': data};
      } else {
        return {'success': false, 'message': 'Failed to load tag stats'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error loading tag stats: $e'};
    }
  }
}