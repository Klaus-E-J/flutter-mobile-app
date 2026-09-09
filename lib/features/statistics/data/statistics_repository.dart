import '../models/statistics_models.dart';

/// Interface abstrata para o repositório de estatísticas.
///
/// Permite trocar a implementação mockada por uma real (banco de dados)
/// sem alterar nenhum código de UI.
abstract class StatisticsRepository {
  /// Retorna a lista de turmas disponíveis para seleção.
  Future<List<String>> getAvailableClasses();

  /// Retorna a lista de provas disponíveis para uma turma.
  Future<List<String>> getAvailableExams(String className);

  /// Retorna as estatísticas da turma para uma prova específica.
  Future<ClassStats> getClassStats(String className, String examName);

  /// Retorna a lista de alunos de uma turma.
  Future<List<String>> getAvailableStudents(String className);

  /// Retorna as estatísticas de um aluno específico.
  Future<StudentStats> getStudentStats(String className, String studentName);
}
