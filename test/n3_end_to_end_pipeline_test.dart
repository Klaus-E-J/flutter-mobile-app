import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/classes/services/student_import_service.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/correction/services/exam_grading_service.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/exams/services/exam_pdf_service.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/features/export/services/result_export_service.dart';
import 'package:avalia_pro/features/statistics/data/firestore_statistics_repository.dart';
import 'package:avalia_pro/screens/correcao/leitura_gabarito_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';

void main() {
  group('Entrega N3 — End-to-End Integration Pipeline (N3-01 to N3-10)', () {
    const importService = StudentImportService();
    const randomizerService = ExamRandomizerService();
    const pdfService = ExamPdfService();
    const omrService = OmrImageService();
    const gradingService = ExamGradingService();
    const exportService = ResultExportService();

    test('Executes full N3 pipeline: Import -> Randomize -> PDF -> OMR Scan -> Grade -> Export CSV/Excel', () async {
      // 1. N3-01: Import students from CSV
      const csvInput = '\uFEFFNome Completo;Matrícula;E-mail\n'
          'Helena Vasconcelos;2026101;helena@escola.br\n'
          'Igor Cavalcanti;2026102;igor@escola.br\n'
          'Helena Vasconcelos;2026999;duplicada@escola.br\n';

      final importResult = importService.parseBytes(
        bytes: Uint8List.fromList(utf8.encode(csvInput)),
        fileName: 'turma_3a.csv',
      );

      expect(importResult.validStudents.length, 2);
      expect(importResult.duplicates.length, 1);
      final students = [
        for (var i = 0; i < importResult.validStudents.length; i++)
          importResult.validStudents[i].id.isEmpty
              ? importResult.validStudents[i]
              : importResult.validStudents[i],
      ];

      // 2. N3-02: Create Exam Questions and Generate Randomized Variants
      final masterQuestions = [
        Questao(
          id: 'q1',
          enunciado: 'Qual é o resultado de 12 + 15?',
          alternativas: [
            Alternativa(id: 'q1_a', texto: '25'),
            Alternativa(id: 'q1_b', texto: '27', correta: true),
            Alternativa(id: 'q1_c', texto: '29'),
            Alternativa(id: 'q1_d', texto: '31'),
          ],
        ),
        Questao(
          id: 'q2',
          enunciado: 'Qual é a raiz quadrada de 81?',
          alternativas: [
            Alternativa(id: 'q2_a', texto: '7'),
            Alternativa(id: 'q2_b', texto: '8'),
            Alternativa(id: 'q2_c', texto: '9', correta: true),
            Alternativa(id: 'q2_d', texto: '10'),
          ],
        ),
        Questao(
          id: 'q3',
          enunciado: 'Quanto é 5 ao cubo?',
          alternativas: [
            Alternativa(id: 'q3_a', texto: '125', correta: true),
            Alternativa(id: 'q3_b', texto: '25'),
            Alternativa(id: 'q3_c', texto: '75'),
            Alternativa(id: 'q3_d', texto: '150'),
          ],
        ),
        Questao(
          id: 'q4',
          enunciado: 'Qual é o valor de pi aproximado?',
          alternativas: [
            Alternativa(id: 'q4_a', texto: '2,14'),
            Alternativa(id: 'q4_b', texto: '3,14', correta: true),
            Alternativa(id: 'q4_c', texto: '4,14'),
            Alternativa(id: 'q4_d', texto: '1,14'),
          ],
        ),
      ];

      final variants = randomizerService.generateVariants(
        examId: 'exam_n3_e2e',
        questions: masterQuestions,
        sameExamForEveryone: true,
        variantCount: 2,
        seed: 2026,
      );

      expect(variants.length, 2);
      for (final v in variants) {
        expect(randomizerService.verifyVariantIntegrity(v, masterQuestions), isTrue);
      }

      // 3. N3-03: Generate Printable PDF Package (Booklet + OMR Answer Sheets with QR)
      final pdfBytes = await pdfService.generateCompleteExamPackagePdf(
        examTitle: 'Prova Final N3',
        classNames: const ['3º Ano A'],
        variants: variants,
      );
      expect(pdfBytes.length, greaterThan(1500));
      expect(ascii.decode(pdfBytes.sublist(0, 5), allowInvalid: true), '%PDF-');

      // 4. N3-04 & N3-05: Render OMR Sheets, Scan with Computer Vision, and Auto-Grade
      // Student 1 (Helena) takes Variant A and answers all 4 questions correctly!
      final variantA = variants[0];
      final helenaMarks = <int, List<String>>{
        for (var q = 1; q <= 4; q++) q: [variantA.answerKey[q]!],
      };
      final helenaSheetPng = omrService.renderSyntheticSheetPng(
        qrPayload: variantA.qrPayload,
        totalQuestions: 4,
        markedAnswers: helenaMarks,
        simulatePerspectiveSkew: true,
      );
      final helenaScan = omrService.processSheetBytes(
        imageBytes: helenaSheetPng,
        expectedQuestions: 4,
      );
      expect(helenaScan.qrPayload?.variantId, variantA.id);
      expect(helenaScan.perspectiveCorrected, isTrue);

      final helenaGrade = gradingService.gradeOmrScan(
        variant: variantA,
        scanResult: helenaScan,
      );
      expect(helenaGrade.correctCount, 4);
      expect(helenaGrade.finalGrade, 10.0);

      // Student 2 (Igor) takes Variant B: answers Q1 & Q2 right, leaves Q3 blank, double-marks Q4
      final variantB = variants[1];
      final igorMarks = <int, List<String>>{
        1: [variantB.answerKey[1]!],
        2: [variantB.answerKey[2]!],
        3: const [], // Blank
        4: const ['A', 'D'], // Invalid double mark
      };
      final igorSheetPng = omrService.renderSyntheticSheetPng(
        qrPayload: variantB.qrPayload,
        totalQuestions: 4,
        markedAnswers: igorMarks,
        simulatePerspectiveSkew: true,
      );
      final igorScan = omrService.processSheetBytes(
        imageBytes: igorSheetPng,
        expectedQuestions: 4,
      );
      expect(igorScan.qrPayload?.variantId, variantB.id);
      final igorGrade = gradingService.gradeOmrScan(
        variant: variantB,
        scanResult: igorScan,
      );
      expect(igorGrade.correctCount, 2);
      expect(igorGrade.blankCount, 1);
      expect(igorGrade.invalidMultipleCount, 1);
      expect(igorGrade.finalGrade, 5.0);

      // Build SubmissionRecords
      final submissions = [
        SubmissionRecord(
          id: 'sub_helena',
          examId: 'exam_n3_e2e',
          examTitle: 'Prova Final N3',
          classId: 'class_3a',
          className: '3º Ano A',
          studentId: 'std_helena',
          studentName: students[0].name,
          score: helenaGrade.correctCount,
          totalQuestions: helenaGrade.totalQuestions,
          percentage: helenaGrade.percentage,
          variantId: helenaGrade.variantId,
          variantCode: helenaGrade.variantCode,
          blankCount: helenaGrade.blankCount,
          invalidCount: helenaGrade.invalidMultipleCount,
          finalGrade: helenaGrade.finalGrade,
          answers: helenaGrade.answers,
        ),
        SubmissionRecord(
          id: 'sub_igor',
          examId: 'exam_n3_e2e',
          examTitle: 'Prova Final N3',
          classId: 'class_3a',
          className: '3º Ano A',
          studentId: 'std_igor',
          studentName: students[1].name,
          score: igorGrade.correctCount,
          totalQuestions: igorGrade.totalQuestions,
          percentage: igorGrade.percentage,
          variantId: igorGrade.variantId,
          variantCode: igorGrade.variantCode,
          blankCount: igorGrade.blankCount,
          invalidCount: igorGrade.invalidMultipleCount,
          finalGrade: igorGrade.finalGrade,
          answers: igorGrade.answers,
        ),
      ];

      // 5. N3-08: Export to CSV and Excel and verify contents
      final csvBytes = exportService.generateCsvBytes(
        submissions: submissions,
        includeStudentResults: true,
        includeStatistics: true,
        includeAnswerMatrix: true,
      );
      final csvText = utf8.decode(csvBytes);
      expect(csvText, contains('Helena Vasconcelos'));
      expect(csvText, contains('Igor Cavalcanti'));
      expect(csvText, contains('10.00'));
      expect(csvText, contains('5.00'));

      final excelBytes = exportService.generateExcelBytes(
        submissions: submissions,
        includeStudentResults: true,
        includeStatistics: true,
        includeAnswerMatrix: true,
      );
      final workbook = Excel.decodeBytes(excelBytes);
      expect(workbook.tables.keys, containsAll(['Resultados', 'Estatisticas', 'Gabarito_Respostas']));
    });

    testWidgets('LeituraGabaritoScreen processes uploaded OMR sheet image and records student score', (tester) async {
      final questions = [
        Questao(
          id: 'q1',
          enunciado: 'Questão 1',
          alternativas: [
            Alternativa(id: 'a1', texto: 'A', correta: true),
            Alternativa(id: 'a2', texto: 'B'),
          ],
        ),
        Questao(
          id: 'q2',
          enunciado: 'Questão 2',
          alternativas: [
            Alternativa(id: 'b1', texto: 'A'),
            Alternativa(id: 'b2', texto: 'B', correta: true),
          ],
        ),
      ];

      final variant = randomizerService.buildCanonicalVariant(
        examId: 'exam_widget_omr',
        questions: questions,
      );

      final syntheticPng = omrService.renderSyntheticSheetPng(
        qrPayload: variant.qrPayload,
        totalQuestions: 2,
        markedAnswers: const {
          1: ['A'],
          2: ['B'],
        },
      );

      const prova = ProvaCorrecao(
        id: 'exam_widget_omr',
        titulo: 'Prova OMR Widget',
        turma: '9º Ano A',
        disciplina: 'Ciências',
        totalQuestoes: 2,
        totalAlunos: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeituraGabaritoScreen(
            prova: prova,
            questions: questions,
            variants: [variant],
            activeVariant: variant,
            autoConfirmReview: true,
            onPickSheetImage: () async => syntheticPng,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Carregar imagem de folha (PNG/JPG)'),
        200.0,
      );
      await tester.pumpAndSettle();

      expect(find.text('Carregar imagem de folha (PNG/JPG)'), findsOneWidget);
      await tester.tap(find.text('Carregar imagem de folha (PNG/JPG)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Todas as 1 folhas previstas foram processadas'), findsWidgets);
    });

    test(
      'Full N3 Journey: Quick Answer Key -> Shuffled Variants + Nominal Sheets -> PDF & Word (.doc) -> OMR Scan -> Canonical Stats -> Excel (.xlsx)',
      () async {
        final quickQuestions = [
          criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A'),
          criarQuestaoGabaritoRapido(numero: 2, letraCorreta: 'E'),
          criarQuestaoGabaritoRapido(numero: 3, letraCorreta: 'B'),
          criarQuestaoGabaritoRapido(numero: 4, letraCorreta: 'C'),
          criarQuestaoGabaritoRapido(numero: 5, letraCorreta: 'D'),
        ];

        final students = const [
          StudentRecord(
            id: 'stu_1',
            name: 'Alice Ferreira',
            matricula: '2026001',
          ),
          StudentRecord(
            id: 'stu_2',
            name: 'Bruno Cardoso',
            matricula: '2026002',
          ),
        ];

        final variants = randomizerService.generateVariants(
          examId: 'exam_journey_n3',
          questions: quickQuestions,
          sameExamForEveryone: false,
          students: students,
          shuffleQuestions: true,
          shuffleAlternatives: true,
          seed: 99,
        );

        expect(variants.length, 2);
        expect(variants[0].studentMatricula, '2026001');
        expect(variants[1].studentMatricula, '2026002');

        final singleVariant = randomizerService.generateVariants(
          examId: 'exam_journey_n3',
          questions: quickQuestions,
          sameExamForEveryone: true,
          variantCount: 1,
          seed: 99,
        );
        final nominalSheets = randomizerService.buildNominalAnswerSheetVariants(
          baseVariants: singleVariant,
          students: students,
        );
        expect(nominalSheets.length, 2);
        expect(nominalSheets[0].studentName, 'Alice Ferreira');
        expect(nominalSheets[1].studentName, 'Bruno Cardoso');

        final pdfBytes = await pdfService.generateCompleteExamPackagePdf(
          examTitle: 'Simulado N3',
          classNames: const ['3º Ano A'],
          variants: singleVariant,
          answerSheetVariants: nominalSheets,
        );
        expect(pdfBytes.length, greaterThan(1500));

        final docBytes = pdfService.generateExamBookletDoc(
          examTitle: 'Simulado N3',
          classNames: const ['3º Ano A'],
          variants: variants,
        );
        final docHtml = utf8.decode(docBytes);
        expect(docHtml, contains('page-break-inside: avoid'));
        expect(docHtml, contains('Alice Ferreira'));

        final vAlice = variants[0];
        final aliceMarks = <int, List<String>>{
          for (var q = 1; q <= 5; q++) q: [vAlice.answerKey[q]!],
        };
        final alicePng = omrService.renderSyntheticSheetPng(
          qrPayload: vAlice.qrPayload,
          totalQuestions: 5,
          markedAnswers: aliceMarks,
        );
        final aliceScan = omrService.processSheetBytes(
          imageBytes: alicePng,
          expectedQuestions: 5,
        );
        final aliceGrade = gradingService.gradeOmrScan(
          scanResult: aliceScan,
          variant: vAlice,
        );
        expect(aliceGrade.finalGrade, 10.0);

        final aliceSub = SubmissionRecord(
          id: 'sub_alice',
          examId: 'exam_journey_n3',
          examTitle: 'Simulado N3',
          classId: 'class_3a',
          className: '3º Ano A',
          studentId: vAlice.studentId ?? 'stu_1',
          studentName: vAlice.studentName ?? 'Alice Ferreira',
          score: aliceGrade.correctCount,
          totalQuestions: aliceGrade.totalQuestions,
          percentage: aliceGrade.percentage,
          variantId: aliceGrade.variantId,
          variantCode: aliceGrade.variantCode,
          blankCount: aliceGrade.blankCount,
          invalidCount: aliceGrade.invalidMultipleCount,
          finalGrade: aliceGrade.finalGrade,
          answers: aliceGrade.answers,
        );

        final stats = FirestoreStatisticsRepository.buildClassStatsFromSubmissions(
          className: '3º Ano A',
          examName: 'Simulado N3',
          matching: [aliceSub],
        );
        expect(stats.questionStats.length, 5);
        final q2Stats = stats.questionStats.firstWhere((q) => q.questionNumber == 2);
        expect(q2Stats.mostMarkedOption, 'E');
        expect(q2Stats.mostMarkedPercentage, 100.0);
      },
    );
  });
}
