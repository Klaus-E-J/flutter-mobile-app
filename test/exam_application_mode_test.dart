import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/exams/models/exam_application_mode.dart';
import 'package:avalia_pro/features/exams/models/exam_variant.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const randomizer = ExamRandomizerService();

  // 10 questões com 5 alternativas: embaralhar sem mudar nada é praticamente impossível.
  final questions = List<Questao>.generate(
    10,
    (q) => Questao(
      id: 'q$q',
      enunciado: 'Questão $q',
      alternativas: List<Alternativa>.generate(
        5,
        (a) => Alternativa(id: 'q${q}_a$a', texto: 'Alt $a', correta: a == 0),
      ),
    ),
  );

  final students = List<StudentRecord>.generate(
    6,
    (i) => StudentRecord(id: 'stu_$i', name: 'Aluno $i', matricula: '$i'),
  );

  List<ExamVariant> generate(ExamApplicationMode mode, {List<StudentRecord>? to}) {
    return randomizer.generateVariantsForMode(
      examId: 'exam_modes',
      questions: questions,
      mode: mode,
      students: to ?? students,
    );
  }

  bool questionsInOriginalOrder(ExamVariant v) => [
        for (var i = 0; i < v.questions.length; i++)
          v.questions[i].originalQuestionId == 'q$i',
      ].every((ok) => ok);

  bool alternativesInOriginalOrder(ExamVariant v) => v.questions.every(
        (q) => [
          for (var a = 0; a < q.alternatives.length; a++)
            q.alternatives[a].originalAlternativeId ==
                '${q.originalQuestionId}_a$a',
        ].every((ok) => ok),
      );

  group('ExamApplicationMode', () {
    test('Provas diferentes por aluno: questões e alternativas mudam por aluno', () {
      final variants = generate(ExamApplicationMode.individual);
      expect(variants, hasLength(students.length));
      expect(variants.map((v) => v.studentId), students.map((s) => s.id));
      expect(variants.any((v) => !questionsInOriginalOrder(v)), isTrue);
      expect(variants.any((v) => !alternativesInOriginalOrder(v)), isTrue);
    });

    test('Ordem das questões por aluno: alternativas ficam na ordem original', () {
      final variants = generate(ExamApplicationMode.questionOrder);
      expect(variants, hasLength(students.length));
      expect(variants.any((v) => !questionsInOriginalOrder(v)), isTrue);
      expect(variants.every(alternativesInOriginalOrder), isTrue);
    });

    test('Ordem das respostas por aluno: questões ficam na ordem original', () {
      final variants = generate(ExamApplicationMode.answerOrder);
      expect(variants, hasLength(students.length));
      expect(variants.every(questionsInOriginalOrder), isTrue);
      expect(variants.any((v) => !alternativesInOriginalOrder(v)), isTrue);
    });

    test('Mesma prova para todos: uma única prova, sem embaralhar nada', () {
      final variants = generate(ExamApplicationMode.sameForEveryone);
      expect(variants, hasLength(1));
      expect(variants.single.studentId, isNull);
      expect(questionsInOriginalOrder(variants.single), isTrue);
      expect(alternativesInOriginalOrder(variants.single), isTrue);
    });

    test('o gabarito de cada variante continua correto em todos os modos', () {
      for (final mode in ExamApplicationMode.values) {
        for (final variant in generate(mode)) {
          for (final q in variant.questions) {
            final correct = q.alternatives.singleWhere((a) => a.isCorrect);
            expect(correct.originalAlternativeId, '${q.originalQuestionId}_a0');
            expect(q.correctLetter, correct.letter, reason: mode.name);
          }
        }
      }
    });

    test('modos por aluno sem alunos geram cadernos A–D como reserva', () {
      final variants = generate(ExamApplicationMode.questionOrder, to: const []);
      expect(variants.map((v) => v.code), ['A', 'B', 'C', 'D']);
      expect(variants.every(alternativesInOriginalOrder), isTrue);
    });

    test('lê o modo salvo e converte provas antigas', () {
      for (final mode in ExamApplicationMode.values) {
        expect(ExamApplicationMode.fromStored(mode.id), mode);
      }
      expect(
        ExamApplicationMode.fromStored(null, legacySameForEveryone: false),
        ExamApplicationMode.individual,
      );
      expect(
        ExamApplicationMode.fromStored(null, legacySameForEveryone: true),
        ExamApplicationMode.sameForEveryone,
      );
      expect(ExamApplicationMode.fromStored(null), ExamApplicationMode.sameForEveryone);
    });

    test('ProvaCorrecao mantém compatibilidade com provaIndividual', () {
      const legacy = ProvaCorrecao(
        id: 'e',
        titulo: 't',
        turma: 'x',
        disciplina: 'd',
        totalQuestoes: 1,
        totalAlunos: 1,
        provaIndividual: true,
      );
      expect(legacy.modoAplicacao, ExamApplicationMode.individual);

      const answers = ProvaCorrecao(
        id: 'e',
        titulo: 't',
        turma: 'x',
        disciplina: 'd',
        totalQuestoes: 1,
        totalAlunos: 1,
        modoAplicacao: ExamApplicationMode.answerOrder,
      );
      expect(answers.provaIndividual, isTrue);
    });
  });
}
