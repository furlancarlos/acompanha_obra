// main.dart
// Arquivo de definição da classe principal do aplicativo.
// Para iniciar o aplicativo, execute o comando flutter run.
// Pasta de trabalho: C:\projetos\Flutter\acompanha_obra
// TELA PRINCIPAL - DASHBOARD (VERSÃO COMPONENTIZADA)
//============================================================================//

import 'package:acompanha_obra/screens/cadastro_despesa.dart';
import 'package:acompanha_obra/form/lista_orcamento.dart';
import 'package:acompanha_obra/widgets/cards/card_grafico_etapas.dart';
import 'package:acompanha_obra/widgets/cards/card_resumo_orcamento.dart';
import 'package:acompanha_obra/widgets/cards/card_lista_orcamentos.dart';
import 'package:flutter/material.dart';
import 'dao/despesa_dao.dart';
import 'dao/orcamento_dao.dart';
import 'dao/etapa_dao.dart';
import 'models/orcamento.dart';
import 'models/etapa.dart';

void main() {
  runApp(const AcompanhaObraApp());
}

class AcompanhaObraApp extends StatelessWidget {
  const AcompanhaObraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Acompanha Obra',
      theme: ThemeData(
        primaryColor: const Color(0xFF1B3A5C),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: const Color(0xFFE8751A)),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HOME PAGE - DASHBOARD
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dados
  List<Orcamento> _orcamentos = [];
  Orcamento? _orcamentoSelecionado;
  List<Etapa> _etapas = [];  // ← NOVO
  
  // Resumo financeiro do orçamento selecionado
  double _valorOrcamento = 0;
  double _valorGasto = 0;
  bool _isLoading = true;

  final _orcamentoDAO = OrcamentoDAO();
  final _despesaDAO = DespesaDAO();
  final _etapaDAO = EtapaDAO();  // ← NOVO

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final orcamentos = await _orcamentoDAO.getAll();
      
      setState(() {
        _orcamentos = orcamentos;
        
        if (_orcamentoSelecionado == null && _orcamentos.isNotEmpty) {
          _orcamentoSelecionado = _orcamentos.first;
        }
        
        _isLoading = false;
      });
      
      if (_orcamentoSelecionado != null) {
      await _etapaDAO.atualizarProgressoEtapas(_orcamentoSelecionado!.id!);
    }

      await _carregarDadosFinanceiros();
      await _carregarEtapas();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar dados: $e', isErro: true);
    }
  }

  Future<void> _carregarDadosFinanceiros() async {
    if (_orcamentoSelecionado == null) {
      setState(() {
        _valorOrcamento = 0;
        _valorGasto = 0;
      });
      return;
    }

    try {
      final totalOrcamento = _orcamentoSelecionado!.valorTotal;
      final totalGasto = await _despesaDAO.getTotalGastoPorOrcamento(
        _orcamentoSelecionado!.id!
      );
      
      setState(() {
        _valorOrcamento = totalOrcamento;
        _valorGasto = totalGasto;
      });
    } catch (e) {
      print('Erro ao carregar dados financeiros: $e');
    }
  }

  // ← NOVO MÉTODO
  Future<void> _carregarEtapas() async {
  if (_orcamentoSelecionado == null) {
    setState(() => _etapas = []);
    return;
  }

  try {
    final etapas = await _etapaDAO.getByOrcamento(
      _orcamentoSelecionado!.id!
    );
    print('📊 Etapas carregadas: ${etapas.length}');  // ← ADICIONAR
    for (var e in etapas) {
      print('   - ${e.nome}: ${(e.progresso * 100).toInt()}%');
    }
    setState(() {
      _etapas = etapas;
    });
  } catch (e) {
    print('❌ Erro ao carregar etapas: $e');
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

  void _selecionarOrcamento(Orcamento orcamento) {
    setState(() {
      _orcamentoSelecionado = orcamento;
    });
   
  // 🔧 ATUALIZA O PROGRESSO DAS ETAPAS
  _etapaDAO.atualizarProgressoEtapas(orcamento.id!).then((_) {
    _carregarDadosFinanceiros();
    _carregarEtapas();
  });
}

  @override
  Widget build(BuildContext context) {
    final percentual = _valorOrcamento > 0 ? _valorGasto / _valorOrcamento : 0;
    final restante = _valorOrcamento - _valorGasto;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Acompanha Obra',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1B3A5C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 01: Gráfico de Etapas (NOVO)
                    if (_orcamentoSelecionado != null)
                      CardGraficoEtapas(
                        etapas: _etapas,
                        alturaMaxima: 140,
                      ),
                    const SizedBox(height: 16),

                    // Card 02: Resumo do Orçamento Selecionado
                    if (_orcamentoSelecionado != null)
                      CardResumoOrcamento(
                        orcamento: _orcamentoSelecionado!,
                        valorOrcamento: _valorOrcamento,
                        valorGasto: _valorGasto,
                        percentual: percentual.toDouble(),
                        restante: restante,
                        onInfoPressed: () {
                          _mostrarMensagem(_orcamentoSelecionado!.descricao!);
                        },
                      ),
                    const SizedBox(height: 16),

                    // Card 03: Lista de Orçamentos
                    CardListaOrcamentos(
                      orcamentos: _orcamentos,
                      orcamentoSelecionado: _orcamentoSelecionado,
                      onOrcamentoSelecionado: _selecionarOrcamento,
                      onVerTodos: _abrirListaOrcamentos,
                      onRefresh: _carregarDados,
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: _orcamentoSelecionado != null
          ? FloatingActionButton.extended(
              onPressed: _adicionarDespesa,
              backgroundColor: const Color(0xFFE8751A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nova Despesa'),
            )
          : null,
    );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void _adicionarDespesa() async {
    if (_orcamentoSelecionado == null) {
      _mostrarMensagem(
        'Selecione um orçamento antes de lançar uma despesa!',
        isErro: true,
      );
      return;
    }
    
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroDespesaPage(
          orcamentoId: _orcamentoSelecionado!.id,
        ),
      ),
    );
    if (resultado == true) {
      _carregarDados();
    }
  }

  void _abrirListaOrcamentos() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ListaOrcamentoPage(),
      ),
    );
    if (resultado == true) {
      _carregarDados();
    }
  }
}
