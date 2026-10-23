class AppConstants {
  AppConstants._();

  static const String appName = 'SANKET AI';
  static const String appVersion = '1.0.0';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxFileUploadMb = 50;
  static const List<String> allowedMimeTypes = [
    'image/jpeg', 'image/png', 'image/webp',
    'video/mp4', 'video/quicktime',
    'audio/mpeg', 'audio/wav',
    'application/pdf',
  ];

  // Offline
  static const int maxDraftCount = 20;
  static const Duration syncRetryDelay = Duration(minutes: 2);
  static const int maxSyncRetries = 5;

  // Pagination
  static const int defaultPageSize = 20;

  // Storage
  static const String evidenceBucket = 'evidence';
  static const String profileBucket = 'profiles';
}
