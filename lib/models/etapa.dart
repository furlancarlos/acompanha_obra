// models/etapa.dart
// Arquivo de definição da classe Etapa que será responsável por armazenar os dados de uma etapa.
//======================================================================================================//

class Etapa {
  int? id;
  String nome;
  String? descricao;
  int orcamentoId;
  double progresso;
  String status; // 'Pendente', 'Em Andamento', 'Concluído'
  String? dataInicio;
  String? dataFim;
  double? valorOrcado;

  Etapa({
    this.id,
    required this.nome,
    this.descricao,
    required this.orcamentoId,
    this.progresso = 0.0,
    this.status = 'Pendente',
    this.dataInicio,
    this.dataFim,
    this.valorOrcado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'orcamento_id': orcamentoId,
      'progresso': progresso,
      'status': status,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'valor_orcado': valorOrcado,
    };
  }

  factory Etapa.fromMap(Map<String, dynamic> map) {
    return Etapa(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      orcamentoId: map['orcamento_id'],
      progresso: (map['progresso'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pendente',
      dataInicio: map['data_inicio'],
      dataFim: map['data_fim'],
      valorOrcado: (map['valor_orcado'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => nome;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Etapa) return false;
    return id == other.id && nome == other.nome;
  }

  @override
  int get hashCode => id.hashCode ^ nome.hashCode;
}
