// widgets/cards/card_lista_orcamentos.dart
// Arquivo de definição da tela de card de listagem de orçamentos.
//============================================================================//

import 'package:flutter/material.dart';
import '../../models/orcamento.dart';
import '../items/item_orcamento.dart';
import '../common/empty_state.dart';

class CardListaOrcamentos extends StatelessWidget {
  final List<Orcamento> orcamentos;
  final Orcamento? orcamentoSelecionado;
  final Function(Orcamento) onOrcamentoSelecionado;
  final VoidCallback onVerTodos;
  final VoidCallback onRefresh;

  const CardListaOrcamentos({
    super.key,
    required this.orcamentos,
    required this.orcamentoSelecionado,
    required this.onOrcamentoSelecionado,
    required this.onVerTodos,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No seu arquivo: widgets/cards/card_lista_orcamentos.dart
            // Substitua o bloco do // Título por este:
            Row(
              children: [
                // Título ganha o espaço que sobrar à esquerda
                const Expanded(
                  child: Text(
                    '📋 Orçamentos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Botão "Ver Todos" simplificado (apenas ícone se a tela for minúscula) ou flexível
                Flexible(
                  child: TextButton.icon(
                    onPressed: onVerTodos,
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text(
                      'Ver Todos',
                      overflow: TextOverflow
                          .ellipsis, // Evita estouro dentro do botão
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B3A5C),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Ícone de atualizar isolado da Row interna perigosa
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Atualizar',
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lista de Orçamentos
            if (orcamentos.isEmpty)
              const EmptyState(
                icon: Icons.attach_money_outlined,
                message: 'Nenhum orçamento cadastrado',
                actionLabel: 'Criar primeiro orçamento',
              )
            else
              ...orcamentos.map((orcamento) {
                final isSelecionado = orcamentoSelecionado?.id == orcamento.id;
                return ItemOrcamento(
                  orcamento: orcamento,
                  isSelecionado: isSelecionado,
                  onTap: () => onOrcamentoSelecionado(orcamento),
                );
              }).toList(),

            const SizedBox(height: 8),

            // Botão Gerenciar Orçamentos
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onVerTodos,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Gerenciar Orçamentos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B3A5C),
                  side: const BorderSide(color: Color(0xFF1B3A5C)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
