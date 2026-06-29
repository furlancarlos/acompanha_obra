// cadastro_unidade.dart
// Arquivo de definição da tela de cadastro de unidade.
//============================================================================//

import 'package:flutter/material.dart';
import '../dao/unidade_dao.dart';
import '../models/unidade.dart';

class CadastroUnidadePage extends StatefulWidget {
  final Unidade? unidade;
  const CadastroUnidadePage({super.key, this.unidade});

  @override
  State<CadastroUnidadePage> createState() => _CadastroUnidadePageState();
}

class _CadastroUnidadePageState extends State<CadastroUnidadePage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _siglaController = TextEditingController();
  
  bool _isLoading = false;
  final _unidadeDAO = UnidadeDAO();

  @override
  void initState() {
    super.initState();
    _preencherCampos();
  }

  void _preencherCampos() {
    if (widget.unidade != null) {
      _descricaoController.text = widget.unidade!.descricao;
      _siglaController.text = widget.unidade!.sigla ?? '';
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _siglaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verifica se já existe uma unidade com o mesmo nome (evita duplicidade)
      final existe = await _unidadeDAO.existsByDescricao(_descricaoController.text);
      if (existe && widget.unidade == null) {
        _mostrarMensagem(
          'Já existe uma unidade com este nome!',
          isErro: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      final unidade = Unidade(
        id: widget.unidade?.id,
        descricao: _descricaoController.text.trim(),
        sigla: _siglaController.text.trim().toUpperCase(),
      );

      if (widget.unidade == null) {
        await _unidadeDAO.insert(unidade);
        _mostrarMensagem('Unidade cadastrada com sucesso!');
      } else {
        await _unidadeDAO.update(unidade);
        _mostrarMensagem('Unidade atualizada com sucesso!');
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
    final isEditando = widget.unidade != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Unidade' : 'Nova Unidade'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      // Campo: Descrição (Nome da Unidade)
                      TextFormField(
                        controller: _descricaoController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Unidade',
                          hintText: 'Ex: Metro, Quilograma, Litro',
                          prefixIcon: Icon(Icons.abc),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome da unidade';
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

                      // Campo: Sigla (opcional)
                      TextFormField(
                        controller: _siglaController,
                        decoration: const InputDecoration(
                          labelText: 'Sigla (opcional)',
                          hintText: 'Ex: m, kg, L, un',
                          prefixIcon: Icon(Icons.short_text),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 10,
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
                  ? '🔄 Editando unidade existente' 
                  : '💡 Cadastre uma nova unidade de medida',
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
    );
  }
}
