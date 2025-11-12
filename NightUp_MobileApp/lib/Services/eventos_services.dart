import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';
import '../Models/eventos.dart';

class EventosServices {
  final String baseUrl = 'http://localhost:3000/api/event';
  final AuthInterceptor _client = Get.find<AuthInterceptor>();

  Future<List<Evento>> fetchEvents() async {
    try {
      print('🔄 [EVENT SERVICE] Fetching events...');
      final response = await _client.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> eventsData = data['events'] ?? [];
        
        List<Evento> eventos = eventsData.map((dynamic item) => Evento.fromJson(item)).toList();
        print('✅ [EVENT SERVICE] Successfully fetched ${eventos.length} events');
        return eventos;
      } else {
        print('❌ [EVENT SERVICE] Failed to load events: ${response.statusCode}');
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in fetchEvents: $e');
      throw Exception('Error loading events: $e');
    }
  }

  Future<Evento> fetchEventById(String id) async {
    try {
      print('🔄 [EVENT SERVICE] Fetching event by ID: $id');
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [EVENT SERVICE] Successfully fetched event: ${data['name']}');
        return Evento.fromJson(data);
      } else {
        print('❌ [EVENT SERVICE] Error loading event: ${response.statusCode}');
        throw Exception('Error loading event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in fetchEventById: $e');
      throw Exception('Error loading event: $e');
    }
  }

  Future<Evento> createEvent(Map<String, dynamic> eventData) async {
    try {
      print('🔄 [EVENT SERVICE] Creating event...');
      final response = await _client.post(
        Uri.parse(baseUrl),
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [EVENT SERVICE] Successfully created event: ${data['name']}');
        return Evento.fromJson(data);
      } else {
        print('❌ [EVENT SERVICE] Failed to create event: ${response.statusCode}');
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in createEvent: $e');
      throw Exception('Error creating event: $e');
    }
  }

  Future<Evento> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    try {
      print('🔄 [EVENT SERVICE] Updating event: $eventId');
      final response = await _client.patch(
        Uri.parse('$baseUrl/$eventId'),
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final event = data['event'] ?? data;
        print('✅ [EVENT SERVICE] Successfully updated event');
        return Evento.fromJson(event);
      } else {
        print('❌ [EVENT SERVICE] Failed to update event: ${response.statusCode}');
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in updateEvent: $e');
      throw Exception('Error updating event: $e');
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      print('🔄 [EVENT SERVICE] Deleting event: $eventId');
      final response = await _client.delete(Uri.parse('$baseUrl/hard/$eventId'));
      
      if (response.statusCode == 200) {
        print('✅ [EVENT SERVICE] Successfully deleted event');
        return true;
      } else {
        print('❌ [EVENT SERVICE] Failed to delete event: ${response.statusCode}');
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in deleteEvent: $e');
      throw Exception('Error deleting event: $e');
    }
  }

  Future<Evento> joinEvent(String eventId) async {
    try {
      print('🔄 [EVENT SERVICE] Joining event: $eventId');
      final response = await _client.post(
        Uri.parse('$baseUrl/$eventId/add-user'),
        body: json.encode({'userIdentifier': 'current'}),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [EVENT SERVICE] Successfully joined event');
        return Evento.fromJson(data);
      } else {
        print('❌ [EVENT SERVICE] Failed to join event: ${response.statusCode}');
        throw Exception('Failed to join event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in joinEvent: $e');
      throw Exception('Error joining event: $e');
    }
  }

  Future<Evento> leaveEvent(String eventId) async {
    try {
      print('🔄 [EVENT SERVICE] Leaving event: $eventId');
      final response = await _client.post(
        Uri.parse('$baseUrl/$eventId/remove-user'),
        body: json.encode({'userIdentifier': 'current'}),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [EVENT SERVICE] Successfully left event');
        return Evento.fromJson(data);
      } else {
        print('❌ [EVENT SERVICE] Failed to leave event: ${response.statusCode}');
        throw Exception('Failed to leave event: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in leaveEvent: $e');
      throw Exception('Error leaving event: $e');
    }
  }

  Future<Map<String, dynamic>> getEventStats() async {
    try {
      print('🔄 [EVENT SERVICE] Fetching event stats...');
      final response = await _client.get(Uri.parse('$baseUrl/stats'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ [EVENT SERVICE] Successfully fetched event stats');
        return {'success': true, 'stats': data};
      } else {
        print('❌ [EVENT SERVICE] Failed to load stats: ${response.statusCode}');
        return {'success': false, 'message': 'Failed to load stats'};
      }
    } catch (e) {
      print('❌ [EVENT SERVICE] Error in getEventStats: $e');
      return {'success': false, 'message': 'Error loading stats: $e'};
    }
  }
}