// form/lista_orcamento.dart
// Arquivo de definição da tela de listagem de orçamentos.
//============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/orcamento_dao.dart';
import '../models/orcamento.dart';
import '../screens/cadastro_orcamento.dart';
import '../form/lista_etapa.dart';  // ← ADICIONAR

class ListaOrcamentoPage extends StatefulWidget {
  const ListaOrcamentoPage({super.key});

  @override
  State<ListaOrcamentoPage> createState() => _ListaOrcamentoPageState();
}

class _ListaOrcamentoPageState extends State<ListaOrcamentoPage> {
  List<Orcamento> _orcamentos = [];
  bool _isLoading = true;
  final _orcamentoDAO = OrcamentoDAO();

  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _carregarOrcamentos();
  }

  Future<void> _carregarOrcamentos() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _orcamentoDAO.getAll();
      setState(() {
        _orcamentos = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar orçamentos: $e', isErro: true);
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

  Future<void> _confirmarExclusao(Orcamento orcamento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o orçamento "${orcamento.nome}"?'),
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
        await _orcamentoDAO.delete(orcamento.id!);
        _mostrarMensagem('Orçamento excluído com sucesso!');
        _carregarOrcamentos();
      } catch (e) {
        _mostrarMensagem('Erro ao excluir: $e', isErro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        backgroundColor: const Color(0xFF1B3A5C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarOrcamentos,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orcamentos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orcamentos.length,
                  itemBuilder: (context, index) {
                    final orcamento = _orcamentos[index];
                    return _buildOrcamentoCard(orcamento);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroOrcamentoPage()),
          );
          if (resultado == true) {
            _carregarOrcamentos();
          }
        },
        backgroundColor: const Color(0xFFE8751A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_money_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum orçamento cadastrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no botão + para adicionar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrcamentoCard(Orcamento orcamento) {
    String status = 'Ativo';
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;

    final hoje = DateTime.now();
    final dataInicio = DateTime.parse(orcamento.dataInicio);
    final dataFim = orcamento.dataFim != null 
        ? DateTime.parse(orcamento.dataFim!) 
        : null;

    if (dataFim != null && hoje.isAfter(dataFim)) {
      status = 'Concluído';
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle_outline;
    } else if (hoje.isBefore(dataInicio)) {
      status = 'Planejado';
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    }

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
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A5C).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: const Color(0xFF1B3A5C),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orcamento.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (orcamento.descricao != null && orcamento.descricao!.isNotEmpty)
                        Text(
                          orcamento.descricao!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _dateFormat.format(dataInicio),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (dataFim != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dateFormat.format(dataFim),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(orcamento.valorTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3A5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ← BOTÃO ETAPAS (NOVO)
                TextButton.icon(
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListaEtapaPage(
                          orcamentoId: orcamento.id,
                        ),
                      ),
                    );
                    if (resultado == true) {
                      _carregarOrcamentos();
                    }
                  },
                  icon: Icon(Icons.list_alt, size: 18, color: Colors.orange.shade700),
                  label: Text(
                    'Etapas',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CadastroOrcamentoPage(orcamento: orcamento),
                      ),
                    );
                    if (resultado == true) {
                      _carregarOrcamentos();
                    }
                  },
                  icon: Icon(Icons.edit, size: 18, color: Colors.blue.shade700),
                  label: Text(
                    'Editar',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _confirmarExclusao(orcamento),
                  icon: Icon(Icons.delete, size: 18, color: Colors.red.shade700),
                  label: Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
