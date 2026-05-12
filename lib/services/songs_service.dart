import 'dart:convert';
import 'package:http/http.dart' as http;

class SongsService {
  static Future<List<dynamic>> fetchSongs() async {
    final response = await http.get(
      Uri.parse(
        'https://itunes.apple.com/search?term=health&entity=song&limit=50',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load songs');
    }
  }
}
