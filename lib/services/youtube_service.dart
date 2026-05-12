import 'dart:convert';
import 'package:agent_doctor/constants.dart';
import 'package:http/http.dart' as http;

class YouTubeService {
  static const String _apiKey = AppConstants.youtubeApiKey;

  static Future<List<dynamic>> fetchVideos() async {
    final response = await http.get(
      Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&q=health'
        '&type=video'
        '&maxResults=50'
        '&key=$_apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to load videos');
    }
  }
}
