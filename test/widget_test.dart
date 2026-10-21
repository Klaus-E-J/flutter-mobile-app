import 'package:flutter_test/flutter_test.dart';

import 'package:avalia_pro/app.dart';

void main() {
  testWidgets('aplicação inicia corretamente exibindo tela de autenticação', (
    tester,
  ) async {
    await tester.pumpWidget(const AvaliaProApp());
    await tester.pumpAndSettle();

    expect(find.text('Avalia Pro'), findsOneWidget);
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
  });
}
