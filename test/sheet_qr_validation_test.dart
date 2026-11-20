import 'dart:typed_data';

import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/correction/services/sheet_qr_validator.dart';
import 'package:avalia_pro/features/exams/models/exam_variant.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/leitura_gabarito_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Regressões da auditoria: folha de outra prova, variante inexistente ou
/// imagem que não é folha nunca podem ser corrigidas com outro gabarito.
void main() {
  const randomizer = ExamRandomizerService();
  const omr = OmrImageService();

  final questions = [
    criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A'),
    criarQuestaoGabaritoRapido(numero: 2, letraCorreta: 'B'),
  ];
  const students = [
    StudentRecord(id: 'stu_1', name: 'Ana', matricula: '1'),
    StudentRecord(id: 'stu_2', name: 'Bruno', matricula: '2'),
  ];

  List<ExamVariant> variantsFor(String examId) => randomizer.generateVariants(
        examId: examId,
        questions: questions,
        sameExamForEveryone: false,
        students: students,
        seed: 1,
      );

  group('SheetQrValidator.match', () {
    final variants = variantsFor('exam_mat');

    test('aceita folha desta prova e vincula o aluno', () {
      final payload = ExamQrPayload.tryParse(variants[1].qrPayload)!;
      final r = SheetQrValidator.match(
        payload: payload,
        examId: 'exam_mat',
        variants: variants,
        students: students,
      );
      expect(r.isOk, isTrue);
      expect(r.variant!.studentName, 'Bruno');
    });

    test('recusa folha de outra prova mesmo que o ID da variante coincida', () {
      // Mesmo aluno => mesmo ID de variante (var_stu_1) nas duas provas.
      final otherExamSheet = variantsFor('exam_hist').first;
      expect(otherExamSheet.id, variants.first.id);
      final r = SheetQrValidator.match(
        payload: ExamQrPayload.tryParse(otherExamSheet.qrPayload)!,
        examId: 'exam_mat',
        variants: variants,
        students: students,
      );
      expect(r.isOk, isFalse);
      expect(r.error, SheetQrValidator.msgOtherExam);
    });

    test('recusa variante inexistente em vez de usar outra', () {
      final r = SheetQrValidator.match(
        payload: const ExamQrPayload(examId: 'exam_mat', variantId: 'var_apagada', studentId: 'stu_9'),
        examId: 'exam_mat',
        variants: variants,
        students: students,
      );
      expect(r.error, SheetQrValidator.msgUnknownVariant);
    });

    test('recusa aluno que não está na turma selecionada', () {
      final shared = randomizer.generateVariants(
        examId: 'exam_mat',
        questions: questions,
        sameExamForEveryone: true,
        variantCount: 1,
      );
      final r = SheetQrValidator.match(
        payload: ExamQrPayload(examId: 'exam_mat', variantId: shared.single.id, studentId: 'aluno_outra_turma'),
        examId: 'exam_mat',
        variants: shared,
        students: students,
      );
      expect(r.error, SheetQrValidator.msgStudentNotInClass);
    });

    test('recusa QR cujo aluno não confere com a prova individual', () {
      final r = SheetQrValidator.match(
        payload: ExamQrPayload(examId: 'exam_mat', variantId: variants.first.id, studentId: 'stu_2'),
        examId: 'exam_mat',
        variants: variants,
        students: students,
      );
      expect(r.error, SheetQrValidator.msgStudentMismatch);
    });
  });

  group('LeituraGabaritoScreen', () {
    const prova = ProvaCorrecao(
      id: 'exam_mat',
      titulo: 'Matemática',
      turma: '9º A',
      disciplina: 'Mat',
      totalQuestoes: 2,
      totalAlunos: 2,
      provaIndividual: true,
    );

    Future<void> pickAndLoad(WidgetTester tester, Uint8List png, List<ExamVariant> variants) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeituraGabaritoScreen(
            prova: prova,
            questions: questions,
            students: students,
            variants: variants,
            activeVariant: variants.first,
            onPickSheetImage: () async => png,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Carregar imagem de folha (PNG/JPG)'), 200);
      await tester.tap(find.text('Carregar imagem de folha (PNG/JPG)'));
      await tester.pumpAndSettle();
    }

    testWidgets('folha de outra prova é recusada e nada é corrigido', (tester) async {
      final variants = variantsFor('exam_mat');
      final otherSheet = omr.renderSyntheticSheetPng(
        qrPayload: variantsFor('exam_hist').first.qrPayload,
        totalQuestions: 2,
        markedAnswers: const {1: ['A'], 2: ['B']},
      );
      await pickAndLoad(tester, otherSheet, variants);
      expect(find.text(SheetQrValidator.msgOtherExam), findsOneWidget);
      expect(find.text('Confirmar Nota'), findsNothing);
    });

    testWidgets('imagem que não é folha (sem marcadores) é recusada', (tester) async {
      final blank = img.Image(width: 600, height: 840);
      img.fill(blank, color: img.ColorRgb8(240, 240, 240));
      await pickAndLoad(tester, Uint8List.fromList(img.encodePng(blank)), variantsFor('exam_mat'));
      expect(find.text(SheetQrValidator.msgSheetNotDetected), findsOneWidget);
      expect(find.text('Confirmar Nota'), findsNothing);
    });

    testWidgets('folha válida desta prova continua abrindo a revisão', (tester) async {
      final variants = variantsFor('exam_mat');
      final sheet = omr.renderSyntheticSheetPng(
        qrPayload: variants.first.qrPayload,
        totalQuestions: 2,
        markedAnswers: {1: [variants.first.answerKey[1]!], 2: [variants.first.answerKey[2]!]},
      );
      await pickAndLoad(tester, sheet, variants);
      expect(find.text('Confirmar Nota'), findsOneWidget);
      expect(find.textContaining('Nota prévia: 10.0/10'), findsOneWidget);
    });
  });
}
