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

  // ✅ Ambil lokasi user + fetch RS
  Future<void> _getUserLocation() async {
    try {
      // 1. Pastikan layanan lokasi di perangkat aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          'Layanan lokasi di perangkat nonaktif. '
          'Aktifkan lokasi lalu coba lagi.',
        );
        return;
      }

      // 2. Cek dan minta izin lokasi
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

      // 3. Ambil posisi pengguna (maksimal menunggu 15 detik)
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

      // 4. Ambil rumah sakit terdekat dari Places API.
      //    Jika gagal, peta tetap tampil dan pengguna diberi tahu.
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
              infoWindow: InfoWindow(title: name),
              onTap: () => _openGoogleMaps(lat, lng),
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

  // ✅ Buka Google Maps app
  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps';
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
          _controller.complete(controller);
        },
      ),
    );
  }
}
