import '../models/statistics_models.dart';
import 'statistics_repository.dart';

/// Implementação mockada do repositório de estatísticas.
///
/// Retorna dados fictícios para desenvolvimento da UI.
/// Será substituída por uma implementação com banco de dados real.
class MockStatisticsRepository implements StatisticsRepository {
  // ─── Dados mockados por turma ───

  static const _classExams = {
    '9º Ano A': ['Avaliação Matemática', 'Avaliação Português'],
    '8º Ano B': ['Avaliação Ciências', 'Avaliação História'],
    'Ensino Médio — 1A': ['Avaliação Física'],
  };

  static const _classStudents = {
    '9º Ano A': ['João Silva', 'Ana Costa', 'Bruno Mendes'],
    '8º Ano B': ['Carla Souza', 'Diego Rocha'],
    'Ensino Médio — 1A': ['Elisa Rocha', 'Felipe Santos', 'Gabriela Lima'],
  };

  @override
  Future<List<String>> getAvailableClasses() async {
    return _classExams.keys.toList();
  }

  @override
  Future<List<String>> getAvailableExams(String className) async {
    return _classExams[className] ?? [];
  }

  @override
  Future<ClassStats> getClassStats(String className, String examName) async {
    final key = '$className|$examName';

    final Map<String, ClassStats> mockData = {
      '9º Ano A|Avaliação Matemática': const ClassStats(
        className: '9º Ano A',
        examName: 'Avaliação Matemática',
        average: 7.8,
        approvalRate: 82,
        totalStudents: 28,
        gradeDistribution: [
          GradeDistribution(label: '0-2', count: 1),
          GradeDistribution(label: '2-4', count: 3),
          GradeDistribution(label: '4-6', count: 5),
          GradeDistribution(label: '6-8', count: 10),
          GradeDistribution(label: '8-10', count: 9),
        ],
        questionStats: [
          QuestionStats(
            questionNumber: 1,
            correctAlternative: 'A',
            alternativePercentages: {'A': 75, 'B': 10, 'C': 8, 'D': 7},
          ),
          QuestionStats(
            questionNumber: 2,
            correctAlternative: 'C',
            alternativePercentages: {'A': 12, 'B': 18, 'C': 60, 'D': 10},
          ),
          QuestionStats(
            questionNumber: 3,
            correctAlternative: 'B',
            alternativePercentages: {'A': 5, 'B': 80, 'C': 10, 'D': 5},
          ),
          QuestionStats(
            questionNumber: 4,
            correctAlternative: 'D',
            alternativePercentages: {'A': 20, 'B': 15, 'C': 10, 'D': 55},
          ),
          QuestionStats(
            questionNumber: 5,
            correctAlternative: 'A',
            alternativePercentages: {'A': 65, 'B': 12, 'C': 13, 'D': 10},
          ),
          QuestionStats(
            questionNumber: 6,
            correctAlternative: 'C',
            alternativePercentages: {'A': 8, 'B': 22, 'C': 58, 'D': 12},
          ),
          QuestionStats(
            questionNumber: 7,
            correctAlternative: 'B',
            alternativePercentages: {'A': 10, 'B': 42, 'C': 33, 'D': 15},
          ),
          QuestionStats(
            questionNumber: 8,
            correctAlternative: 'A',
            alternativePercentages: {'A': 70, 'B': 14, 'C': 9, 'D': 7},
          ),
          QuestionStats(
            questionNumber: 9,
            correctAlternative: 'D',
            alternativePercentages: {'A': 15, 'B': 10, 'C': 20, 'D': 55},
          ),
          QuestionStats(
            questionNumber: 10,
            correctAlternative: 'B',
            alternativePercentages: {'A': 18, 'B': 50, 'C': 22, 'D': 10},
          ),
        ],
      ),
      '9º Ano A|Avaliação Português': const ClassStats(
        className: '9º Ano A',
        examName: 'Avaliação Português',
        average: 7.2,
        approvalRate: 75,
        totalStudents: 28,
        gradeDistribution: [
          GradeDistribution(label: '0-2', count: 2),
          GradeDistribution(label: '2-4', count: 4),
          GradeDistribution(label: '4-6', count: 6),
          GradeDistribution(label: '6-8', count: 9),
          GradeDistribution(label: '8-10', count: 7),
        ],
        questionStats: [
          QuestionStats(
            questionNumber: 1,
            correctAlternative: 'C',
            alternativePercentages: {'A': 15, 'B': 20, 'C': 55, 'D': 10},
          ),
          QuestionStats(
            questionNumber: 2,
            correctAlternative: 'A',
            alternativePercentages: {'A': 68, 'B': 12, 'C': 10, 'D': 10},
          ),
          QuestionStats(
            questionNumber: 3,
            correctAlternative: 'D',
            alternativePercentages: {'A': 10, 'B': 15, 'C': 25, 'D': 50},
          ),
        ],
      ),
      '8º Ano B|Avaliação Ciências': const ClassStats(
        className: '8º Ano B',
        examName: 'Avaliação Ciências',
        average: 8.1,
        approvalRate: 88,
        totalStudents: 24,
        gradeDistribution: [
          GradeDistribution(label: '0-2', count: 0),
          GradeDistribution(label: '2-4', count: 2),
          GradeDistribution(label: '4-6', count: 3),
          GradeDistribution(label: '6-8', count: 8),
          GradeDistribution(label: '8-10', count: 11),
        ],
        questionStats: [
          QuestionStats(
            questionNumber: 1,
            correctAlternative: 'B',
            alternativePercentages: {'A': 8, 'B': 78, 'C': 7, 'D': 7},
          ),
          QuestionStats(
            questionNumber: 2,
            correctAlternative: 'A',
            alternativePercentages: {'A': 72, 'B': 10, 'C': 12, 'D': 6},
          ),
        ],
      ),
      '8º Ano B|Avaliação História': const ClassStats(
        className: '8º Ano B',
        examName: 'Avaliação História',
        average: 6.9,
        approvalRate: 65,
        totalStudents: 24,
        gradeDistribution: [
          GradeDistribution(label: '0-2', count: 2),
          GradeDistribution(label: '2-4', count: 3),
          GradeDistribution(label: '4-6', count: 7),
          GradeDistribution(label: '6-8', count: 8),
          GradeDistribution(label: '8-10', count: 4),
        ],
        questionStats: [
          QuestionStats(
            questionNumber: 1,
            correctAlternative: 'A',
            alternativePercentages: {'A': 52, 'B': 20, 'C': 18, 'D': 10},
          ),
          QuestionStats(
            questionNumber: 2,
            correctAlternative: 'D',
            alternativePercentages: {'A': 15, 'B': 25, 'C': 20, 'D': 40},
          ),
        ],
      ),
      'Ensino Médio — 1A|Avaliação Física': const ClassStats(
        className: 'Ensino Médio — 1A',
        examName: 'Avaliação Física',
        average: 7.5,
        approvalRate: 78,
        totalStudents: 31,
        gradeDistribution: [
          GradeDistribution(label: '0-2', count: 1),
          GradeDistribution(label: '2-4', count: 4),
          GradeDistribution(label: '4-6', count: 6),
          GradeDistribution(label: '6-8', count: 11),
          GradeDistribution(label: '8-10', count: 9),
        ],
        questionStats: [
          QuestionStats(
            questionNumber: 1,
            correctAlternative: 'C',
            alternativePercentages: {'A': 12, 'B': 18, 'C': 58, 'D': 12},
          ),
          QuestionStats(
            questionNumber: 2,
            correctAlternative: 'B',
            alternativePercentages: {'A': 20, 'B': 55, 'C': 15, 'D': 10},
          ),
          QuestionStats(
            questionNumber: 3,
            correctAlternative: 'A',
            alternativePercentages: {'A': 62, 'B': 18, 'C': 10, 'D': 10},
          ),
        ],
      ),
    };

    return mockData[key] ?? mockData.values.first;
  }

  @override
  Future<List<String>> getAvailableStudents(String className) async {
    return _classStudents[className] ?? [];
  }

  @override
  Future<StudentStats> getStudentStats(
    String className,
    String studentName,
  ) async {
    final Map<String, StudentStats> mockData = {
      'João Silva': const StudentStats(
        studentName: 'João Silva',
        average: 8.4,
        examCount: 5,
        approvalRate: 84,
        subjectResults: [
          SubjectResult(subjectName: 'Matemática', grade: 8.5),
          SubjectResult(subjectName: 'Português', grade: 7.8),
          SubjectResult(subjectName: 'Ciências', grade: 9.0),
          SubjectResult(subjectName: 'História', grade: 8.3),
        ],
      ),
      'Ana Costa': const StudentStats(
        studentName: 'Ana Costa',
        average: 9.1,
        examCount: 5,
        approvalRate: 92,
        subjectResults: [
          SubjectResult(subjectName: 'Matemática', grade: 9.5),
          SubjectResult(subjectName: 'Português', grade: 8.8),
          SubjectResult(subjectName: 'Ciências', grade: 9.2),
          SubjectResult(subjectName: 'História', grade: 8.9),
        ],
      ),
      'Bruno Mendes': const StudentStats(
        studentName: 'Bruno Mendes',
        average: 6.8,
        examCount: 5,
        approvalRate: 68,
        subjectResults: [
          SubjectResult(subjectName: 'Matemática', grade: 6.0),
          SubjectResult(subjectName: 'Português', grade: 7.2),
          SubjectResult(subjectName: 'Ciências', grade: 7.0),
          SubjectResult(subjectName: 'História', grade: 7.0),
        ],
      ),
      'Carla Souza': const StudentStats(
        studentName: 'Carla Souza',
        average: 7.5,
        examCount: 4,
        approvalRate: 76,
        subjectResults: [
          SubjectResult(subjectName: 'Ciências', grade: 7.5),
          SubjectResult(subjectName: 'História', grade: 7.5),
        ],
      ),
      'Diego Rocha': const StudentStats(
        studentName: 'Diego Rocha',
        average: 7.9,
        examCount: 5,
        approvalRate: 80,
        subjectResults: [
          SubjectResult(subjectName: 'Ciências', grade: 8.2),
          SubjectResult(subjectName: 'História', grade: 7.6),
        ],
      ),
      'Elisa Rocha': const StudentStats(
        studentName: 'Elisa Rocha',
        average: 8.0,
        examCount: 3,
        approvalRate: 80,
        subjectResults: [
          SubjectResult(subjectName: 'Física', grade: 8.0),
        ],
      ),
      'Felipe Santos': const StudentStats(
        studentName: 'Felipe Santos',
        average: 7.2,
        examCount: 3,
        approvalRate: 72,
        subjectResults: [
          SubjectResult(subjectName: 'Física', grade: 7.2),
        ],
      ),
      'Gabriela Lima': const StudentStats(
        studentName: 'Gabriela Lima',
        average: 9.3,
        examCount: 3,
        approvalRate: 94,
        subjectResults: [
          SubjectResult(subjectName: 'Física', grade: 9.3),
        ],
      ),
    };

    return mockData[studentName] ?? mockData.values.first;
  }
}
