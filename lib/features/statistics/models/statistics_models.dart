// Data classes para as estatísticas da turma e do aluno.
//
// Estrutura preparada para ser populada por banco de dados no futuro.
// Por enquanto os dados vêm de MockStatisticsRepository.

class ClassStats {
  const ClassStats({
    required this.className,
    required this.examName,
    required this.average,
    required this.approvalRate,
    required this.totalStudents,
    required this.gradeDistribution,
    required this.questionStats,
  });

  final String className;
  final String examName;
  final double average;

  /// Percentual de aproveitamento (0–100).
  final double approvalRate;
  final int totalStudents;
  final List<GradeDistribution> gradeDistribution;
  final List<QuestionStats> questionStats;
}

class GradeDistribution {
  const GradeDistribution({
    required this.label,
    required this.count,
  });

  /// Rótulo da faixa, ex.: "0-2", "2-4".
  final String label;
  final int count;
}

class QuestionStats {
  const QuestionStats({
    required this.questionNumber,
    required this.correctAlternative,
    required this.alternativePercentages,
  });

  /// Número da questão, ex.: 7.
  final int questionNumber;

  /// Letra da alternativa correta, ex.: "B".
  final String correctAlternative;

  /// Mapa alternativa → percentual. Ex.: {"A": 10, "B": 42, "C": 33, "D": 15}.
  final Map<String, int> alternativePercentages;
}

class StudentStats {
  const StudentStats({
    required this.studentName,
    required this.average,
    required this.examCount,
    required this.approvalRate,
    required this.subjectResults,
  });

  final String studentName;
  final double average;
  final int examCount;

  /// Percentual de aproveitamento (0–100).
  final double approvalRate;
  final List<SubjectResult> subjectResults;
}

class SubjectResult {
  const SubjectResult({
    required this.subjectName,
    required this.grade,
  });

  final String subjectName;
  final double grade;
}
