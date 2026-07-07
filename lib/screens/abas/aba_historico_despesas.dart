// lib/screens/abas/aba_historico_despesas.dart
// Aba que lista as despesas de um orçamento em ordem decrescente de data com CRUD.
//===============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../dao/despesa_dao.dart';
import '../../models/despesa.dart';
import '../cadastro_despesa.dart';

class AbaHistoricoDespesas extends StatefulWidget {
  final int orcamentoId;

  const AbaHistoricoDespesas({super.key, required this.orcamentoId});

  @override
  State<AbaHistoricoDespesas> createState() => _AbaHistoricoDespesasState();
}

class _AbaHistoricoDespesasState extends State<AbaHistoricoDespesas> {
  final _despesaDAO = DespesaDAO();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

  // Função para abrir a tela de cadastro em formato de EDIÇÃO
  void _editarDespesa(Despesa despesa) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroDespesaPage(
          orcamentoId: widget.orcamentoId,
          despesaAntiga: despesa, // Passa a despesa antiga para ativar o modo de edição
        ),
      ),
    );

    if (resultado == true) {
      setState(() {}); // Recarrega a listagem atual se houve alteração
    }
  }

  // Função para confirmar e excluir a despesa
  void _confirmarExclusao(Despesa despesa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Excluir Lançamento'),
        content: Text('Deseja realmente excluir o lançamento de "${despesa.descricao}" no valor de ${_currencyFormat.format(despesa.valorTotal)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _despesaDAO.delete(despesa.id!);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {}); // Recarrega a lista após deletar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lançamento removido com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Despesa>>(
        future: _despesaDAO.getByOrcamento(widget.orcamentoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar despesas: ${snapshot.error}'));
          }

          final despesas = snapshot.data ?? [];

          if (despesas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma despesa lançada neste orçamento.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: despesas.length,
            itemBuilder: (context, index) {
              final despesa = despesas[index];
              
              // Formatação simples da data vinda do banco (ISO8601)
              DateTime dataDespesa;
              try {
                dataDespesa = DateTime.parse(despesa.data);
              } catch (_) {
                dataDespesa = DateTime.now();
              }
              final dataFormatada = DateFormat('dd/MM/yyyy').format(dataDespesa);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1B3A5C).withValues(alpha: 0.1),
                    child: const Icon(Icons.monetization_on, color: Color(0xFF1B3A5C)),
                  ),
                  title: Text(
                    despesa.descricao,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Data: $dataFormatada\nQtd: ${despesa.quantidade} x ${_currencyFormat.format(despesa.valorUnitario)}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currencyFormat.format(despesa.valorTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (opcao) {
                          if (opcao == 'editar') _editarDespesa(despesa);
                          if (opcao == 'excluir') _confirmarExclusao(despesa);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
