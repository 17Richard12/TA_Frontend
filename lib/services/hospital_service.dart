import 'dart:convert';
import 'package:lungs_assistant_agent/constants.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = AppConstants.googleMapsApiKey;

  static Future<List<Map<String, dynamic>>> fetchNearbyHospitals(
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=3000'
      '&type=hospital'
      '&keyword=rumah+sakit+umum'
      '&key=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      final List<dynamic> allResults = decodedResponse['results'] ?? [];

      final List<Map<String, dynamic>> generalHospitals = [];

      for (final place in allResults) {
        final name = (place['name'] ?? '').toString().toLowerCase();

        final isMaternity =
            name.contains('ibu dan anak') ||
            name.contains('rsia') ||
            name.contains('bersalin');
        final isClinic = name.contains('klinik') || name.contains('puskesmas');
        final isSpecialist =
            name.contains('gigi') ||
            name.contains('mata') ||
            name.contains('kecantikan');

        if (!isMaternity && !isClinic && !isSpecialist) {
          final location = place['geometry']['location'];
          final openNow = place['opening_hours']?['open_now'];
          generalHospitals.add({
            'name': place['name'],
            'place_id': place['place_id'],
            'lat': location['lat'],
            'lng': location['lng'],
            'vicinity': place['vicinity'] ?? '',
            'rating': place['rating'],
            'open_now': openNow,
            // Tidak mengisi jadwal dokter fiktif karena Google Places Nearby Search
            // tidak menyediakan jadwal resmi praktik dokter rumah sakit.
            'doctor_schedules': <Map<String, dynamic>>[],
          });
        }
      }

      return generalHospitals;
    } else {
      throw Exception(
        'Gagal memuat data dari Google Maps API: ${response.statusCode}',
      );
    }
  }
}
