/// Representa uma solicitação de serviço hidráulico.
///
/// Mapeia a resposta dos endpoints:
/// - GET /solicitacoes        (lista — campos resumidos)
/// - GET /solicitacoes/:id    (detalhe — campos adicionais do prestador/usuário)
class Solicitacao {
  final int id;
  final String tipoServico;
  final String descricao;
  final String endereco;
  final String status;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Dados relacionados (preenchidos pelos JOINs do backend)
  final String? usuarioNome;
  final String? usuarioTelefone;
  final String? prestadorNome;
  final String? prestadorTelefone;
  final String? prestadorEspecialidade;

  const Solicitacao({
    required this.id,
    required this.tipoServico,
    required this.descricao,
    required this.endereco,
    required this.status,
    this.criadoEm,
    this.atualizadoEm,
    this.usuarioNome,
    this.usuarioTelefone,
    this.prestadorNome,
    this.prestadorTelefone,
    this.prestadorEspecialidade,
  });

  bool get temPrestador => prestadorNome != null && prestadorNome!.isNotEmpty;

  static DateTime? _parseData(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString())?.toLocal();
  }

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    return Solicitacao(
      id: json['id'] as int,
      tipoServico: json['tipo_servico'] as String,
      descricao: json['descricao'] as String,
      endereco: json['endereco'] as String,
      status: json['status'] as String,
      criadoEm: _parseData(json['criado_em']),
      atualizadoEm: _parseData(json['atualizado_em']),
      usuarioNome: json['usuario_nome'] as String?,
      usuarioTelefone: json['usuario_telefone'] as String?,
      prestadorNome: json['prestador_nome'] as String?,
      prestadorTelefone: json['prestador_telefone'] as String?,
      prestadorEspecialidade: json['prestador_especialidade'] as String?,
    );
  }
}
