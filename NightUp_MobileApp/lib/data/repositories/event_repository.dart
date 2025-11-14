import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../models/event_model.dart';

class EventRepository {
  final ApiService _apiService = ApiService();
  
  // Dio instance for public endpoints (no auth required)
  late Dio _publicDio;
  
  EventRepository() {
    _initPublicDio();
  }
  
  void _initPublicDio() {
    _publicDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getEvents({int skip = 0, int limit = 10}) async {
    try {
      final response = await _publicDio.get(
        '${ApiConstants.events}?skip=$skip&limit=$limit',
      );
      
      if (response.data is List) {
        final events = <EventModel>[];
        for (var eventJson in (response.data as List)) {
          try {
            events.add(EventModel.fromJson(eventJson));
          } catch (e) {}
        }
        
        print('Parsed ${events.length} events from direct list');
        
        return {
          'events': events,
          'pagination': {
            'skip': skip,
            'limit': limit,
            'total': events.length,
            'hasMore': false,
          },
          'hasMore': false,
          'total': events.length,
        };
      } else if (response.data is Map<String, dynamic>) {
        final events = <EventModel>[];
        final eventsList = response.data['events'] ?? [];
        
        for (var eventJson in eventsList) {
          try {
            events.add(EventModel.fromJson(eventJson));
          } catch (e) {}
        }
        
        final pagination = response.data['pagination'] ?? {};
        
        print('Parsed ${events.length} events from structured response');
        
        return {
          'events': events,
          'pagination': pagination,
          'hasMore': pagination['hasMore'] ?? false,
          'total': pagination['total'] ?? events.length,
        };
      } else {
        print('Unexpected response format: ${response.data}');
        return {
          'events': <EventModel>[],
          'pagination': {},
          'hasMore': false,
          'total': 0,
        };
      }
    } on DioException catch (e) {
      print('Error loading events: ${_handleError(e)}');
      return {
        'events': <EventModel>[],
        'pagination': {},
        'hasMore': false,
        'total': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getEventStats() async {
    try {
      final response = await _publicDio.get('${ApiConstants.events}/stats');
      return response.data;
    } on DioException catch (e) {
      print('Error loading event stats: ${_handleError(e)}');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'newCount': 0,
      };
    }
  }

  Future<List<EventModel>> getMyEvents() async {
    try {
      final response = await _apiService.get(ApiConstants.myEvents);
      final List<dynamic> data = response.data['events'] ?? 
                                response.data['data'] ?? 
                                (response.data is List ? response.data : []);
      return data.map((json) => EventModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error loading my events: ${_handleError(e)}');
      return [];
    }
  }

  Future<EventModel> getEventById(String id) async {
    try {
      final response = await _publicDio.get('${ApiConstants.events}/$id');
      return EventModel.fromJson(
        response.data['event'] ?? response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------
  //  NUEVAS FUNCIONES AÑADIDAS (join / leave)
  // ------------------------------------------------------------

  Future<void> joinEvent(String eventId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.joinEvent(eventId),
        data: {},
      );
      print('Join event response: ${response.data}');
    } on DioException catch (e) {
      print('Join event error: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.leaveEvent(eventId),
        data: {},
      );
      print('Leave event response: ${response.data}');
    } on DioException catch (e) {
      print('Leave event error: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  // ------------------------------------------------------------

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Error desconocido';
      }
      return 'Error del servidor';
    }
    return 'Error de conexión';
  }
}
