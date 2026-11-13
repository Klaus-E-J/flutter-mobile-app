import '../../exams/models/exam_variant.dart';
import '../data/submission_repository.dart';
import 'omr_image_service.dart';

/// Alias para item de resposta corrigida com mapeamento canônico.
typedef GradedAnswerItem = SubmissionQuestionAnswer;

/// Status detalhado da avaliação de uma questão individual (N3-05).
enum GradingQuestionStatus {
  correct,
  wrong,
  blank,
  multipleMarks,
  annulled,
}

/// Resultado completo da correção automática de uma folha de respostas (N3-05).
class ExamGradingResult {
  const ExamGradingResult({
    required this.variantId,
    required this.variantCode,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.blankCount,
    required this.invalidMultipleCount,
    required this.annulledCount,
    required this.earnedWeight,
    required this.totalWeight,
    required this.percentage,
    required this.finalGrade,
    required this.answers,
    required this.questionStatuses,
  });

  final String variantId;
  final String variantCode;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int blankCount;
  final int invalidMultipleCount;
  final int annulledCount;
  final double earnedWeight;
  final double totalWeight;
  final double percentage;
  final double finalGrade;
  final List<SubmissionQuestionAnswer> answers;
  final Map<int, GradingQuestionStatus> questionStatuses;
}

/// Serviço responsável pela correção automática das respostas reconhecidas pelo OMR
/// contra o gabarito da variante correspondente e cálculo da nota final (N3-05).
class ExamGradingService {
  const ExamGradingService();

  /// Corrige um [OmrSheetScanResult] confrontando-o com o gabarito de [variant].
  ExamGradingResult gradeOmrScan({
    required ExamVariant variant,
    required OmrSheetScanResult scanResult,
    Set<int> annulledQuestions = const {},
    double maxGrade = 10.0,
  }) {
    final markedMap = <int, List<String>>{};
    for (final entry in scanResult.questions.entries) {
      markedMap[entry.key] = entry.value.markedLetters;
    }
    return gradeFromMarkedLetters(
      variant: variant,
      markedLettersByQuestion: markedMap,
      annulledQuestions: annulledQuestions,
      maxGrade: maxGrade,
    );
  }

  /// Corrige um mapa de alternativas marcadas por questão (`questionNumber -> List<String>`)
  /// contra o gabarito oficial de [variant], preservando o mapeamento canônico original.
  ExamGradingResult gradeFromMarkedLetters({
    required ExamVariant variant,
    required Map<int, List<String>> markedLettersByQuestion,
    Set<int> annulledQuestions = const {},
    double maxGrade = 10.0,
  }) {
    var correctCount = 0;
    var wrongCount = 0;
    var blankCount = 0;
    var invalidMultipleCount = 0;
    var annulledCount = 0;
    var earnedWeight = 0.0;
    var totalWeight = 0.0;

    final answers = <SubmissionQuestionAnswer>[];
    final statuses = <int, GradingQuestionStatus>{};

    for (final q in variant.questions) {
      final qNum = q.questionNumber;
      final originalQNum = q.originalQuestionOrder + 1;
      final expectedCorrect = variant.answerKey[qNum] ?? q.correctLetter;
      final canonicalCorrect = q.toCanonicalLetter(expectedCorrect);
      final markedList = markedLettersByQuestion[qNum] ?? const <String>[];
      final weight = q.weight > 0 ? q.weight : 1.0;
      totalWeight += weight;

      final isAnnulled = q.annulled || annulledQuestions.contains(qNum);

      if (isAnnulled) {
        annulledCount++;
        correctCount++;
        earnedWeight += weight;
        statuses[qNum] = GradingQuestionStatus.annulled;
        answers.add(
          SubmissionQuestionAnswer(
            questionNumber: qNum,
            originalQuestionNumber: originalQNum,
            marked: 'ANULADA',
            correct: expectedCorrect,
            canonicalSelected: 'ANULADA',
            canonicalCorrect: canonicalCorrect,
            isCorrect: true,
          ),
        );
        continue;
      }

      if (markedList.isEmpty) {
        blankCount++;
        statuses[qNum] = GradingQuestionStatus.blank;
        answers.add(
          SubmissionQuestionAnswer(
            questionNumber: qNum,
            originalQuestionNumber: originalQNum,
            marked: 'EM BRANCO',
            correct: expectedCorrect,
            canonicalSelected: 'EM BRANCO',
            canonicalCorrect: canonicalCorrect,
            isCorrect: false,
          ),
        );
        continue;
      }

      if (markedList.length > 1) {
        invalidMultipleCount++;
        statuses[qNum] = GradingQuestionStatus.multipleMarks;
        final canonicalLetters = markedList
            .map((l) => q.toCanonicalLetter(l))
            .toList();
        answers.add(
          SubmissionQuestionAnswer(
            questionNumber: qNum,
            originalQuestionNumber: originalQNum,
            marked: 'INVÁLIDA (${markedList.join('+')})',
            correct: expectedCorrect,
            canonicalSelected: 'INVÁLIDA (${canonicalLetters.join('+')})',
            canonicalCorrect: canonicalCorrect,
            isCorrect: false,
          ),
        );
        continue;
      }

      final singleMarked = markedList.single.trim().toUpperCase();
      final canonicalMarked = q.toCanonicalLetter(singleMarked);
      final isCorrect = singleMarked == expectedCorrect.trim().toUpperCase();

      if (isCorrect) {
        correctCount++;
        earnedWeight += weight;
        statuses[qNum] = GradingQuestionStatus.correct;
      } else {
        wrongCount++;
        statuses[qNum] = GradingQuestionStatus.wrong;
      }

      answers.add(
        SubmissionQuestionAnswer(
          questionNumber: qNum,
          originalQuestionNumber: originalQNum,
          marked: singleMarked,
          correct: expectedCorrect,
          canonicalSelected: canonicalMarked,
          canonicalCorrect: canonicalCorrect,
          isCorrect: isCorrect,
        ),
      );
    }

    final totalQuestions = variant.questions.length;
    final percentage =
        totalWeight > 0 ? (earnedWeight / totalWeight) * 100.0 : 0.0;
    final finalGrade =
        totalWeight > 0 ? (earnedWeight / totalWeight) * maxGrade : 0.0;

    return ExamGradingResult(
      variantId: variant.id,
      variantCode: variant.code,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      blankCount: blankCount,
      invalidMultipleCount: invalidMultipleCount,
      annulledCount: annulledCount,
      earnedWeight: earnedWeight,
      totalWeight: totalWeight,
      percentage: percentage,
      finalGrade: finalGrade,
      answers: answers,
      questionStatuses: statuses,
    );
  }
}
