import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia_pro/features/classes/data/class_repository.dart';
import 'package:avalia_pro/features/classes/importacao_alunos_screen.dart';
import 'package:avalia_pro/features/classes/services/student_import_service.dart';

void main() {
  group('StudentImportService Tests (N3-01)', () {
    const service = StudentImportService();

    test('parses standard UTF-8 CSV with BOM and comma delimiter', () {
      const csvText = '\uFEFFNome,Matrícula,Email\n'
          'Ana Beatriz Silva,2026001,ana@escola.com\n'
          'Bruno Henrique Costa,2026002,bruno@escola.com\n';
      final bytes = Uint8List.fromList(utf8.encode(csvText));

      final result = service.parseBytes(
        bytes: bytes,
        fileName: 'alunos.csv',
      );

      expect(result.validStudents.length, 2);
      expect(result.validStudents[0].name, 'Ana Beatriz Silva');
      expect(result.validStudents[0].matricula, '2026001');
      expect(result.validStudents[0].email, 'ana@escola.com');
      expect(result.validStudents[1].name, 'Bruno Henrique Costa');
      expect(result.validStudents[1].matricula, '2026002');
      expect(result.duplicates, isEmpty);
      expect(result.rejectedRows, isEmpty);
    });

    test('parses semicolon CSV encoded in ISO-8859-1 (Latin-1) with accents', () {
      const csvText = 'Matrícula;Nome Completo;E-mail\r\n'
          '1001;João Conceição;joao@escola.br\r\n'
          '1002;Andréia Araújo;andreia@escola.br\r\n';
      final bytes = Uint8List.fromList(latin1.encode(csvText));

      final result = service.parseBytes(
        bytes: bytes,
        fileName: 'turma_latin1.csv',
      );

      expect(result.validStudents.length, 2);
      expect(result.validStudents[0].name, 'João Conceição');
      expect(result.validStudents[0].matricula, '1001');
      expect(result.validStudents[0].email, 'joao@escola.br');
      expect(result.validStudents[1].name, 'Andréia Araújo');
      expect(result.validStudents[1].matricula, '1002');
    });

    test('parses headerless single-column CSV', () {
      const csvText = 'Carlos Eduardo\nFernanda Lima\nGabriel Souza';
      final bytes = Uint8List.fromList(utf8.encode(csvText));

      final result = service.parseBytes(
        bytes: bytes,
        fileName: 'lista_simples.csv',
      );

      expect(result.validStudents.length, 3);
      expect(result.validStudents.map((s) => s.name).toList(), [
        'Carlos Eduardo',
        'Fernanda Lima',
        'Gabriel Souza',
      ]);
    });

    test('detects duplicates in file and against existing class students (by name, matricula, and email), and rejects empty names', () {
      const csvText = 'Nome,Matricula,Email\n'
          'Lucas Mendes,202610,lucas@escola.com\n'
          'lucas mendes,202699,lucas2@escola.com\n' // duplicate by name
          'Mariana Costa,202610,mari@escola.com\n' // duplicate by matricula
          'Outro Nome,202644,lucas@escola.com\n' // duplicate by email in file
          'Aluno Email Turma,202645,carla.existente@escola.com\n' // duplicate by email against existing
          ',202655,semnome@escola.com\n' // missing name -> rejected
          'Pedro Rocha,202688,email-invalido\n' // valid student with email warning
          ' Carla Existente ,202677,carla2@escola.com\n'; // duplicate against existing by name

      final bytes = Uint8List.fromList(utf8.encode(csvText));
      final existing = [
        const StudentRecord(
          id: 'std-1',
          name: 'Carla Existente',
          matricula: '999999',
          email: 'carla.existente@escola.com',
        ),
      ];

      final result = service.parseBytes(
        bytes: bytes,
        fileName: 'validacao.csv',
        existingStudents: existing,
      );

      expect(result.validStudents.length, 2);
      expect(result.validStudents[0].name, 'Lucas Mendes');
      expect(result.validStudents[1].name, 'Pedro Rocha');
      expect(result.duplicates.length, 5);
      expect(result.rejectedRows.length, 1);
      expect(result.warnings, isNotEmpty);
    });

    test('parses Excel (.xlsx) workbook accurately', () {
      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      sheet.appendRow([
        TextCellValue('Nome do Aluno'),
        TextCellValue('RA'),
        TextCellValue('Email'),
      ]);
      sheet.appendRow([
        TextCellValue('Rafael Almeida'),
        IntCellValue(2026123),
        TextCellValue('rafael@escola.com'),
      ]);
      sheet.appendRow([
        TextCellValue('Sofia Ribeiro'),
        TextCellValue('2026124'),
        TextCellValue('sofia@escola.com'),
      ]);

      final encoded = excel.encode()!;
      final result = service.parseBytes(
        bytes: Uint8List.fromList(encoded),
        fileName: 'alunos.xlsx',
      );

      expect(result.validStudents.length, 2);
      expect(result.validStudents[0].name, 'Rafael Almeida');
      expect(result.validStudents[0].matricula, '2026123');
      expect(result.validStudents[0].email, 'rafael@escola.com');
      expect(result.validStudents[1].name, 'Sofia Ribeiro');
      expect(result.validStudents[1].matricula, '2026124');
    });

    test('handles empty file gracefully', () {
      final result = service.parseBytes(
        bytes: Uint8List(0),
        fileName: 'vazio.csv',
      );

      expect(result.validStudents, isEmpty);
      expect(result.hasErrors, isTrue);
    });

    testWidgets('ImportacaoAlunosScreen previews valid students, shows duplicate warnings, and saves on confirm', (tester) async {
      const csvText = 'Nome,Matrícula,Email\n'
          'Beatriz Rocha,202601,bia@escola.com\n'
          'Caio Martins,202602,caio@escola.com\n'
          'Beatriz Rocha,202603,bia2@escola.com\n';
      final bytes = Uint8List.fromList(utf8.encode(csvText));
      List<StudentRecord>? savedStudents;

      await tester.pumpWidget(
        MaterialApp(
          home: ImportacaoAlunosScreen(
            nomeTurma: '9º Ano A',
            classId: 'class_9a',
            onPickFile: () async => (name: 'turma_9a.csv', bytes: bytes),
            onSaveStudents: (students) async {
              savedStudents = students;
            },
          ),
        ),
      );

      expect(find.text('Selecionar arquivo'), findsOneWidget);
      await tester.tap(find.text('Selecionar arquivo'));
      await tester.pumpAndSettle();

      // Should be on preview step
      expect(find.text('Prévia da importação'), findsOneWidget);
      expect(find.text('Beatriz Rocha'), findsOneWidget);
      expect(find.text('Caio Martins'), findsOneWidget);
      expect(find.textContaining('1 duplicado(s) ignorado(s)'), findsOneWidget);

      // Confirm import
      await tester.tap(find.text('Confirmar importação'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Importar'), findsOneWidget);
      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(find.text('Importação concluída!'), findsOneWidget);
      expect(savedStudents, isNotNull);
      expect(savedStudents!.length, 2);
      expect(savedStudents!.first.matricula, '202601');
    });
  });
}
