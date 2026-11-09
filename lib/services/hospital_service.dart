import 'dart:convert';
import 'package:lungs_assistant_agent/constants.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  /// Memuat daftar rumah sakit umum terdekat melalui endpoint FastAPI backend
  /// (`/api/hospitals/nearby`) agar kunci Google Places Web Service tetap aman
  /// di sisi server dan tidak diekspos di kode klien.
  static Future<List<Map<String, dynamic>>> fetchNearbyHospitals(
    double lat,
    double lng, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse(
      '${AppConstants.baseUrl}/api/hospitals/nearby?lat=$lat&lng=$lng&radius=3000',
    );
    final headers = await SessionService.getAuthHeaders();

    final response = await httpClient.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decodedResponse =
          json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawList =
          (decodedResponse['data'] ?? decodedResponse['results'] ?? [])
              as List<dynamic>;

      final List<Map<String, dynamic>> generalHospitals = [];

      for (final item in rawList) {
        if (item is! Map) continue;
        final place = Map<String, dynamic>.from(item);
        final name = (place['name'] ?? '').toString();
        final lowerName = name.toLowerCase();

        final isMaternity =
            lowerName.contains('ibu dan anak') ||
            lowerName.contains('rsia') ||
            lowerName.contains('bersalin');
        final isClinic =
            lowerName.contains('klinik') || lowerName.contains('puskesmas');
        final isSpecialist =
            lowerName.contains('gigi') ||
            lowerName.contains('mata') ||
            lowerName.contains('kecantikan');

        if (!isMaternity && !isClinic && !isSpecialist) {
          final dynamic rawLat =
              place['lat'] ?? place['geometry']?['location']?['lat'];
          final dynamic rawLng =
              place['lng'] ?? place['geometry']?['location']?['lng'];
          if (rawLat == null || rawLng == null) continue;

          final dynamic openNow = place.containsKey('open_now')
              ? place['open_now']
              : place['opening_hours']?['open_now'];

          generalHospitals.add({
            'name': name,
            'place_id': place['place_id'] ?? '',
            'lat': (rawLat as num).toDouble(),
            'lng': (rawLng as num).toDouble(),
            'vicinity': place['vicinity'] ?? '',
            'rating': place['rating'],
            'open_now': openNow,
            'doctor_schedules': <Map<String, dynamic>>[],
          });
        }
      }

      return generalHospitals;
    } else if (response.statusCode == 401) {
      await SessionService.clearSession();
      throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
    } else {
      throw Exception(
        'Gagal memuat data rumah sakit terdekat (${response.statusCode})',
      );
    }
  }
}
