import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/exams/services/exam_pdf_service.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';

void main() {
  group('ExamPdfService Tests (N3-03)', () {
    const pdfService = ExamPdfService();
    const randomizer = ExamRandomizerService();

    final questions = [
      Questao(
        id: 'q1',
        enunciado: 'Qual é a fórmula química da água?',
        alternativas: [
          Alternativa(id: 'a1', texto: 'H2O', correta: true),
          Alternativa(id: 'a2', texto: 'CO2'),
          Alternativa(id: 'a3', texto: 'O2'),
          Alternativa(id: 'a4', texto: 'NaCl'),
        ],
      ),
      Questao(
        id: 'q2',
        enunciado: 'Qual é o maior oceano da Terra?',
        alternativas: [
          Alternativa(id: 'b1', texto: 'Oceano Atlântico'),
          Alternativa(id: 'b2', texto: 'Oceano Pacífico', correta: true),
          Alternativa(id: 'b3', texto: 'Oceano Índico'),
          Alternativa(id: 'b4', texto: 'Oceano Ártico'),
        ],
      ),
    ];

    test('generates valid Exam Booklet PDF bytes for multiple variants', () async {
      final variants = randomizer.generateVariants(
        examId: 'exam_pdf_1',
        questions: questions,
        sameExamForEveryone: true,
        variantCount: 2,
        seed: 10,
      );

      final bytes = await pdfService.generateExamBookletPdf(
        examTitle: 'Avaliação de Ciências',
        classNames: const ['9º Ano A'],
        variants: variants,
      );

      expect(bytes, isNotEmpty);
      final header = ascii.decode(bytes.sublist(0, 5), allowInvalid: true);
      expect(header, equals('%PDF-'));
    });

    test('generates valid OMR Answer Sheet PDF bytes with QR Code and fiducial markers', () async {
      final variants = randomizer.generateVariants(
        examId: 'exam_pdf_2',
        questions: questions,
        sameExamForEveryone: true,
        variantCount: 2,
        seed: 20,
      );

      final bytes = await pdfService.generateAnswerSheetsPdf(
        examTitle: 'Avaliação de Ciências',
        classNames: const ['9º Ano A'],
        variants: variants,
      );

      expect(bytes, isNotEmpty);
      final header = ascii.decode(bytes.sublist(0, 5), allowInvalid: true);
      expect(header, equals('%PDF-'));
    });

    test('generates combined print package (booklet + answer sheet + answer key summary)', () async {
      final variants = randomizer.generateVariants(
        examId: 'exam_pdf_3',
        questions: questions,
        sameExamForEveryone: true,
        variantCount: 2,
        seed: 30,
      );

      final bytes = await pdfService.generateCompleteExamPackagePdf(
        examTitle: 'Avaliação Bimestral',
        classNames: const ['9º Ano A', '9º Ano B'],
        variants: variants,
        includeTeacherAnswerKey: true,
      );

      expect(bytes.length, greaterThan(1000));
      final header = ascii.decode(bytes.sublist(0, 5), allowInvalid: true);
      expect(header, equals('%PDF-'));
    });
  });
}
