import '../models/solicitacao.dart';
import 'api_client.dart';

class SolicitacaoService {
  final ApiClient _api;

  SolicitacaoService(this._api);

  /// GET /solicitacoes?status=PENDENTE&disponivel_para=<prestadorId>
  /// Exclui automaticamente as solicitações que este prestador já recusou.
  Future<List<Solicitacao>> listarPendentes(int prestadorId) async {
    final resp = await _api.get('/solicitacoes', query: {
      'status': 'PENDENTE',
      'disponivel_para': prestadorId,
    });
    return (resp['dados'] as List)
        .map((e) => Solicitacao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /solicitacoes?prestador_id=... — solicitações atribuídas ao prestador
  Future<List<Solicitacao>> listarPorPrestador(int prestadorId) async {
    final resp = await _api
        .get('/solicitacoes', query: {'prestador_id': prestadorId});
    return (resp['dados'] as List)
        .map((e) => Solicitacao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /solicitacoes/:id
  Future<Solicitacao> buscarPorId(int id) async {
    final resp = await _api.get('/solicitacoes/$id');
    return Solicitacao.fromJson(resp['dados'] as Map<String, dynamic>);
  }

  /// PATCH /solicitacoes/:id/status — muda status (aceitar, iniciar, concluir)
  Future<Solicitacao> atualizarStatus(
    int id,
    String status, {
    int? prestadorId,
    double? valorMaoDeObra,
    double? valorPecas,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (prestadorId != null) body['prestador_id'] = prestadorId;
    if (valorMaoDeObra != null) body['valor_mao_de_obra'] = valorMaoDeObra;
    if (valorPecas != null) body['valor_pecas'] = valorPecas;
    final resp = await _api.patch('/solicitacoes/$id/status', body);
    return Solicitacao.fromJson(resp['dados'] as Map<String, dynamic>);
  }

  /// POST /solicitacoes/:id/recusar — recusa individual; solicitação permanece
  /// PENDENTE até que todos os prestadores disponíveis recusem.
  Future<void> recusar(int solicitacaoId, int prestadorId) async {
    await _api.post('/solicitacoes/$solicitacaoId/recusar', {
      'prestador_id': prestadorId,
    });
  }
}
