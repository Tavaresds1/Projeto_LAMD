import '../models/solicitacao.dart';
import '../services/solicitacao_service.dart';

class SolicitacaoRepository {
  final SolicitacaoService _service;

  SolicitacaoRepository(this._service);

  Future<List<Solicitacao>> listarPendentes(int prestadorId) =>
      _service.listarPendentes(prestadorId);

  Future<List<Solicitacao>> listarPorPrestador(int prestadorId) =>
      _service.listarPorPrestador(prestadorId);

  Future<Solicitacao> detalhar(int id) => _service.buscarPorId(id);

  Future<Solicitacao> atualizarStatus(
    int id,
    String status, {
    int? prestadorId,
    double? valorMaoDeObra,
    double? valorPecas,
  }) =>
      _service.atualizarStatus(
        id,
        status,
        prestadorId: prestadorId,
        valorMaoDeObra: valorMaoDeObra,
        valorPecas: valorPecas,
      );

  Future<void> recusar(int solicitacaoId, int prestadorId) =>
      _service.recusar(solicitacaoId, prestadorId);
}
