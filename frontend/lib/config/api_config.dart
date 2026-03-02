import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  static String get assetsUrl => '$baseUrl/api/assets';

  static String resolveImageUrl(String url) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }
}
