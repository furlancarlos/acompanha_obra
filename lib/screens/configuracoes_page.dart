// lib/screens/configuracoes_page.dart
// Tela principal de Configurações e Manutenção estruturada em Abas.
//============================================================================//

import 'package:flutter/material.dart';
import 'abas/aba_historico_despesas.dart';
import 'abas/aba_historico_etapas.dart';
import 'abas/aba_backup.dart';
import 'abas/aba_outros.dart';
import '../form/lista_produto.dart';

class ConfiguracoesPage extends StatelessWidget {
  final int? orcamentoId;

  const ConfiguracoesPage({super.key, this.orcamentoId});

  @override
  Widget build(BuildContext context) {
    // Se não houver orçamento selecionado na home, evita que a aba de despesas quebre
    final idValido = orcamentoId ?? 0;

    return DefaultTabController(
      length: 4, // Total de abas
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Configurações e Manutenção',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: const Color(0xFF1B3A5C),
          foregroundColor: Colors.white,
          elevation: 2,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFFE8751A), // Laranja de destaque do seu app
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Despesas'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Etapas'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Produtos'),
              Tab(icon: Icon(Icons.backup), text: 'Backup'),
              Tab(icon: Icon(Icons.build), text: 'Outros'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            idValido > 0
                ? AbaHistoricoDespesas(orcamentoId: idValido)
                : const Center(
                    child: Text('Selecione um orçamento na tela inicial.'),
                  ),
            idValido > 0
                ? AbaHistoricoEtapas(orcamentoId: idValido)
                : const Center(
                    child: Text('Selecione uma etapa na tela inicial.'),
                  ),
            const ListaProdutoPage(embedded: true),
            const AbaBackup(),
            const AbaOutros(),
          ],
        ),
      ),
    );
  }
}
