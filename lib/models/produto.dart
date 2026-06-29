// produto.dart
// Arquivo de definição da classe produto que será responsável por armazenar os dados de um produto.
//======================================================================================================//

// models/produto.dart
import 'unidade.dart';

class Produto {
  int? id;
  String nome;
  String? descricao;
  int? unidadeId;
  Unidade? unidade;

  Produto({
    this.id,
    required this.nome,
    this.descricao,
    this.unidadeId,
    this.unidade,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'unidade_id': unidadeId,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      unidadeId: map['unidade_id'],
    );
  }

  @override
  String toString() => nome;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Produto) return false;
    return id == other.id && nome == other.nome;
  }

  @override
  int get hashCode => id.hashCode ^ nome.hashCode;
}
