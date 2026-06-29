// widgets/cards/card_resumo_orcamento.dart
// Arquivo de definição da tela de card de resumo do orçamento.
//============================================================================//

import 'package:flutter/material.dart';
import '../../models/orcamento.dart';

class CardResumoOrcamento extends StatelessWidget {
  final Orcamento orcamento;
  final double valorOrcamento;
  final double valorGasto;
  final double percentual;
  final double restante;
  final VoidCallback? onInfoPressed;

  const CardResumoOrcamento({
    super.key,
    required this.orcamento,
    required this.valorOrcamento,
    required this.valorGasto,
    required this.percentual,
    required this.restante,
    this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do Orçamento
            Row(
              children: [
                const Icon(
                  Icons.assignment,
                  color: Color(0xFF1B3A5C),
                  size: 10,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orcamento.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A5C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (orcamento.descricao != null && orcamento.descricao!.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.info_outline, size: 10, color: Colors.grey.shade500),
                    tooltip: orcamento.descricao,
                    onPressed: onInfoPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            // Valores
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Orçado',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'R\$ ${valorOrcamento.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3A5C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gasto Total',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'R\$ ${valorGasto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE8751A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Restante',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'R\$ ${restante.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: restante >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de Progresso
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: percentual.clamp(0.0, 1.0),
                  minHeight: 20,
                  backgroundColor: Colors.transparent,
                  color: percentual > 0.8
                      ? Colors.red.shade700
                      : percentual > 0.5
                          ? const Color(0xFFE8751A)
                          : const Color(0xFF1B3A5C),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percentual * 100).toStringAsFixed(1)}% Gasto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: percentual > 0.8
                        ? Colors.red.shade700
                        : percentual > 0.5
                            ? const Color(0xFFE8751A)
                            : const Color(0xFF1B3A5C),
                  ),
                ),
                if (percentual > 0)
                  Text(
                    'Meta: 100%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
