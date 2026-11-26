import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/statistics/data/firestore_statistics_repository.dart';
import 'package:avalia_pro/features/statistics/data/statistics_repository.dart';
import 'package:avalia_pro/features/statistics/models/statistics_models.dart';
import 'package:avalia_pro/features/statistics/views/class_stats_view.dart';
import 'package:avalia_pro/features/statistics/widgets/question_stats_tile.dart';

class _FakeStatisticsRepository implements StatisticsRepository {
  @override
  Future<List<String>> getAvailableClasses() async => const ['9º Ano A'];

  @override
  Future<List<String>> getAvailableExams(String className) async {
    if (className == 'Turma Sem Provas') return const [];
    return const ['Prova 1'];
  }

  @override
  Future<ClassStats> getClassStats(String className, String examName) async {
    return const ClassStats(
      className: '9º Ano A',
      examName: 'Prova 1',
      average: 7.5,
      approvalRate: 80.0,
      totalStudents: 4,
      gradeDistribution: [
        GradeDistribution(label: '8-10', count: 2),
      ],
      questionStats: [
        QuestionStats(
          questionNumber: 1,
          correctAlternative: 'B',
          alternativePercentages: {'A': 25, 'B': 75, 'C': 0, 'D': 0, 'E': 0},
          optionCounts: {'A': 1, 'B': 3, 'C': 0, 'D': 0, 'E': 0, 'Branco': 0},
          mostMarkedOption: 'B',
          mostMarkedPercentage: 75,
          hitRate: 75,
        ),
      ],
    );
  }

  @override
  Future<List<StudentOption>> getAvailableStudents(String className) async =>
      const [];

  @override
  Future<StudentStats> getStudentStats(
    String className,
    String studentId,
  ) async =>
      const StudentStats(
        studentName: 'Aluno',
        average: 8.0,
        examCount: 1,
        approvalRate: 100.0,
        subjectResults: [],
      );
}

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

      final stats = FirestoreStatisticsRepository.buildClassStatsFromSubmissions(
        className: '9A',
        examName: 'Matemática',
        matching: submissions,
      );

      expect(stats.average, 7.5);
      expect(stats.approvalRate, 50.0);
      expect(
        stats.gradeDistribution.firstWhere((g) => g.label == '4-6').count,
        1,
      );
      expect(
        stats.gradeDistribution.firstWhere((g) => g.label == '8-10').count,
        1,
      );
      expect(stats.questionStats.first.correctAlternative, 'A');
      expect(stats.questionStats.first.alternativePercentages['A'], 50);
      expect(stats.questionStats.first.alternativePercentages['B'], 50);
    });

    test('Aggregates shuffled variants by originalQuestionNumber and canonicalSelected with mostMarkedOption', () {
      final submissions = [
        const SubmissionRecord(
          id: 'sub1',
          examId: 'e1',
          examTitle: 'Física',
          classId: 'c1',
          className: '3A',
          studentId: 's1',
          studentName: 'Aluno 1',
          score: 1,
          totalQuestions: 1,
          percentage: 100.0,
          answers: [
            SubmissionQuestionAnswer(
              questionNumber: 3,
              originalQuestionNumber: 1,
              marked: 'A',
              canonicalSelected: 'C',
              correct: 'A',
              canonicalCorrect: 'C',
              isCorrect: true,
            ),
          ],
        ),
        const SubmissionRecord(
          id: 'sub2',
          examId: 'e1',
          examTitle: 'Física',
          classId: 'c1',
          className: '3A',
          studentId: 's2',
          studentName: 'Aluno 2',
          score: 0,
          totalQuestions: 1,
          percentage: 0.0,
          answers: [
            SubmissionQuestionAnswer(
              questionNumber: 2,
              originalQuestionNumber: 1,
              marked: 'D',
              canonicalSelected: 'E',
              correct: 'B',
              canonicalCorrect: 'C',
              isCorrect: false,
            ),
          ],
        ),
        const SubmissionRecord(
          id: 'sub3',
          examId: 'e1',
          examTitle: 'Física',
          classId: 'c1',
          className: '3A',
          studentId: 's3',
          studentName: 'Aluno 3',
          score: 0,
          totalQuestions: 1,
          percentage: 0.0,
          answers: [
            SubmissionQuestionAnswer(
              questionNumber: 4,
              originalQuestionNumber: 1,
              marked: 'B',
              canonicalSelected: 'E',
              correct: 'E',
              canonicalCorrect: 'C',
              isCorrect: false,
            ),
          ],
        ),
      ];

      final stats = FirestoreStatisticsRepository.buildClassStatsFromSubmissions(
        className: '3A',
        examName: 'Física',
        matching: submissions,
      );

      expect(stats.questionStats.length, 1);
      final q1 = stats.questionStats.single;
      expect(q1.questionNumber, 1);
      expect(q1.correctAlternative, 'C');
      expect(q1.optionCounts['C'], 1);
      expect(q1.optionCounts['E'], 2);
      expect(q1.mostMarkedOption, 'E');
      expect(q1.mostMarkedPercentage, 67);
    });

    testWidgets('QuestionStatsTile displays most marked alternative badge and option counts', (tester) async {
      const qStats = QuestionStats(
        questionNumber: 1,
        correctAlternative: 'B',
        alternativePercentages: {'A': 20, 'B': 60, 'C': 20, 'D': 0, 'E': 0},
        optionCounts: {'A': 1, 'B': 3, 'C': 1, 'D': 0, 'E': 0, 'Branco': 0},
        mostMarkedOption: 'B',
        mostMarkedPercentage: 60,
        hitRate: 60,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionStatsTile(stats: qStats),
          ),
        ),
      );

      expect(find.textContaining('Mais marcada: B (60%)'), findsOneWidget);
      expect(find.textContaining('B: 60% (3)'), findsOneWidget);
    });

    testWidgets('ClassStatsView stops loading when class has no exams and updates on didUpdateWidget', (tester) async {
      final repo = _FakeStatisticsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassStatsView(
              repository: repo,
              className: 'Turma Sem Provas',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not hang in CircularProgressIndicator; should display empty message
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nenhuma prova disponível'), findsOneWidget);

      // Update className to a class with exams (triggers didUpdateWidget)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassStatsView(
              repository: repo,
              className: '9º Ano A',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Mais marcada: B (75%)'), findsOneWidget);
    });
  });
}
