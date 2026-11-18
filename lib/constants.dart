class AppConstants {
  // ── Server ───────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://lungs-backend-z3hx2fqata-et.a.run.app',
  );
  //static const String baseUrl = 'http://192.168.118.18:8000';

  // ── API Keys (Injected via --dart-define or --dart-define-from-file=dart_defines.json) ──
  // Restrict keys in Google Cloud Console / NewsAPI dashboard:
  // - Android Maps SDK key: restrict to package `com.example.agent_doctor` + signing SHA-1
  // - iOS Maps SDK key: restrict to bundle identifier in Xcode
  // - YouTube Data API v3 key: restrict to YouTube Data API v3 + application restriction
  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: '4c1ca56375b7478a9b855875856e728e',
  );
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyAlba-EULjIvPWhikZuRJbwwRDKWMHI-SM',
  );
  // Google Places Nearby Search is proxied via backend (/api/hospitals/nearby)
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAmhauopUHLnvFOU1h0DGa2LEUkVNDOTXM',
  );

  static String requireNewsApiKey({String? override}) {
    final key = (override ?? newsApiKey).trim();
    if (key.isEmpty) {
      throw StateError(
        'Konfigurasi NEWS_API_KEY belum diatur. Jalankan aplikasi dengan '
        '--dart-define-from-file=dart_defines.json atau --dart-define=NEWS_API_KEY=...',
      );
    }
    return key;
  }

  static String requireYoutubeApiKey({String? override}) {
    final key = (override ?? youtubeApiKey).trim();
    if (key.isEmpty) {
      throw StateError(
        'Konfigurasi YOUTUBE_API_KEY belum diatur. Jalankan aplikasi dengan '
        '--dart-define-from-file=dart_defines.json atau --dart-define=YOUTUBE_API_KEY=...',
      );
    }
    return key;
  }
}
