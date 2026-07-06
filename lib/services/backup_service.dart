// lib/services/backup_service.dart
// Arquivo de definição da classe BackupService que será responsável por
// gerenciar backups de banco de dados.
//============================================================================//

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../database/db_helper.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DBHelper _dbHelper = DBHelper();

  /// Verifica e solicita permissões de armazenamento
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Para Android 11+ (API 30+), usa permissão de gerenciamento de arquivos
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS não precisa de permissão especial para Downloads
      return true;
    }
    return false;
  }

  /// Faz backup do banco de dados para a pasta Downloads
  Future<String?> backupDatabase(BuildContext context) async {
    try {
      // 1. Verificar permissões
      final hasPermission = await requestStoragePermission();
      if (!context.mounted) return null;

      if (!hasPermission) {
        _showSnackBar(context, '❌ Permissão de armazenamento negada!');
        return null;
      }

      // 2. Obter o caminho do banco atual
      final dbPath = await _getDatabasePath();
      if (!context.mounted) return null;

      if (dbPath == null) {
        _showSnackBar(context, '❌ Banco de dados não encontrado!');
        return null;
      }

      // 3. Ler o arquivo do banco
      final File dbFile = File(dbPath);
      final fileExists = await dbFile.exists();
      if (!context.mounted) return null;

      if (!fileExists) {
        _showSnackBar(context, '❌ Arquivo do banco não existe!');
        return null;
      }

      // 4. Gerar nome do arquivo de backup com timestamp
      final timestamp = DateTime.now().formatyyyyMMddHHmmss();
      final backupFileName = 'acompanha_obra_backup_$timestamp.db';

      // 5. Obter diretório de destino (Downloads)
      final downloadsDir = await _getDownloadsDirectory();
      if (!context.mounted) return null;

      if (downloadsDir == null) {
        _showSnackBar(context, '❌ Não foi possível acessar a pasta Downloads!');
        return null;
      }

      final backupFile = File('${downloadsDir.path}/$backupFileName');

      // 6. Copiar o arquivo
      await dbFile.copy(backupFile.path);

      // 7. Verificar se o backup foi criado
      final exists = await backupFile.exists();
      if (!context.mounted) return null;

      if (exists) {
        final size = await backupFile.length();
        if (!context.mounted) return null;

        final sizeInMB = (size / (1024 * 1024)).toStringAsFixed(2);
        _showSnackBar(
          context,
          '✅ Backup criado com sucesso!\n📁 $backupFileName ($sizeInMB MB)',
          duration: const Duration(seconds: 4),
        );
        return backupFile.path;
      } else {
        _showSnackBar(context, '❌ Falha ao criar o backup!');
        return null;
      }
    } catch (e) {
      _showSnackBar(context, '❌ Erro ao fazer backup: $e');
      return null;
    }
  }

  /// Restaura o banco de dados a partir de um arquivo selecionado
  Future<bool> restoreDatabase(BuildContext context) async {
    try {
      // 1. Verificar permissões
      final hasPermission = await requestStoragePermission();
      if (!context.mounted) return false;

      if (!hasPermission) {
        _showSnackBar(context, '❌ Permissão de armazenamento negada!');
        return false;
      }

      // 2. Pedir para o usuário selecionar o arquivo de backup
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Selecione o arquivo de backup',
      );

      if (!context.mounted) return false;

      if (result == null || result.files.isEmpty) {
        _showSnackBar(context, '⏹️ Restauração cancelada.');
        return false;
      }

      final selectedFile = result.files.first;
      if (selectedFile.path == null) {
        _showSnackBar(context, '❌ Arquivo inválido!');
        return false;
      }

      // 3. Validar se é um arquivo SQLite válido (verifica cabeçalho)
      final File backupFile = File(selectedFile.path!);
      final isValid = await _isValidSqliteFile(backupFile);
      if (!context.mounted) return false;

      if (!isValid) {
        _showSnackBar(context, '❌ Arquivo não é um banco SQLite válido!');
        return false;
      }

      // 4. Confirmar com o usuário
      final confirm = await _showConfirmDialog(
        context,
        '⚠️ Atenção!',
        'Restaurar o backup substituirá TODOS os dados atuais.\n\n'
            'Recomendamos fazer um backup antes de continuar.\n\n'
            'Deseja continuar?',
      );

      if (!context.mounted) return false;

      if (!confirm) {
        _showSnackBar(context, '⏹️ Restauração cancelada.');
        return false;
      }

      // 5. Fechar a conexão atual com o banco
      await _dbHelper.close();

      // 6. Fazer um backup automático antes de restaurar
      final autoBackupPath = await _createAutoBackup();
      if (!context.mounted) return false;

      if (autoBackupPath != null) {
        _showSnackBar(
          context,
          '📦 Backup automático criado em: ${autoBackupPath.split('/').last}',
          duration: const Duration(seconds: 3),
        );
      }

      // 7. Obter caminho do banco atual
      final dbPath = await _getDatabasePath();
      if (!context.mounted) return false;

      if (dbPath == null) {
        _showSnackBar(context, '❌ Banco de dados não encontrado!');
        return false;
      }

      // 8. Copiar o arquivo de backup para o local do banco
      final File currentDbFile = File(dbPath);
      await backupFile.copy(currentDbFile.path);

      // 9. Verificar se a restauração foi bem-sucedida
      final exists = await currentDbFile.exists();
      if (!context.mounted) return false;

      if (exists) {
        // 10. Recriar a conexão com o banco
        await _dbHelper.db;
        if (!context.mounted) return false;
        _showSnackBar(
          context,
          '✅ Banco restaurado com sucesso!\nReinicie o app para aplicar as alterações.',
          duration: const Duration(seconds: 4),
        );
        return true;
      } else {
        _showSnackBar(context, '❌ Falha ao restaurar o banco!');
        return false;
      }
    } catch (e) {
      _showSnackBar(context, '❌ Erro ao restaurar: $e');
      return false;
    }
  }

  /// Verifica se o arquivo é um banco SQLite válido
  Future<bool> _isValidSqliteFile(File file) async {
    try {
      // Abre o arquivo para leitura
      final RandomAccessFile raf = await file.open(mode: FileMode.read);
      try {
        // Lê apenas os primeiros 16 bytes
        final Uint8List bytes = Uint8List(16);
        final int bytesRead = await raf.readInto(bytes);

        // Se não leu 16 bytes, não é um arquivo SQLite válido
        if (bytesRead < 16) {
          return false;
        }

        // SQLite header: "SQLite format 3\0"
        const sqliteHeader = [
          0x53,
          0x51,
          0x4C,
          0x69,
          0x74,
          0x65,
          0x20,
          0x66,
          0x6F,
          0x72,
          0x6D,
          0x61,
          0x74,
          0x20,
          0x33,
          0x00,
        ];

        for (int i = 0; i < 16; i++) {
          if (bytes[i] != sqliteHeader[i]) {
            return false;
          }
        }
        return true;
      } finally {
        // Sempre fecha o arquivo
        await raf.close();
      }
    } catch (e) {
      return false;
    }
  }

  /// Obtém o caminho do banco de dados atual
  Future<String?> _getDatabasePath() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = '$databasesPath/acompanha_obra.db';
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Obtém o diretório de Downloads
  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Para Android, usa o diretório de Downloads
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
      // Fallback para outros diretórios
      return await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    return await getExternalStorageDirectory();
  }

  /// Cria um backup automático antes de restaurar
  Future<String?> _createAutoBackup() async {
    try {
      final dbPath = await _getDatabasePath();
      if (dbPath == null) return null;

      final File dbFile = File(dbPath);
      if (!await dbFile.exists()) return null;

      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) return null;

      final timestamp = DateTime.now().formatyyyyMMddHHmmss();
      final backupFileName = 'acompanha_obra_auto_backup_$timestamp.db';
      final backupFile = File('${downloadsDir.path}/$backupFileName');

      await dbFile.copy(backupFile.path);
      return backupFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Mostra um SnackBar com mensagem
  void _showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2),
        duration: duration,
        backgroundColor: message.contains('✅')
            ? Colors.green
            : message.contains('❌')
            ? Colors.red
            : Colors.blue,
      ),
    );
  }

  /// Mostra um diálogo de confirmação
  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title, style: const TextStyle(color: Colors.orange)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Restaurar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// Extension para formatar DateTime
extension DateTimeFormat on DateTime {
  String formatyyyyMMddHHmmss() {
    return '$year${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}_${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}${second.toString().padLeft(2, '0')}';
  }
}
