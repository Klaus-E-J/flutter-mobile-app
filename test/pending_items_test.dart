import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/exams/exam_print_screen.dart';
import 'package:avalia_pro/features/exams/models/exam_application_mode.dart';
import 'package:avalia_pro/features/exams/models/exam_variant.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/leitura_gabarito_screen.dart';
import 'package:avalia_pro/screens/correcao/leitura_qr_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/correcao/resultado_correcao_screen.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Itens pendentes apontados na revisão das correções críticas.
void main() {
  const randomizer = ExamRandomizerService();

  List<Questao> questions() => List.generate(
        5,
        (q) => Questao(
          id: 'q$q',
          enunciado: 'Questão $q',
          alternativas: List.generate(
            5,
            (a) => Alternativa(id: 'q${q}_a$a', texto: 'Alt $a', correta: a == q % 5),
          ),
        ),
      );

  /// Cadernos A–D embaralhados, como a versão antiga gerava para "mesma prova".
  List<ExamVariant> legacyBooklets() => randomizer.generateVariants(
        examId: 'exam_legacy',
        questions: questions(),
        sameExamForEveryone: true,
        variantCount: 4,
        seed: 77,
      );

  group('provas antigas (sem fingerprint)', () {
    const shared = ExamApplicationMode.sameForEveryone;
    List<ExamVariant> generatedShared() => randomizer.generateVariantsForMode(
          examId: 'exam_legacy',
          questions: questions(),
          mode: shared,
          seed: 1,
        );
    final fpShared =
        ExamRandomizerService.configFingerprint(mode: shared, seed: 1, questions: questions());

    test('"mesma prova" muito antiga: cadernos A–D impressos continuam valendo', () {
      final legacy = legacyBooklets();
      // Prova sem `applicationMode` salvo => o repositório não passa o modo.
      final merged = randomizer.mergeWithExisting(
        generated: generatedShared(),
        existing: legacy,
        fingerprint: fpShared,
        legacyQuestions: questions(),
      );
      expect(merged.map((v) => v.code), ['A', 'B', 'C', 'D']);
      for (final v in legacy) {
        final m = merged.firstWhere((x) => x.id == v.id);
        expect(m.answerKey, v.answerKey, reason: 'caderno ${v.code} não pode mudar');
      }
    });

    test('com o modo "mesma prova" salvo explicitamente, cadernos embaralhados antigos não valem', () {
      final merged = randomizer.mergeWithExisting(
        generated: generatedShared(),
        existing: legacyBooklets(),
        fingerprint: fpShared,
        legacyQuestions: questions(),
        mode: shared,
      );
      expect(merged.map((v) => v.code), ['A']);
      expect(
        merged.single.questions.map((q) => q.originalQuestionId).join(),
        questions().map((q) => q.id).join(),
      );
    });

    test('variante antiga que não respeita o modo atual não é reaproveitada', () {
      // Prova antiga com questões embaralhadas; agora o modo manda manter a
      // ordem das questões ("Sequência das respostas diferente por aluno").
      const students = [StudentRecord(id: 's1', name: 'Ana')];
      final legacy = randomizer.generateVariants(
        examId: 'exam_legacy',
        questions: questions(),
        sameExamForEveryone: false,
        students: students,
        seed: 5,
      );
      expect(
        legacy.single.questions.map((q) => q.originalQuestionId).join(),
        isNot(questions().map((q) => q.id).join()),
        reason: 'a variante antiga precisa estar com as questões embaralhadas',
      );
      const mode = ExamApplicationMode.answerOrder;
      final generated = randomizer.generateVariantsForMode(
        examId: 'exam_legacy',
        questions: questions(),
        mode: mode,
        students: students,
        seed: 9,
      );
      final fp = ExamRandomizerService.configFingerprint(mode: mode, seed: 9, questions: questions());
      final merged = randomizer.mergeWithExisting(
        generated: generated,
        existing: legacy,
        fingerprint: fp,
        legacyQuestions: questions(),
        mode: mode,
      );
      expect(
        merged.single.questions.map((q) => q.originalQuestionId).join(),
        questions().map((q) => q.id).join(),
      );
    });
  });

  testWidgets('"mesma prova": a impressão mostra só o caderno atual (A)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExamPrintScreen(
          examId: 'exam_legacy',
          examTitle: 'Prova antiga',
          classIds: const [],
          classNames: const ['9º A'],
          applicationMode: ExamApplicationMode.sameForEveryone,
          initialQuestions: questions(),
          initialVariants: legacyBooklets(),
          initialStudents: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('5 questões • 1 variante(s)'), findsOneWidget);
  });

  testWidgets('resultados: aluno cuja nota anterior foi mantida fica sinalizado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultadoCorrecaoScreen(
          prova: const ProvaCorrecao(
            id: 'exam_keep',
            titulo: 'Prova',
            turma: '9º A',
            disciplina: 'Mat',
            totalQuestoes: 5,
            totalAlunos: 1,
          ),
          resultados: const [
            ResultadoAluno(studentId: 'ana', nomeAluno: 'Ana', acertos: 4, totalQuestoes: 5, notaFinal10: 8),
          ],
          onSaveSubmissions: (_) async {},
          loadExistingGrades: (_) async => {'sub_exam_keep_ana': 10.0},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Nota anterior mantida'), findsNothing);
    await tester.tap(find.text('Concluir Correção'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter notas salvas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nota anterior mantida'), findsOneWidget);
  });

  testWidgets('prova individual: "Manter a anterior" volta ao passo 1 (QR)', (tester) async {
    final qs = [criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A')];
    const students = [StudentRecord(id: 'ana', name: 'Ana'), StudentRecord(id: 'bia', name: 'Bia')];
    final variants = randomizer.generateVariants(
      examId: 'exam_ind',
      questions: qs,
      sameExamForEveryone: false,
      students: students,
    );
    final anaSheet = const OmrImageService().renderSyntheticSheetPng(
      qrPayload: variants.first.qrPayload,
      totalQuestions: 1,
      markedAnswers: {1: [variants.first.answerKey[1]!]},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LeituraGabaritoScreen(
          prova: const ProvaCorrecao(
            id: 'exam_ind',
            titulo: 'Prova',
            turma: '9º A',
            disciplina: 'Mat',
            totalQuestoes: 1,
            totalAlunos: 2,
            provaIndividual: true,
          ),
          questions: qs,
          students: students,
          variants: variants,
          activeVariant: variants.first,
          provasLidas: 1,
          resultadosIniciais: const [
            ResultadoAluno(studentId: 'ana', nomeAluno: 'Ana', acertos: 1, totalQuestoes: 1, notaFinal10: 10),
          ],
          onPickSheetImage: () async => anaSheet,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Carregar imagem de folha (PNG/JPG)'), 200);
    await tester.tap(find.text('Carregar imagem de folha (PNG/JPG)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar Nota'));
    await tester.pumpAndSettle();
    expect(find.text('Aluno já corrigido nesta sessão'), findsOneWidget);
    await tester.tap(find.text('Manter a anterior'));
    await tester.pumpAndSettle();
    expect(find.byType(LeituraQrScreen), findsOneWidget);
    expect(find.text('QR CODE • IND-02'), findsOneWidget, reason: 'próxima sugerida: Bia');
  });
}
