// dao/etapa_dao.dart
// Arquivo de definição da classe EtapaDAO que será responsável por fazer
// operações com o banco de dados.
//============================================================================//

import '../database/db_helper.dart';
import '../models/etapa.dart';

class EtapaDAO {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insert(Etapa etapa) async {
    final db = await _dbHelper.db;
    return await db.insert('etapa', etapa.toMap());
  }

  Future<int> update(Etapa etapa) async {
    final db = await _dbHelper.db;
    return await db.update(
      'etapa',
      etapa.toMap(),
      where: 'id = ?',
      whereArgs: [etapa.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.db;
    return await db.delete('etapa', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Etapa>> getAll() async {
    final db = await _dbHelper.db;
    final result = await db.query('etapa', orderBy: 'nome');
    return result.map((map) => Etapa.fromMap(map)).toList();
  }

  Future<List<Etapa>> getByOrcamento(int orcamentoId) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'etapa',
      where: 'orcamento_id = ?',
      whereArgs: [orcamentoId],
      orderBy: 'id',
    );
    return result.map((map) => Etapa.fromMap(map)).toList();
  }

  // dao/etapa_dao.dart - getById (versão mais segura)

  Future<Etapa?> getById(int id) async {
    final db = await _dbHelper.db;
    final result = await db.query('etapa', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Etapa.fromMap(result.first);
    }
    return null;
  }

  Future<double> getProgressoTotal(int orcamentoId) async {
    final db = await _dbHelper.db;
    final result = await db.rawQuery(
      '''
      SELECT AVG(progresso) as media FROM etapa WHERE orcamento_id = ?
    ''',
      [orcamentoId],
    );
    if (result.isNotEmpty && result.first['media'] != null) {
      return (result.first['media'] as num).toDouble();
    }
    return 0.0;
  }

  Future<bool> existsByNome(String nome, int orcamentoId) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'etapa',
      where: 'nome = ? AND orcamento_id = ?',
      whereArgs: [nome.trim(), orcamentoId],
    );
    return result.isNotEmpty;
  }

  Future<double> getTotalValorOrcado(int orcamentoId) async {
    final db = await _dbHelper.db;
    final result = await db.rawQuery(
      '''
    SELECT SUM(valor_orcado) as total FROM etapa WHERE orcamento_id = ?
  ''',
      [orcamentoId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Calcula o progresso de uma etapa com base nas despesas
  /// usando a fórmula: (valor gasto / valor orçado) * 100
  /// Se não houver valor orçado, usa a quantidade de despesas
  Future<double> calcularProgressoEtapa(int etapaId) async {
    final db = await DBHelper().db;

    // Busca o valor orçado da etapa
    final etapaResult = await db.query(
      'etapa',
      columns: ['valor_orcado'],
      where: 'id = ?',
      whereArgs: [etapaId],
    );

    if (etapaResult.isEmpty) return 0.0;

    final valorOrcado = etapaResult.first['valor_orcado'] as double? ?? 0.0;

    // Busca o total gasto na etapa
    final gastoResult = await db.rawQuery(
      '''
      SELECT SUM(valor_total) as total 
      FROM despesa 
      WHERE etapa_id = ?
    ''',
      [etapaId],
    );

    final totalGasto = gastoResult.first['total'] as double? ?? 0.0;

    if (valorOrcado > 0) {
      // Se tem valor orçado, calcula o progresso baseado no gasto
      return (totalGasto / valorOrcado).clamp(0.0, 1.0);
    } else {
      // Se não tem valor orçado, verifica se há despesas
      return totalGasto > 0 ? 0.1 : 0.0;
    }
  }

  /// Atualiza o progresso de todas as etapas de um orçamento
  Future<void> atualizarProgressoEtapas(int orcamentoId) async {
    final etapas = await getByOrcamento(orcamentoId);

    for (var etapa in etapas) {
      if (etapa.id != null) {
        final progresso = await calcularProgressoEtapa(etapa.id!);
        final novoStatus = _calcularStatus(progresso);

        await update(
          Etapa(
            id: etapa.id,
            nome: etapa.nome,
            descricao: etapa.descricao,
            orcamentoId: etapa.orcamentoId,
            progresso: progresso,
            status: novoStatus,
            dataInicio: etapa.dataInicio,
            dataFim: etapa.dataFim,
            valorOrcado: etapa.valorOrcado,
          ),
        );
      }
    }
  }

  String _calcularStatus(double progresso) {
    if (progresso >= 1.0) return 'Concluído';
    if (progresso >= 0.7) return 'Em Andamento';
    if (progresso >= 0.3) return 'Em Andamento';
    if (progresso > 0) return 'Iniciado';
    return 'Pendente';
  }
}
