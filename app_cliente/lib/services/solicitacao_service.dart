import '../models/solicitacao.dart';
import 'api_client.dart';

/// Serviço de solicitações — encapsula os endpoints REST do recurso
/// `/solicitacoes` consumidos pelo app do cliente.
class SolicitacaoService {
  final ApiClient _api;

  SolicitacaoService(this._api);

  /// GET /solicitacoes?usuario_id=...&status=...
  Future<List<Solicitacao>> listarPorUsuario(
    int usuarioId, {
    String? status,
  }) async {
    final resp = await _api.get('/solicitacoes', query: {
      'usuario_id': usuarioId,
      'status': status,
    });
    final lista = (resp['dados'] as List)
        .map((e) => Solicitacao.fromJson(e as Map<String, dynamic>))
        .toList();
    return lista;
  }

  /// GET /solicitacoes/:id
  Future<Solicitacao> buscarPorId(int id) async {
    final resp = await _api.get('/solicitacoes/$id');
    return Solicitacao.fromJson(resp['dados'] as Map<String, dynamic>);
  }

  /// POST /solicitacoes
  Future<Solicitacao> criar({
    required int usuarioId,
    required String tipoServico,
    required String descricao,
    required String endereco,
  }) async {
    final resp = await _api.post('/solicitacoes', {
      'usuario_id': usuarioId,
      'tipo_servico': tipoServico,
      'descricao': descricao,
      'endereco': endereco,
    });
    return Solicitacao.fromJson(resp['dados'] as Map<String, dynamic>);
  }
}
