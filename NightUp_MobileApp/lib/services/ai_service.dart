import 'package:get/get.dart';
import 'api_service.dart';
import '../models/event.dart';

class AiService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<Map<String, dynamic>> searchEventsWithAi(String query) async {
    try {
      final response = await _apiService.post(
        '/ai/search',
        data: {'query': query},
      );

      if (response.data != null && response.data['events'] is List) {
        final List<dynamic> eventsJson = response.data['events'];
        final List<Event> events = eventsJson
            .map((e) => Event.fromJson(e))
            .toList();

        return {
          'events': events,
          'count': response.data['count'],
          'meta': response.data['meta'],
        };
      }
      return {'events': <Event>[], 'count': 0};
    } catch (e) {
      return {'events': <Event>[], 'count': 0, 'error': e.toString()};
    }
  }
}
