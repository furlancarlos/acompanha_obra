// produto_dao.dart
// Arquivo de definição da classe ProdutoDAO que será responsável por fazer
// operações com o banco de dados.
//============================================================================//

// dao/produto_dao.dart
import '../database/db_helper.dart';
import '../models/produto.dart';
import '../models/unidade.dart';

class ProdutoDAO {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insert(Produto produto) async {
    final db = await _dbHelper.db;
    return await db.insert('produto', produto.toMap());
  }

  Future<int> update(Produto produto) async {
    final db = await _dbHelper.db;
    return await db.update(
      'produto',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.db;
    return await db.delete(
      'produto',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Produto>> getAll() async {
    final db = await _dbHelper.db;
    
    // Busca todos os produtos com JOIN na tabela unidade
    final result = await db.rawQuery('''
      SELECT 
        p.*,
        u.id as unidade_id,
        u.descricao as unidade_descricao,
        u.sigla as unidade_sigla
      FROM produto p
      LEFT JOIN unidade u ON p.unidade_id = u.id
      ORDER BY p.nome
    ''');

    return result.map((map) {
      // Cria o produto a partir do map
      final produto = Produto(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        descricao: map['descricao'] as String?,
        unidadeId: map['unidade_id'] as int?,
      );
      
      // Se tiver dados da unidade, monta o objeto
      if (map['unidade_id'] != null) {
        produto.unidade = Unidade(
          id: map['unidade_id'] as int,
          descricao: map['unidade_descricao'] as String? ?? '',
          sigla: map['unidade_sigla'] as String?,
        );
      }
      
      return produto;
    }).toList();
  }

  Future<Produto?> getById(int id) async {
    final db = await _dbHelper.db;
    final result = await db.rawQuery('''
      SELECT 
        p.*,
        u.id as unidade_id,
        u.descricao as unidade_descricao,
        u.sigla as unidade_sigla
      FROM produto p
      LEFT JOIN unidade u ON p.unidade_id = u.id
      WHERE p.id = ?
    ''', [id]);

    if (result.isNotEmpty) {
      final map = result.first;
      
      final produto = Produto(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        descricao: map['descricao'] as String?,
        unidadeId: map['unidade_id'] as int?,
      );
      
      if (map['unidade_id'] != null) {
        produto.unidade = Unidade(
          id: map['unidade_id'] as int,
          descricao: map['unidade_descricao'] as String? ?? '',
          sigla: map['unidade_sigla'] as String?,
        );
      }
      
      return produto;
    }
    return null;
  }

  Future<bool> existsByNome(String nome) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'produto',
      where: 'nome = ?',
      whereArgs: [nome.trim()],
    );
    return result.isNotEmpty;
  }

  Future<List<Produto>> getByUnidade(int unidadeId) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'produto',
      where: 'unidade_id = ?',
      whereArgs: [unidadeId],
      orderBy: 'nome',
    );
    return result.map((map) => Produto.fromMap(map)).toList();
  }
}
