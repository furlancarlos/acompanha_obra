// db_helper.dart
// Arquivo de definição da classe DBHelper que será responsável por criar e
// abrir a conexão com o banco de dados.
//============================================================================//

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'acompanha_obra.db');

    return await openDatabase(
      path,
      version: 5, // ← ALTERADO PARA VERSÃO 5
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Configuração obrigatória para o ON DELETE CASCADE funcionar
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // TABELAS INDEPENDENTES (Não dependem de ninguém)

    // Tabela Orcamento
    await db.execute('''
      CREATE TABLE orcamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        valor_total REAL NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT
      )
    ''');

    // Tabela Unidade
    await db.execute('''
      CREATE TABLE unidade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        sigla TEXT
      )
    ''');

    // Tabela Fornecedor
    await db.execute('''
      CREATE TABLE fornecedor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        endereco TEXT,
        telefone TEXT,
        contato TEXT
      )
    ''');

    // TABELAS DEPENDENTES (Possuem chaves estrangeiras)

    // Tabela Etapa
    await db.execute('''
      CREATE TABLE etapa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        orcamento_id INTEGER NOT NULL,
        progresso REAL DEFAULT 0.0,
        status TEXT DEFAULT 'Pendente',
        data_inicio TEXT,
        data_fim TEXT,
        valor_orcado REAL,
        FOREIGN KEY (orcamento_id) REFERENCES orcamento (id) ON DELETE CASCADE
      )
    ''');

    // Tabela Produto
    await db.execute('''
      CREATE TABLE produto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        unidade_id INTEGER,
        FOREIGN KEY (unidade_id) REFERENCES unidade (id) ON DELETE SET NULL
      )
    ''');

    // Tabela Despesa
    await db.execute('''
      CREATE TABLE despesa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        data TEXT NOT NULL,
        fornecedor_id INTEGER,
        produto_id INTEGER,
        unidade_id INTEGER,
        orcamento_id INTEGER,    // ← NOVO CAMPO
        etapa_id INTEGER,        // ← NOVO CAMPO
        quantidade REAL NOT NULL,
        valor_unitario REAL NOT NULL,
        valor_total REAL NOT NULL,
        FOREIGN KEY (fornecedor_id) REFERENCES fornecedor (id) ON DELETE SET NULL,
        FOREIGN KEY (produto_id) REFERENCES produto (id) ON DELETE SET NULL,
        FOREIGN KEY (unidade_id) REFERENCES unidade (id) ON DELETE SET NULL,
        FOREIGN KEY (orcamento_id) REFERENCES orcamento (id) ON DELETE CASCADE,
        FOREIGN KEY (etapa_id) REFERENCES etapa (id) ON DELETE SET NULL
      )
    ''');

    // ÍNDICES (Otimização de buscas)
    await db.execute(
      'CREATE INDEX idx_despesa_fornecedor ON despesa(fornecedor_id)',
    );
    await db.execute('CREATE INDEX idx_despesa_produto ON despesa(produto_id)');
    await db.execute('CREATE INDEX idx_despesa_unidade ON despesa(unidade_id)');
    await db.execute(
      'CREATE INDEX idx_despesa_orcamento ON despesa(orcamento_id)',
    ); // ← NOVO
    await db.execute(
      'CREATE INDEX idx_despesa_etapa ON despesa(etapa_id)',
    ); // ← NOVO
    await db.execute('CREATE INDEX idx_etapa_orcamento ON etapa(orcamento_id)');
    await db.execute('CREATE INDEX idx_etapa_status ON etapa(status)');
    await db.execute('CREATE INDEX idx_despesa_data ON despesa(data)');
    await db.execute(
      'CREATE INDEX idx_orcamento_datas ON orcamento(data_inicio, data_fim)',
    );

    // POPULAR BANCO INICIAL
    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Versão 1 → 2: Adiciona unidade_id em produto
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE produto ADD COLUMN unidade_id INTEGER');
        print('✅ Coluna unidade_id adicionada à tabela produto');
      } catch (e) {
        print('⚠️ Erro ao adicionar unidade_id: $e');
      }
    }

    // Versão 2 → 3: (Se houver alguma alteração futura)
    // if (oldVersion < 3) { ... }

    // Versão 3 → 4: Adiciona orcamento_id e etapa_id em despesa
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE despesa ADD COLUMN orcamento_id INTEGER');
        await db.execute('ALTER TABLE despesa ADD COLUMN etapa_id INTEGER');
        print('✅ Colunas orcamento_id e etapa_id adicionadas à tabela despesa');
      } catch (e) {
        print('⚠️ Erro ao adicionar colunas em despesa: $e');
      }
    }

    // Versão 4 → 5: Adiciona valor_orcado na tabela etapa
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE etapa ADD COLUMN valor_orcado REAL');
        print('✅ Coluna valor_orcado adicionada à tabela etapa');
      } catch (e) {
        print('⚠️ Erro ao adicionar valor_orcado: $e');
      }
    }
  }

  Future<void> _insertInitialData(Database db) async {
    // Uso de Batch: Insere tudo de uma vez de forma muito mais rápida
    final batch = db.batch();

    final unidades = [
      {'descricao': 'Metro', 'sigla': 'm'},
      {'descricao': 'Metro Quadrado', 'sigla': 'm²'},
      {'descricao': 'Metro Cúbico', 'sigla': 'm³'},
      {'descricao': 'Quilograma', 'sigla': 'kg'},
      {'descricao': 'Litro', 'sigla': 'L'},
      {'descricao': 'Unidade', 'sigla': 'un'},
      {'descricao': 'Hora', 'sigla': 'h'},
      {'descricao': 'Dia', 'sigla': 'dia'},
    ];

    for (var unidade in unidades) {
      batch.insert('unidade', unidade);
    }

    await batch.commit(noResult: true);
  }

  // ================================================================
  // OPERAÇÕES COMUNS (Mantidas de forma limpa caso as DAOs usem)
  // ================================================================

  Future<int> insert(String table, Map<String, dynamic> data) async =>
      (await db).insert(table, data);

  Future<List<Map<String, dynamic>>> queryAll(String table) async =>
      (await db).query(table);

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return (await db).query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> querySingle(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final results = await query(
      table,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    return (await db).update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    return (await db).delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async =>
      (await db).rawQuery(sql);

  Future<void> transaction(
    Future<void> Function(Transaction txn) action,
  ) async => (await db).transaction(action);

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
