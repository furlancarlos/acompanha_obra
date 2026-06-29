// unidade.dart
// Arquivo de definição da classe unidade que será responsável por armazenar os dados de um unidade.
//======================================================================================================//

class Unidade {
  final int? id;
  final String descricao;
  final String? sigla;

  Unidade({this.id, required this.descricao, this.sigla});

  Map<String, dynamic> toMap() {
    return {'id': id, 'descricao': descricao, 'sigla': sigla};
  }

  factory Unidade.fromMap(Map<String, dynamic> map) {
    return Unidade(
      id: map['id'],
      descricao: map['descricao'],
      sigla: map['sigla'],
    );
  }

  @override
  String toString() => descricao;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Unidade) return false;
    return id == other.id && descricao == other.descricao;
  }

  @override
  int get hashCode => id.hashCode ^ descricao.hashCode;

}
