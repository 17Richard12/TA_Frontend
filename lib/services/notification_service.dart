import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _dailyReminderMorningId = 1001;
  static const int _dailyReminderEveningId = 1002;
  static const int _warningLowId = 2001;
  static const int _warningHighId = 2002;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings);

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
      await scheduleDailyReminders();
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  /// Menjadwalkan pengingat harian (pagi 08:00 & malam 20:00 WIB)
  Future<void> scheduleDailyReminders() async {
    if (!_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'Pengingat Harian Kesehatan Paru',
        channelDescription:
            'Notifikasi pengingat harian aktivitas sehat dan pencatatan rokok',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        _dailyReminderMorningId,
        'Semangat Pagi! 🌿',
        'Jangan lupa cek aktivitas sehat harianmu di Agent Doctor dan jaga paru-parumu hari ini.',
        _nextInstanceOfHour(8, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _plugin.zonedSchedule(
        _dailyReminderEveningId,
        'Evaluasi Harian Agent Doctor 📊',
        'Sudahkah kamu menyelesaikan aktivitas sehat dan mencatat konsumsi rokok hari ini?',
        _nextInstanceOfHour(20, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDailyReminders error: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfHour(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Mengevaluasi apakah jumlah rokok mendekati/melewati batas rendah atau tinggi
  /// dan memunculkan local push notification "Warning".
  Future<void> checkAndNotifySmokeLimit({
    required String userId,
    required String dateStr,
    required int smokeCount,
    required int lowLimit,
    required int highLimit,
  }) async {
    await init();
    if (!_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final highKey = 'notif_high_${userId}_$dateStr';
      final lowKey = 'notif_low_${userId}_$dateStr';

      const androidDetails = AndroidNotificationDetails(
        'smoke_warning_channel',
        'Peringatan Batas Rokok',
        channelDescription:
            'Peringatan ketika konsumsi rokok mendekati atau melebihi batas wajar',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      if (highLimit > 0 && smokeCount >= highLimit) {
        final alreadySentHigh = prefs.getBool(highKey) ?? false;
        if (!alreadySentHigh || smokeCount > highLimit) {
          await _plugin.show(
            _warningHighId,
            '⚠️ Warning: Batas Tinggi Rokok Terlampaui!',
            'Konsumsi rokokmu hari ini ($smokeCount batang) telah mencapai/melebihi batas tinggi ($highLimit batang). Segera hentikan merokok hari ini demi kesehatan paru-parumu!',
            details,
          );
          await prefs.setBool(highKey, true);
        }
      } else if (lowLimit > 0 && smokeCount >= lowLimit) {
        final alreadySentLow = prefs.getBool(lowKey) ?? false;
        if (!alreadySentLow) {
          await _plugin.show(
            _warningLowId,
            '⚠️ Warning: Mendekati Batas Wajar Merokok',
            'Kamu sudah merokok $smokeCount batang hari ini (batas rendah: $lowLimit, batas tinggi: $highLimit). Yuk alihkan dengan aktivitas sehat!',
            details,
          );
          await prefs.setBool(lowKey, true);
        }
      }
    } catch (e) {
      debugPrint('checkAndNotifySmokeLimit error: $e');
    }
  }
}
