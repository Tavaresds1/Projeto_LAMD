import '../models/usuario.dart';
import 'api_client.dart';

/// Serviço de autenticação — encapsula as chamadas REST de
/// cadastro e login de usuários.
class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  /// POST /usuarios/login
  Future<Usuario> login({required String email, required String senha}) async {
    final resp = await _api.post('/usuarios/login', {
      'email': email,
      'senha': senha,
    });
    return Usuario.fromJson(resp['dados'] as Map<String, dynamic>);
  }

  /// POST /usuarios/registrar
  Future<Usuario> registrar({
    required String nome,
    required String email,
    required String senha,
    String? telefone,
  }) async {
    final resp = await _api.post('/usuarios/registrar', {
      'nome': nome,
      'email': email,
      'senha': senha,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
    });
    return Usuario.fromJson(resp['dados'] as Map<String, dynamic>);
  }
}
