import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

enum AuthStatus { inicial, carregando, autenticado, naoAutenticado }

/// Provider responsável pelo estado de autenticação do app.
///
/// Expõe o usuário logado e os métodos de login/cadastro/logout para a
/// camada de UI, notificando os listeners a cada mudança de estado.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo);

  AuthStatus _status = AuthStatus.inicial;
  Usuario? _usuario;
  String? _erro;
  bool _processando = false;

  AuthStatus get status => _status;
  Usuario? get usuario => _usuario;
  String? get erro => _erro;
  bool get processando => _processando;
  bool get autenticado => _status == AuthStatus.autenticado && _usuario != null;

  /// Carrega a sessão persistida ao abrir o app (usado pela splash).
  Future<void> carregarSessao() async {
    _usuario = await _repo.sessaoAtual();
    _status =
        _usuario != null ? AuthStatus.autenticado : AuthStatus.naoAutenticado;
    notifyListeners();
  }

  Future<bool> login(String email, String senha) async {
    return _executar(() => _repo.login(email, senha));
  }

  Future<bool> registrar({
    required String nome,
    required String email,
    required String senha,
    String? telefone,
  }) async {
    return _executar(() => _repo.registrar(
          nome: nome,
          email: email,
          senha: senha,
          telefone: telefone,
        ));
  }

  Future<void> logout() async {
    await _repo.logout();
    _usuario = null;
    _status = AuthStatus.naoAutenticado;
    notifyListeners();
  }

  Future<bool> _executar(Future<Usuario> Function() acao) async {
    _processando = true;
    _erro = null;
    notifyListeners();
    try {
      _usuario = await acao();
      _status = AuthStatus.autenticado;
      return true;
    } on ApiException catch (e) {
      _erro = e.mensagem;
      return false;
    } catch (e) {
      _erro = 'Erro inesperado. Tente novamente.';
      return false;
    } finally {
      _processando = false;
      notifyListeners();
    }
  }
}
