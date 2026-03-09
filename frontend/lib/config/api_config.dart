import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 判斷是否為正式環境 (Release Mode)，若是則使用相對路徑，讓 IIS 的 Reverse Proxy 處理
    if (kReleaseMode) {
      return ''; // 回傳空字串代表目前的網域本身，這會組合成 /api/assets
    }

    // 以下為開發階段 (Debug Mode) 的設定
    if (kIsWeb) {
      return 'http://localhost:8081';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    } else {
      return 'http://localhost:8081';
    }
  }

  static String get assetsUrl => '$baseUrl/api/assets';

  static String resolveImageUrl(String url) {
    // 若為正式環境，圖片網址會自然是相對路徑，開發階段才需要取代
    if (!kReleaseMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }
}
