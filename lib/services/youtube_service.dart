import 'dart:convert';
import 'package:lungs_assistant_agent/constants.dart';
import 'package:http/http.dart' as http;

class YouTubeService {
  static Future<List<dynamic>> fetchVideos({http.Client? client}) async {
    final apiKey = AppConstants.requireYoutubeApiKey();
    final httpClient = client ?? http.Client();
    final response = await httpClient.get(
      Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&q=lungs health'
        '&type=video'
        '&maxResults=50'
        '&key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List<dynamic>?) ?? [];
    } else {
      throw Exception('Failed to load videos (HTTP ${response.statusCode})');
    }
  }
}
