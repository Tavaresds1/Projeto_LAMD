import '../models/prestador.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  /// POST /prestadores/login
  Future<Prestador> login({
    required String email,
    required String senha,
  }) async {
    final resp = await _api.post('/prestadores/login', {
      'email': email,
      'senha': senha,
    });
    return Prestador.fromJson(resp['dados'] as Map<String, dynamic>);
  }
}
