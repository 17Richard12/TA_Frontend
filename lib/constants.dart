class AppConstants {
  // ── Server ───────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://lungs-backend-z3hx2fqata-et.a.run.app',
  );
  //static const String baseUrl = 'http://192.168.118.18:8000';

  // ── API Keys ─────────────────────────────────────────
  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: 'e7dd18be34d0430c9fd526bee9c03213',
  );
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyAlba-EULjIvPWhikZuRJbwwRDKWMHI-SM',
  );
  // Google Places Nearby Search is proxied via backend (/api/hospitals/nearby)
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
