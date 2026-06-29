// despesa.dart
// Arquivo de definição da classe despesa que será responsável por armazenar os dados de um despesa.
//======================================================================================================//

class Despesa {
  int? id;
  String descricao;
  String data;
  int? fornecedorId;
  int? produtoId;
  int? unidadeId;
  int? orcamentoId;
  int? etapaId;
  double quantidade;
  double valorUnitario;
  double valorTotal;

  Despesa({
    this.id,
    required this.descricao,
    required this.data,
    this.fornecedorId,
    this.produtoId,
    this.unidadeId,
    this.orcamentoId,
    this.etapaId,  
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'data': data,
      'fornecedor_id': fornecedorId,
      'produto_id': produtoId,
      'unidade_id': unidadeId,
      'orcamento_id': orcamentoId,
      'etapa_id': etapaId,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
    };
  }

  factory Despesa.fromMap(Map<String, dynamic> map) {
    return Despesa(
      id: map['id'],
      descricao: map['descricao'],
      data: map['data'],
      fornecedorId: map['fornecedor_id'],
      produtoId: map['produto_id'],
      unidadeId: map['unidade_id'],
      orcamentoId: map['orcamento_id'],
      etapaId: map['etapa_id'], 
      quantidade: (map['quantidade'] as num).toDouble(),
      valorUnitario: (map['valor_unitario'] as num).toDouble(),
      valorTotal: (map['valor_total'] as num).toDouble(),
    );
  }
}
