import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/leitura_gabarito_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressão da auditoria: o botão "Simular Leitura OMR" gerava marcações
/// inventadas e sobrescrevia a nota real do aluno.
void main() {
  final questions = [criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A')];
  const students = [StudentRecord(id: 'stu_1', name: 'Ana')];
  final variants = const ExamRandomizerService().generateVariants(
    examId: 'exam_x',
    questions: questions,
    sameExamForEveryone: false,
    students: students,
  );
  const prova = ProvaCorrecao(
    id: 'exam_x',
    titulo: 'Prova',
    turma: '9º A',
    disciplina: 'Mat',
    totalQuestoes: 1,
    totalAlunos: 1,
    provaIndividual: true,
  );

  testWidgets('no app não existe leitura simulada; sem câmera nenhuma nota é gerada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LeituraGabaritoScreen(
          prova: prova,
          questions: questions,
          students: students,
          variants: variants,
          activeVariant: variants.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Carregar imagem de folha (PNG/JPG)'), 200);

    expect(find.textContaining('Simular'), findsNothing);
    expect(find.text('Ativar câmera'), findsOneWidget);

    await tester.tap(find.text('Ativar câmera'));
    await tester.pumpAndSettle();

    // Sem câmera no ambiente de teste: só um aviso, nenhuma revisão/nota.
    expect(find.text('Confirmar Nota'), findsNothing);
    expect(find.textContaining('corrigida'), findsNothing);
    expect(find.textContaining('Ver resultados e concluir'), findsNothing);
  });

  testWidgets('a simulação só existe quando um teste a habilita explicitamente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LeituraGabaritoScreen(
          prova: prova,
          questions: questions,
          students: students,
          variants: variants,
          activeVariant: variants.first,
          allowSimulatedCapture: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Carregar imagem de folha (PNG/JPG)'), 200);
    expect(find.textContaining('Simular Leitura OMR'), findsOneWidget);
  });
}
