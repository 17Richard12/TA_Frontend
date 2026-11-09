import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lungs_assistant_agent/services/smoke_service.dart';

/// Single source of truth untuk jumlah rokok hari ini.
///
/// * Semua penulisan diserialisasi lewat antrean ([_tail]) dan di-*coalesce*
///   (hanya nilai terbaru yang dikirim).
/// * Layar lain (Report) mendengarkan [SmokeSync] dan dapat menunggu
///   [waitForPendingWrites] sebelum fetch agar tidak membaca data basi.
class SmokeSync extends ChangeNotifier {
  SmokeSync._();
  static final SmokeSync instance = SmokeSync._();

  String? _userId;
  String? _date; // YYYY-MM-DD
  int? _desired; // nilai terakhir yang diminta UI
  int? _lastSynced; // nilai terakhir yang sukses tersimpan di server
  int _pendingWrites = 0;
  int _revision = 0;
  Future<void> _tail = Future.value();

  /// Bertambah setiap kali server mengonfirmasi perubahan.
  int get revision => _revision;

  /// Jumlah rokok terakhir yang sudah tersimpan di server untuk [date].
  int? confirmedCountFor(String userId, String date) =>
      (_userId == userId && _date == date) ? _lastSynced : null;

  bool get hasPendingWrites => _pendingWrites > 0;

  /// Dipanggil Home setelah GET dari server agar store tahu nilai awal.
  void seed(String userId, String date, int count) {
    final safeCount = count < 0 ? 0 : count;
    if (_userId != userId || _date != date) {
      _userId = userId;
      _date = date;
      _desired = safeCount;
      _lastSynced = safeCount;
      return;
    }
    if (!hasPendingWrites) {
      _desired = safeCount;
      _lastSynced = safeCount;
    }
  }

  /// Menyimpan total rokok hari ini. Return `true` jika tersimpan.
  Future<bool> setCount(String userId, String date, int count) {
    final safeCount = count < 0 ? 0 : (count > 200 ? 200 : count);
    if (_userId != userId || _date != date) {
      _userId = userId;
      _date = date;
      _lastSynced = 0;
    }
    _desired = safeCount;
    _pendingWrites++;

    final completer = Completer<bool>();
    _tail = _tail.then((_) async {
      bool ok = true;
      try {
        final target = _desired ?? 0;
        if (target != _lastSynced) {
          ok = await SmokeService.postSmokeCount(userId, date, target);
          if (ok) {
            _lastSynced = target;
            _revision++;
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('SmokeSync.setCount error: $e');
        ok = false;
      } finally {
        _pendingWrites--;
        if (!ok && _pendingWrites == 0) {
          _desired = _lastSynced ?? 0;
        }
        completer.complete(ok);
      }
    });
    return completer.future;
  }

  /// Menunggu semua penulisan yang sedang berjalan selesai.
  Future<void> waitForPendingWrites() => _tail;

  /// Reset saat logout.
  void reset() {
    _userId = null;
    _date = null;
    _desired = null;
    _lastSynced = null;
    _revision = 0;
  }
}
