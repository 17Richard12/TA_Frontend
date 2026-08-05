import 'dart:convert';
import 'package:agent_doctor/constants.dart';
import 'package:http/http.dart' as http;

class NewsService {
  static const String _apiKey = AppConstants.newsApiKey;

  static Future<List<dynamic>> fetchTopHeadlines() async {
    final response = await http.get(
      Uri.parse('https://newsapi.org/v2/everything?q=lungs&apiKey=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['articles'];
    } else {
      throw Exception('Failed to load news');
    }
  }
}
