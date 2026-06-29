import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import '../models/solicitacao.dart';
import '../repositories/solicitacao_repository.dart';
import '../services/api_client.dart';

/// Provider das solicitações do prestador.
///
/// Mantém duas listas independentes:
/// - [pendentes]: todas as solicitações com status PENDENTE (polling para
///   simular notificação assíncrona via MOM — Sprint 4).
/// - [minhasSolicitacoes]: solicitações atribuídas a este prestador.
class SolicitacoesProvider extends ChangeNotifier {
  final SolicitacaoRepository _repo;

  SolicitacoesProvider(this._repo);

  List<Solicitacao> _pendentes = [];
  List<Solicitacao> _minhasSolicitacoes = [];
  bool _carregando = false;
  bool _atualizando = false;
  String? _erro;
  int? _prestadorId;
  Timer? _timer;

  // Badge: conta novas pendentes detectadas pelo polling
  int _novasPendentes = 0;

  List<Solicitacao> get pendentes => List.unmodifiable(_pendentes);
  List<Solicitacao> get minhasSolicitacoes =>
      List.unmodifiable(_minhasSolicitacoes);
  bool get carregando => _carregando;
  bool get atualizando => _atualizando;
  String? get erro => _erro;
  int get novasPendentes => _novasPendentes;
  bool get vazio => !_carregando && _erro == null && _pendentes.isEmpty;

  void configurarPrestador(int prestadorId) {
    _prestadorId = prestadorId;
  }

  void limparNovasPendentes() {
    if (_novasPendentes == 0) return;
    _novasPendentes = 0;
    notifyListeners();
  }

  /// Carga inicial completa (mostra loading).
  Future<void> carregar() async {
    if (_prestadorId == null) return;
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.listarPendentes(_prestadorId!),
        _repo.listarPorPrestador(_prestadorId!),
      ]);
      _pendentes = results[0];
      _minhasSolicitacoes = results[1];
    } on ApiException catch (e) {
      _erro = e.mensagem;
    } catch (_) {
      _erro = 'Erro ao carregar solicitações.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Atualização silenciosa em segundo plano (polling).
  /// Detecta novas PENDENTE para acionar o badge de notificação.
  Future<void> atualizarSilencioso() async {
    if (_prestadorId == null || _atualizando) return;
    _atualizando = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.listarPendentes(_prestadorId!),
        _repo.listarPorPrestador(_prestadorId!),
      ]);
      final novasPend = results[0];
      final minhas = results[1];

      // Detecta chegada de novas pendentes para o badge
      final idsAntigos = _pendentes.map((s) => s.id).toSet();
      final novasChegadas =
          novasPend.where((s) => !idsAntigos.contains(s.id)).length;
      if (novasChegadas > 0) _novasPendentes += novasChegadas;

      if (_mudou(novasPend, _pendentes) || _mudou(minhas, _minhasSolicitacoes)) {
        _pendentes = novasPend;
        _minhasSolicitacoes = minhas;
      }
      _erro = null;
    } catch (_) {
      // Mantém os dados já exibidos silenciosamente
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

  Future<void> aceitar(int solicitacaoId) async {
    await _repo.atualizarStatus(
      solicitacaoId,
      'ACEITO',
      prestadorId: _prestadorId,
    );
    await carregar();
  }

  Future<void> recusar(int solicitacaoId) async {
    if (_prestadorId == null) return;
    await _repo.recusar(solicitacaoId, _prestadorId!);
    await carregar();
  }

  Future<void> iniciarServico(int solicitacaoId) async {
    await _repo.atualizarStatus(solicitacaoId, 'EM_ANDAMENTO');
    await carregar();
  }

  Future<void> concluir(
    int solicitacaoId, {
    required double maoDeObra,
    required double pecas,
  }) async {
    await _repo.atualizarStatus(
      solicitacaoId,
      'CONCLUIDO',
      valorMaoDeObra: maoDeObra,
      valorPecas: pecas,
    );
    await carregar();
  }

  bool _mudou(List<Solicitacao> novos, List<Solicitacao> atuais) {
    if (novos.length != atuais.length) return true;
    for (var i = 0; i < novos.length; i++) {
      if (novos[i].id != atuais[i].id ||
          novos[i].status != atuais[i].status ||
          novos[i].atualizadoEm != atuais[i].atualizadoEm) {
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
