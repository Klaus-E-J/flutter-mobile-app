import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/access/data/auth_repository.dart';
import 'package:avalia_pro/features/access/data/user_profile.dart';
import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/config/config_screen.dart';
import 'package:avalia_pro/features/correction/data/submission_repository.dart';
import 'package:avalia_pro/features/correction/services/omr_image_service.dart';
import 'package:avalia_pro/features/exams/services/exam_randomizer_service.dart';
import 'package:avalia_pro/screens/correcao/leitura_gabarito_screen.dart';
import 'package:avalia_pro/screens/correcao/models/correcao_models.dart';
import 'package:avalia_pro/screens/correcao/resultado_correcao_screen.dart';
import 'package:avalia_pro/screens/provas/models/questao_model.dart';
import 'package:avalia_pro/screens/provas/prova_questoes_screen.dart';
import 'package:avalia_pro/screens/provas/widgets/alternativa_item.dart';

class _FakeAuthRepository extends AuthRepository {
  UserProfile profile = const UserProfile(
    uid: 'prof_1',
    name: 'Prof. Inicial',
    email: 'prof@escola.br',
    school: 'Escola Inicial',
    accessCode: 'PROF-1234',
  );

  int updateCalls = 0;

  @override
  Future<UserProfile?> getCurrentProfile() async => profile;

  @override
  Future<void> updateProfile(UserProfile updated) async {
    updateCalls++;
    profile = updated;
  }
}

void main() {
  group('Entrega N3 — UI & Domain Feature Tests', () {
    testWidgets('AlternativaItem StatefulWidget preserves text controller across parent rebuilds', (tester) async {
      String latestText = 'Inicial';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AlternativaItem(
                  alternativa: Alternativa(id: 'a1', texto: latestText, correta: true),
                  indice: 0,
                  isCorreta: true,
                  podeRemover: false,
                  onTextoChanged: (val) {
                    setState(() => latestText = val);
                  },
                  onMarcarCorreta: () {},
                  onRemover: () {},
                ),
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Texto Editado A');
      await tester.pump();

      expect(latestText, 'Texto Editado A');
      expect(find.text('Texto Editado A'), findsOneWidget);
    });

    testWidgets('ProvaQuestoesScreen enforces 30-question OMR limit and supports Gabarito Rápido assistant', (tester) async {
      final thirtyQuestions = List<Questao>.generate(
        30,
        (i) => criarQuestaoGabaritoRapido(
          numero: i + 1,
          letraCorreta: 'A',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProvaQuestoesScreen(
            examId: 'exam_30_limit',
            provaTitulo: 'Simulado ENEM',
            initialQuestions: thirtyQuestions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30/30 questão(ões)'), findsOneWidget);

      // Trying to add a 31st question triggers the 30-question OMR limit banner
      await tester.tap(find.text('Questão'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Limite máximo de 30 questões por folha de respostas OMR atingido'),
        findsOneWidget,
      );

      // Open Gabarito Rápido modal
      await tester.tap(find.text('Gabarito Rápido'));
      await tester.pumpAndSettle();

      expect(find.text('Gabarito Rápido (Prova Externa)'), findsOneWidget);
      expect(find.text('Aplicar Gabarito'), findsOneWidget);

      await tester.tap(find.text('Aplicar Gabarito'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Gabarito rápido com 30 questão(ões) gerado!'),
        findsOneWidget,
      );
    });

    testWidgets('ResultadoCorrecaoScreen auto-saves submissions once and prevents duplicate saves', (tester) async {
      final savedBatches = <List<SubmissionRecord>>[];

      const prova = ProvaCorrecao(
        id: 'exam_auto_save',
        titulo: 'Prova Auto Save',
        turma: '9º Ano A',
        disciplina: 'História',
        totalQuestoes: 5,
        totalAlunos: 1,
        classId: 'class_9a',
      );

      const resultados = [
        ResultadoAluno(
          studentId: 'std_1',
          nomeAluno: 'Mariana Souza',
          acertos: 4,
          totalQuestoes: 5,
          variantId: 'variant_A',
          variantCode: 'A',
          notaFinal10: 8.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ResultadoCorrecaoScreen(
            prova: prova,
            resultados: resultados,
            onSaveSubmissions: (records) async {
              savedBatches.add(records);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Auto-saved on initState!
      expect(savedBatches.length, 1);
      expect(savedBatches.first.single.id, 'sub_exam_auto_save_std_1');
      expect(savedBatches.first.single.studentName, 'Mariana Souza');
    });

    testWidgets('ConfigScreen loads and updates teacher profile (name and school)', (tester) async {
      final fakeAuthRepo = _FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ConfigScreen(authRepository: fakeAuthRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prof. Inicial'), findsOneWidget);
      expect(find.text('Escola Inicial'), findsOneWidget);

      // Tap edit profile button
      await tester.tap(find.byTooltip('Editar perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Editar perfil'), findsOneWidget);

      final textFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'Prof. Roberto Carlos');
      await tester.enterText(textFields.at(1), 'Colégio Dom Pedro II');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepo.updateCalls, 1);
      expect(fakeAuthRepo.profile.name, 'Prof. Roberto Carlos');
      expect(fakeAuthRepo.profile.school, 'Colégio Dom Pedro II');
      expect(find.text('Prof. Roberto Carlos'), findsOneWidget);
      expect(find.text('Colégio Dom Pedro II'), findsOneWidget);
    });

    testWidgets('LeituraGabaritoScreen binds nominal OMR QR studentId on shared exam and supports question annulment', (tester) async {
      const randomizer = ExamRandomizerService();
      const omrService = OmrImageService();

      final questions = [
        criarQuestaoGabaritoRapido(numero: 1, letraCorreta: 'A'),
        criarQuestaoGabaritoRapido(numero: 2, letraCorreta: 'B'),
      ];
      const students = [
        StudentRecord(id: 'stu_1', name: 'Alice Primeira', matricula: '101'),
        StudentRecord(id: 'stu_2', name: 'Bruno Segundo', matricula: '102'),
      ];

      final variants = randomizer.generateVariants(
        examId: 'exam_nominal_shared',
        questions: questions,
        sameExamForEveryone: true,
        variantCount: 1,
        shuffleQuestions: false,
        shuffleAlternatives: false,
      );
      final nominalSheets = randomizer.buildNominalAnswerSheetVariants(
        baseVariants: variants,
        students: students,
      );

      // Render synthetic OMR sheet for student #2 (Bruno Segundo) scanned FIRST
      // Bruno answers Q1=A (correct) and Q2=C (wrong, expected B)
      final brunoSheetPng = omrService.renderSyntheticSheetPng(
        qrPayload: nominalSheets[1].qrPayload,
        totalQuestions: 2,
        markedAnswers: const {
          1: ['A'],
          2: ['C'],
        },
      );

      const prova = ProvaCorrecao(
        id: 'exam_nominal_shared',
        titulo: 'Prova Nominal Unica',
        turma: '9º Ano A',
        disciplina: 'Física',
        totalQuestoes: 2,
        totalAlunos: 2,
        provaIndividual: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeituraGabaritoScreen(
            prova: prova,
            questions: questions,
            students: students,
            variants: variants,
            onPickSheetImage: () async => brunoSheetPng,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Carregar imagem de folha (PNG/JPG)'),
        200.0,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carregar imagem de folha (PNG/JPG)'));
      await tester.pumpAndSettle();

      // Verify OMR review modal opened with Bruno Segundo pre-selected (not Alice)
      expect(find.textContaining('Nota prévia: 5.0/10 (1/2)'), findsOneWidget);

      // Annul Question 2 so Bruno gets 2/2 (10.0/10)
      final anularChips = find.widgetWithText(FilterChip, 'Anular');
      expect(anularChips, findsNWidgets(2));
      await tester.tap(anularChips.at(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nota prévia: 10.0/10 (2/2)'), findsOneWidget);

      await tester.tap(find.text('Confirmar Nota'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Folha de Bruno Segundo corrigida: 2/2 acertos (Nota 10.0)'),
        findsOneWidget,
      );
    });
  });
}
