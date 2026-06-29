// form/lista_etapa.dart
// Arquivo de definição da tela de listagem de etapas.
// Seu acionamento é feito pelo botão "Ver Todos" no card de orçamento.
//============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/etapa_dao.dart';
import '../models/etapa.dart';
import '../screens/cadastro_etapa.dart';

class ListaEtapaPage extends StatefulWidget {
  final int? orcamentoId;
  const ListaEtapaPage({super.key, this.orcamentoId});

  @override
  State<ListaEtapaPage> createState() => _ListaEtapaPageState();
}

class _ListaEtapaPageState extends State<ListaEtapaPage> {
  List<Etapa> _etapas = [];
  bool _isLoading = true;
  final _etapaDAO = EtapaDAO();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  @override
  void initState() {
    super.initState();
    _carregarEtapas();
  }

  Future<void> _carregarEtapas() async {
    setState(() => _isLoading = true);
    try {
      List<Etapa> lista;
      if (widget.orcamentoId != null) {
        lista = await _etapaDAO.getByOrcamento(widget.orcamentoId!);
      } else {
        lista = await _etapaDAO.getAll();
      }
      setState(() {
        _etapas = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar etapas: $e', isErro: true);
    }
  }

  void _mostrarMensagem(String mensagem, {bool isErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmarExclusao(Etapa etapa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a etapa "${etapa.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _etapaDAO.delete(etapa.id!);
        _mostrarMensagem('Etapa excluída com sucesso!');
        _carregarEtapas();
      } catch (e) {
        _mostrarMensagem('Erro ao excluir: $e', isErro: true);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Concluído':
        return Colors.green;
      case 'Em Andamento':
        return const Color(0xFFE8751A);
      case 'Pendente':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.orcamentoId != null 
              ? 'Etapas do Orçamento' 
              : 'Todas as Etapas',
        ),
        backgroundColor: const Color(0xFF1B3A5C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEtapas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _etapas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _etapas.length,
                  itemBuilder: (context, index) {
                    final etapa = _etapas[index];
                    return _buildEtapaCard(etapa);
                  },
                ),
      floatingActionButton: widget.orcamentoId != null
          ? FloatingActionButton(
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CadastroEtapaPage(
                      orcamentoId: widget.orcamentoId,
                    ),
                  ),
                );
                if (resultado == true) {
                  _carregarEtapas();
                }
              },
              backgroundColor: const Color(0xFFE8751A),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma etapa cadastrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.orcamentoId != null
                ? 'Clique no botão + para adicionar'
                : 'Selecione um orçamento para gerenciar suas etapas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapaCard(Etapa etapa) {
    final statusColor = _getStatusColor(etapa.status);
    final progresso = etapa.progresso;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              etapa.nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // ← STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              etapa.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // ← DESCRIÇÃO
                      if (etapa.descricao != null && etapa.descricao!.isNotEmpty)
                        Text(
                          etapa.descricao!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // ← DATAS
                      Row(
                        children: [
                          if (etapa.dataInicio != null) ...[
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _dateFormat.format(DateTime.parse(etapa.dataInicio!)),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (etapa.dataFim != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dateFormat.format(DateTime.parse(etapa.dataFim!)),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (etapa.dataInicio == null && etapa.dataFim == null)
                            Text(
                              'Sem datas definidas',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // ← BARRA DE PROGRESSO + VALOR ORÇADO
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ← PROGRESSO
                          Row(
                            children: [
                              Text(
                                'Progresso',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progresso * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          // ← VALOR ORÇADO (NOVO)
                          if (etapa.valorOrcado != null && etapa.valorOrcado! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3A5C).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 14,
                                    color: const Color(0xFF1B3A5C),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _currencyFormat.format(etapa.valorOrcado),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1B3A5C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progresso,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ← BOTÕES DE AÇÃO
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
                  tooltip: 'Editar',
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CadastroEtapaPage(etapa: etapa),
                      ),
                    );
                    if (resultado == true) {
                      _carregarEtapas();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: Colors.red.shade700),
                  tooltip: 'Excluir',
                  onPressed: () => _confirmarExclusao(etapa),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
