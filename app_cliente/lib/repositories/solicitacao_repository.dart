import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';

/// Repositório de solicitações.
///
/// Atua como ponto único de acesso aos dados de solicitações para os
/// providers, abstraindo a origem (atualmente a API REST). Caso futuramente
/// haja cache local ou outra fonte, apenas esta camada muda.
class SolicitacaoRepository {
  final SolicitacaoService _service;

  SolicitacaoRepository(this._service);

  Future<List<Solicitacao>> listar(int usuarioId, {String? status}) {
    return _service.listarPorUsuario(usuarioId, status: status);
  }

  Future<Solicitacao> detalhar(int id) => _service.buscarPorId(id);

  Future<Solicitacao> criar({
    required int usuarioId,
    required String tipoServico,
    required String descricao,
    required String endereco,
  }) {
    return _service.criar(
      usuarioId: usuarioId,
      tipoServico: tipoServico,
      descricao: descricao,
      endereco: endereco,
    );
  }
}
