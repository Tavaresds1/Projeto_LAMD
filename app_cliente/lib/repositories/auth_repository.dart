import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Repositório de autenticação.
///
/// Coordena o [AuthService] (REST) com a persistência local da sessão
/// (via `shared_preferences`), permitindo que o usuário continue logado
/// entre execuções do app.
class AuthRepository {
  final AuthService _service;
  static const _chaveSessao = 'usuario_logado';

  AuthRepository(this._service);

  Future<Usuario> login(String email, String senha) async {
    final usuario = await _service.login(email: email, senha: senha);
    await _salvarSessao(usuario);
    return usuario;
  }

  Future<Usuario> registrar({
    required String nome,
    required String email,
    required String senha,
    String? telefone,
  }) async {
    final usuario = await _service.registrar(
      nome: nome,
      email: email,
      senha: senha,
      telefone: telefone,
    );
    await _salvarSessao(usuario);
    return usuario;
  }

  /// Recupera a sessão salva localmente (ou null se não houver).
  Future<Usuario?> sessaoAtual() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveSessao);
    if (json == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveSessao);
  }

  Future<void> _salvarSessao(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveSessao, jsonEncode(usuario.toJson()));
  }
}
