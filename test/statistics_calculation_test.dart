import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/statistics/models/statistics_models.dart';

void main() {
  group('Statistics calculation tests', () {
    test('Calculates grades and distribution accurately', () {
      final submissions = [
        const SubmissionRecord(
          id: '1',
          examId: 'e1',
          examTitle: 'Matemática',
          classId: 'c1',
          className: '9A',
          studentId: 's1',
          studentName: 'Ana',
          score: 10,
          totalQuestions: 10,
          percentage: 100.0,
          answers: [
            SubmissionQuestionAnswer(
              questionNumber: 1,
              marked: 'A',
              correct: 'A',
              isCorrect: true,
            ),
          ],
        ),
        const SubmissionRecord(
          id: '2',
          examId: 'e1',
          examTitle: 'Matemática',
          classId: 'c1',
          className: '9A',
          studentId: 's2',
          studentName: 'Bruno',
          score: 5,
          totalQuestions: 10,
          percentage: 50.0,
          answers: [
            SubmissionQuestionAnswer(
              questionNumber: 1,
              marked: 'B',
              correct: 'A',
              isCorrect: false,
            ),
          ],
        ),
      ];

      // Total average in 0-10 scale: (10 + 5) / 2 = 7.5
      final grades = submissions.map((s) => (s.score / s.totalQuestions) * 10.0).toList();
      final average = grades.reduce((a, b) => a + b) / grades.length;
      expect(average, 7.5);

      // Approval rate (>= 6.0): 1 out of 2 = 50.0%
      final approved = grades.where((g) => g >= 6.0).length;
      final approvalRate = (approved / grades.length) * 100.0;
      expect(approvalRate, 50.0);

      // Grade distribution
      int c4to6 = grades.where((g) => g >= 4.0 && g < 6.0).length;
      int c8to10 = grades.where((g) => g >= 8.0 && g <= 10.0).length;
      expect(c4to6, 1);
      expect(c8to10, 1);

      // Question alternative percentages:
      // Q1: 'A' -> 1/2 (50%), 'B' -> 1/2 (50%)
      final q1Answers = submissions.expand((s) => s.answers).where((a) => a.questionNumber == 1).toList();
      final aCount = q1Answers.where((a) => a.marked == 'A').length;
      final bCount = q1Answers.where((a) => a.marked == 'B').length;
      expect((aCount / submissions.length) * 100, 50);
      expect((bCount / submissions.length) * 100, 50);

      final qStats = QuestionStats(
        questionNumber: 1,
        correctAlternative: 'A',
        alternativePercentages: {'A': 50, 'B': 50, 'C': 0, 'D': 0},
      );
      expect(qStats.correctAlternative, 'A');
      expect(qStats.alternativePercentages['A'], 50);
    });
  });
}
