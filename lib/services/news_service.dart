import 'dart:convert';
import 'package:lungs_assistant_agent/constants.dart';
import 'package:http/http.dart' as http;

class NewsService {
  static Future<List<dynamic>> fetchTopHeadlines({http.Client? client}) async {
    final apiKey = AppConstants.requireNewsApiKey();
    final httpClient = client ?? http.Client();
    final response = await httpClient.get(
      Uri.parse('https://newsapi.org/v2/everything?q=lungs&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['articles'] as List<dynamic>?) ?? [];
    } else {
      throw Exception('Failed to load news (HTTP ${response.statusCode})');
    }
  }
}
