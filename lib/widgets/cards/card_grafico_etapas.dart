// widgets/cards/card_grafico_etapas.dart
// Card que exibe o progresso das etapas de forma ordenada e horizontal
// Card exibido na tela main de orçamentos. Card 02.
//============================================================================//

import 'package:flutter/material.dart';
import '../../models/etapa.dart';

class CardGraficoEtapas extends StatelessWidget {
  final List<Etapa> etapas;
  final double alturaMaxima; // Mantida por compatibilidade de assinatura

  const CardGraficoEtapas({
    super.key,
    required this.etapas,
    this.alturaMaxima = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (etapas.isEmpty) {
      return _buildEmptyState();
    }

    // Calcula o progresso total geral
    final progressoTotal =
        etapas.fold<double>(0.0, (sum, etapa) => sum + etapa.progresso) /
        etapas.length;

    // 1. Cria uma cópia da lista e ordena de forma CRESCENTE pelo percentual de progresso
    final etapasOrdenadas = List<Etapa>.from(etapas)
      ..sort((a, b) => a.progresso.compareTo(b.progresso));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título e indicador geral
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 Evolução das Etapas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getProgressColor(progressoTotal).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progressoTotal * 100).toInt()}% Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progressoTotal),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Gráfico usando Barras de Progresso Horizontais
            Column(
              children: etapasOrdenadas.map((etapa) {
                final progresso = etapa.progresso.clamp(0.0, 1.0);
                final cor = _getProgressColor(progresso);
                final status = _getStatusText(progresso);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha de informações superior da etapa
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              etapa.nome, // Agora pode exibir o nome completo se couber
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$status (${(progresso * 100).toInt()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // A barra de progresso linear propriamente dita
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 18,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(cor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendaItem(Colors.red.shade700, 'Crítico'),
                const SizedBox(width: 12),
                _buildLegendaItem(const Color(0xFFE8751A), 'Em Andamento'),
                const SizedBox(width: 12),
                _buildLegendaItem(Colors.green.shade700, 'Concluído'),
                const SizedBox(width: 12),
                _buildLegendaItem(Colors.grey.shade400, 'Pendente'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma etapa cadastrada',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Cadastre etapas para ver o progresso',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendaItem(Color cor, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Color _getProgressColor(double progresso) {
    if (progresso >= 1.0) return Colors.green.shade700;
    if (progresso >= 0.7) return Colors.green.shade400;
    if (progresso >= 0.4) return const Color(0xFFE8751A);
    if (progresso >= 0.1) return Colors.orange.shade700;
    return Colors.grey.shade400;
  }

  String _getStatusText(double progresso) {
    if (progresso >= 1.0) return 'Concluído';
    if (progresso >= 0.7) return 'Quase lá';
    if (progresso >= 0.4) return 'Em andamento';
    if (progresso >= 0.1) return 'Iniciado';
    return 'Pendente';
  }
}
