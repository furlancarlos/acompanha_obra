// screens/cadastro_etapa.dart
// Arquivo de definição da tela de cadastro de etapa.
//============================================================================//

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dao/etapa_dao.dart';
import '../dao/orcamento_dao.dart';
import '../models/etapa.dart';
import '../models/orcamento.dart';

class CadastroEtapaPage extends StatefulWidget {
  final Etapa? etapa;
  final int? orcamentoId;
  const CadastroEtapaPage({super.key, this.etapa, this.orcamentoId});

  @override
  State<CadastroEtapaPage> createState() => _CadastroEtapaPageState();
}

class _CadastroEtapaPageState extends State<CadastroEtapaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorOrcadoController = TextEditingController();

  Orcamento? _selectedOrcamento;
  List<Orcamento> _orcamentos = [];

  String _selectedStatus = 'Pendente';
  double _progresso = 0.0;

  DateTime? _dataInicio;
  DateTime? _dataFim;

  bool _isLoading = false;
  bool _isLoadingOrcamentos = true;

  final _etapaDAO = EtapaDAO();
  final _orcamentoDAO = OrcamentoDAO();

  // Formatador de data
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // Status disponíveis
  final List<String> _statusList = ['Pendente', "Iniciado", 'Em Andamento', 'Concluído'];

  @override
  void initState() {
    super.initState();
    _preencherCampos();
    _carregarOrcamentos();
  }

  void _preencherCampos() {
    if (widget.etapa != null) {
      _nomeController.text = widget.etapa!.nome;
      _descricaoController.text = widget.etapa!.descricao ?? '';
      _selectedStatus = widget.etapa!.status;
      _progresso = widget.etapa!.progresso;

      if (widget.etapa!.dataInicio != null) {
        _dataInicio = DateTime.parse(widget.etapa!.dataInicio!);
      }
      if (widget.etapa!.dataFim != null) {
        _dataFim = DateTime.parse(widget.etapa!.dataFim!);
      }
      if (widget.etapa!.valorOrcado != null) {
        _valorOrcadoController.text =
            widget.etapa!.valorOrcado!.toStringAsFixed(2);
      }
    }

    // Se veio com orcamentoId pré-selecionado
    if (widget.orcamentoId != null) {
      _selectedOrcamento = Orcamento(
        id: widget.orcamentoId,
        nome: 'Carregando...',
        valorTotal: 0,
        dataInicio: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<void> _carregarOrcamentos() async {
    setState(() => _isLoadingOrcamentos = true);
    try {
      final orcamentos = await _orcamentoDAO.getAll();
      setState(() {
        _orcamentos = orcamentos;
        _isLoadingOrcamentos = false;

        // Se tinha um orcamentoId pré-selecionado, encontra ele na lista
        if (widget.orcamentoId != null) {
          try {
            _selectedOrcamento = _orcamentos.firstWhere(
              (o) => o.id == widget.orcamentoId,
            );
          } catch (e) {
            _selectedOrcamento = _orcamentos.isNotEmpty
                ? _orcamentos.first
                : null;
          }
        }

        // Se está editando, seleciona o orçamento da etapa
        if (widget.etapa?.orcamentoId != null) {
          try {
            _selectedOrcamento = _orcamentos.firstWhere(
              (o) => o.id == widget.etapa!.orcamentoId,
            );
          } catch (e) {
            _selectedOrcamento = _orcamentos.isNotEmpty
                ? _orcamentos.first
                : null;
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingOrcamentos = false);
      _mostrarMensagem('Erro ao carregar orçamentos: $e', isErro: true);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _valorOrcadoController.dispose();  // ← ADICIONADO
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verifica se já existe uma etapa com o mesmo nome neste orçamento
      if (_selectedOrcamento != null) {
        final existe = await _etapaDAO.existsByNome(
          _nomeController.text.trim(),
          _selectedOrcamento!.id!,
        );
        if (existe && widget.etapa == null) {
          _mostrarMensagem(
            'Já existe uma etapa com este nome neste orçamento!',
            isErro: true,
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // 🔧 Converte o valor orçado para double
      double? valorOrcado;
      if (_valorOrcadoController.text.trim().isNotEmpty) {
        valorOrcado = double.tryParse(
          _valorOrcadoController.text
              .replaceAll('R\$ ', '')
              .replaceAll('.', '')
              .replaceAll(',', '.')
              .trim(),
        );
      }

      final etapa = Etapa(
        id: widget.etapa?.id,
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        orcamentoId: _selectedOrcamento!.id!,
        progresso: _progresso,
        status: _selectedStatus,
        dataInicio: _dataInicio?.toIso8601String().split('T').first,
        dataFim: _dataFim?.toIso8601String().split('T').first,
        valorOrcado: valorOrcado,  // ← USANDO A VARIÁVEL
      );

      if (widget.etapa == null) {
        await _etapaDAO.insert(etapa);
        _mostrarMensagem('Etapa cadastrada com sucesso!');
      } else {
        await _etapaDAO.update(etapa);
        _mostrarMensagem('Etapa atualizada com sucesso!');
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

  Future<void> _selecionarDataInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
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
      initialDate: _dataFim ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dataFim = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditando = widget.etapa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Etapa' : 'Nova Etapa'),
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
                        // Dropdown: Orçamento
                        if (_isLoadingOrcamentos)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          DropdownButtonFormField<Orcamento>(
                            decoration: const InputDecoration(
                              labelText: 'Orçamento',
                              hintText: 'Selecione o orçamento',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedOrcamento,
                            isExpanded: true,
                            items: _orcamentos.map((Orcamento orcamento) {
                              return DropdownMenuItem<Orcamento>(
                                value: orcamento,
                                child: Text(orcamento.nome),
                              );
                            }).toList(),
                            onChanged: (Orcamento? newValue) {
                              setState(() {
                                _selectedOrcamento = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Selecione um orçamento';
                              }
                              return null;
                            },
                          ),

                        const SizedBox(height: 16),

                        // Campo: Nome da Etapa
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Etapa',
                            hintText: 'Ex: Fundação, Estrutura, Pintura',
                            prefixIcon: Icon(Icons.label),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome da etapa';
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
                            hintText: 'Ex: Escavação e fundação da casa',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          onFieldSubmitted: (_) => _salvar(),
                        ),

                        const SizedBox(height: 16),

                        // Campo: Valor Orçado (opcional)
                        TextFormField(
                          controller: _valorOrcadoController,
                          decoration: const InputDecoration(
                            labelText: 'Valor Orçado (R\$)',
                            hintText: 'Ex: 50000.00',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final valor = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
                              if (valor == null || valor < 0) {
                                return 'Digite um valor válido';
                              }
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _salvar(),
                        ),

                        const SizedBox(height: 16),

                        // Dropdown: Status
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.info_outline),
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedStatus,
                          isExpanded: true,
                          items: _statusList.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStatus = newValue!;
                              if (_selectedStatus == 'Concluído') {
                                _progresso = 1.0;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Slider: Progresso
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progresso',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${(_progresso * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B3A5C),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _progresso,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: _getStatusColor(_selectedStatus),
                              label: '${(_progresso * 100).toInt()}%',
                              onChanged: (double value) {
                                setState(() {
                                  _progresso = value;
                                  if (value == 0) {
                                    _selectedStatus = 'Pendente';
                                  } else if (value >= 1.0) {
                                    _selectedStatus = 'Concluído';
                                  } else if (_selectedStatus == 'Pendente' ||
                                      _selectedStatus == 'Concluído') {
                                    _selectedStatus = 'Em Andamento';
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Campo: Data de Início (opcional)
                        InkWell(
                          onTap: _selecionarDataInicio,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data de Início (opcional)',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dataInicio != null
                                      ? _dateFormat.format(_dataInicio!)
                                      : 'Selecione uma data',
                                  style: TextStyle(
                                    color: _dataInicio != null
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
                                      ? _dateFormat.format(_dataFim!)
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
                      ? '🔄 Editando etapa existente'
                      : '💡 Cadastre uma nova etapa para o orçamento',
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
}
