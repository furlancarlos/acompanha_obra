// cadastro_produto.dart
// Arquivo de definição da tela de cadastro de produto.
//============================================================================//

import 'package:flutter/material.dart';
import '../dao/produto_dao.dart';
import '../dao/unidade_dao.dart';
import '../models/produto.dart';
import '../models/unidade.dart';
import 'cadastro_unidade.dart';

class CadastroProdutoPage extends StatefulWidget {
  final Produto? produto;
  const CadastroProdutoPage({super.key, this.produto});

  @override
  State<CadastroProdutoPage> createState() => _CadastroProdutoPageState();
}

class _CadastroProdutoPageState extends State<CadastroProdutoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();

  Unidade? _selectedUnidade;
  List<Unidade> _unidades = [];
  bool _isLoading = false;
  bool _isLoadingUnidades = true;

  final _produtoDAO = ProdutoDAO();
  final _unidadeDAO = UnidadeDAO();

  @override
  void initState() {
    super.initState();
    _preencherCampos();
    _carregarUnidades();
  }

  void _preencherCampos() {
    if (widget.produto != null) {
      _nomeController.text = widget.produto!.nome;
      _descricaoController.text = widget.produto!.descricao ?? '';
      _selectedUnidade = widget.produto!.unidade;
    }
  }

  Future<void> _carregarUnidades() async {
    setState(() => _isLoadingUnidades = true);
    try {
      final unidades = await _unidadeDAO.getAll();
      setState(() {
        _unidades = unidades;
        _isLoadingUnidades = false;

        // Se estiver editando, tenta selecionar a unidade do produto
        if (widget.produto != null &&
            widget.produto!.unidadeId != null &&
            _unidades.isNotEmpty) {
          // Encontra a unidade ou usa a primeira
          final unidadeEncontrada = _unidades.firstWhere(
            (u) => u.id == widget.produto!.unidadeId,
            orElse: () => _unidades.first,
          );
          _selectedUnidade = unidadeEncontrada;
        }
      });
    } catch (e) {
      setState(() => _isLoadingUnidades = false);
      _mostrarMensagem('Erro ao carregar unidades: $e', isErro: true);
    }
  }

  Future<void> _atualizarUnidades() async {
    await _carregarUnidades();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verifica se já existe um produto com o mesmo nome
      final existe = await _produtoDAO.existsByNome(
        _nomeController.text.trim(),
      );
      if (existe && widget.produto == null) {
        _mostrarMensagem('Já existe um produto com este nome!', isErro: true);
        setState(() => _isLoading = false);
        return;
      }

      final produto = Produto(
        id: widget.produto?.id,
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        unidadeId: _selectedUnidade?.id,
        unidade: _selectedUnidade,
      );

      if (widget.produto == null) {
        await _produtoDAO.insert(produto);
        _mostrarMensagem('Produto cadastrado com sucesso!');
      } else {
        await _produtoDAO.update(produto);
        _mostrarMensagem('Produto atualizado com sucesso!');
      }

      Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensagem('Erro ao salvar: $e', isErro: true);
      setState(() => _isLoading = false);
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

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditando = widget.produto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Produto' : 'Novo Produto'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card com os campos
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Campo: Nome do Produto
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Produto',
                            hintText: 'Ex: Cimento, Areia, Tijolo',
                            prefixIcon: Icon(Icons.production_quantity_limits),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome do produto';
                            }
                            if (value.trim().length < 2) {
                              return 'O nome deve ter pelo menos 2 caracteres';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) => _salvar(),
                        ),
          
                        const SizedBox(height: 16),
          
                        // Campo: Descrição (opcional)
                        TextFormField(
                          controller: _descricaoController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                            hintText: 'Ex: Cimento CP-32, Areia fina',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          onFieldSubmitted: (_) => _salvar(),
                        ),
          
                        const SizedBox(height: 16),
          
                        // Dropdown: Unidade de Medida (Obrigatório)
                        if (_isLoadingUnidades)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<Unidade>(
                                  decoration: const InputDecoration(
                                    labelText: 'Unidade de Medida',
                                    hintText: 'Selecione a unidade',
                                    prefixIcon: Icon(Icons.straighten),
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedUnidade,
                                  isExpanded: true,
                                  items: _unidades.map((Unidade unidade) {
                                    return DropdownMenuItem<Unidade>(
                                      value: unidade,
                                      child: Text(unidade.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (Unidade? newValue) {
                                    setState(() {
                                      _selectedUnidade = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Selecione uma unidade de medida';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                tooltip: 'Cadastrar nova unidade',
                                onPressed: () async {
                                  final resultado = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CadastroUnidadePage(),
                                    ),
                                  );
                                  if (resultado == true) {
                                    await _atualizarUnidades();
                                  }
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
          
                const SizedBox(height: 24),
          
                // Botões de ação
                if (!_isLoading) ...[
                  Row(
                    children: [
                      // Botão Cancelar
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botão Salvar
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _salvar,
                          icon: Icon(isEditando ? Icons.edit : Icons.save),
                          label: Text(isEditando ? 'Atualizar' : 'Salvar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Indicador de carregamento
                  const Center(child: CircularProgressIndicator()),
                ],
          
                const SizedBox(height: 16),
          
                // Texto informativo
                Text(
                  isEditando
                      ? '🔄 Editando produto existente'
                      : '💡 Cadastre um novo produto com sua unidade de medida',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
