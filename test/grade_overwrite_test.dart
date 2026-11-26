import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/leitura_gabarito_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/correcao/resultado_correcao_screen.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressões da auditoria: uma nota já salva era sobrescrita sem aviso e o
/// mesmo aluno podia ser contado duas vezes na mesma correção.
void main() {
  const prova = ProvaCorrecao(
    id: 'exam_ow',
    titulo: 'Prova',
    turma: '9º A',
    disciplina: 'Mat',
    totalQuestoes: 5,
    totalAlunos: 2,
    classId: 'c9a',
  );
  const resultados = [
    ResultadoAluno(studentId: 'ana', nomeAluno: 'Ana', acertos: 4, totalQuestoes: 5, notaFinal10: 8.0),
    ResultadoAluno(studentId: 'bruno', nomeAluno: 'Bruno', acertos: 3, totalQuestoes: 5, notaFinal10: 6.0),
  ];

  Future<List<List<SubmissionRecord>>> abrir(WidgetTester tester) async {
    final batches = <List<SubmissionRecord>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ResultadoCorrecaoScreen(
          prova: prova,
          resultados: resultados,
          onSaveSubmissions: (r) async => batches.add(r),
          // Ana já tinha 10.0 salvo nesta prova.
          loadExistingGrades: (_) async => {'sub_exam_ow_ana': 10.0},
        ),
      ),
    );
    await tester.pumpAndSettle();
    return batches;
  }

  testWidgets('nota nova é salva na hora; nota existente não é sobrescrita sem perguntar', (tester) async {
    final batches = await abrir(tester);
    expect(batches, hasLength(1));
    expect(batches.single.map((r) => r.studentName), ['Bruno']);
    expect(find.textContaining('já tinham nota salva'), findsOneWidget);

    await tester.tap(find.text('Concluir Correção'));
    await tester.pumpAndSettle();
    expect(find.text('Substituir notas já salvas?'), findsOneWidget);
    expect(find.textContaining('Ana: nota salva 10.0 → nova 8.0'), findsOneWidget);

    await tester.tap(find.text('Manter notas salvas'));
    await tester.pumpAndSettle();
    expect(batches, hasLength(1), reason: 'a nota antiga da Ana deve ser mantida');
  });

  testWidgets('com confirmação, a nota existente é substituída', (tester) async {
    final batches = await abrir(tester);
    await tester.tap(find.text('Concluir Correção'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Substituir'));
    await tester.pumpAndSettle();
    expect(batches, hasLength(2));
    expect(batches.last.map((r) => r.studentName), ['Ana']);
    expect(batches.last.single.finalGrade, 8.0);
  });

  testWidgets('cancelar a decisão não salva nada e mantém a tela', (tester) async {
    final batches = await abrir(tester);
    await tester.tap(find.text('Concluir Correção'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(batches, hasLength(1));
    expect(find.text('Concluir Correção'), findsOneWidget);
  });

  testWidgets('mesmo aluno lido duas vezes na sessão: pergunta e não conta em dobro', (tester) async {
    final questions = [
      criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A'),
      criarQuestaoGabaritoRapido(numero: 2, letraCorreta: 'B'),
    ];
    const students = [
      StudentRecord(id: 'stu_1', name: 'Alice'),
      StudentRecord(id: 'stu_2', name: 'Bruno'),
    ];
    const randomizer = ExamRandomizerService();
    final shared = randomizer.generateVariants(
      examId: 'exam_dup',
      questions: questions,
      sameExamForEveryone: true,
      variantCount: 1,
      shuffleQuestions: false,
      shuffleAlternatives: false,
    );
    final sheets = randomizer.buildNominalAnswerSheetVariants(baseVariants: shared, students: students);
    final brunoPng = const OmrImageService().renderSyntheticSheetPng(
      qrPayload: sheets[1].qrPayload,
      totalQuestions: 2,
      markedAnswers: const {1: ['A'], 2: ['B']},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LeituraGabaritoScreen(
          prova: const ProvaCorrecao(
            id: 'exam_dup',
            titulo: 'Prova',
            turma: '9º A',
            disciplina: 'Mat',
            totalQuestoes: 2,
            totalAlunos: 2,
          ),
          questions: questions,
          students: students,
          variants: shared,
          onPickSheetImage: () async => brunoPng,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> lerFolha() async {
      await tester.scrollUntilVisible(find.text('Carregar imagem de folha (PNG/JPG)'), 200);
      await tester.tap(find.text('Carregar imagem de folha (PNG/JPG)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar Nota'));
      await tester.pumpAndSettle();
    }

    await lerFolha();
    expect(find.textContaining('Folha de Bruno corrigida'), findsOneWidget);
    // Próximo sugerido deve ser quem ainda não foi corrigido.
    expect(find.textContaining('Próximo aluno sugerido: Alice'), findsOneWidget);

    await lerFolha();
    expect(find.text('Aluno já corrigido nesta sessão'), findsOneWidget);
    await tester.tap(find.text('Manter a anterior'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nova leitura descartada'), findsOneWidget);
    expect(find.textContaining('Ver resultados e concluir (1 lida(s))'), findsOneWidget);
  });
}
