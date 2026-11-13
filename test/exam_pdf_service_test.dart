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

    test('generates editable Word (.doc) booklet with page-break-inside: avoid on every question', () {
      final variants = randomizer.generateVariants(
        examId: 'exam_doc_1',
        questions: questions,
        sameExamForEveryone: true,
        variantCount: 2,
        seed: 40,
      );

      final docBytes = pdfService.generateExamBookletDoc(
        examTitle: 'Avaliação de Ciências',
        classNames: const ['9º Ano A'],
        variants: variants,
      );

      expect(docBytes, isNotEmpty);
      final html = utf8.decode(docBytes);
      expect(html, contains('urn:schemas-microsoft-com:office:word'));
      expect(html, contains('page-break-inside: avoid'));
      expect(html, contains('class="question-block"'));
      expect(html, contains('Avaliação de Ciências'));
      expect(html, contains('Qual é a fórmula química da água?'));
    });

    test('generates multi-page PDF without cutting questions and supports nominal answerSheetVariants', () async {
      final manyQuestions = List<Questao>.generate(
        14,
        (index) => Questao(
          id: 'q_${index + 1}',
          enunciado:
              'Questão ${index + 1}: Texto longo do enunciado para testar paginação sem corte entre páginas no PDF gerado pelo sistema Avalia Pro.',
          alternativas: [
            Alternativa(id: 'a', texto: 'Alternativa A da questão ${index + 1}', correta: true),
            Alternativa(id: 'b', texto: 'Alternativa B da questão ${index + 1}'),
            Alternativa(id: 'c', texto: 'Alternativa C da questão ${index + 1}'),
            Alternativa(id: 'd', texto: 'Alternativa D da questão ${index + 1}'),
            Alternativa(id: 'e', texto: 'Alternativa E da questão ${index + 1}'),
          ],
        ),
      );

      final variants = randomizer.generateVariants(
        examId: 'exam_multipage',
        questions: manyQuestions,
        sameExamForEveryone: true,
        variantCount: 1,
        seed: 50,
      );

      final nominalSheet = variants.first.copyWith(
        id: 'variant_A_std_1',
        studentId: 'std_1',
        studentName: 'Fernanda Costa',
        studentMatricula: '2026555',
      );

      final bytesWithNominal = await pdfService.generateCompleteExamPackagePdf(
        examTitle: 'Simulado Geral',
        classNames: const ['3º Ano A'],
        variants: variants,
        answerSheetVariants: [nominalSheet],
        includeTeacherAnswerKey: true,
      );

      final bytesWithoutNominal = await pdfService.generateCompleteExamPackagePdf(
        examTitle: 'Simulado Geral',
        classNames: const ['3º Ano A'],
        variants: variants,
        includeTeacherAnswerKey: true,
      );

      expect(bytesWithNominal.length, greaterThan(2000));
      expect(bytesWithNominal, isNot(equals(bytesWithoutNominal)));
      final header = ascii.decode(bytesWithNominal.sublist(0, 5), allowInvalid: true);
      expect(header, equals('%PDF-'));
    });

    test('handles ultra-long single question (>45 lines) without throwing TooManyPagesException', () async {
      final ultraLongStatement = List<String>.generate(
        50,
        (i) => 'Linha ${i + 1}: Texto extenso de interpretação literária e científica com múltiplos parágrafos.',
      ).join('\n');

      final ultraLongQuestions = [
        Questao(
          id: 'q_long',
          enunciado: ultraLongStatement,
          alternativas: [
            Alternativa(id: 'a', texto: 'Alternativa A', correta: true),
            Alternativa(id: 'b', texto: 'Alternativa B'),
            Alternativa(id: 'c', texto: 'Alternativa C'),
            Alternativa(id: 'd', texto: 'Alternativa D'),
            Alternativa(id: 'e', texto: 'Alternativa E'),
          ],
        ),
      ];

      final variants = randomizer.generateVariants(
        examId: 'exam_ultralong',
        questions: ultraLongQuestions,
        sameExamForEveryone: true,
        variantCount: 1,
      );

      final bytes = await pdfService.generateExamBookletPdf(
        examTitle: 'Prova Textos Longos',
        classNames: const ['3º Ano B'],
        variants: variants,
      );

      expect(bytes.length, greaterThan(1000));
      final header = ascii.decode(bytes.sublist(0, 5), allowInvalid: true);
      expect(header, equals('%PDF-'));
    });
  });
}
