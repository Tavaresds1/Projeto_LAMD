import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Centraliza a configuração de acesso à API REST do backend.
///
/// O endereço muda conforme o ambiente onde o app roda:
/// - Emulador Android: `10.0.2.2` é o alias do `localhost` da máquina host.
/// - Emulador iOS / Desktop / Web: `localhost` funciona normalmente.
/// - Dispositivo físico: troque por `http://<IP_DA_SUA_MAQUINA>:3000`.
class ApiConfig {
  ApiConfig._();

  static const int _porta = 3000;

  /// Permite sobrescrever a URL em tempo de build:
  /// `flutter run --dart-define=API_URL=http://192.168.0.10:3000`
  static const String _override =
      String.fromEnvironment('API_URL', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:$_porta';

    // No emulador Android, 10.0.2.2 é o alias do localhost da máquina host.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_porta';
    }
    return 'http://localhost:$_porta';
  }

  /// Intervalo de polling usado para refletir mudanças de estado
  /// vindas do servidor sem ação manual do usuário (Sprint 3).
  static const Duration intervaloPolling = Duration(seconds: 5);
}
