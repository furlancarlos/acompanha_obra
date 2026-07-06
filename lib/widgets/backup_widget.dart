// lib/widgets/backup_widget.dart
// Widget para gerenciar backups
//============================================================================//

import 'package:flutter/material.dart';
import '../services/backup_service.dart';

class BackupWidget extends StatelessWidget {
  const BackupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final backupService = BackupService();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💾 Gerenciamento de Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Proteja seus dados fazendo backups regulares. '
              'Restauração substitui todos os dados atuais.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await backupService.backupDatabase(context);
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Fazer Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await backupService.restoreDatabase(context);
                      if (success) {
                        // Opcional: reiniciar o app ou recarregar dados
                      }
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
