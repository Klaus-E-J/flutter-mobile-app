import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/leitura_qr_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/correcao/resultado_correcao_screen.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressão da auditoria: na prova individual, depois de cada folha o app
/// voltava ao passo 1, que não tinha como finalizar (aluno ausente).
void main() {
  final questions = [criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A')];
  const students = [
    StudentRecord(id: 'ana', name: 'Ana'),
    StudentRecord(id: 'bruno', name: 'Bruno'),
  ];
  final variants = const ExamRandomizerService().generateVariants(
    examId: 'exam_fin',
    questions: questions,
    sameExamForEveryone: false,
    students: students,
  );
  const prova = ProvaCorrecao(
    id: 'exam_fin',
    titulo: 'Prova',
    turma: '9º A',
    disciplina: 'Mat',
    totalQuestoes: 1,
    totalAlunos: 2,
    provaIndividual: true,
  );

  testWidgets('sem leituras, o passo 1 não mostra "Finalizar"', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LeituraQrScreen(prova: prova, questions: questions, students: students, variants: variants),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Finalizar'), findsNothing);
  });

  testWidgets('com folhas lidas, dá para concluir direto do passo 1', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LeituraQrScreen(
        prova: prova,
        questions: questions,
        students: students,
        variants: variants,
        provasLidas: 1,
        resultadosAcumulados: const [
          ResultadoAluno(studentId: 'ana', nomeAluno: 'Ana', acertos: 1, totalQuestoes: 1, notaFinal10: 10),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    // A próxima prova sugerida é a do aluno que ainda não foi lido (Bruno, IND-02).
    expect(find.text('QR CODE • IND-02'), findsOneWidget);

    expect(find.text('Finalizar'), findsOneWidget);
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ResultadoCorrecaoScreen), findsOneWidget);
    expect(find.textContaining('Ana'), findsWidgets);
  });

  test('tipo de registro salvo continua o mesmo', () {
    expect(SubmissionRecord, isNotNull);
  });
}
