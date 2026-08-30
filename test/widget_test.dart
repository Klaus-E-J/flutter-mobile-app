
import 'package:flutter_test/flutter_test.dart';

import 'package:avalia_pro/app.dart';

void main() {
  testWidgets('aplicação inicia corretamente', (tester) async {
    await tester.pumpWidget(const AvaliaProApp());

    expect(find.text('Acesse o Avalia Pro'), findsOneWidget);
  });
}