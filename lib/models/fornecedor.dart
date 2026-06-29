// fornecedor.dart
// Arquivo de definição da classe Fornecedor que será responsável por armazenar os dados de um fornecedor.
//======================================================================================================//

// models/fornecedor.dart
class Fornecedor {
  int? id;
  String nome;
  String? endereco;
  String? telefone;
  String? contato;

  Fornecedor({
    this.id,
    required this.nome,
    this.endereco,
    this.telefone,
    this.contato,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
      'contato': contato,
    };
  }

  factory Fornecedor.fromMap(Map<String, dynamic> map) {
    return Fornecedor(
      id: map['id'],
      nome: map['nome'],
      endereco: map['endereco'],
      telefone: map['telefone'],
      contato: map['contato'],
    );
  }

  @override
  String toString() => nome;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Fornecedor) return false;
    return id == other.id && nome == other.nome;
  }

  @override
  int get hashCode => id.hashCode ^ nome.hashCode;
}
