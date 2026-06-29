import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  ApiConfig._();

  static const int _porta = 3000;

  static const String _override =
      String.fromEnvironment('API_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:$_porta';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_porta';
    }
    return 'http://localhost:$_porta';
  }

  static const Duration intervaloPolling = Duration(seconds: 5);
}
