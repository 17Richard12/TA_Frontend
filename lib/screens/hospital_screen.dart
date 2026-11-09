import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lungs_assistant_agent/services/hospital_service.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const Color primaryDark = Color(0xFF1A1A8C);
  static const Color primaryBlue = Color(0xFF2F60CC);

  LatLng? _currentPosition;
  Set<Marker> _markers = {};

  String? _error;

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          'Layanan lokasi di perangkat nonaktif. '
          'Aktifkan lokasi lalu coba lagi.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _setError(
          'Izin lokasi ditolak. Izinkan lokasi untuk melihat '
          'rumah sakit terdekat.',
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setError(
          'Izin lokasi diblokir. Buka Pengaturan aplikasi dan '
          'izinkan akses lokasi.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _error = null;
      });

      try {
        final hospitals = await PlacesService.fetchNearbyHospitals(
          position.latitude,
          position.longitude,
        );

        final newMarkers = <Marker>{};
        for (final hospital in hospitals) {
          final lat = (hospital['lat'] as num).toDouble();
          final lng = (hospital['lng'] as num).toDouble();
          final name = hospital['name'].toString();

          newMarkers.add(
            Marker(
              markerId: MarkerId('$name-$lat-$lng'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: 'Ketuk untuk jadwal dokter & rute',
                onTap: () => _showHospitalDetailBottomSheet(hospital),
              ),
              onTap: () => _showHospitalDetailBottomSheet(hospital),
            ),
          );
        }

        if (!mounted) return;
        setState(() => _markers = newMarkers);

        if (newMarkers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada rumah sakit dalam radius 3 km.'),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat rumah sakit: $e')));
      }
    } on TimeoutException {
      _setError(
        'Waktu pengambilan lokasi habis. Pastikan lokasi perangkat '
        'atau simulator sudah diatur, lalu coba lagi.',
      );
    } catch (e) {
      _setError('Gagal mengambil lokasi: $e');
    }
  }

  void _showHospitalDetailBottomSheet(Map<String, dynamic> hospital) {
    final String name = (hospital['name'] ?? 'Rumah Sakit').toString();
    final String vicinity = (hospital['vicinity'] ?? '').toString();
    final double lat = (hospital['lat'] as num).toDouble();
    final double lng = (hospital['lng'] as num).toDouble();
    final dynamic rating = hospital['rating'];
    final bool? openNow = hospital['open_now'] as bool?;
    final List<dynamic> schedules =
        (hospital['doctor_schedules'] as List<dynamic>?) ?? const [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (vicinity.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          vicinity,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      if (rating != null || openNow != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (rating != null) ...[
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$rating / 5.0',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (rating != null && openNow != null)
                              const SizedBox(width: 10),
                            if (openNow != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: openNow
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  openNow ? 'Buka Saat Ini' : 'Tutup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: openNow
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: primaryDark),
                SizedBox(width: 8),
                Text(
                  'Jadwal Praktik Dokter & Layanan Paru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (schedules.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jadwal resmi praktik dokter spesialis paru belum tersedia dari Google Maps. Silakan hubungi pihak rumah sakit secara langsung untuk konfirmasi jam praktik dokter.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...schedules.map((item) {
                final s = item as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['poli']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s['days']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s['hours']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openGoogleMapsDirections(name, lat, lng);
                },
                icon: const Icon(Icons.directions_rounded),
                label: const Text(
                  'Arahkan Rute',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuka aplikasi Google Maps eksternal untuk navigasi rute ke RS.
  Future<void> _openGoogleMapsDirections(
    String hospitalName,
    double lat,
    double lng,
  ) async {
    final encodedDest = Uri.encodeComponent('$hospitalName @$lat,$lng');
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encodedDest&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final fallback = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _getUserLocation();
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Hospitals"),
        automaticallyImplyLeading: false,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          if (!_controller.isCompleted) {
            _controller.complete(controller);
          }
        },
      ),
    );
  }
}
