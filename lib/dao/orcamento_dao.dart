// orcamento_dao.dart
// Arquivo de definição da classe OrcamentoDAO que será responsável por fazer
// operações com o banco de dados.
//============================================================================//

// dao/orcamento_dao.dart
import '../database/db_helper.dart';
import '../models/orcamento.dart';

class OrcamentoDAO {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insert(Orcamento orcamento) async {
    final db = await _dbHelper.db;
    return await db.insert('orcamento', orcamento.toMap());
  }

  Future<int> update(Orcamento orcamento) async {
    final db = await _dbHelper.db;
    return await db.update(
      'orcamento',
      orcamento.toMap(),
      where: 'id = ?',
      whereArgs: [orcamento.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.db;
    return await db.delete(
      'orcamento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Orcamento>> getAll() async {
    final db = await _dbHelper.db;
    final result = await db.query('orcamento', orderBy: 'nome');
    return result.map((map) => Orcamento.fromMap(map)).toList();
  }

  Future<Orcamento?> getById(int id) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'orcamento',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Orcamento.fromMap(result.first);
    }
    return null;
  }

  Future<double> getOrcamentoAtual() async {
    final db = await _dbHelper.db;
    final result = await db.rawQuery('''
      SELECT SUM(valor_total) as total FROM orcamento
    ''');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<bool> existsByNome(String nome) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'orcamento',
      where: 'nome = ?',
      whereArgs: [nome.trim()],
    );
    return result.isNotEmpty;
  }
}
