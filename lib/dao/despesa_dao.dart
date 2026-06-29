// despesa_dao.dart
// Arquivo de definição da classe DespesaDAO que será responsável por fazer
// operações com o banco de dados.
//============================================================================//

import '../database/db_helper.dart';
import '../models/despesa.dart';

class DespesaDAO {
  Future<int> insert(Despesa despesa) async {
    final db = await DBHelper().db;
    return await db.insert('despesa', despesa.toMap());
  }

  Future<List<Despesa>> getAll() async {
    final db = await DBHelper().db;
    final result = await db.query('despesa');
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  Future<int> update(Despesa despesa) async {
    final db = await DBHelper().db;
    return await db.update(
      'despesa',
      despesa.toMap(),
      where: 'id = ?',
      whereArgs: [despesa.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBHelper().db;
    return await db.delete('despesa', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalGasto() async {
    final db = await DBHelper().db;
    final result = await db.rawQuery(
      'SELECT SUM(valor_total) as total FROM despesa',
    );
    if (result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // ✅ CORRIGIDO: despesa já tem orcamento_id
  Future<double> getTotalGastoPorOrcamento(int orcamentoId) async {
    final db = await DBHelper().db;
    final result = await db.rawQuery(
      '''
      SELECT SUM(valor_total) as total 
      FROM despesa 
      WHERE orcamento_id = ?
      ''',
      [orcamentoId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Soma despesas de uma etapa específica
  Future<double> getTotalGastoPorEtapa(int etapaId) async {
    final db = await DBHelper().db;
    final result = await db.rawQuery(
      '''
      SELECT SUM(valor_total) as total 
      FROM despesa 
      WHERE etapa_id = ?
      ''',
      [etapaId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // Busca despesas por orçamento
  Future<List<Despesa>> getByOrcamento(int orcamentoId) async {
    final db = await DBHelper().db;
    final result = await db.query(
      'despesa',
      where: 'orcamento_id = ?',
      whereArgs: [orcamentoId],
      orderBy: 'data DESC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }

  // Busca despesas por etapa
  Future<List<Despesa>> getByEtapa(int etapaId) async {
    final db = await DBHelper().db;
    final result = await db.query(
      'despesa',
      where: 'etapa_id = ?',
      whereArgs: [etapaId],
      orderBy: 'data DESC',
    );
    return result.map((map) => Despesa.fromMap(map)).toList();
  }
}
