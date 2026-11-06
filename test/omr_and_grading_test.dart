import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/correction/services/exam_grading_service.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/exams/models/exam_variant.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';

void main() {
  group('ExamGradingService Tests (N3-05)', () {
    const gradingService = ExamGradingService();
    const randomizer = ExamRandomizerService();

    ExamVariant buildTestVariant() {
      final questions = [
        Questao(
          id: 'q1',
          enunciado: 'Questão 1',
          alternativas: [
            Alternativa(id: 'a1', texto: 'Alt A', correta: true),
            Alternativa(id: 'a2', texto: 'Alt B'),
            Alternativa(id: 'a3', texto: 'Alt C'),
            Alternativa(id: 'a4', texto: 'Alt D'),
          ],
        ),
        Questao(
          id: 'q2',
          enunciado: 'Questão 2',
          alternativas: [
            Alternativa(id: 'b1', texto: 'Alt A'),
            Alternativa(id: 'b2', texto: 'Alt B', correta: true),
            Alternativa(id: 'b3', texto: 'Alt C'),
            Alternativa(id: 'b4', texto: 'Alt D'),
          ],
        ),
        Questao(
          id: 'q3',
          enunciado: 'Questão 3',
          alternativas: [
            Alternativa(id: 'c1', texto: 'Alt A'),
            Alternativa(id: 'c2', texto: 'Alt B'),
            Alternativa(id: 'c3', texto: 'Alt C', correta: true),
            Alternativa(id: 'c4', texto: 'Alt D'),
          ],
        ),
        Questao(
          id: 'q4',
          enunciado: 'Questão 4',
          alternativas: [
            Alternativa(id: 'd1', texto: 'Alt A'),
            Alternativa(id: 'd2', texto: 'Alt B'),
            Alternativa(id: 'd3', texto: 'Alt C'),
            Alternativa(id: 'd4', texto: 'Alt D', correta: true),
          ],
        ),
        Questao(
          id: 'q5',
          enunciado: 'Questão 5',
          alternativas: [
            Alternativa(id: 'e1', texto: 'Alt A', correta: true),
            Alternativa(id: 'e2', texto: 'Alt B'),
            Alternativa(id: 'e3', texto: 'Alt C'),
            Alternativa(id: 'e4', texto: 'Alt D'),
          ],
        ),
      ];
      return randomizer.buildCanonicalVariant(
        examId: 'exam_grade',
        questions: questions,
      );
    }

    test('grades 100% correct answers accurately', () {
      final variant = buildTestVariant();
      final result = gradingService.gradeFromMarkedLetters(
        variant: variant,
        markedLettersByQuestion: {
          1: ['A'],
          2: ['B'],
          3: ['C'],
          4: ['D'],
          5: ['A'],
        },
      );

      expect(result.correctCount, 5);
      expect(result.wrongCount, 0);
      expect(result.blankCount, 0);
      expect(result.invalidMultipleCount, 0);
      expect(result.percentage, 100.0);
      expect(result.finalGrade, 10.0);
    });

    test('identifies correct, wrong, blank, multiple marks, and annulled questions', () {
      final variant = buildTestVariant();
      final result = gradingService.gradeFromMarkedLetters(
        variant: variant,
        markedLettersByQuestion: {
          1: ['A'], // Correct
          2: ['D'], // Wrong (correct is B)
          3: [], // Blank (unanswered)
          4: ['B', 'D'], // Invalid multiple marks (rasura)
          5: [], // Blank, but question 5 is annulled -> awards full point!
        },
        annulledQuestions: {5},
      );

      expect(result.correctCount, 2); // Q1 + annulled Q5
      expect(result.wrongCount, 1); // Q2
      expect(result.blankCount, 1); // Q3
      expect(result.invalidMultipleCount, 1); // Q4
      expect(result.annulledCount, 1); // Q5
      expect(result.percentage, 40.0);
      expect(result.finalGrade, 4.0);

      expect(result.answers[0].isCorrect, isTrue);
      expect(result.answers[1].isCorrect, isFalse);
      expect(result.answers[2].marked, equals('EM BRANCO'));
      expect(result.answers[3].marked, equals('INVÁLIDA (B+D)'));
      expect(result.answers[4].marked, equals('ANULADA'));
      expect(result.answers[4].isCorrect, isTrue);
    });
  });

  group('OmrImageService Computer Vision Tests (N3-04)', () {
    const omrService = OmrImageService();
    const gradingService = ExamGradingService();
    const randomizer = ExamRandomizerService();

    test('decodes QR Code, rectifies perspective skew, and detects filled, blank, and double bubbles', () {
      final questions = List<Questao>.generate(
        6,
        (i) => Questao(
          id: 'q_${i + 1}',
          enunciado: 'Pergunta ${i + 1}',
          alternativas: [
            Alternativa(id: 'a', texto: 'A', correta: i % 4 == 0),
            Alternativa(id: 'b', texto: 'B', correta: i % 4 == 1),
            Alternativa(id: 'c', texto: 'C', correta: i % 4 == 2),
            Alternativa(id: 'd', texto: 'D', correta: i % 4 == 3),
            Alternativa(id: 'e', texto: 'E'),
          ],
        ),
      );

      final variant = randomizer
          .generateVariants(
            examId: 'exam_omr_cv',
            questions: questions,
            sameExamForEveryone: true,
            variantCount: 1,
            seed: 123,
          )
          .single;

      // Simulate student markings on the sheet:
      // Q1: single mark 'C'
      // Q2: single mark 'A'
      // Q3: blank []
      // Q4: double mark ['B', 'D'] (invalid!)
      // Q5: single mark 'E'
      // Q6: single mark matching variant's answerKey[6]
      final expectedQ6 = variant.answerKey[6]!;
      final simulatedMarks = <int, List<String>>{
        1: ['C'],
        2: ['A'],
        3: [],
        4: ['B', 'D'],
        5: ['E'],
        6: [expectedQ6],
      };

      // Render synthetic image with simulated camera perspective skew!
      final pngBytes = omrService.renderSyntheticSheetPng(
        qrPayload: variant.qrPayload,
        totalQuestions: 6,
        markedAnswers: simulatedMarks,
        simulatePerspectiveSkew: true,
      );

      final scanResult = omrService.processSheetBytes(
        imageBytes: pngBytes,
        expectedQuestions: 6,
      );

      // 1. Verify QR Code was decoded from the image
      expect(scanResult.qrPayload, isNotNull);
      expect(scanResult.qrPayload!.examId, 'exam_omr_cv');
      expect(scanResult.qrPayload!.variantId, variant.id);

      // 2. Verify perspective correction was applied using the 4 fiducial markers
      expect(scanResult.perspectiveCorrected, isTrue);
      expect(scanResult.detectedCorners.length, 4);

      // 3. Verify bubble detection for all 6 questions
      expect(scanResult.questions[1]!.markedLetters, equals(['C']));
      expect(scanResult.questions[2]!.markedLetters, equals(['A']));
      expect(scanResult.questions[3]!.isBlank, isTrue);
      expect(scanResult.questions[4]!.isMultipleMarks, isTrue);
      expect(scanResult.questions[4]!.markedLetters, equals(['B', 'D']));
      expect(scanResult.questions[5]!.markedLetters, equals(['E']));
      expect(scanResult.questions[6]!.markedLetters, equals([expectedQ6]));

      // 4. Verify grading integration with the scanned OMR sheet
      final gradeResult = gradingService.gradeOmrScan(
        variant: variant,
        scanResult: scanResult,
      );
      expect(gradeResult.blankCount, 1);
      expect(gradeResult.invalidMultipleCount, 1);
      expect(gradeResult.answers[5].isCorrect, isTrue);
    });

    test('accurately detects fiducials and bubbles under dark desk border, uneven shadow gradient, and perspective skew across 2 columns (20 questions)', () {
      final questions = List<Questao>.generate(
        20,
        (i) => Questao(
          id: 'q_${i + 1}',
          enunciado: 'Questão ${i + 1}',
          alternativas: [
            Alternativa(id: 'a', texto: 'A', correta: i % 5 == 0),
            Alternativa(id: 'b', texto: 'B', correta: i % 5 == 1),
            Alternativa(id: 'c', texto: 'C', correta: i % 5 == 2),
            Alternativa(id: 'd', texto: 'D', correta: i % 5 == 3),
            Alternativa(id: 'e', texto: 'E', correta: i % 5 == 4),
          ],
        ),
      );

      final variant = randomizer
          .generateVariants(
            examId: 'exam_shadow_border',
            questions: questions,
            sameExamForEveryone: true,
            variantCount: 1,
            seed: 777,
          )
          .single;

      final simulatedMarks = <int, List<String>>{};
      for (var q = 1; q <= 20; q++) {
        if (q == 10 || q == 19) {
          simulatedMarks[q] = const []; // Blank in both column 1 and shadowed column 2
        } else if (q == 15) {
          simulatedMarks[q] = const ['A', 'E']; // Double mark at bottom of column 1
        } else {
          simulatedMarks[q] = [variant.answerKey[q]!];
        }
      }

      final pngBytes = omrService.renderSyntheticSheetPng(
        qrPayload: variant.qrPayload,
        totalQuestions: 20,
        markedAnswers: simulatedMarks,
        simulatePerspectiveSkew: true,
        simulateDarkBorder: true,
        simulateLightingGradient: true,
      );

      final scanResult = omrService.processSheetBytes(
        imageBytes: pngBytes,
        expectedQuestions: 20,
      );

      expect(scanResult.perspectiveCorrected, isTrue);
      expect(scanResult.qrPayload, isNotNull);
      expect(scanResult.qrPayload!.examId, 'exam_shadow_border');

      // Verify fiducial corners were NOT pulled to the outer (0,0) dark desk border
      for (final corner in scanResult.detectedCorners) {
        expect(corner.x, greaterThan(35));
        expect(corner.y, greaterThan(30));
      }

      // Verify blank questions in shadowed bottom-right were NOT misclassified as filled
      expect(scanResult.questions[10]!.isBlank, isTrue);
      expect(scanResult.questions[19]!.isBlank, isTrue);
      expect(scanResult.questions[15]!.isMultipleMarks, isTrue);

      final gradeResult = gradingService.gradeOmrScan(
        variant: variant,
        scanResult: scanResult,
      );
      expect(gradeResult.correctCount, 17);
      expect(gradeResult.blankCount, 2);
      expect(gradeResult.invalidMultipleCount, 1);
    });
  });
}
