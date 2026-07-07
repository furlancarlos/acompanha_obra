// lib/screens/abas/aba_outros.dart
// Arquivo de definição da tela de outros (aba).
//============================================================================//

import 'package:flutter/material.dart';

class AbaOutros extends StatelessWidget {
  const AbaOutros({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '🚀 Novas ferramentas de manutenção em breve!',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}