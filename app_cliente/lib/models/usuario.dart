/// Representa o usuário cliente autenticado no app.
class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? telefone;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      telefone: json['telefone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'telefone': telefone,
      };
}
