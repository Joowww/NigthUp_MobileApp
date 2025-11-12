import 'package:NightUp_MobileApp/Models/eventos.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../Interceptor/auth_interceptor.dart';

class EventosServices {
  final String baseUrl = 'http://localhost:3000/api/event';
  final AuthInterceptor _client = Get.put(AuthInterceptor());
  EventosServices();

  Future<List<Evento>> fetchEvents() async {
    final response = await _client.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Evento> eventos =
          body.map((dynamic item) => Evento.fromJson(item)).toList();
      return eventos;
    } else {
      throw Exception('Failed to load events');
    }
  }
  Future<Evento> fetchEventById(String id) async {
    try {
      
      final response = await _client.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Evento.fromJson(data);
      } else {
        throw Exception('Error al cargar el Evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUserById: $e');
      throw Exception('Error al cargar el Evento: $e');
    }
  }
}