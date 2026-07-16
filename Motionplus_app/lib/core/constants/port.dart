import 'package:flutter/foundation.dart';

class PortConstants {
  // Returns the base backend URL
  static String get backendUrl {
    if (kReleaseMode) {
      // Production URL when built (e.g., flutter build apk)
      return 'https://motion-plus.onrender.com';
    } else {
      // Development URL when running locally (e.g., flutter run)
      // Note: If using physical device, use the PC's Wi-Fi IPv4 address
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://192.168.29.105:5000';
      } else {
        return 'http://localhost:5000';
      }
    }
  }

  // Returns the API URL
  static String get apiUrl => '\$backendUrl/api';
}
