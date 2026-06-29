import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prestador.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;
  static const _chaveSessao = 'prestador_logado';

  AuthRepository(this._service);

  Future<Prestador> login(String email, String senha) async {
    final prestador = await _service.login(email: email, senha: senha);
    await _salvarSessao(prestador);
    return prestador;
  }

  Future<Prestador?> sessaoAtual() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveSessao);
    if (json == null) return null;
    try {
      return Prestador.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveSessao);
  }

  Future<void> _salvarSessao(Prestador prestador) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveSessao, jsonEncode(prestador.toJson()));
  }
}
