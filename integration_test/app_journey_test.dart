import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/correction/services/exam_grading_service.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/exams/services/exam_pdf_service.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/features/export/services/result_export_service.dart';
import 'package:avalia_pro/features/statistics/data/firestore_statistics_repository.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Entrega N3 — Complete Teacher & Student Journey (integration_test)', () {
    const randomizerService = ExamRandomizerService();
    const pdfService = ExamPdfService();
    const omrService = OmrImageService();
    const gradingService = ExamGradingService();
    const exportService = ResultExportService();

    test(
      'Full N3 Journey: Quick Answer Key -> Shuffled Variants + Nominal Sheets -> PDF & Word (.doc) -> OMR Scan -> Canonical Stats -> Excel (.xlsx)',
      () async {
        // 1. Teacher creates a 5-question exam using "Gabarito Rápido (Prova Externa)" (A..E)
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

        // 2. Generate individual shuffled variants per student
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

        // Also verify nominal answer sheets generation when sameExamForEveryone == true
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

        // 3. Export Printable PDF and Editable Word (.doc)
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

        // 4. Simulate OMR Scanning and Canonical Grading
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

        // 5. Verify Canonical Class Statistics (A..E distribution + most marked option)
        final stats = FirestoreStatisticsRepository.buildClassStatsFromSubmissions(
          className: '3º Ano A',
          examName: 'Simulado N3',
          matching: [aliceSub],
        );
        expect(stats.questionStats.length, 5);
        final q2Stats = stats.questionStats.firstWhere((q) => q.questionNumber == 2);
        expect(q2Stats.mostMarkedOption, 'E');
        expect(q2Stats.mostMarkedPercentage, 100.0);

        // 6. Export Excel (.xlsx) with Canonical Distribution
        final xlsxBytes = exportService.generateExcelBytes(
          submissions: [aliceSub],
          includeStudentResults: true,
          includeStatistics: true,
          includeAnswerMatrix: true,
        );
        final excel = Excel.decodeBytes(xlsxBytes);
        expect(excel.tables.containsKey('Estatisticas'), isTrue);
      },
    );
  });
}
