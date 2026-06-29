// cadastro_despesa.dart
// Arquivo de definição da tela de cadastro de despesa.
//============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/despesa_dao.dart';
import '../dao/fornecedor_dao.dart';
import '../dao/produto_dao.dart';
import '../dao/etapa_dao.dart';
import '../models/despesa.dart';
import '../models/fornecedor.dart';
import '../models/produto.dart';
import '../models/etapa.dart';

// importando as telas auxiliares
import '../form/lista_fornecedor.dart';
import '../form/lista_produto.dart';

class CadastroDespesaPage extends StatefulWidget {
  final int? orcamentoId;
  final int? etapaId;

  const CadastroDespesaPage({super.key, this.orcamentoId, this.etapaId});

  @override
  State<CadastroDespesaPage> createState() => _CadastroDespesaPageState();
}

class _CadastroDespesaPageState extends State<CadastroDespesaPage> {
  final _formKey = GlobalKey<FormState>();

  // Variáveis para os dropdowns
  Fornecedor? _selectedFornecedor;
  Produto? _selectedProduto;
  Etapa? _selectedEtapa;

  // Listas para popular os dropdowns
  List<Fornecedor> _fornecedores = [];
  List<Produto> _produtos = [];
  List<Etapa> _etapas = [];
  bool _dadosCarregados = false;

  // Controllers
  final _quantidadeController = TextEditingController();
  final _valorUnitarioController = TextEditingController();
  final _valorTotalController = TextEditingController();

  DateTime _data = DateTime.now();
  bool _isLoading = false;

  // DAOs
  final _fornecedorDAO = FornecedorDAO();
  final _produtoDAO = ProdutoDAO();
  final _despesaDAO = DespesaDAO();
  final _etapaDAO = EtapaDAO();

  // Formatadores
  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarEtapas();

    // Adiciona listeners para calcular o total automaticamente
    _quantidadeController.addListener(_calcularTotal);
    _valorUnitarioController.addListener(_calcularTotal);
  }

  Future<void> _carregarDados() async {
    try {
      final fornecedores = await _fornecedorDAO.getAll();
      final produtos = await _produtoDAO.getAll();

      setState(() {
        _fornecedores = fornecedores;
        _produtos = produtos;
        _dadosCarregados = true;
      });
    } catch (e) {
      setState(() => _dadosCarregados = true);
      _mostrarMensagem('Erro ao carregar dados: $e', isErro: true);
    }
  }

  Future<void> _carregarEtapas() async {
    if (widget.orcamentoId != null) {
      final etapas = await _etapaDAO.getByOrcamento(widget.orcamentoId!);
      setState(() {
        _etapas = etapas;
        // Se veio com etapaId pré-selecionado, encontra na lista
        if (widget.etapaId != null) {
          try {
            _selectedEtapa = _etapas.firstWhere((e) => e.id == widget.etapaId);
          } catch (e) {
            // Se não encontrar, pega o primeiro ou null
            _selectedEtapa = _etapas.isNotEmpty ? _etapas.first : null;
          }
        }
      });
    }
  }

  Future<void> _atualizarDados() async {
    await _carregarDados();
  }

  void _calcularTotal() {
    final quantidade =
        double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 0;
    final valorUnitario =
        double.tryParse(
          _valorUnitarioController.text
              .replaceAll('R\$ ', '')
              .replaceAll('.', '')
              .replaceAll(',', '.'),
        ) ??
        0;

    final valorTotal = quantidade * valorUnitario;

    // Atualiza o campo de valor total com formatação
    if (valorTotal > 0) {
      _valorTotalController.text = _currencyFormat.format(valorTotal);
    } else {
      _valorTotalController.text = '';
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

  // 🔧 MÉTODO PARA CALCULAR STATUS (MOVIDO PARA FORA DO _salvarDespesa)
  String _calcularStatus(double progresso) {
    if (progresso >= 1.0) return 'Concluído';
    if (progresso >= 0.7) return 'Em Andamento';
    if (progresso >= 0.3) return 'Em Andamento';
    if (progresso > 0) return 'Iniciado';
    return 'Pendente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Despesa'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_dadosCarregados
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                              // Dropdown Fornecedor
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<Fornecedor>(
                                      decoration: const InputDecoration(
                                        labelText: 'Fornecedor',
                                        hintText: 'Selecione um fornecedor',
                                        prefixIcon: Icon(Icons.business),
                                        border: OutlineInputBorder(),
                                      ),
                                      initialValue: _selectedFornecedor,
                                      isExpanded: true,
                                      items: _fornecedores.map((
                                        Fornecedor fornecedor,
                                      ) {
                                        return DropdownMenuItem<Fornecedor>(
                                          value: fornecedor,
                                          child: Text(fornecedor.nome),
                                        );
                                      }).toList(),
                                      onChanged: (Fornecedor? newValue) {
                                        setState(() {
                                          _selectedFornecedor = newValue;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Selecione um fornecedor';
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
                                    tooltip: 'Cadastrar novo fornecedor',
                                    onPressed: () async {
                                      final resultado = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ListaFornecedorPage(),
                                        ),
                                      );
                                      if (resultado == true) {
                                        await _atualizarDados();
                                      }
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Dropdown Produto
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<Produto>(
                                      decoration: const InputDecoration(
                                        labelText: 'Produto',
                                        hintText: 'Selecione um produto',
                                        prefixIcon: Icon(
                                          Icons.production_quantity_limits,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      initialValue: _selectedProduto,
                                      isExpanded: true,
                                      items: _produtos.map((Produto produto) {
                                        return DropdownMenuItem<Produto>(
                                          value: produto,
                                          child: Text(produto.nome),
                                        );
                                      }).toList(),
                                      onChanged: (Produto? newValue) {
                                        setState(() {
                                          _selectedProduto = newValue;
                                          // Limpa os campos quando muda o produto
                                          _quantidadeController.clear();
                                          _valorUnitarioController.clear();
                                          _valorTotalController.clear();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Selecione um produto';
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
                                    tooltip: 'Cadastrar novo produto',
                                    onPressed: () async {
                                      final resultado = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ListaProdutoPage(),
                                        ),
                                      );
                                      if (resultado == true) {
                                        await _atualizarDados();
                                      }
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Campo Unidade (READ-ONLY - preenchido automaticamente)
                              TextFormField(
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'Unidade de Medida',
                                  hintText:
                                      _selectedProduto?.unidade?.toString() ??
                                      'Selecione um produto primeiro',
                                  prefixIcon: const Icon(Icons.straighten),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                initialValue:
                                    _selectedProduto?.unidade?.toString() ?? '',
                              ),

                              const SizedBox(height: 16),

                              // Dropdown Etapa (opcional)
                              if (widget.orcamentoId != null) ...[
                                DropdownButtonFormField<Etapa>(
                                  decoration: const InputDecoration(
                                    labelText: 'Etapa (opcional)',
                                    hintText: 'Selecione uma etapa',
                                    prefixIcon: Icon(Icons.timeline),
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: _selectedEtapa,
                                  isExpanded: true,
                                  items: _etapas.map((Etapa etapa) {
                                    return DropdownMenuItem<Etapa>(
                                      value: etapa,
                                      child: Text(etapa.nome),
                                    );
                                  }).toList(),
                                  onChanged: (Etapa? newValue) {
                                    setState(() {
                                      _selectedEtapa = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Campo Quantidade
                              TextFormField(
                                controller: _quantidadeController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade',
                                  hintText: 'Digite a quantidade',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a quantidade';
                                  }
                                  if (double.tryParse(
                                        value.replaceAll(',', '.'),
                                      ) ==
                                      null) {
                                    return 'Digite um número válido';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _salvarDespesa(),
                              ),

                              const SizedBox(height: 16),

                              // Campo Valor Unitário (COM MÁSCARA MONETÁRIA)
                              TextFormField(
                                controller: _valorUnitarioController,
                                decoration: const InputDecoration(
                                  labelText: 'Valor Unitário (R\$)',
                                  hintText: 'Digite o valor unitário',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe o valor unitário';
                                  }
                                  final valorLimpo = value
                                      .replaceAll('R\$ ', '')
                                      .replaceAll('.', '')
                                      .replaceAll(',', '.');
                                  if (double.tryParse(valorLimpo) == null) {
                                    return 'Digite um valor válido';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _salvarDespesa(),
                              ),

                              const SizedBox(height: 16),

                              // Campo Valor Total (READ-ONLY - calculado automaticamente)
                              TextFormField(
                                controller: _valorTotalController,
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'Valor Total (R\$)',
                                  hintText: 'Calculado automaticamente',
                                  prefixIcon: Icon(
                                    Icons.calculate,
                                    color: Colors.green,
                                  ),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.green.shade50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Card da Data
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Data: ${DateFormat('dd/MM/yyyy').format(_data)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _data,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => _data = picked);
                                  }
                                },
                                icon: const Icon(Icons.edit_calendar),
                                label: const Text('Alterar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
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
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancelar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _salvarDespesa,
                                icon: const Icon(Icons.save),
                                label: const Text('Salvar Despesa'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                        '💡 A unidade de medida será carregada automaticamente do produto selecionado',
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

  Future<void> _salvarDespesa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantidade =
          double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 0;

      final valorUnitario =
          double.tryParse(
            _valorUnitarioController.text
                .replaceAll('R\$ ', '')
                .replaceAll('.', '')
                .replaceAll(',', '.'),
          ) ??
          0;

      final valorTotal = quantidade * valorUnitario;

      final despesa = Despesa(
        descricao: _selectedProduto?.nome ?? 'Despesa',
        fornecedorId: _selectedFornecedor?.id,
        produtoId: _selectedProduto?.id,
        unidadeId: _selectedProduto?.unidadeId,
        orcamentoId: widget.orcamentoId,
        etapaId: _selectedEtapa?.id,
        data: _data.toIso8601String(),
        quantidade: quantidade,
        valorUnitario: valorUnitario,
        valorTotal: valorTotal,
      );

      await _despesaDAO.insert(despesa);

      // 🔧 RECALCULA O PROGRESSO DA ETAPA
      if (despesa.etapaId != null) {
        final progresso = await _etapaDAO.calcularProgressoEtapa(
          despesa.etapaId!,
        );
        
        // Busca a etapa completa para obter o nome
        final etapaCompleta = await _etapaDAO.getById(despesa.etapaId!);
        
        if (etapaCompleta != null) {
          final etapaAtualizada = Etapa(
            id: etapaCompleta.id,
            nome: etapaCompleta.nome,
            descricao: etapaCompleta.descricao,
            orcamentoId: etapaCompleta.orcamentoId,
            progresso: progresso,
            status: _calcularStatus(progresso),
            dataInicio: etapaCompleta.dataInicio,
            dataFim: etapaCompleta.dataFim,
            valorOrcado: etapaCompleta.valorOrcado,
          );
          await _etapaDAO.update(etapaAtualizada);
        }
      }

      _mostrarMensagem('Despesa salva com sucesso!');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao salvar: $e', isErro: true);
    }
  }

  @override
  void dispose() {
    _quantidadeController.removeListener(_calcularTotal);
    _valorUnitarioController.removeListener(_calcularTotal);
    _quantidadeController.dispose();
    _valorUnitarioController.dispose();
    _valorTotalController.dispose();
    super.dispose();
  }
}
