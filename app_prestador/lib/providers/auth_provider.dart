import 'package:flutter/foundation.dart';

import '../models/prestador.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

enum AuthStatus { inicial, carregando, autenticado, naoAutenticado }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo);

  AuthStatus _status = AuthStatus.inicial;
  Prestador? _prestador;
  String? _erro;
  bool _processando = false;

  AuthStatus get status => _status;
  Prestador? get prestador => _prestador;
  String? get erro => _erro;
  bool get processando => _processando;
  bool get autenticado =>
      _status == AuthStatus.autenticado && _prestador != null;

  Future<void> carregarSessao() async {
    _prestador = await _repo.sessaoAtual();
    _status = _prestador != null
        ? AuthStatus.autenticado
        : AuthStatus.naoAutenticado;
    notifyListeners();
  }

  Future<bool> login(String email, String senha) async {
    _processando = true;
    _erro = null;
    notifyListeners();
    try {
      _prestador = await _repo.login(email, senha);
      _status = AuthStatus.autenticado;
      return true;
    } on ApiException catch (e) {
      _erro = e.mensagem;
      return false;
    } catch (_) {
      _erro = 'Erro inesperado. Tente novamente.';
      return false;
    } finally {
      _processando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _prestador = null;
    _status = AuthStatus.naoAutenticado;
    notifyListeners();
  }
}
