// lib/screens/abas/aba_historico_despesas.dart
// Aba que lista as despesas de um orçamento em ordem decrescente de data com CRUD.
//===============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../dao/despesa_dao.dart';
import '../../models/despesa.dart';
import '../cadastro_despesa.dart';

/// Classe auxiliar para agrupar as despesas por Nota Fiscal
class NotaDespesaGroup {
  final String identificador;
  final String? numeroNota;
  final String? nomeEtapa;
  final String? nomeFornecedor;
  final String data;
  final List<Despesa> itens;

  NotaDespesaGroup({
    required this.identificador,
    this.numeroNota,
    this.nomeEtapa,
    this.nomeFornecedor,
    required this.data,
    required this.itens,
  });

  /// Soma o valor total de todos os itens desta nota
  double get valorTotalNota {
    return itens.fold(0.0, (sum, item) => sum + item.valorTotal);
  }
}

class AbaHistoricoDespesas extends StatefulWidget {
  final int orcamentoId;

  const AbaHistoricoDespesas({super.key, required this.orcamentoId});

  @override
  State<AbaHistoricoDespesas> createState() => _AbaHistoricoDespesasState();
}

class _AbaHistoricoDespesasState extends State<AbaHistoricoDespesas> {
  final _despesaDAO = DespesaDAO();
  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );
  late Future<List<Despesa>> _despesasFuture;

  @override
  void initState() {
    super.initState();
    _despesasFuture = _despesaDAO.getByOrcamento(widget.orcamentoId);
  }

  void _recarregarDespesas() {
    setState(() {
      _despesasFuture = _despesaDAO.getByOrcamento(widget.orcamentoId);
    });
  }

  /// 💡 Função Principal: Agrupa a lista de despesas em Notas Fiscais
  List<NotaDespesaGroup> _agruparDespesasEmNotas(List<Despesa> despesas) {
    final Map<String, List<Despesa>> mapaGrupos = {};

    for (var despesa in despesas) {
      final temNota =
          despesa.numeroNota != null && despesa.numeroNota!.trim().isNotEmpty;

      // Se tiver número de nota, agrupa por ele.
      // Se não tiver nota, agrupa por Data + Descrição (fallback)
      final chave = temNota
          ? 'NF_${despesa.numeroNota!.trim()}'
          : 'AVULSO_${despesa.data}_${despesa.descricao.trim().toLowerCase()}';

      if (!mapaGrupos.containsKey(chave)) {
        mapaGrupos[chave] = [];
      }
      mapaGrupos[chave]!.add(despesa);
    }

    return mapaGrupos.entries.map((entry) {
      final primeiroItem = entry.value.first;
      final temNota =
          primeiroItem.numeroNota != null &&
          primeiroItem.numeroNota!.trim().isNotEmpty;

      final identificador = temNota
          ? 'Nota Fiscal nº ${primeiroItem.numeroNota}'
          : primeiroItem.descricao;

      return NotaDespesaGroup(
        identificador: identificador,
        numeroNota: primeiroItem.numeroNota,
        nomeEtapa: primeiroItem.nomeEtapa,
        nomeFornecedor: primeiroItem.nomeFornecedor,
        data: primeiroItem.data,
        itens: entry.value,
      );
    }).toList();
  }

  void _editarDespesa(Despesa despesa) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroDespesaPage(
          orcamentoId: widget.orcamentoId,
          despesaAntiga: despesa,
        ),
      ),
    );

    if (resultado == true) {
      _recarregarDespesas();
    }
  }

  void _confirmarExclusao(Despesa despesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Excluir Lançamento'),
        content: Text(
          'Deseja realmente excluir o lançamento de "${despesa.descricao}" '
          'no valor de ${_currencyFormat.format(despesa.valorTotal)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (despesa.id != null) {
                await _despesaDAO.delete(despesa.id!);
              }
              if (!mounted) return;
              Navigator.pop(context);
              _recarregarDespesas();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lançamento removido com sucesso!'),
                ),
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
        future: _despesasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar despesas: ${snapshot.error}'),
            );
          }

          final despesas = snapshot.data ?? [];

          if (despesas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma despesa lançada neste orçamento.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Executa o agrupamento antes de renderizar a lista
          final notasAgrupadas = _agruparDespesasEmNotas(despesas);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notasAgrupadas.length,
            itemBuilder: (context, index) {
              final grupoNota = notasAgrupadas[index];

              DateTime dataDespesa;
              try {
                dataDespesa = DateTime.parse(grupoNota.data);
              } catch (_) {
                dataDespesa = DateTime.now();
              }
              final dataFormatada = DateFormat(
                'dd/MM/yyyy',
              ).format(dataDespesa);

              // Se houver apenas 1 item no grupo sem nota, exibe Card simples
              // Se houver múltiplos itens ou tiver número de nota, exibe ExpansionTile
              if (grupoNota.itens.length == 1 && grupoNota.numeroNota == null) {
                final despesa = grupoNota.itens.first;
                final etapaText = despesa.nomeEtapa ?? 'Sem Etapa';
                final fornecedorText =
                    despesa.nomeFornecedor ?? 'Sem Fornecedor';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFF1B3A5C,
                      ).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.monetization_on,
                        color: Color(0xFF1B3A5C),
                      ),
                    ),
                    title: Text(
                      despesa.descricao,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Data: $dataFormatada\n'
                      'Etapa: $etapaText \n'
                      'Fornecedor: $fornecedorText\n'
                      'Qtd: ${despesa.quantidade} x ${_currencyFormat.format(despesa.valorUnitario)}',
                    ),
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
                                  Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'excluir',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
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
              }

              // Renderiza um Card expansível quando a nota reúne múltiplos itens
              final etapaGrupoText = grupoNota.nomeEtapa ?? 'Sem Etapa';
              final fornecedorGrupoText =
                  grupoNota.nomeFornecedor ?? 'Sem Fornecedor';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(
                      0xFF1B3A5C,
                    ).withValues(alpha: 0.1),
                    child: const Icon(Icons.receipt, color: Color(0xFF1B3A5C)),
                  ),
                  title: Text(
                    grupoNota.identificador,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text.rich(
                    TextSpan(
                      children: [
                        // Linha do topo com tamanho normal do subtitle
                        TextSpan(
                          text:
                              'Data: $dataFormatada • ${grupoNota.itens.length} itens\n',
                          style: TextStyle(fontSize: 9),
                        ),
                        // Linha da Etapa e Fornecedor com fonte menor e cor suave
                        TextSpan(
                          text:
                              'Etapa: $etapaGrupoText\nFornecedor: $fornecedorGrupoText',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    _currencyFormat.format(grupoNota.valorTotalNota),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  children: grupoNota.itens.map((despesa) {
                    //final itemEtapa = despesa.nomeEtapa ?? 'Sem Etapa';
                    //final itemFornecedor = despesa.nomeFornecedor ?? 'Sem Fornecedor';

                    return Container(
                      color: Colors.grey.shade50,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          despesa.descricao,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          //'Etapa: $itemEtapa | Fornecedor: $itemFornecedor\n'
                          'Qtd: ${despesa.quantidade} x ${_currencyFormat.format(despesa.valorUnitario)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currencyFormat.format(despesa.valorTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (opcao) {
                                if (opcao == 'editar') _editarDespesa(despesa);
                                if (opcao == 'excluir') {
                                  _confirmarExclusao(despesa);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'excluir',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
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
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
