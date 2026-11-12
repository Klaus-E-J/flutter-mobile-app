import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/export/export_screen.dart';
import 'package:avalia_pro/features/export/services/result_export_service.dart';

void main() {
  group('ResultExportService Tests (N3-08)', () {
    const exportService = ResultExportService();

    final sampleSubmissions = [
      SubmissionRecord(
        id: 'sub_1',
        examId: 'exam_1',
        examTitle: 'Avaliação de Matemática',
        classId: 'class_1',
        className: '9º Ano A',
        studentId: 'std_1',
        studentName: 'Ana Clara Conceição',
        score: 4,
        totalQuestions: 5,
        percentage: 80.0,
        variantId: 'variant_A',
        variantCode: 'A',
        blankCount: 0,
        invalidCount: 0,
        finalGrade: 8.0,
        answers: const [
          SubmissionQuestionAnswer(questionNumber: 1, marked: 'A', correct: 'A', isCorrect: true),
          SubmissionQuestionAnswer(questionNumber: 2, marked: 'B', correct: 'B', isCorrect: true),
          SubmissionQuestionAnswer(questionNumber: 3, marked: 'C', correct: 'C', isCorrect: true),
          SubmissionQuestionAnswer(questionNumber: 4, marked: 'D', correct: 'D', isCorrect: true),
          SubmissionQuestionAnswer(questionNumber: 5, marked: 'E', correct: 'A', isCorrect: false),
        ],
        createdAt: DateTime(2026, 11, 5),
      ),
      SubmissionRecord(
        id: 'sub_2',
        examId: 'exam_1',
        examTitle: 'Avaliação de Matemática',
        classId: 'class_1',
        className: '9º Ano A',
        studentId: 'std_2',
        studentName: 'Bruno Henrique Araújo',
        score: 2,
        totalQuestions: 5,
        percentage: 40.0,
        variantId: 'variant_B',
        variantCode: 'B',
        blankCount: 1,
        invalidCount: 1,
        finalGrade: 4.0,
        answers: const [
          SubmissionQuestionAnswer(questionNumber: 1, marked: 'C', correct: 'C', isCorrect: true),
          SubmissionQuestionAnswer(questionNumber: 2, marked: 'A', correct: 'D', isCorrect: false),
          SubmissionQuestionAnswer(questionNumber: 3, marked: 'EM BRANCO', correct: 'B', isCorrect: false),
          SubmissionQuestionAnswer(questionNumber: 4, marked: 'INVÁLIDA (A+B)', correct: 'E', isCorrect: false),
          SubmissionQuestionAnswer(questionNumber: 5, marked: 'D', correct: 'D', isCorrect: true),
        ],
        createdAt: DateTime(2026, 11, 5),
      ),
    ];

    test('generates CSV with UTF-8 BOM and accurate student results, statistics, and answer matrix', () {
      final bytes = exportService.generateCsvBytes(
        submissions: sampleSubmissions,
        includeStudentResults: true,
        includeStatistics: true,
        includeAnswerMatrix: true,
      );

      // Must start with UTF-8 BOM bytes (0xEF, 0xBB, 0xBF) for Excel compatibility
      expect(bytes.sublist(0, 3), equals([0xEF, 0xBB, 0xBF]));
      final text = utf8.decode(bytes);
      expect(text, contains('Ana Clara Conceição'));
      expect(text, contains('Bruno Henrique Araújo'));
      expect(text, contains('Avaliação de Matemática'));
      expect(text, contains('8.00'));
      expect(text, contains('4.00'));
      expect(text, contains('ESTATÍSTICAS DA TURMA'));
      expect(text, contains('MATRIZ DE RESPOSTAS E GABARITO'));
      expect(text, contains('INVÁLIDA (A+B)'));
    });

    test('generates multi-sheet Excel (.xlsx) workbook with Resultados, Estatisticas, and Gabarito_Respostas', () {
      final bytes = exportService.generateExcelBytes(
        submissions: sampleSubmissions,
        includeStudentResults: true,
        includeStatistics: true,
        includeAnswerMatrix: true,
      );

      expect(bytes, isNotEmpty);

      final decodedExcel = Excel.decodeBytes(bytes);
      expect(decodedExcel.tables.keys, contains('Resultados'));
      expect(decodedExcel.tables.keys, contains('Estatisticas'));
      expect(decodedExcel.tables.keys, contains('Gabarito_Respostas'));

      final resultsSheet = decodedExcel['Resultados'];
      expect(resultsSheet.rows.length, greaterThanOrEqualTo(3)); // Header + 2 students
    });

    testWidgets('ExportScreen loads submissions, generates real file, and invokes share callback', (tester) async {
      Uint8List? exportedBytes;
      String? exportedFileName;

      await tester.pumpWidget(
        MaterialApp(
          home: ExportScreen(
            initialSubmissions: sampleSubmissions,
            onShareExportedFile: (bytes, fileName, mimeType) async {
              exportedBytes = bytes;
              exportedFileName = fileName;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exportar'), findsOneWidget);
      expect(find.text('Resultados dos alunos'), findsOneWidget);

      // Scroll down to Format and Export button
      await tester.scrollUntilVisible(
        find.text('Exportar e compartilhar'),
        200.0,
      );
      await tester.pumpAndSettle();

      // Select CSV format to test format toggle
      await tester.tap(find.text('CSV (.csv)'));
      await tester.pumpAndSettle();

      // Trigger export
      await tester.tap(find.text('Exportar e compartilhar'));
      await tester.pumpAndSettle();

      expect(find.text('Arquivo gerado!'), findsOneWidget);

      // Tap Compartilhar / Salvar
      await tester.tap(find.text('Compartilhar / Salvar'));
      await tester.pumpAndSettle();

      expect(exportedBytes, isNotNull);
      expect(exportedBytes!, isNotEmpty);
      expect(exportedFileName, endsWith('.csv'));
    });
  });
}
