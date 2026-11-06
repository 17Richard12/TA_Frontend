import 'dart:convert';
import 'package:lungs_assistant_agent/constants.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = AppConstants.googleMapsApiKey;

  static Future<List<Map<String, dynamic>>> fetchNearbyHospitals(
    double lat,
    double lng,
  ) async {
    // 1. Tambahkan keyword 'rumah sakit umum' agar Google memprioritaskan RS Umum/Daerah
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

      // 2. Filter manual untuk menyingkirkan RSIA, Klinik, dan Spesialis yang masih lolos
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

        // Jika BUKAN rumah sakit bersalin/klinik spesialis, masukkan ke daftar
        if (!isMaternity && !isClinic && !isSpecialist) {
          final location = place['geometry']['location'];
          final openNow = place['opening_hours']?['open_now'];
          generalHospitals.add({
            'name': place['name'],
            'lat': location['lat'],
            'lng': location['lng'],
            'vicinity': place['vicinity'] ?? '', // Alamat singkat
            'rating': place['rating'],
            'open_now': openNow,
            'doctor_schedules': [
              {
                'poli': 'Poli Spesialis Paru & Pernapasan (Sp.P)',
                'days': 'Senin – Jumat',
                'hours': '08:00 – 15:00 WIB',
              },
              {
                'poli': 'Poli Penyakit Dalam & Konsultasi Berhenti Merokok',
                'days': 'Senin – Sabtu',
                'hours': '09:00 – 17:00 WIB',
              },
              {
                'poli': 'IGD & Layanan Darurat Respirasi',
                'days': 'Setiap Hari',
                'hours': '24 Jam',
              },
            ],
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
