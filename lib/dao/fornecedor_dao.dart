// fornecedor_dao.dart
// Arquivo de definição da classe FornecedorDAO que será responsável por fazer
// operações com o banco de dados.
//============================================================================//

// dao/fornecedor_dao.dart
import '../database/db_helper.dart';
import '../models/fornecedor.dart';

class FornecedorDAO {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insert(Fornecedor fornecedor) async {
    final db = await _dbHelper.db;
    return await db.insert('fornecedor', fornecedor.toMap());
  }

  Future<int> update(Fornecedor fornecedor) async {
    final db = await _dbHelper.db;
    return await db.update(
      'fornecedor',
      fornecedor.toMap(),
      where: 'id = ?',
      whereArgs: [fornecedor.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.db;
    return await db.delete(
      'fornecedor',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Fornecedor>> getAll() async {
    final db = await _dbHelper.db;
    final result = await db.query('fornecedor', orderBy: 'nome');
    return result.map((map) => Fornecedor.fromMap(map)).toList();
  }

  Future<Fornecedor?> getById(int id) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'fornecedor',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Fornecedor.fromMap(result.first);
    }
    return null;
  }

  Future<bool> existsByNome(String nome) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'fornecedor',
      where: 'nome = ?',
      whereArgs: [nome.trim()],
    );
    return result.isNotEmpty;
  }
}
