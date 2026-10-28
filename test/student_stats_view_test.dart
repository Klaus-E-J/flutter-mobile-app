import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/statistics/data/statistics_repository.dart';
import 'package:avalia_pro/features/statistics/models/statistics_models.dart';
import 'package:avalia_pro/features/statistics/views/student_stats_view.dart';

class FakeStatisticsRepository implements StatisticsRepository {
  FakeStatisticsRepository({
    this.studentsToReturn = const [],
    this.statsToReturn,
  });

  List<StudentOption> studentsToReturn;
  StudentStats? statsToReturn;
  String? lastRequestedStudentId;

  @override
  Future<List<String>> getAvailableClasses() async => ['Turma A'];

  @override
  Future<List<String>> getAvailableExams(String className) async => ['Prova 1'];

  @override
  Future<ClassStats> getClassStats(String className, String examName) async {
    return const ClassStats(
      className: 'Turma A',
      examName: 'Prova 1',
      average: 8.0,
      approvalRate: 100.0,
      totalStudents: 1,
      gradeDistribution: [],
      questionStats: [],
    );
  }

  @override
  Future<List<StudentOption>> getAvailableStudents(String className) async {
    return studentsToReturn;
  }

  @override
  Future<StudentStats> getStudentStats(String className, String studentId) async {
    lastRequestedStudentId = studentId;
    return statsToReturn ??
        StudentStats(
          studentName: 'Aluno $studentId',
          average: 8.5,
          examCount: 2,
          approvalRate: 100.0,
          subjectResults: const [
            SubjectResult(subjectName: 'Matemática', grade: 8.5),
          ],
        );
  }
}

void main() {
  group('StudentStatsView tests', () {
    testWidgets('exibe "Nenhum aluno disponível" sem loop de loading quando turma não tem alunos', (tester) async {
      final fakeRepo = FakeStatisticsRepository(studentsToReturn: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentStatsView(
              repository: fakeRepo,
              className: 'Turma Vazia',
            ),
          ),
        ),
      );

      // Aguarda as chamadas assíncronas
      await tester.pumpAndSettle();

      // Não deve ter CircularProgressIndicator preso na tela
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nenhum aluno disponível'), findsOneWidget);
    });

    testWidgets('renderiza homônimos no Dropdown sem conflito de chaves e com labels diferenciados', (tester) async {
      final fakeRepo = FakeStatisticsRepository(
        studentsToReturn: const [
          StudentOption(id: 'std_001', name: 'Lucas Gabriel'),
          StudentOption(id: 'std_002', name: 'Lucas Gabriel'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentStatsView(
              repository: fakeRepo,
              className: 'Turma A',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Primeiro aluno é selecionado por padrão
      expect(fakeRepo.lastRequestedStudentId, 'std_001');

      // Abre o dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Devem existir os dois rótulos diferenciados
      expect(find.text('Lucas Gabriel (#1 - std_)'), findsWidgets);
      expect(find.text('Lucas Gabriel (#2 - std_)'), findsOneWidget);

      // Seleciona o segundo aluno
      await tester.tap(find.text('Lucas Gabriel (#2 - std_)').last);
      await tester.pumpAndSettle();

      // Confirma que o ID correto foi solicitado
      expect(fakeRepo.lastRequestedStudentId, 'std_002');
    });

    test('StudentOption implementa equality e toString', () {
      const opt1 = StudentOption(id: '1', name: 'Ana');
      const opt2 = StudentOption(id: '1', name: 'Ana');
      const opt3 = StudentOption(id: '2', name: 'Ana');

      expect(opt1, equals(opt2));
      expect(opt1.hashCode, equals(opt2.hashCode));
      expect(opt1 == opt3, isFalse);
      expect(opt1.toString(), 'StudentOption(id: 1, name: Ana)');
    });
  });
}
