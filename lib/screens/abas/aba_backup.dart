// lib/screens/abas/aba_backup.dart
// Arquivo de definição da tela de backup (aba).
//============================================================================//

import 'package:flutter/material.dart';
import '../../widgets/backup_widget.dart';

class AbaBackup extends StatelessWidget {
  const AbaBackup({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            BackupWidget(),
          ],
        ),
      ),
    );
  }
}
