/// Representa um prestador de serviços hidráulicos.
class Prestador {
  final int id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? especialidade;
  final bool disponivel;

  const Prestador({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.especialidade,
    this.disponivel = true,
  });

  factory Prestador.fromJson(Map<String, dynamic> json) {
    return Prestador(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      especialidade: json['especialidade'] as String?,
      disponivel: json['disponivel'] as bool? ?? true,
    );
  }
}
