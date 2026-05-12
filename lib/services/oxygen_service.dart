import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

class OxygenService {
  static final Health _health = Health();

  /// Buka Health Connect langsung agar user bisa grant permission manual
  static Future<void> openHealthConnectSettings() async {
    final uri = Uri.parse('healthconnect://');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback ke Play Store jika Health Connect belum terinstall
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final granted = await _health.requestAuthorization(
        [HealthDataType.BLOOD_OXYGEN],
        permissions: [HealthDataAccess.READ],
      );
      print('DEBUG Permission granted: $granted');
      return granted;
    } catch (e) {
      print('DEBUG requestPermission error: $e');
      return false;
    }
  }

  static Future<double> getLatestOxygenLevel() async {
    try {
      final now = DateTime.now();
      final sevenDays = now.subtract(const Duration(days: 7));

      final hasPermission = await _health.hasPermissions(
        [HealthDataType.BLOOD_OXYGEN],
        permissions: [HealthDataAccess.READ],
      );
      print('DEBUG hasPermission: $hasPermission');

      if (hasPermission != true) {
        final granted = await _health.requestAuthorization(
          [HealthDataType.BLOOD_OXYGEN],
          permissions: [HealthDataAccess.READ],
        );
        if (!granted) return 0.0;
      }

      final data = await _health.getHealthDataFromTypes(
        startTime: sevenDays,
        endTime: now,
        types: [HealthDataType.BLOOD_OXYGEN],
      );

      print('DEBUG Data count: ${data.length}');
      for (final d in data) {
        print(
          'DEBUG SpO2: ${d.value} at ${d.dateFrom} source: ${d.sourceName}',
        );
      }

      if (data.isEmpty) return 0.0;

      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = (data.first.value as NumericHealthValue).numericValue
          .toDouble();
      return value > 1 ? value : value * 100;
    } catch (e) {
      print('DEBUG getLatestOxygenLevel error: $e');
      return 0.0;
    }
  }
}
