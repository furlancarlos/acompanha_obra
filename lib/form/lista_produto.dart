// lista_produto.dart
// Arquivo de definição da tela de listagem de produtos.  
// Layout alinhado com o layout do app
//============================================================================//

import 'package:flutter/material.dart';
import '../dao/produto_dao.dart';
import '../models/produto.dart';
import '../screens/cadastro_produto.dart';

class ListaProdutoPage extends StatefulWidget {
  const ListaProdutoPage({super.key});

  @override
  State<ListaProdutoPage> createState() => _ListaProdutoPageState();
}

class _ListaProdutoPageState extends State<ListaProdutoPage> {
  List<Produto> _produtos = [];
  bool _isLoading = true;
  final _produtoDAO = ProdutoDAO();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _produtoDAO.getAll();
      setState(() {
        _produtos = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar produtos: $e', isErro: true);
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

  Future<void> _confirmarExclusao(Produto produto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o produto "${produto.nome}"?'),
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
        await _produtoDAO.delete(produto.id!);
        _mostrarMensagem('Produto excluído com sucesso!');
        _carregarProdutos();
      } catch (e) {
        _mostrarMensagem('Erro ao excluir: $e', isErro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _produtos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _produtos.length,
                  itemBuilder: (context, index) {
                    final produto = _produtos[index];
                    return _buildProdutoCard(produto);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroProdutoPage()),
          );
          if (resultado == true) {
            _carregarProdutos();
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
            Icons.production_quantity_limits_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum produto cadastrado',
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

  Widget _buildProdutoCard(Produto produto) {
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
                // Ícone do produto
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.production_quantity_limits,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Informações do produto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (produto.descricao != null && produto.descricao!.isNotEmpty)
                        Text(
                          produto.descricao!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (produto.unidade != null)
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              produto.unidade!.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
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
                            builder: (_) => CadastroProdutoPage(produto: produto),
                          ),
                        );
                        if (resultado == true) {
                          _carregarProdutos();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade700),
                      tooltip: 'Excluir',
                      onPressed: () => _confirmarExclusao(produto),
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
