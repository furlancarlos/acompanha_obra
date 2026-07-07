// cadastro_despesa.dart
// Arquivo de definição da tela de cadastro de despesa (Suporta múltiplos itens e edição).
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
//import '../form/lista_fornecedor.dart';
//import '../form/lista_produto.dart';

// Classe auxiliar para gerenciar os itens adicionados dinamicamente na nota
class ItemDespesaTemporario {
  Produto produto;
  double quantidade;
  double valorUnitario;

  ItemDespesaTemporario({
    required this.produto,
    required this.quantidade,
    required this.valorUnitario,
  });

  double get valorTotal => quantidade * valorUnitario;
}

class CadastroDespesaPage extends StatefulWidget {
  final int? orcamentoId;
  final int? etapaId;
  final Despesa? despesaAntiga; // ✏️ Parâmetro para modo de edição

  const CadastroDespesaPage({
    super.key,
    this.orcamentoId,
    this.etapaId,
    this.despesaAntiga,
  });

  @override
  State<CadastroDespesaPage> createState() => _CadastroDespesaPageState();
}

class _CadastroDespesaPageState extends State<CadastroDespesaPage> {
  final _formKey = GlobalKey<FormState>();

  // Variáveis para os dropdowns
  Fornecedor? _selectedFornecedor;
  Produto? _selectedProduto;
  Etapa? _selectedEtapa;

  // Listas locais
  List<Fornecedor> _fornecedores = [];
  List<Produto> _produtos = [];
  List<Etapa> _etapas = [];
  bool _dadosCarregados = false;

  // Lista de itens adicionados nesta nota/despesa
  final List<ItemDespesaTemporario> _itensAdicionados = [];

  // Controllers para inclusão do item atual
  final _quantidadeController = TextEditingController();
  final _valorUnitarioController = TextEditingController();
  final _valorTotalController = TextEditingController();

  DateTime _data = DateTime.now();
  bool _isLoading = false;
  bool _isEdicao = false;

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
    _isEdicao = widget.despesaAntiga != null;
    _carregarDadosERefatorar();

    _quantidadeController.addListener(_calcularTotalItemAtual);
    _valorUnitarioController.addListener(_calcularTotalItemAtual);
  }

  Future<void> _carregarDadosERefatorar() async {
    try {
      final fornecedores = await _fornecedorDAO.getAll();
      final produtos = await _produtoDAO.getAll();
      await _carregarEtapas();

      setState(() {
        _fornecedores = fornecedores;
        _produtos = produtos;

        // Se for EDIÇÃO, popula os campos com os dados antigos
        if (_isEdicao && widget.despesaAntiga != null) {
          final antiga = widget.despesaAntiga!;
          _data = DateTime.tryParse(antiga.data) ?? DateTime.now();

          try {
            _selectedFornecedor = _fornecedores.firstWhere(
              (f) => f.id == antiga.fornecedorId,
            );
          } catch (_) {}

          try {
            _selectedEtapa = _etapas.firstWhere((e) => e.id == antiga.etapaId);
          } catch (_) {}

          // No modo edição, trazemos o item atual para a lista editável
          try {
            final prod = _produtos.firstWhere((p) => p.id == antiga.produtoId);
            _itensAdicionados.add(
              ItemDespesaTemporario(
                produto: prod,
                quantidade: antiga.quantidade,
                valorUnitario: antiga.valorUnitario,
              ),
            );
          } catch (_) {}
        }

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
        if (widget.etapaId != null && !_isEdicao) {
          try {
            _selectedEtapa = _etapas.firstWhere((e) => e.id == widget.etapaId);
          } catch (_) {
            _selectedEtapa = _etapas.isNotEmpty ? _etapas.first : null;
          }
        }
      });
    }
  }

  void _calcularTotalItemAtual() {
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
    if (valorTotal > 0) {
      _valorTotalController.text = _currencyFormat.format(valorTotal);
    } else {
      _valorTotalController.text = '';
    }
  }

  // ➕ Adiciona o item digitado à lista da nota fiscal
  void _adicionarItemNaLista() {
    if (_selectedProduto == null) {
      _mostrarMensagem('Selecione um produto primeiro.', isErro: true);
      return;
    }

    final qte =
        double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 0;
    final vUnit =
        double.tryParse(
          _valorUnitarioController.text
              .replaceAll('R\$ ', '')
              .replaceAll('.', '')
              .replaceAll(',', '.'),
        ) ??
        0;

    if (qte <= 0 || vUnit <= 0) {
      _mostrarMensagem(
        'Quantidade e Valor devem ser maiores que zero.',
        isErro: true,
      );
      return;
    }

    setState(() {
      _itensAdicionados.add(
        ItemDespesaTemporario(
          produto: _selectedProduto!,
          quantidade: qte,
          valorUnitario: vUnit,
        ),
      );

      // Limpa os campos de inserção para o próximo item
      _selectedProduto = null;
      _quantidadeController.clear();
      _valorUnitarioController.clear();
      _valorTotalController.clear();
    });
  }

  double _calcularTotalGeralNota() {
    return _itensAdicionados.fold(0, (soma, item) => soma + item.valorTotal);
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
        title: Text(_isEdicao ? 'Alterar Despesa' : 'Nova Despesa / Nota'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_dadosCarregados
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. DADOS CABEÇALHO DA NOTA (Fornecedor, Etapa, Data)
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<Fornecedor>(
                                      decoration: const InputDecoration(
                                        labelText: 'Fornecedor',
                                        prefixIcon: Icon(Icons.business),
                                        border: OutlineInputBorder(),
                                      ),
                                      initialValue: _selectedFornecedor,
                                      isExpanded: true,
                                      items: _fornecedores.map((f) {
                                        return DropdownMenuItem<Fornecedor>(
                                          value: f,
                                          child: Text(f.nome),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(
                                        () => _selectedFornecedor = val,
                                      ),
                                      validator: (v) => v == null
                                          ? 'Selecione o fornecedor'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    if (widget.orcamentoId != null) ...[
                                      DropdownButtonFormField<Etapa>(
                                        decoration: const InputDecoration(
                                          labelText: 'Etapa (opcional)',
                                          prefixIcon: Icon(Icons.timeline),
                                          border: OutlineInputBorder(),
                                        ),
                                        initialValue: _selectedEtapa,
                                        isExpanded: true,
                                        items: _etapas.map((e) {
                                          return DropdownMenuItem<Etapa>(
                                            value: e,
                                            child: Text(e.nome),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(
                                          () => _selectedEtapa = val,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Data: ${DateFormat('dd/MM/yyyy').format(_data)}',
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: _data,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null)
                                              setState(() => _data = picked);
                                          },
                                          child: const Text('Alterar Data'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2. INCLUSÃO DE ITENS (SÓ BLOQUEIA SE FOR EDIÇÃO DE UM ITEM FIXO JÁ EXISTENTE)
                            if (!_isEdicao) ...[
                              Card(
                                color: Colors.blue.shade50,
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Adicionar Item à Nota',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<Produto>(
                                        decoration: const InputDecoration(
                                          labelText: 'Produto',
                                          border: OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                        ),
                                        initialValue: _selectedProduto,
                                        isExpanded: true,
                                        items: _produtos.map((p) {
                                          return DropdownMenuItem<Produto>(
                                            value: p,
                                            child: Text(p.nome),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(
                                          () => _selectedProduto = val,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _quantidadeController,
                                              decoration: const InputDecoration(
                                                labelText: 'Qtd',
                                                border: OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  _valorUnitarioController,
                                              decoration: const InputDecoration(
                                                labelText: 'V. Unit (R\$)',
                                                border: OutlineInputBorder(),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _adicionarItemNaLista,
                                        icon: const Icon(Icons.add),
                                        label: const Text(
                                          'Inserir Item na Nota',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // 3. SEÇÃO DOS ITENS ADICIONADOS / EM EDIÇÃO
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Itens da Nota:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            if (_itensAdicionados.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'Nenhum item adicionado à nota ainda.',
                                  ),
                                ),
                              ),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _itensAdicionados.length,
                              itemBuilder: (context, index) {
                                final item = _itensAdicionados[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    title: Text(item.produto.nome),
                                    subtitle: Text(
                                      '${item.quantidade} x ${_currencyFormat.format(item.valorUnitario)} = ${_currencyFormat.format(item.valorTotal)}',
                                    ),
                                    trailing: _isEdicao
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                            ),
                                            onPressed: () =>
                                                _abrirDialogEdicaoItem(
                                                  item,
                                                  index,
                                                ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(
                                                () => _itensAdicionados
                                                    .removeAt(index),
                                              );
                                            },
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // TOTAL DA NOTA E SALVAMENTO
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL DA NOTA:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(
                                  _calcularTotalGeralNota(),
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _salvarProcessoGeral,
                                  icon: const Icon(Icons.save),
                                  label: Text(
                                    _isEdicao
                                        ? 'Confirmar Alteração'
                                        : 'Gravar Nota',
                                  ),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ✏️ Modal para corrigir o valor de um item digitado incorretamente (Ex: de 234,00 para 324,00)
  void _abrirDialogEdicaoItem(ItemDespesaTemporario item, int index) {
    final qtdEditController = TextEditingController(
      text: item.quantidade.toString(),
    );
    final valEditController = TextEditingController(
      text: item.valorUnitario.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Corrigir item: ${item.produto.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtdEditController,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: valEditController,
              decoration: const InputDecoration(
                labelText: 'Valor Unitário (R\$)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final novaQtd =
                  double.tryParse(qtdEditController.text) ?? item.quantidade;
              final novoVal =
                  double.tryParse(valEditController.text) ?? item.valorUnitario;
              setState(() {
                _itensAdicionados[index].quantidade = novaQtd;
                _itensAdicionados[index].valorUnitario = novoVal;
              });
              Navigator.pop(context);
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  // 💾 Salva todas as despesas da nota (se novo, insere múltiplos. Se edição, altera a existente)
  Future<void> _salvarProcessoGeral() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itensAdicionados.isEmpty) {
      _mostrarMensagem('Adicione pelo menos um item à nota.', isErro: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEdicao && widget.despesaAntiga != null) {
        // MODO ALTERAÇÃO: Atualiza o registro existente
        final itemAlterado = _itensAdicionados.first;
        final despesaAtualizada = Despesa(
          id: widget.despesaAntiga!.id, // Mantém o ID original
          descricao: itemAlterado.produto.nome,
          fornecedorId: _selectedFornecedor?.id,
          produtoId: itemAlterado.produto.id,
          unidadeId: itemAlterado.produto.unidadeId,
          orcamentoId: widget.orcamentoId,
          etapaId: _selectedEtapa?.id,
          data: _data.toIso8601String(),
          quantidade: itemAlterado.quantidade,
          valorUnitario: itemAlterado.valorUnitario,
          valorTotal: itemAlterado.valorTotal,
        );

        await _despesaDAO.update(despesaAtualizada);
        await _recalcularProgressoSeNecessario(
          _selectedEtapa?.id ?? widget.despesaAntiga!.etapaId,
        );
        _mostrarMensagem('Lançamento alterado com sucesso!');
      } else {
        // MODO LANÇAMENTO MULTIPLO: Varre a lista inserindo cada item como uma despesa associada à nota
        for (var item in _itensAdicionados) {
          final despesa = Despesa(
            descricao: item.produto.nome,
            fornecedorId: _selectedFornecedor?.id,
            produtoId: item.produto.id,
            unidadeId: item.produto.unidadeId,
            orcamentoId: widget.orcamentoId,
            etapaId: _selectedEtapa?.id,
            data: _data.toIso8601String(),
            quantidade: item.quantidade,
            valorUnitario: item.valorUnitario,
            valorTotal: item.valorTotal,
          );
          await _despesaDAO.insert(despesa);
        }
        await _recalcularProgressoSeNecessario(_selectedEtapa?.id);
        _mostrarMensagem(
          'Nota com ${_itensAdicionados.length} itens salva com sucesso!',
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao salvar despesa(s): $e', isErro: true);
    }
  }

  Future<void> _recalcularProgressoSeNecessario(int? etapaId) async {
    if (etapaId == null) return;
    final progresso = await _etapaDAO.calcularProgressoEtapa(etapaId);
    final etapaCompleta = await _etapaDAO.getById(etapaId);

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

  @override
  void dispose() {
    _quantidadeController.removeListener(_calcularTotalItemAtual);
    _valorUnitarioController.removeListener(_calcularTotalItemAtual);
    _quantidadeController.dispose();
    _valorUnitarioController.dispose();
    _valorTotalController.dispose();
    super.dispose();
  }
}
