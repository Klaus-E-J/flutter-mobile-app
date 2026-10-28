import '../../classes/data/class_repository.dart';
import '../../correction/data/submission_repository.dart';
import '../../exams/data/exam_repository.dart';
import '../models/statistics_models.dart';
import 'statistics_repository.dart';

/// Implementação do repositório de estatísticas integrado com o Cloud Firestore.
///
/// Lê classes, provas e submissões reais e calcula dinamicamente
/// as métricas de turma e aluno.
class FirestoreStatisticsRepository implements StatisticsRepository {
  FirestoreStatisticsRepository({
    ClassRepository? classRepository,
    ExamRepository? examRepository,
    SubmissionRepository? submissionRepository,
  })  : _classRepository = classRepository ?? ClassRepository(),
        _examRepository = examRepository ?? ExamRepository(),
        _submissionRepository = submissionRepository ?? SubmissionRepository();

  final ClassRepository _classRepository;
  final ExamRepository _examRepository;
  final SubmissionRepository _submissionRepository;

  @override
  Future<List<String>> getAvailableClasses() async {
    final classes = await _classRepository.getClasses();
    return classes.map((c) => c.name).toList();
  }

  @override
  Future<List<String>> getAvailableExams(String className) async {
    // Busca exames vinculados à turma
    final exams = await _examRepository.watchExams().first;
    final matchingExams = exams
        .where((exam) => exam.classNames.contains(className))
        .map((exam) => exam.title)
        .toList();

    // Também inclui provas que já possuem submissões para essa turma
    final submissions = await _submissionRepository.getSubmissions();
    for (final sub in submissions) {
      if (sub.className == className && !matchingExams.contains(sub.examTitle)) {
        matchingExams.add(sub.examTitle);
      }
    }

    return matchingExams;
  }

  @override
  Future<ClassStats> getClassStats(String className, String examName) async {
    final allSubmissions = await _submissionRepository.getSubmissions();
    final matching = allSubmissions
        .where((s) => s.className == className && s.examTitle == examName)
        .toList();

    if (matching.isEmpty) {
      return ClassStats(
        className: className,
        examName: examName,
        average: 0.0,
        approvalRate: 0.0,
        totalStudents: 0,
        gradeDistribution: const [
          GradeDistribution(label: '0-2', count: 0),
          GradeDistribution(label: '2-4', count: 0),
          GradeDistribution(label: '4-6', count: 0),
          GradeDistribution(label: '6-8', count: 0),
          GradeDistribution(label: '8-10', count: 0),
        ],
        questionStats: const [],
      );
    }

    final totalStudents = matching.length;
    double totalGrades = 0.0;
    int approvedCount = 0;

    int c0to2 = 0;
    int c2to4 = 0;
    int c4to6 = 0;
    int c6to8 = 0;
    int c8to10 = 0;

    for (final sub in matching) {
      final grade = sub.totalQuestions > 0
          ? (sub.score / sub.totalQuestions) * 10.0
          : 0.0;

      totalGrades += grade;
      if (grade >= 6.0) {
        approvedCount++;
      }

      if (grade < 2.0) {
        c0to2++;
      } else if (grade < 4.0) {
        c2to4++;
      } else if (grade < 6.0) {
        c4to6++;
      } else if (grade < 8.0) {
        c6to8++;
      } else {
        c8to10++;
      }
    }

    final average = double.parse((totalGrades / totalStudents).toStringAsFixed(1));
    final approvalRate = double.parse(
      ((approvedCount / totalStudents) * 100).toStringAsFixed(1),
    );

    final gradeDistribution = [
      GradeDistribution(label: '0-2', count: c0to2),
      GradeDistribution(label: '2-4', count: c2to4),
      GradeDistribution(label: '4-6', count: c4to6),
      GradeDistribution(label: '6-8', count: c6to8),
      GradeDistribution(label: '8-10', count: c8to10),
    ];

    // Estatísticas por questão
    final totalQuestions = matching.first.totalQuestions;
    final questionStats = <QuestionStats>[];

    for (int qNum = 1; qNum <= totalQuestions; qNum++) {
      String correct = '';
      final alternativeCounts = <String, int>{};

      for (final sub in matching) {
        final answer = sub.answers.firstWhere(
          (a) => a.questionNumber == qNum,
          orElse: () => const SubmissionQuestionAnswer(
            questionNumber: 0,
            marked: '',
            correct: '',
            isCorrect: false,
          ),
        );

        if (answer.questionNumber != 0) {
          if (correct.isEmpty && answer.correct.isNotEmpty) {
            correct = answer.correct;
          }
          final marked = answer.marked.toUpperCase().trim();
          if (marked.isNotEmpty) {
            alternativeCounts[marked] = (alternativeCounts[marked] ?? 0) + 1;
          }
        }
      }

      final alternativePercentages = <String, int>{};
      const standardAlternatives = ['A', 'B', 'C', 'D', 'E'];
      for (final alt in standardAlternatives) {
        final count = alternativeCounts[alt] ?? 0;
        final pct = totalStudents > 0 ? ((count / totalStudents) * 100).round() : 0;
        if (count > 0 || alt == correct || alt == 'A' || alt == 'B' || alt == 'C' || alt == 'D') {
          alternativePercentages[alt] = pct;
        }
      }

      questionStats.add(
        QuestionStats(
          questionNumber: qNum,
          correctAlternative: correct.isNotEmpty ? correct : 'A',
          alternativePercentages: alternativePercentages,
        ),
      );
    }

    return ClassStats(
      className: className,
      examName: examName,
      average: average,
      approvalRate: approvalRate,
      totalStudents: totalStudents,
      gradeDistribution: gradeDistribution,
      questionStats: questionStats,
    );
  }

  @override
  Future<List<StudentOption>> getAvailableStudents(String className) async {
    final classes = await _classRepository.getClasses();
    final matchingClass = classes.cast<ClassRecord?>().firstWhere(
      (c) => c?.name == className,
      orElse: () => null,
    );

    if (matchingClass != null) {
      final students = await _classRepository.watchStudents(matchingClass.id).first;
      if (students.isNotEmpty) {
        return students
            .map((student) => StudentOption(id: student.id, name: student.name))
            .toList();
      }
    }

    // Fallback para alunos encontrados em submissões antigas ou sem cadastro.
    // Usa studentId sempre que disponível para não misturar homônimos.
    final submissions = await _submissionRepository.getSubmissions();
    final byId = <String, StudentOption>{};
    for (final submission in submissions.where((s) => s.className == className)) {
      final id = submission.studentId.isNotEmpty
          ? submission.studentId
          : 'legacy:${submission.studentName}';
      byId.putIfAbsent(
        id,
        () => StudentOption(id: id, name: submission.studentName),
      );
    }

    final students = byId.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return students;
  }

  @override
  Future<StudentStats> getStudentStats(
      String className,
      String studentId,
      ) async {
    final submissions = await _submissionRepository.getSubmissions();
    final matching = submissions
        .where((s) => s.className == className && (studentId.startsWith('legacy:')
        ? s.studentId.isEmpty && s.studentName == studentId.substring(7)
        : s.studentId == studentId))
        .toList();

    var studentName = matching.isNotEmpty ? matching.first.studentName : studentId;
    if (matching.isEmpty && !studentId.startsWith('legacy:')) {
      final classes = await _classRepository.getClasses();
      final matchingClass = classes.cast<ClassRecord?>().firstWhere(
            (c) => c?.name == className,
        orElse: () => null,
      );
      if (matchingClass != null) {
        final students = await _classRepository.watchStudents(matchingClass.id).first;
        for (final student in students) {
          if (student.id == studentId) {
            studentName = student.name;
            break;
          }
        }
      }
    }

    if (matching.isEmpty) {
      return StudentStats(
        studentName: studentName,
        average: 0.0,
        examCount: 0,
        approvalRate: 0.0,
        subjectResults: const [],
      );
    }

    // DECLARAÇÃO DAS VARIÁVEIS ANTES DO LOOP
    double totalGrade = 0.0;
    int approvedCount = 0;
    final subjectResults = <SubjectResult>[];

    for (final sub in matching) {
      final grade = sub.totalQuestions > 0
          ? double.parse(((sub.score / sub.totalQuestions) * 10.0).toStringAsFixed(1))
          : 0.0;

      totalGrade += grade;
      if (grade >= 6.0) approvedCount++;

      subjectResults.add(
        SubjectResult(
          subjectName: sub.examTitle,
          grade: grade,
        ),
      );
    }

    final average = double.parse((totalGrade / matching.length).toStringAsFixed(1));
    final approvalRate = double.parse(
      ((approvedCount / matching.length) * 100).toStringAsFixed(1),
    );

    return StudentStats(
      studentName: studentName,
      average: average,
      examCount: matching.length,
      approvalRate: approvalRate,
      subjectResults: subjectResults,
    );
  }

}
