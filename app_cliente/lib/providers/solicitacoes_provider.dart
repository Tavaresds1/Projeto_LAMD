import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import '../models/solicitacao.dart';
import '../repositories/solicitacao_repository.dart';
import '../services/api_client.dart';

/// Provider das solicitações do usuário logado.
///
/// A lista completa é sempre buscada sem filtro de status.
/// A filtragem é feita localmente via [itensFiltrados], o que permite
/// trocar de aba instantaneamente sem nova requisição e garante que o
/// polling sempre tenha a visão completa do estado atual.
class SolicitacoesProvider extends ChangeNotifier {
  final SolicitacaoRepository _repo;

  SolicitacoesProvider(this._repo);

  List<Solicitacao> _itens = [];
  bool _carregando = false;
  bool _atualizando = false;
  String? _erro;

  // null  = "Ativas"  (PENDENTE + ACEITO + EM_ANDAMENTO)
  // 'HISTORICO' = CONCLUIDO + RECUSADO
  // qualquer outro valor = filtro exato por status
  String? _filtroLocal;

  int? _usuarioId;
  Timer? _timer;

  static const _statusAtivos = {'PENDENTE', 'ACEITO', 'EM_ANDAMENTO'};
  static const _statusHistorico = {'CONCLUIDO', 'RECUSADO'};

  List<Solicitacao> get itens => List.unmodifiable(_itens);

  List<Solicitacao> get itensFiltrados {
    if (_filtroLocal == null) {
      return _itens
          .where((s) => _statusAtivos.contains(s.status))
          .toList();
    }
    if (_filtroLocal == 'HISTORICO') {
      return _itens
          .where((s) => _statusHistorico.contains(s.status))
          .toList();
    }
    return _itens.where((s) => s.status == _filtroLocal).toList();
  }

  bool get carregando => _carregando;
  bool get atualizando => _atualizando;
  String? get erro => _erro;
  String? get filtroLocal => _filtroLocal;
  bool get vazio => !_carregando && _erro == null && itensFiltrados.isEmpty;

  int get totalAtivas =>
      _itens.where((s) => _statusAtivos.contains(s.status)).length;
  int get totalHistorico =>
      _itens.where((s) => _statusHistorico.contains(s.status)).length;

  void configurarUsuario(int usuarioId) {
    _usuarioId = usuarioId;
  }

  void definirFiltro(String? filtro) {
    if (_filtroLocal == filtro) return;
    _filtroLocal = filtro;
    notifyListeners();
  }

  Future<void> carregar() async {
    if (_usuarioId == null) return;
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _itens = await _repo.listar(_usuarioId!);
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } catch (_) {
      _erro = 'Erro ao carregar solicitações.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> atualizarSilencioso() async {
    if (_usuarioId == null || _atualizando) return;
    _atualizando = true;
    notifyListeners();
    try {
      final novos = await _repo.listar(_usuarioId!);
      if (_mudou(novos)) _itens = novos;
      _erro = null;
    } catch (_) {
      // Silencioso: mantém os dados já exibidos.
    } finally {
      _atualizando = false;
      notifyListeners();
    }
  }

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
