import 'package:flutter/foundation.dart';

/// Centralized API Configuration for PawStay application.
/// Automatically resolves the correct backend host depending on target platform:
/// - Android emulator: http://10.0.2.2:8000 / :8001
/// - Web / Windows Desktop / macOS / Linux: http://127.0.0.1:8000 / :8001
class ApiConfig {
  static const int port = 8000;
  static const int messagePort = 8001;

  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:$port';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://127.0.0.1:$port';
  }

  /// URL for the PawStay Message Microservice (port 8001).
  static String get messageBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return 'http://$host:$messagePort';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$messagePort';
    }
    return 'http://127.0.0.1:$messagePort';
  }
}
