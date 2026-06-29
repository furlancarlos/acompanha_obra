// screens/cadastro_orcamento.dart
// Arquivo de definição da tela de cadastro de orçamento.
//============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/orcamento_dao.dart';
import '../models/orcamento.dart';

class CadastroOrcamentoPage extends StatefulWidget {
  final Orcamento? orcamento;
  const CadastroOrcamentoPage({super.key, this.orcamento});

  @override
  State<CadastroOrcamentoPage> createState() => _CadastroOrcamentoPageState();
}

class _CadastroOrcamentoPageState extends State<CadastroOrcamentoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _isLoading = false;

  final _orcamentoDAO = OrcamentoDAO();

  // Formatador de moeda
  //final _currencyFormat = NumberFormat.currency(
  //  locale: 'pt_BR',
  //  symbol: 'R\$ ',
  //);

  @override
  void initState() {
    super.initState();
    _preencherCampos();
  }

  void _preencherCampos() {
    if (widget.orcamento != null) {
      _nomeController.text = widget.orcamento!.nome;
      _descricaoController.text = widget.orcamento!.descricao ?? '';
      _valorController.text = widget.orcamento!.valorTotal.toStringAsFixed(2);
      _dataInicio = DateTime.parse(widget.orcamento!.dataInicio);
      if (widget.orcamento!.dataFim != null) {
        _dataFim = DateTime.parse(widget.orcamento!.dataFim!);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verifica se já existe um orçamento com o mesmo nome
      final existe = await _orcamentoDAO.existsByNome(
        _nomeController.text.trim(),
      );

      if (!mounted) return;

      if (existe && widget.orcamento == null) {
        _mostrarMensagem('Já existe um orçamento com este nome!', isErro: true);
        setState(() => _isLoading = false);
        return;
      }

      final valor =
          double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0;

      final orcamento = Orcamento(
        id: widget.orcamento?.id,
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        valorTotal: valor,
        dataInicio: _dataInicio.toIso8601String().split('T').first,
        dataFim: _dataFim?.toIso8601String().split('T').first,
      );

      if (widget.orcamento == null) {
        await _orcamentoDAO.insert(orcamento);
        _mostrarMensagem('Orçamento cadastrado com sucesso!');
      } else {
        await _orcamentoDAO.update(orcamento);
        _mostrarMensagem('Orçamento atualizado com sucesso!');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarMensagem('Erro ao salvar: $e', isErro: true);
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _selecionarDataInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataInicio = picked);
    }
  }

  Future<void> _selecionarDataFim() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio,
      firstDate: _dataInicio,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataFim = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditando = widget.orcamento != null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Orçamento' : 'Novo Orçamento'),
        backgroundColor: const Color(0xFF1B3A5C),
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
                        // Campo: Nome do Orçamento
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Orçamento',
                            hintText: 'Ex: Obra Principal, Reforma Quartos',
                            prefixIcon: Icon(Icons.assignment),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome do orçamento';
                            }
                            if (value.trim().length < 3) {
                              return 'O nome deve ter pelo menos 3 caracteres';
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
                            hintText: 'Ex: Orçamento para construção da casa',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          onFieldSubmitted: (_) => _salvar(),
                        ),

                        const SizedBox(height: 16),

                        // Campo: Valor Total
                        TextFormField(
                          controller: _valorController,
                          decoration: const InputDecoration(
                            labelText: 'Valor Total (R\$)',
                            hintText: 'Ex: 100000.00',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o valor total';
                            }
                            final valor = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (valor == null) {
                              return 'Digite um valor válido';
                            }
                            if (valor <= 0) {
                              return 'O valor deve ser maior que zero';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _salvar(),
                        ),

                        const SizedBox(height: 16),

                        // Campo: Data de Início
                        InkWell(
                          onTap: _selecionarDataInicio,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data de Início',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateFormat.format(_dataInicio)),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Campo: Data de Fim (opcional)
                        InkWell(
                          onTap: _selecionarDataFim,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data de Fim (opcional)',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dataFim != null
                                      ? dateFormat.format(_dataFim!)
                                      : 'Selecione uma data',
                                  style: TextStyle(
                                    color: _dataFim != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
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
                  const Center(child: CircularProgressIndicator()),
                ],

                const SizedBox(height: 16),

                // Texto informativo
                Text(
                  isEditando
                      ? '🔄 Editando orçamento existente'
                      : '💡 Cadastre um novo orçamento para sua obra',
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
