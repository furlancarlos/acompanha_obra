// lib/screens/abas/aba_historico_despesas.dart
// Histórico dos itens lançados em cada etapa do orçamento.
// ========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../dao/despesa_dao.dart';
import '../../dao/etapa_dao.dart';
import '../../models/despesa.dart';
import '../../models/etapa.dart';
import '../cadastro_despesa.dart';

class _EtapaDespesasGroup {
  final int? etapaId;
  final String nome;
  final double valorOrcado;
  final List<Despesa> despesas;

  const _EtapaDespesasGroup({
    required this.etapaId,
    required this.nome,
    required this.valorOrcado,
    required this.despesas,
  });

  double get total => despesas.fold(0, (soma, despesa) => soma + despesa.valorTotal);
}

class AbaHistoricoEtapas extends StatefulWidget {
  final int orcamentoId;

  const AbaHistoricoEtapas({super.key, required this.orcamentoId});

  @override
  State<AbaHistoricoEtapas> createState() => _AbaHistoricoEtapasState();
}

class _AbaHistoricoEtapasState extends State<AbaHistoricoEtapas> {
  final _despesaDAO = DespesaDAO();
  final _etapaDAO = EtapaDAO();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
  final _percentFormat = NumberFormat.percentPattern('pt_BR')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;
  late Future<List<Despesa>> _despesasFuture;
  late Future<List<Etapa>> _etapasFuture;
  late Future<Map<String, double>> _resumoFuture;

  @override
  void initState() {
    super.initState();
    _carregarDespesas();
  }

  void _carregarDespesas() {
    _despesasFuture = _despesaDAO.getByOrcamento(widget.orcamentoId);
    _etapasFuture = _etapaDAO.getByOrcamento(widget.orcamentoId);
    _resumoFuture = _carregarResumo();
  }

  Future<Map<String, double>> _carregarResumo() async {
    final valores = await Future.wait<double>([
      _etapaDAO.getTotalValorOrcado(widget.orcamentoId),
      _despesaDAO.getTotalGastoPorOrcamento(widget.orcamentoId),
    ]);
    return {'orcado': valores[0], 'executado': valores[1]};
  }

  void _recarregarDespesas() {
    setState(_carregarDespesas);
  }

  List<_EtapaDespesasGroup> _agruparPorEtapa(
    List<Despesa> despesas,
    List<Etapa> etapas,
  ) {
    final grupos = <String, List<Despesa>>{};
    for (final despesa in despesas) {
      final chave = despesa.etapaId == null
          ? 'sem_etapa'
          : 'etapa_${despesa.etapaId}';
      grupos.putIfAbsent(chave, () => []).add(despesa);
    }

    final resultado = grupos.entries.map((entry) {
      final itens = entry.value..sort((a, b) => b.data.compareTo(a.data));
      final etapaId = itens.first.etapaId;
      var valorOrcado = 0.0;
      for (final etapa in etapas) {
        if (etapa.id == etapaId) {
          valorOrcado = etapa.valorOrcado ?? 0.0;
          break;
        }
      }
      return _EtapaDespesasGroup(
        etapaId: etapaId,
        nome: itens.first.nomeEtapa ?? 'Sem etapa',
        valorOrcado: valorOrcado,
        despesas: itens,
      );
    }).toList();
    resultado.sort((a, b) {
      final percentualA = a.valorOrcado > 0 ? a.total / a.valorOrcado : 0.0;
      final percentualB = b.valorOrcado > 0 ? b.total / b.valorOrcado : 0.0;
      final comparacaoPercentual = percentualA.compareTo(percentualB);
      if (comparacaoPercentual != 0) return comparacaoPercentual;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return resultado;
  }

  Future<void> _editarDespesa(Despesa despesa) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroDespesaPage(
          orcamentoId: widget.orcamentoId,
          etapaId: despesa.etapaId,
          despesaAntiga: despesa,
        ),
      ),
    );
    if (resultado == true) _recarregarDespesas();
  }

  Future<void> _confirmarExclusao(Despesa despesa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: Text(
          'Deseja excluir "${despesa.descricao}" no valor de '
          '${_currencyFormat.format(despesa.valorTotal)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true || despesa.id == null) return;
    await _despesaDAO.delete(despesa.id!);
    if (!mounted) return;
    _recarregarDespesas();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lançamento removido com sucesso.')),
    );
  }

  String _formatarData(String data) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(data));
    } catch (_) {
      return data;
    }
  }

  Widget _menuDespesa(Despesa despesa) => PopupMenuButton<String>(
    onSelected: (opcao) {
      if (opcao == 'editar') _editarDespesa(despesa);
      if (opcao == 'excluir') _confirmarExclusao(despesa);
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'editar', child: Text('Editar')),
      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
    ],
  );

  Widget _itemDespesa(Despesa despesa) => ListTile(
    dense: true,
    title: Text(despesa.descricao, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      '${_formatarData(despesa.data)}'
      '${despesa.nomeFornecedor == null ? '' : ' • ${despesa.nomeFornecedor}'}\n'
      '${despesa.numeroNota == null || despesa.numeroNota!.trim().isEmpty ? '' : 'NF ${despesa.numeroNota} • '}'
      'Qtd: ${despesa.quantidade} × ${_currencyFormat.format(despesa.valorUnitario)}',
    ),
    isThreeLine: true,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_currencyFormat.format(despesa.valorTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
        _menuDespesa(despesa),
      ],
    ),
  );

  Widget _totalizador() => FutureBuilder<Map<String, double>>(
    future: _resumoFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (snapshot.hasError) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erro ao carregar totais: ${snapshot.error}'),
          ),
        );
      }

      final resumo = snapshot.data!;
      final orcado = resumo['orcado'] ?? 0;
      final executado = resumo['executado'] ?? 0;
      final percentual = orcado > 0 ? executado / orcado : 0.0;

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo do orçamento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _linhaTotal('Total orçado', orcado, Colors.blueGrey.shade800),
              const SizedBox(height: 8),
              _linhaTotal('Total executado', executado, Colors.red.shade700),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('% executado'),
                  Text(
                    _percentFormat.format(percentual),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _linhaTotal(String titulo, double valor, Color cor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(titulo),
      Text(
        _currencyFormat.format(valor),
        style: TextStyle(fontWeight: FontWeight.bold, color: cor),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Despesa>>(
      future: _despesasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar histórico: ${snapshot.error}'));
        }
        final despesas = snapshot.data ?? [];
        if (despesas.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _totalizador(),
              SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'Nenhum item lançado neste orçamento.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),
              ),
            ],
          );
        }

        return FutureBuilder<List<Etapa>>(
          future: _etapasFuture,
          builder: (context, etapasSnapshot) {
            if (etapasSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (etapasSnapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar etapas: ${etapasSnapshot.error}'),
              );
            }

            final grupos = _agruparPorEtapa(despesas, etapasSnapshot.data ?? []);
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _totalizador(),
                ...grupos.map((grupo) {
                  final percentual = grupo.valorOrcado > 0
                      ? grupo.total / grupo.valorOrcado
                      : 0.0;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.construction,
                        color: Color(0xFF1B3A5C),
                      ),
                      title: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: '${grupo.nome} - '),
                            TextSpan(
                              text: _percentFormat.format(percentual),
                              style: TextStyle(
                                color: percentual > 1
                                    ? Colors.red.shade700
                                    : percentual == 1
                                    ? Colors.green.shade700
                                    : const Color.fromARGB(255, 230, 25, 223),
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Text('${grupo.despesas.length} itens lançados'),
                      trailing: Text(
                        _currencyFormat.format(grupo.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      children: grupo.despesas
                          .map((despesa) => _itemDespesa(despesa))
                          .toList(),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
