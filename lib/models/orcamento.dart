// orcamento.dart
// Arquivo de definição da classe orcamento que será responsável por armazenar os dados de um orcamento.
// Layout alinhado com o layout do app
//======================================================================================================//

// models/orcamento.dart
class Orcamento {
  int? id;
  String nome;
  String? descricao;
  double valorTotal;
  String dataInicio;
  String? dataFim;

  Orcamento({
    this.id,
    required this.nome,
    this.descricao,
    required this.valorTotal,
    required this.dataInicio,
    this.dataFim,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'valor_total': valorTotal,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
    };
  }

  factory Orcamento.fromMap(Map<String, dynamic> map) {
    return Orcamento(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      valorTotal: map['valor_total']?.toDouble() ?? 0.0,
      dataInicio: map['data_inicio'],
      dataFim: map['data_fim'],
    );
  }

  @override
  String toString() => nome;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Orcamento) return false;
    return id == other.id && nome == other.nome;
  }

  @override
  int get hashCode => id.hashCode ^ nome.hashCode;
}
