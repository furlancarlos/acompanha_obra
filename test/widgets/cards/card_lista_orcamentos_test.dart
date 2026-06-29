// test/widgets/cards/card_lista_orcamentos_test.dart (CORRIGIDO)
// Testes para o widget CardListaOrcamentos
//============================================================================//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acompanha_obra/widgets/cards/card_lista_orcamentos.dart';
import 'package:acompanha_obra/models/orcamento.dart';

void main() {
  // Dados de exemplo para os testes
  final orcamento1 = Orcamento(
    id: 1,
    nome: 'Obra Principal',
    descricao: 'Construção da casa',
    valorTotal: 100000.0,
    dataInicio: '2024-01-15',
    dataFim: '2024-12-30',
  );

  final orcamento2 = Orcamento(
    id: 2,
    nome: 'Reforma Quartos',
    descricao: 'Reforma dos quartos',
    valorTotal: 15000.0,
    dataInicio: '2024-03-01',
    dataFim: '2024-04-30',
  );

  // ============================================================
  // CONFIGURAÇÃO DO TESTE
  // ============================================================

  Widget createWidget({
    required List<Orcamento> orcamentos,
    Orcamento? orcamentoSelecionado,
    required Function(Orcamento) onOrcamentoSelecionado,
    required VoidCallback onVerTodos,
    required VoidCallback onRefresh,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CardListaOrcamentos(
          orcamentos: orcamentos,
          orcamentoSelecionado: orcamentoSelecionado,
          onOrcamentoSelecionado: onOrcamentoSelecionado,
          onVerTodos: onVerTodos,
          onRefresh: onRefresh,
        ),
      ),
    );
  }

  // ============================================================
  // TESTES
  // ============================================================

  group('CardListaOrcamentos', () {
    testWidgets('Deve exibir mensagem de lista vazia quando não há orçamentos',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: [],
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () {},
          onRefresh: () {},
        ),
      );

      // Assert - Verifica apenas a mensagem principal
      expect(find.text('Nenhum orçamento cadastrado'), findsOneWidget);
    });

    testWidgets('Deve exibir a lista de orçamentos corretamente',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1, orcamento2];

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () {},
          onRefresh: () {},
        ),
      );

      // Assert
      expect(find.text('Obra Principal'), findsOneWidget);
      expect(find.text('Reforma Quartos'), findsOneWidget);
      expect(find.text('R\$ 100000.00'), findsOneWidget);
      expect(find.text('R\$ 15000.00'), findsOneWidget);
    });

    testWidgets('Deve marcar o orçamento como selecionado',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1, orcamento2];

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: orcamento1,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () {},
          onRefresh: () {},
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsAtLeast(1));
    });

    testWidgets('Deve chamar onOrcamentoSelecionado ao clicar em um orçamento',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1, orcamento2];
      Orcamento? orcamentoClicado;

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (orcamento) {
            orcamentoClicado = orcamento;
          },
          onVerTodos: () {},
          onRefresh: () {},
        ),
      );

      // Clica no primeiro orçamento
      await tester.tap(find.text('Obra Principal'));
      await tester.pump();

      // Assert
      expect(orcamentoClicado, isNotNull);
      expect(orcamentoClicado!.id, equals(1));
      expect(orcamentoClicado!.nome, equals('Obra Principal'));
    });

    testWidgets('Deve chamar onVerTodos ao clicar em "Ver Todos"',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1, orcamento2];
      bool verTodosChamado = false;

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () => verTodosChamado = true,
          onRefresh: () {},
        ),
      );

      // Clica no botão "Ver Todos"
      await tester.tap(find.text('Ver Todos'));
      await tester.pump();

      // Assert
      expect(verTodosChamado, isTrue);
    });

    testWidgets('Deve chamar onRefresh ao clicar no ícone de atualizar',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1];
      bool refreshChamado = false;

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () {},
          onRefresh: () => refreshChamado = true,
        ),
      );

      // Clica no ícone de refresh
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      expect(refreshChamado, isTrue);
    });

    testWidgets('Deve chamar onVerTodos ao clicar em "Gerenciar Orçamentos"',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1];
      bool verTodosChamado = false;

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () => verTodosChamado = true,
          onRefresh: () {},
        ),
      );

      // Clica no botão "Gerenciar Orçamentos"
      await tester.tap(find.text('Gerenciar Orçamentos'));
      await tester.pump();

      // Assert
      expect(verTodosChamado, isTrue);
    });

    testWidgets('Deve exibir a descrição do orçamento quando disponível',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1];

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () {},
          onRefresh: () {},
        ),
      );

      // Assert
      expect(find.text('Construção da casa'), findsOneWidget);
    });

    testWidgets('Deve exibir o título "📋 Orçamentos"',
        (WidgetTester tester) async {
      // Arrange
      final orcamentos = [orcamento1];

      // Act
      await tester.pumpWidget(
        createWidget(
          orcamentos: orcamentos,
          orcamentoSelecionado: null,
          onOrcamentoSelecionado: (_) {},
          onVerTodos: () {},
          onRefresh: () {},
        ),
      );

      // Assert
      expect(find.text('📋 Orçamentos'), findsOneWidget);
    });
  });
}
