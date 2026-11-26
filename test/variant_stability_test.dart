import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/exams/models/exam_application_mode.dart';
import 'package:avalia_pro/features/exams/models/exam_variant.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressões da auditoria: a prova (ordem + gabarito) de um aluno nunca pode
/// mudar sozinha depois de impressa.
void main() {
  const randomizer = ExamRandomizerService();
  const examId = 'exam_stable';
  const mode = ExamApplicationMode.individual;

  List<Questao> questions({String suffix = ''}) => List.generate(
        6,
        (q) => Questao(
          id: 'q$q',
          enunciado: 'Questão $q$suffix',
          alternativas: List.generate(
            5,
            (a) => Alternativa(id: 'q${q}_a$a', texto: 'Alt $a', correta: a == q % 5),
          ),
        ),
      );

  const ana = StudentRecord(id: 'id_ana', name: 'Ana', classId: 'c9a', className: '9º A');
  const bruno = StudentRecord(id: 'id_bruno', name: 'Bruno', classId: 'c9a', className: '9º A');
  const carla = StudentRecord(id: 'id_carla', name: 'Carla', classId: 'c9a', className: '9º A');
  const aaron = StudentRecord(id: 'id_aaron', name: 'Aaron', classId: 'c9a', className: '9º A');
  const helena = StudentRecord(id: 'id_helena', name: 'Helena', classId: 'c9b', className: '9º B');

  String signature(ExamVariant v) =>
      '${v.questions.map((q) => q.originalQuestionId).join(',')}|'
      '${v.answerKey.entries.map((e) => '${e.key}${e.value}').join()}';

  List<ExamVariant> generate(List<StudentRecord> students, {int seed = 1234, List<Questao>? qs}) =>
      randomizer.generateVariantsForMode(
        examId: examId,
        questions: qs ?? questions(),
        mode: mode,
        students: students,
        seed: seed,
      );

  test('incluir um aluno (que fica antes na ordem alfabética) não muda a prova dos outros', () {
    final before = generate([ana, bruno, carla]);
    final after = generate([aaron, ana, bruno, carla]);
    for (final v in before) {
      final same = after.firstWhere((a) => a.id == v.id);
      expect(signature(same), signature(v), reason: v.studentName);
    }
  });

  test('a semente padrão é estável (não depende de String.hashCode)', () {
    expect(ExamRandomizerService.defaultSeedFor('abc'), ExamRandomizerService.defaultSeedFor('abc'));
    expect(ExamRandomizerService.stableHash('abc'), 0x1a47e90b);
  });

  test('fingerprint ignora nome da prova/turmas, mas muda com semente, modo ou conteúdo', () {
    final base = ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: questions());
    expect(ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: questions()), base);
    expect(ExamRandomizerService.configFingerprint(mode: mode, seed: 2, questions: questions()), isNot(base));
    expect(
      ExamRandomizerService.configFingerprint(
        mode: ExamApplicationMode.questionOrder,
        seed: 1,
        questions: questions(),
      ),
      isNot(base),
    );
    expect(
      ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: questions(suffix: '!')),
      isNot(base),
    );
  });

  test('variantes salvas com a mesma configuração são mantidas intactas (ex.: depois de renomear a prova)', () {
    final fp = ExamRandomizerService.configFingerprint(mode: mode, seed: 99, questions: questions());
    // Prova impressa depois de um "Reembaralhar" (semente 99).
    final printed = generate([ana, bruno], seed: 99)
        .map((v) => v.copyWith(configFingerprint: fp))
        .toList();
    // Uma regeneração que usasse outra semente produziria provas diferentes...
    final regenerated = generate([ana, bruno], seed: 1);
    expect(signature(regenerated.first), isNot(signature(printed.first)));
    // ...mas o merge mantém as provas impressas enquanto a configuração é a mesma.
    final merged = randomizer.mergeWithExisting(
      generated: regenerated,
      existing: printed,
      fingerprint: fp,
    );
    for (final v in printed) {
      expect(signature(merged.firstWhere((m) => m.id == v.id)), signature(v));
    }
  });

  test('aluno novo recebe código que não colide; aluno removido continua reconhecível', () {
    final fp = ExamRandomizerService.configFingerprint(mode: mode, seed: 7, questions: questions());
    final existing = generate([ana, bruno, carla], seed: 7)
        .map((v) => v.copyWith(configFingerprint: fp))
        .toList();
    // Bruno saiu da turma e Aaron entrou.
    final merged = randomizer.mergeWithExisting(
      generated: generate([aaron, ana, carla], seed: 7),
      existing: existing,
      fingerprint: fp,
    );
    final codes = merged.map((v) => v.code).toList();
    expect(codes.toSet().length, codes.length, reason: 'códigos duplicados: $codes');
    final anaBefore = existing.firstWhere((v) => v.studentId == ana.id);
    final anaAfter = merged.firstWhere((v) => v.studentId == ana.id);
    expect(anaAfter.code, anaBefore.code);
    expect(signature(anaAfter), signature(anaBefore));
    expect(merged.any((v) => v.studentId == bruno.id), isTrue,
        reason: 'a folha já impressa do Bruno precisa continuar reconhecível');
    expect(merged.any((v) => v.studentId == aaron.id), isTrue);
  });

  test('prova com duas turmas: cada aluno recebe a própria turma na variante', () {
    final variants = generate([ana, helena]);
    expect(variants.firstWhere((v) => v.studentId == ana.id).className, '9º A');
    expect(variants.firstWhere((v) => v.studentId == helena.id).className, '9º B');
  });

  test('variantes antigas (sem fingerprint) são reaproveitadas só se ainda conferem com as questões', () {
    final legacy = generate([ana], seed: 555); // sem configFingerprint
    final fp = ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: questions());

    final kept = randomizer.mergeWithExisting(
      generated: generate([ana], seed: 1),
      existing: legacy,
      fingerprint: fp,
      legacyQuestions: questions(),
    );
    expect(signature(kept.single), signature(legacy.single));
    expect(kept.single.configFingerprint, fp);

    final edited = questions(suffix: ' (editada)');
    final fpEdited = ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: edited);
    final regenerated = randomizer.mergeWithExisting(
      generated: generate([ana], seed: 1, qs: edited),
      existing: legacy,
      fingerprint: fpEdited,
      legacyQuestions: edited,
    );
    expect(regenerated.single.questions.first.statement, contains('(editada)'));
  });

  test('variante antiga é reaproveitada mesmo se o texto salvo nela tinha espaços sobrando', () {
    // Versões anteriores geravam a variante com o texto digitado no editor
    // (ex.: "Alt 0 " com espaço do autocompletar), mas o Firestore guarda o
    // texto aparado. A folha impressa continua válida e não pode ser trocada.
    List<Questao> typed() => questions()
        .map((q) => Questao(
              id: q.id,
              enunciado: '${q.enunciado} ',
              alternativas: q.alternativas
                  .map((a) => Alternativa(id: a.id, texto: ' ${a.texto} ', correta: a.correta))
                  .toList(),
            ))
        .toList();
    final legacy = generate([ana, bruno], seed: 555, qs: typed()); // sem fingerprint
    final fp = ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: questions());
    final merged = randomizer.mergeWithExisting(
      generated: generate([ana, bruno], seed: 1),
      existing: legacy,
      fingerprint: fp,
      legacyQuestions: questions(),
    );
    for (final v in legacy) {
      expect(signature(merged.firstWhere((m) => m.id == v.id)), signature(v), reason: v.studentName);
    }
  });

  test('variante antiga com gabarito desatualizado nunca é reaproveitada', () {
    final legacy = generate([ana], seed: 555);
    // O professor corrigiu a alternativa certa da questão 0 depois de imprimir.
    final fixed = questions();
    for (final a in fixed.first.alternativas) {
      a.correta = a.id == 'q0_a3';
    }
    final fp = ExamRandomizerService.configFingerprint(mode: mode, seed: 1, questions: fixed);
    final merged = randomizer.mergeWithExisting(
      generated: generate([ana], seed: 1, qs: fixed),
      existing: legacy,
      fingerprint: fp,
      legacyQuestions: fixed,
    );
    final q0 = merged.single.questions.firstWhere((q) => q.originalQuestionId == 'q0');
    final correct = q0.alternatives.firstWhere((a) => a.letter == merged.single.answerKey[q0.questionNumber]);
    expect(correct.originalAlternativeId, 'q0_a3');
  });

  test('variante antiga por aluno não é reaproveitada quando a prova passa a ser "mesma prova"', () {
    final legacy = generate([ana], seed: 3);
    const shared = ExamApplicationMode.sameForEveryone;
    final generated = randomizer.generateVariantsForMode(
      examId: examId,
      questions: questions(),
      mode: shared,
      seed: 3,
    );
    final fp = ExamRandomizerService.configFingerprint(mode: shared, seed: 3, questions: questions());
    final merged = randomizer.mergeWithExisting(
      generated: generated,
      existing: legacy,
      fingerprint: fp,
      legacyQuestions: questions(),
    );
    expect(merged, hasLength(1));
    expect(merged.single.studentId, isNull);
  });
}
