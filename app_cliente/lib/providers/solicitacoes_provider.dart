import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import '../models/solicitacao.dart';
import '../repositories/solicitacao_repository.dart';
import '../services/api_client.dart';

/// Provider das solicitações do usuário logado.
///
/// Responsável por:
/// - carregar a lista via repositório;
/// - **atualização assíncrona de estado (Sprint 3)**: um [Timer] periódico
///   refaz o GET em segundo plano, de modo que mudanças feitas pelo
///   prestador (ex.: status PENDENTE → ACEITO) apareçam no app do cliente
///   sem nenhuma ação manual;
/// - criar novas solicitações.
class SolicitacoesProvider extends ChangeNotifier {
  final SolicitacaoRepository _repo;

  SolicitacoesProvider(this._repo);

  List<Solicitacao> _itens = [];
  bool _carregando = false;
  bool _atualizando = false;
  String? _erro;
  String? _filtroStatus;
  int? _usuarioId;
  Timer? _timer;

  List<Solicitacao> get itens => List.unmodifiable(_itens);
  bool get carregando => _carregando;
  bool get atualizando => _atualizando;
  String? get erro => _erro;
  String? get filtroStatus => _filtroStatus;
  bool get vazio => !_carregando && _erro == null && _itens.isEmpty;

  /// Define o usuário cujas solicitações serão acompanhadas.
  void configurarUsuario(int usuarioId) {
    _usuarioId = usuarioId;
  }

  void definirFiltro(String? status) {
    if (_filtroStatus == status) return;
    _filtroStatus = status;
    notifyListeners();
    carregar();
  }

  /// Carga inicial (com indicador de loading em tela cheia).
  Future<void> carregar() async {
    if (_usuarioId == null) return;
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _itens = await _repo.listar(_usuarioId!, status: _filtroStatus);
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } catch (_) {
      _erro = 'Erro ao carregar solicitações.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Atualização silenciosa em segundo plano (usada pelo polling e pelo
  /// pull-to-refresh). Não exibe loading de tela cheia e preserva a lista
  /// atual em caso de falha momentânea de rede.
  Future<void> atualizarSilencioso() async {
    if (_usuarioId == null || _atualizando) return;
    _atualizando = true;
    notifyListeners();
    try {
      final novos = await _repo.listar(_usuarioId!, status: _filtroStatus);
      if (_mudou(novos)) {
        _itens = novos;
      }
      _erro = null;
    } catch (_) {
      // Silencioso: mantém os dados já exibidos.
    } finally {
      _atualizando = false;
      notifyListeners();
    }
  }

  /// Inicia o polling periódico de atualização de estado.
  void iniciarPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      ApiConfig.intervaloPolling,
      (_) => atualizarSilencioso(),
    );
  }

  void pararPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<Solicitacao> criar({
    required String tipoServico,
    required String descricao,
    required String endereco,
  }) async {
    if (_usuarioId == null) {
      throw ApiException('Usuário não identificado.');
    }
    final nova = await _repo.criar(
      usuarioId: _usuarioId!,
      tipoServico: tipoServico,
      descricao: descricao,
      endereco: endereco,
    );
    await carregar();
    return nova;
  }

  /// Compara a lista nova com a atual (por id + status + atualização)
  /// para evitar reconstruções desnecessárias da UI.
  bool _mudou(List<Solicitacao> novos) {
    if (novos.length != _itens.length) return true;
    for (var i = 0; i < novos.length; i++) {
      if (novos[i].id != _itens[i].id ||
          novos[i].status != _itens[i].status ||
          novos[i].atualizadoEm != _itens[i].atualizadoEm) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    pararPolling();
    super.dispose();
  }
}
