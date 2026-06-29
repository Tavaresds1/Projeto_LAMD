class Solicitacao {
  final int id;
  final String tipoServico;
  final String descricao;
  final String endereco;
  final String status;
  final int? prestadorId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  // Custos registrados pelo prestador ao concluir
  final double? valorMaoDeObra;
  final double? valorPecas;

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
    this.prestadorId,
    this.criadoEm,
    this.atualizadoEm,
    this.valorMaoDeObra,
    this.valorPecas,
    this.usuarioNome,
    this.usuarioTelefone,
    this.prestadorNome,
    this.prestadorTelefone,
    this.prestadorEspecialidade,
  });

  bool get temValores => valorMaoDeObra != null || valorPecas != null;
  double get valorTotal => (valorMaoDeObra ?? 0) + (valorPecas ?? 0);

  static DateTime? _parseData(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString())?.toLocal();
  }

  static double? _parseDouble(dynamic valor) {
    if (valor == null) return null;
    return double.tryParse(valor.toString());
  }

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    return Solicitacao(
      id: json['id'] as int,
      tipoServico: json['tipo_servico'] as String,
      descricao: json['descricao'] as String,
      endereco: json['endereco'] as String,
      status: json['status'] as String,
      prestadorId: json['prestador_id'] as int?,
      criadoEm: _parseData(json['criado_em']),
      atualizadoEm: _parseData(json['atualizado_em']),
      valorMaoDeObra: _parseDouble(json['valor_mao_de_obra']),
      valorPecas: _parseDouble(json['valor_pecas']),
      usuarioNome: json['usuario_nome'] as String?,
      usuarioTelefone: json['usuario_telefone'] as String?,
      prestadorNome: json['prestador_nome'] as String?,
      prestadorTelefone: json['prestador_telefone'] as String?,
      prestadorEspecialidade: json['prestador_especialidade'] as String?,
    );
  }
}
