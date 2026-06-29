// cadastro_fornecedor.dart
// Arquivo de definição da tela de cadastro de fornecedor.
//============================================================================//

import 'package:flutter/material.dart';
import '../dao/fornecedor_dao.dart';
import '../models/fornecedor.dart';

class CadastroFornecedorPage extends StatefulWidget {
  final Fornecedor? fornecedor;
  const CadastroFornecedorPage({super.key, this.fornecedor});

  @override
  State<CadastroFornecedorPage> createState() => _CadastroFornecedorPageState();
}

class _CadastroFornecedorPageState extends State<CadastroFornecedorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _contatoController = TextEditingController();
  
  bool _isLoading = false;
  final _fornecedorDAO = FornecedorDAO();

  @override
  void initState() {
    super.initState();
    _preencherCampos();
  }

  void _preencherCampos() {
    if (widget.fornecedor != null) {
      _nomeController.text = widget.fornecedor!.nome;
      _enderecoController.text = widget.fornecedor!.endereco ?? '';
      _telefoneController.text = widget.fornecedor!.telefone ?? '';
      _contatoController.text = widget.fornecedor!.contato ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _contatoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verifica se já existe um fornecedor com o mesmo nome
      final existe = await _fornecedorDAO.existsByNome(_nomeController.text.trim());
      if (existe && widget.fornecedor == null) {
        _mostrarMensagem('Já existe um fornecedor com este nome!', isErro: true);
        setState(() => _isLoading = false);
        return;
      }

      final fornecedor = Fornecedor(
        id: widget.fornecedor?.id,
        nome: _nomeController.text.trim(),
        endereco: _enderecoController.text.trim().isEmpty 
            ? null 
            : _enderecoController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty 
            ? null 
            : _telefoneController.text.trim(),
        contato: _contatoController.text.trim().isEmpty 
            ? null 
            : _contatoController.text.trim(),
      );

      if (widget.fornecedor == null) {
        await _fornecedorDAO.insert(fornecedor);
        _mostrarMensagem('Fornecedor cadastrado com sucesso!');
      } else {
        await _fornecedorDAO.update(fornecedor);
        _mostrarMensagem('Fornecedor atualizado com sucesso!');
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
  Widget build(BuildContext context) {
    final isEditando = widget.fornecedor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Fornecedor' : 'Novo Fornecedor'),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo: Nome do Fornecedor
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Fornecedor',
                            hintText: 'Ex: Construtora ABC',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome do fornecedor';
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

                        // Campo: Endereço (opcional)
                        TextFormField(
                          controller: _enderecoController,
                          decoration: const InputDecoration(
                            labelText: 'Endereço (opcional)',
                            hintText: 'Ex: Rua das Flores, 123',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) => _salvar(),
                        ),
                        
                        const SizedBox(height: 16),

                        // Campo: Telefone (opcional)
                        TextFormField(
                          controller: _telefoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefone (opcional)',
                            hintText: 'Ex: (11) 99999-9999',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onFieldSubmitted: (_) => _salvar(),
                        ),
                        
                        const SizedBox(height: 16),

                        // Campo: Contato (opcional)
                        TextFormField(
                          controller: _contatoController,
                          decoration: const InputDecoration(
                            labelText: 'Contato (opcional)',
                            hintText: 'Ex: João Silva',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) => _salvar(),
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
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],

                const SizedBox(height: 16),

                // Texto informativo
                Text(
                  isEditando 
                    ? '🔄 Editando fornecedor existente' 
                    : '💡 Cadastre um novo fornecedor',
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
