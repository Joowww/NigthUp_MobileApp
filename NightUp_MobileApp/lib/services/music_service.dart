import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nightup_mobile_app/utils/constants.dart';

class MusicService {
  static String get _baseUrl => '${ApiConstants.baseUrl}/music/search';

  static Future<List<Map<String, String>>> searchMusic(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?query=$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return (data['results'] as List).map((item) {
          return {
            'title': item['trackName']?.toString() ?? 'Unknown',
            'artist': item['artistName']?.toString() ?? 'Unknown',
            'cover': item['artworkUrl100']?.toString() ?? '',
            'preview': item['previewUrl']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      print('Error searching music: $e');
    }
    return [];
  }
}
