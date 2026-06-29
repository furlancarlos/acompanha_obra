// widgets/cards/card_grafico_etapas.dart
// Card que exibe um gráfico de barras com a evolução das etapas do orçamento
// Card exibido na tela main de orçamentos. Card 01.
//============================================================================//

import 'package:flutter/material.dart';
import '../../models/etapa.dart';

class CardGraficoEtapas extends StatelessWidget {
  final List<Etapa> etapas;
  final double alturaMaxima;

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

    final progressoTotal =
        etapas.fold<double>(0.0, (sum, etapa) => sum + etapa.progresso) /
        etapas.length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
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
                    color: _getProgressColor(progressoTotal).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progressoTotal * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progressoTotal),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gráfico de Barras
            // widgets/cards/card_grafico_etapas.dart - Com status textual
            SizedBox(
              height: alturaMaxima,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: etapas.map((etapa) {
                  final progresso = etapa.progresso.clamp(0.0, 1.0);
                  final altura = progresso * alturaMaxima;
                  final cor = _getProgressColor(progresso);
                  final status = _getStatusText(progresso); // ← MANTER

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Valor percentual
                          Text(
                            '${(progresso * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Barra
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  height: altura > 0 ? altura : 6,
                                  decoration: BoxDecoration(
                                    color: cor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Nome da etapa (abreviado)
                          Text(
                            _abreviarNome(etapa.nome),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // ← ADICIONAR STATUS TEXTUAL (OPCIONAL)
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 8,
                              color: cor,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

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

  String _abreviarNome(String nome) {
    if (nome.length <= 6) return nome;
    return nome.substring(0, 6);
  }
}
