// unidade_dao.dart
// Arquivo de definição da classe UnidadeDAO que será responsável por fazer
// operações com o banco de dados.
//============================================================================//

import '../database/db_helper.dart';
import '../models/unidade.dart';

class UnidadeDAO {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insert(Unidade unidade) async {
    final db = await _dbHelper.db;
    return await db.insert('unidade', unidade.toMap());
  }

  Future<int> update(Unidade unidade) async {
    final db = await _dbHelper.db;
    return await db.update(
      'unidade',
      unidade.toMap(),
      where: 'id = ?',
      whereArgs: [unidade.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.db;
    return await db.delete('unidade', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Unidade>> getAll() async {
    final db = await _dbHelper.db;
    final result = await db.query('unidade', orderBy: 'descricao');
    return result.map((map) => Unidade.fromMap(map)).toList();
  }

  Future<Unidade?> getById(int id) async {
    final db = await _dbHelper.db;
    final result = await db.query('unidade', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Unidade.fromMap(result.first);
    }
    return null;
  }

  Future<bool> existsByDescricao(String descricao) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'unidade',
      where: 'descricao = ?',
      whereArgs: [descricao.trim()],
    );
    return result.isNotEmpty;
  }
}
