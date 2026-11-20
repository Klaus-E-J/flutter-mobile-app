import 'package:avalia_pro/core/navigation/app_shell.dart';
import 'package:avalia_pro/core/navigation/app_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aba falsa com um contador, para verificar se o estado é preservado.
class _FakeTab extends StatefulWidget {
  const _FakeTab(this.tab);
  final AppTab tab;

  @override
  State<_FakeTab> createState() => _FakeTabState();
}

class _FakeTabState extends State<_FakeTab> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tela ${widget.tab.name}')),
      body: Column(
        children: [
          Text('${widget.tab.name}: $_taps'),
          TextButton(
            onPressed: () => setState(() => _taps++),
            child: Text('incrementar ${widget.tab.name}'),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: Builder(
                    builder: (ctx) => TextButton(
                      onPressed: () => AppTabs.go(ctx, AppTab.results),
                      child: const Text('ir para resultados'),
                    ),
                  ),
                ),
              ),
            ),
            child: Text('abrir detalhe ${widget.tab.name}'),
          ),
        ],
      ),
    );
  }
}

Widget _app() => MaterialApp(
      home: AppShell(tabBuilder: (tab) => _FakeTab(tab)),
    );

void main() {
  testWidgets('barra inferior troca de aba e preserva o estado de cada aba', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Tela home'), findsOneWidget);
    await tester.tap(find.text('incrementar home'));
    await tester.pump();
    expect(find.text('home: 1'), findsOneWidget);

    await tester.tap(find.text('Provas'));
    await tester.pumpAndSettle();
    expect(find.text('Tela exams'), findsOneWidget);
    expect(find.text('Tela home'), findsNothing);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('home: 1'), findsOneWidget);
  });

  testWidgets('voltar do sistema leva ao Início antes de sair', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Turmas'));
    await tester.pumpAndSettle();
    expect(find.text('Tela classes'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('Tela home'), findsOneWidget);
  });

  testWidgets('AppTabs.go fecha telas empilhadas e abre a aba pedida', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('abrir detalhe home'));
    await tester.pumpAndSettle();
    expect(find.text('ir para resultados'), findsOneWidget);

    await tester.tap(find.text('ir para resultados'));
    await tester.pumpAndSettle();

    expect(find.text('ir para resultados'), findsNothing);
    expect(find.text('Tela results'), findsOneWidget);
    expect(AppTabs.current.value, AppTab.results);
  });
}
