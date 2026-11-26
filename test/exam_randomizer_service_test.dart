import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/exams/models/exam_variant.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';

void main() {
  group('ExamRandomizerService Tests (N3-02)', () {
    const randomizer = ExamRandomizerService();

    List<Questao> buildSampleQuestions() {
      return [
        Questao(
          id: 'q1',
          enunciado: 'Qual é a capital do Brasil?',
          alternativas: [
            Alternativa(id: 'q1_a1', texto: 'São Paulo'),
            Alternativa(id: 'q1_a2', texto: 'Rio de Janeiro'),
            Alternativa(id: 'q1_a3', texto: 'Brasília', correta: true),
            Alternativa(id: 'q1_a4', texto: 'Salvador'),
            Alternativa(id: 'q1_a5', texto: 'Belo Horizonte'),
          ],
        ),
        Questao(
          id: 'q2',
          enunciado: 'Quanto é 7 x 8?',
          alternativas: [
            Alternativa(id: 'q2_a1', texto: '56', correta: true),
            Alternativa(id: 'q2_a2', texto: '54'),
            Alternativa(id: 'q2_a3', texto: '64'),
            Alternativa(id: 'q2_a4', texto: '48'),
          ],
        ),
        Questao(
          id: 'q3',
          enunciado: 'Qual planeta é conhecido como Planeta Vermelho?',
          alternativas: [
            Alternativa(id: 'q3_a1', texto: 'Vênus'),
            Alternativa(id: 'q3_a2', texto: 'Júpiter'),
            Alternativa(id: 'q3_a3', texto: 'Saturno'),
            Alternativa(id: 'q3_a4', texto: 'Marte', correta: true),
          ],
        ),
        Questao(
          id: 'q4',
          enunciado: 'Quem escreveu Dom Casmurro?',
          alternativas: [
            Alternativa(id: 'q4_a1', texto: 'José de Alencar'),
            Alternativa(id: 'q4_a2', texto: 'Machado de Assis', correta: true),
            Alternativa(id: 'q4_a3', texto: 'Clarice Lispector'),
            Alternativa(id: 'q4_a4', texto: 'Carlos Drummond'),
          ],
        ),
      ];
    }

    test('maintains 100% answer key integrity across 100 random iterations', () {
      final masterQuestions = buildSampleQuestions();

      for (int iteration = 0; iteration < 100; iteration++) {
        final variants = randomizer.generateVariants(
          examId: 'exam_100',
          questions: masterQuestions,
          sameExamForEveryone: true,
          variantCount: 4,
          seed: iteration * 997,
        );

        expect(variants.length, 4);
        for (final variant in variants) {
          expect(
            randomizer.verifyVariantIntegrity(variant, masterQuestions),
            isTrue,
            reason: 'Variant ${variant.id} in iteration $iteration failed integrity check',
          );

          // Explicitly verify that the answerKey letter points to the exact original correct alternative text
          for (final vq in variant.questions) {
            final expectedMaster =
                masterQuestions.firstWhere((mq) => mq.id == vq.originalQuestionId);
            final expectedCorrectAlt = expectedMaster.alternativaCorreta!;

            final keyLetter = variant.answerKey[vq.questionNumber];
            expect(keyLetter, isNotNull);
            expect(keyLetter, equals(vq.correctLetter));

            final markedAlt = vq.alternatives.firstWhere((a) => a.letter == keyLetter);
            expect(markedAlt.isCorrect, isTrue);
            expect(markedAlt.originalAlternativeId, equals(expectedCorrectAlt.id));
            expect(markedAlt.text, equals(expectedCorrectAlt.texto));
          }
        }
      }
    });

    test('generates individual variants per student when sameExamForEveryone is false', () {
      final masterQuestions = buildSampleQuestions();
      final students = [
        const StudentRecord(id: 'std_1', name: 'Alice Ferreira', matricula: '202601'),
        const StudentRecord(id: 'std_2', name: 'Bruno Gomes', matricula: '202602'),
        const StudentRecord(id: 'std_3', name: 'Carla Dias', matricula: '202603'),
      ];

      final variants = randomizer.generateVariants(
        examId: 'exam_ind',
        questions: masterQuestions,
        sameExamForEveryone: false,
        students: students,
        classId: 'class_1',
        className: '9º Ano A',
        seed: 42,
      );

      expect(variants.length, 3);
      expect(variants[0].studentId, 'std_1');
      expect(variants[0].studentName, 'Alice Ferreira');
      expect(variants[1].studentId, 'std_2');
      expect(variants[2].studentId, 'std_3');

      for (final v in variants) {
        expect(randomizer.verifyVariantIntegrity(v, masterQuestions), isTrue);
      }
    });

    test('encodes and decodes QR Code payload and serializes to/from Map', () {
      final masterQuestions = buildSampleQuestions();
      final variants = randomizer.generateVariants(
        examId: 'exam_qr',
        questions: masterQuestions,
        sameExamForEveryone: false,
        students: const [
          StudentRecord(id: 'student_99', name: 'Diego Alves'),
        ],
        seed: 7,
      );

      final variant = variants.single;
      final qr = variant.qrPayload;
      expect(qr, startsWith('AVALIA:1.0|exam_qr|'));

      final parsedQr = ExamQrPayload.tryParse(qr);
      expect(parsedQr, isNotNull);
      expect(parsedQr!.examId, 'exam_qr');
      expect(parsedQr.variantId, variant.id);
      expect(parsedQr.studentId, 'student_99');

      // Serialization round-trip
      final map = variant.toMap();
      final restored = ExamVariant.fromMap(variant.id, map);
      expect(restored.examId, variant.examId);
      expect(restored.code, variant.code);
      expect(restored.studentId, 'student_99');
      expect(restored.answerKey, equals(variant.answerKey));
      expect(restored.questions.length, masterQuestions.length);
      expect(randomizer.verifyVariantIntegrity(restored, masterQuestions), isTrue);
    });

    test('supports 5 alternatives (A-E), records originalLetter, and maps back to canonical letter', () {
      final q = criarQuestaoVazia();
      expect(Questao.maximoAlternativas, 5);
      expect(Questao.maximoQuestoesOmr, 30);
      expect(q.alternativas.length, 5);

      final quickQ = criarQuestaoGabaritoRapido(
        numero: 1,
        letraCorreta: 'E',
      );
      expect(quickQ.alternativas.length, 5);
      expect(quickQ.alternativas.indexWhere((a) => a.correta), 4);

      final masterQuestions = buildSampleQuestions();
      final variants = randomizer.generateVariants(
        examId: 'exam_canonical_map',
        questions: masterQuestions,
        sameExamForEveryone: true,
        variantCount: 2,
        seed: 101,
      );

      for (final variant in variants) {
        for (final vq in variant.questions) {
          final masterQ = masterQuestions[vq.originalQuestionOrder];
          expect(vq.originalQuestionNumber, vq.originalQuestionOrder + 1);

          final correctIndex =
              masterQ.alternativas.indexWhere((a) => a.correta);
          final expectedMasterCorrectLetter =
              ['A', 'B', 'C', 'D', 'E'][correctIndex];
          expect(vq.canonicalCorrectLetter, expectedMasterCorrectLetter);
          expect(
            vq.toCanonicalLetter(vq.correctLetter),
            expectedMasterCorrectLetter,
          );
        }
      }
    });

    test('builds nominal OMR answer sheet variants per student even when sameExamForEveryone is true', () {
      final masterQuestions = buildSampleQuestions();
      final baseVariant = randomizer
          .generateVariants(
            examId: 'exam_nominal',
            questions: masterQuestions,
            sameExamForEveryone: true,
            variantCount: 1,
            seed: 55,
          )
          .single;

      final students = const [
        StudentRecord(id: 's1', name: 'Beatriz Lima', matricula: '202610'),
        StudentRecord(id: 's2', name: 'Caio Martins', matricula: '202611'),
      ];

      final nominalSheets = randomizer.buildNominalAnswerSheetVariants(
        baseVariants: [baseVariant],
        students: students,
        classId: 'c1',
        className: '3º Ano B',
      );

      expect(nominalSheets.length, 2);
      expect(nominalSheets[0].studentId, 's1');
      expect(nominalSheets[0].studentName, 'Beatriz Lima');
      expect(nominalSheets[0].studentMatricula, '202610');
      expect(nominalSheets[0].answerKey, equals(baseVariant.answerKey));

      final qr0 = ExamQrPayload.tryParse(nominalSheets[0].qrPayload);
      expect(qr0, isNotNull);
      expect(qr0!.examId, 'exam_nominal');
      expect(qr0.variantId, baseVariant.id);
      expect(qr0.studentId, 's1');
    });
  });
}
