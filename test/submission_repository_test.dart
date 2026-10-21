import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';

void main() {
  group('SubmissionRecord tests', () {
    test('SubmissionQuestionAnswer toMap and fromMap works correctly', () {
      const answer = SubmissionQuestionAnswer(
        questionNumber: 1,
        marked: 'B',
        correct: 'B',
        isCorrect: true,
      );

      final map = answer.toMap();
      expect(map['questionNumber'], 1);
      expect(map['marked'], 'B');
      expect(map['correct'], 'B');
      expect(map['isCorrect'], true);

      final fromMap = SubmissionQuestionAnswer.fromMap(map);
      expect(fromMap.questionNumber, 1);
      expect(fromMap.marked, 'B');
      expect(fromMap.correct, 'B');
      expect(fromMap.isCorrect, true);
    });

    test('SubmissionRecord toMap and calculated properties', () {
      final now = DateTime(2026, 8, 20);
      final record = SubmissionRecord(
        id: 'sub_1',
        examId: 'exam_1',
        examTitle: 'Prova de Matemática',
        classId: 'class_1',
        className: '9º Ano A',
        studentId: 'student_1',
        studentName: 'Ana Silva',
        score: 8,
        totalQuestions: 10,
        percentage: 80.0,
        answers: const [
          SubmissionQuestionAnswer(
            questionNumber: 1,
            marked: 'A',
            correct: 'A',
            isCorrect: true,
          ),
          SubmissionQuestionAnswer(
            questionNumber: 2,
            marked: 'C',
            correct: 'B',
            isCorrect: false,
          ),
        ],
        createdAt: now,
      );

      expect(record.nota, '8/10');
      final map = record.toMap();
      expect(map['examId'], 'exam_1');
      expect(map['score'], 8);
      expect(map['totalQuestions'], 10);
      expect(map['percentage'], 80.0);
      expect((map['answers'] as List).length, 2);
    });

    test('ExamCorrectionSummary calculates average score accurately', () {
      final subs = [
        const SubmissionRecord(
          id: '1',
          examId: 'ex1',
          examTitle: 'Prova 1',
          classId: 'c1',
          className: '9º A',
          studentId: 's1',
          studentName: 'Aluno 1',
          score: 8,
          totalQuestions: 10,
          percentage: 80.0,
          answers: [],
        ),
        const SubmissionRecord(
          id: '2',
          examId: 'ex1',
          examTitle: 'Prova 1',
          classId: 'c1',
          className: '9º A',
          studentId: 's2',
          studentName: 'Aluno 2',
          score: 6,
          totalQuestions: 10,
          percentage: 60.0,
          answers: [],
        ),
      ];

      final summary = ExamCorrectionSummary(
        examId: 'ex1',
        examTitle: 'Prova 1',
        classId: 'c1',
        className: '9º A',
        submissions: subs,
        totalQuestions: 10,
      );

      expect(summary.studentCount, 2);
      expect(summary.averageScore, 70.0);
    });
  });
}
