// lista_fornecedores.dart
// Arquivo de definição da tela de listagem de fornecedores.
// Layout alinhado com o layout do app
//============================================================================//

import 'package:flutter/material.dart';
import '../dao/fornecedor_dao.dart';
import '../models/fornecedor.dart';
import '../screens/cadastro_fornecedor.dart';

class ListaFornecedorPage extends StatefulWidget {
  const ListaFornecedorPage({super.key});

  @override
  State<ListaFornecedorPage> createState() => _ListaFornecedorPageState();
}

class _ListaFornecedorPageState extends State<ListaFornecedorPage> {
  List<Fornecedor> _fornecedores = [];
  bool _isLoading = true;
  final _fornecedorDAO = FornecedorDAO();

  @override
  void initState() {
    super.initState();
    _carregarFornecedores();
  }

  Future<void> _carregarFornecedores() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _fornecedorDAO.getAll();
      setState(() {
        _fornecedores = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar fornecedores: $e', isErro: true);
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

  Future<void> _confirmarExclusao(Fornecedor fornecedor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o fornecedor "${fornecedor.nome}"?'),
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
        await _fornecedorDAO.delete(fornecedor.id!);
        _mostrarMensagem('Fornecedor excluído com sucesso!');
        _carregarFornecedores();
      } catch (e) {
        _mostrarMensagem('Erro ao excluir: $e', isErro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fornecedores.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _fornecedores.length,
                  itemBuilder: (context, index) {
                    final fornecedor = _fornecedores[index];
                    return _buildFornecedorCard(fornecedor);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroFornecedorPage()),
          );
          if (resultado == true) {
            _carregarFornecedores();
          }
        },
        backgroundColor: Colors.green,
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
            Icons.business_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum fornecedor cadastrado',
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

  Widget _buildFornecedorCard(Fornecedor fornecedor) {
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
                // Ícone do fornecedor
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Informações do fornecedor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fornecedor.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (fornecedor.contato != null && fornecedor.contato!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fornecedor.contato!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      if (fornecedor.telefone != null && fornecedor.telefone!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fornecedor.telefone!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      if (fornecedor.endereco != null && fornecedor.endereco!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fornecedor.endereco!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Botões de ação
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue.shade700),
                      tooltip: 'Editar',
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CadastroFornecedorPage(fornecedor: fornecedor),
                          ),
                        );
                        if (resultado == true) {
                          _carregarFornecedores();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade700),
                      tooltip: 'Excluir',
                      onPressed: () => _confirmarExclusao(fornecedor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
