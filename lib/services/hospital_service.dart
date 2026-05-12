import 'dart:convert';
import 'package:agent_doctor/constants.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = AppConstants.googleMapsApiKey;

  static Future<List<Map<String, dynamic>>> fetchNearbyHospitals(
    double lat,
    double lng,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=3000'
        '&type=hospital'
        '&key=$_apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return (data['results'] as List).map((place) {
        return {
          'name': place['name'],
          'lat': place['geometry']['location']['lat'],
          'lng': place['geometry']['location']['lng'],
        };
      }).toList();
    } else {
      throw Exception('Failed to load hospitals');
    }
  }
}
