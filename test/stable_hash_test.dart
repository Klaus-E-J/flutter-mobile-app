import 'package:avalia_pro/features/exams/models/exam_application_mode.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// A semente e a impressão digital (fingerprint) das variantes precisam dar o
/// MESMO valor no celular (VM, inteiros de 64 bits) e na Web (JavaScript,
/// números de 53 bits). Caso contrário, uma prova impressa pela versão Web
/// teria todas as variantes regeneradas (com outro gabarito) ao iniciar a
/// correção pelo celular.
///
/// Rode também na Web: `flutter test --platform chrome test/stable_hash_test.dart`.
void main() {
  test('stableHash é o FNV-1a de 32 bits (valores de referência)', () {
    expect(ExamRandomizerService.stableHash(''), 0x811c9dc5);
    expect(ExamRandomizerService.stableHash('a'), 0xe40c292c);
    expect(ExamRandomizerService.stableHash('abc'), 0x1a47e90b);
    expect(ExamRandomizerService.stableHash('foobar'), 0xbf9cf968);
    expect(ExamRandomizerService.stableHash('seed|exam123'), 2219119629);
    expect(ExamRandomizerService.stableHash('var_xyz'), 2243509606);
    expect(ExamRandomizerService.stableHash('Ação'), 2841140859);
  });

  test('semente padrão e fingerprint independem da plataforma', () {
    expect(ExamRandomizerService.defaultSeedFor('exam123'), 2219119629);

    final questions = [
      Questao(
        id: 'q1',
        enunciado: 'Capital da França?',
        alternativas: [
          Alternativa(id: 'a1', texto: 'Paris', correta: true),
          Alternativa(id: 'a2', texto: 'Roma'),
        ],
      ),
    ];
    expect(
      ExamRandomizerService.configFingerprint(
        mode: ExamApplicationMode.individual,
        seed: 2219119629,
        questions: questions,
      ),
      _fingerprintReferencia(
        'individual|2219119629|Q:q1:Capital da França?'
        '|A:a1:Paris:1|A:a2:Roma:0',
      ),
    );
  });
}

/// Mesma fórmula do serviço, calculada com aritmética exata em BigInt
/// (independente de plataforma).
String _fingerprintReferencia(String text) {
  String hex(int v) => v.toRadixString(16).padLeft(8, '0');
  return '${hex(_fnv1aBig(text))}${hex(_fnv1aBig('x|$text|${text.length}'))}';
}

int _fnv1aBig(String value) {
  final mask = BigInt.from(0xFFFFFFFF);
  final prime = BigInt.from(0x01000193);
  var hash = BigInt.from(0x811c9dc5);
  for (final unit in value.codeUnits) {
    hash = ((hash ^ BigInt.from(unit)) * prime) & mask;
  }
  return hash.toInt();
}
