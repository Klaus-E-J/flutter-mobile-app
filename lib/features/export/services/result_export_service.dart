import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../correction/data/submission_repository.dart';

/// Serviço responsável pela exportação real dos resultados de avaliações,
/// estatísticas da turma e matrizes de respostas para CSV (UTF-8 com BOM)
/// e Excel (.xlsx multi-abas) (N3-08).
class ResultExportService {
  const ResultExportService();

  /// Gera os bytes de um arquivo CSV estruturado (RFC 4180 com UTF-8 BOM `\uFEFF`).
  Uint8List generateCsvBytes({
    required List<SubmissionRecord> submissions,
    bool includeStudentResults = true,
    bool includeStatistics = false,
    bool includeAnswerMatrix = false,
  }) {
    final buffer = StringBuffer('\uFEFF');

    if (includeStudentResults) {
      _writeCsvRow(buffer, const [
        'Turma',
        'Prova',
        'Variante',
        'ID Aluno',
        'Nome do Aluno',
        'Acertos',
        'Total Questões',
        'Em Branco',
        'Inválidas',
        'Percentual (%)',
        'Nota Final (0-10)',
        'Situação',
      ]);

      for (final sub in submissions) {
        final grade10 = sub.notaFinal10;
        final status = grade10 >= 6.0 ? 'Aprovado' : 'Recuperação';
        _writeCsvRow(buffer, [
          sub.className,
          sub.examTitle,
          sub.variantCode,
          sub.studentId,
          sub.studentName,
          sub.score.toString(),
          sub.totalQuestions.toString(),
          sub.blankCount.toString(),
          sub.invalidCount.toString(),
          sub.percentage.toStringAsFixed(2),
          grade10.toStringAsFixed(2),
          status,
        ]);
      }
      buffer.writeln();
    }

    if (includeStatistics && submissions.isNotEmpty) {
      _writeCsvRow(buffer, const ['ESTATÍSTICAS DA TURMA']);
      final statsRows = _buildStatisticsRows(submissions);
      for (final row in statsRows) {
        _writeCsvRow(buffer, row);
      }
      buffer.writeln();
    }

    if (includeAnswerMatrix && submissions.isNotEmpty) {
      _writeCsvRow(buffer, const ['MATRIZ DE RESPOSTAS E GABARITO']);
      final matrixRows = _buildAnswerMatrixRows(submissions);
      for (final row in matrixRows) {
        _writeCsvRow(buffer, row);
      }
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Gera os bytes de uma pasta de trabalho Excel (.xlsx) multi-abas.
  Uint8List generateExcelBytes({
    required List<SubmissionRecord> submissions,
    bool includeStudentResults = true,
    bool includeStatistics = false,
    bool includeAnswerMatrix = false,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    var createdCustomSheets = false;

    if (includeStudentResults) {
      createdCustomSheets = true;
      final sheet = excel['Resultados'];
      sheet.appendRow([
        TextCellValue('Turma'),
        TextCellValue('Prova'),
        TextCellValue('Variante'),
        TextCellValue('ID Aluno'),
        TextCellValue('Nome do Aluno'),
        TextCellValue('Acertos'),
        TextCellValue('Total Questões'),
        TextCellValue('Em Branco'),
        TextCellValue('Inválidas'),
        TextCellValue('Percentual (%)'),
        TextCellValue('Nota Final (0-10)'),
        TextCellValue('Situação'),
      ]);

      for (final sub in submissions) {
        final grade10 = sub.notaFinal10;
        final status = grade10 >= 6.0 ? 'Aprovado' : 'Recuperação';
        sheet.appendRow([
          TextCellValue(sub.className),
          TextCellValue(sub.examTitle),
          TextCellValue(sub.variantCode),
          TextCellValue(sub.studentId),
          TextCellValue(sub.studentName),
          IntCellValue(sub.score),
          IntCellValue(sub.totalQuestions),
          IntCellValue(sub.blankCount),
          IntCellValue(sub.invalidCount),
          DoubleCellValue(double.parse(sub.percentage.toStringAsFixed(2))),
          DoubleCellValue(double.parse(grade10.toStringAsFixed(2))),
          TextCellValue(status),
        ]);
      }
    }

    if (includeStatistics) {
      createdCustomSheets = true;
      final sheet = excel['Estatisticas'];
      for (final row in _buildStatisticsRows(submissions)) {
        sheet.appendRow(row.map(TextCellValue.new).toList());
      }
    }

    if (includeAnswerMatrix) {
      createdCustomSheets = true;
      final sheet = excel['Gabarito_Respostas'];
      for (final row in _buildAnswerMatrixRows(submissions)) {
        sheet.appendRow(row.map(TextCellValue.new).toList());
      }
    }

    if (createdCustomSheets &&
        defaultSheet != null &&
        defaultSheet != 'Resultados' &&
        defaultSheet != 'Estatisticas' &&
        defaultSheet != 'Gabarito_Respostas') {
      excel.delete(defaultSheet);
    }

    final encoded = excel.encode() ?? <int>[];
    return Uint8List.fromList(encoded);
  }

  List<List<String>> _buildStatisticsRows(List<SubmissionRecord> submissions) {
    if (submissions.isEmpty) {
      return const [
        ['Métrica', 'Valor'],
        ['Total de submissões', '0'],
      ];
    }

    final grades = submissions.map((s) => s.notaFinal10).toList();
    final avgGrade = grades.reduce((a, b) => a + b) / grades.length;
    final maxGrade = grades.reduce(max);
    final minGrade = grades.reduce(min);
    final approved = grades.where((g) => g >= 6.0).length;
    final approvalRate = (approved / grades.length) * 100.0;

    final rows = <List<String>>[
      ['Métrica', 'Valor'],
      ['Total de Alunos Avaliados', submissions.length.toString()],
      ['Média da Turma (0-10)', avgGrade.toStringAsFixed(2)],
      ['Maior Nota (0-10)', maxGrade.toStringAsFixed(2)],
      ['Menor Nota (0-10)', minGrade.toStringAsFixed(2)],
      ['Taxa de Aprovação (>= 6.0)', '${approvalRate.toStringAsFixed(1)}%'],
      [],
      [
        'Questão',
        'Total Avaliado',
        'Acertos',
        'Taxa de Acerto (%)',
        'Gabarito',
        'Mais Marcada',
        '% A',
        '% B',
        '% C',
        '% D',
        '% E',
        '% Branco',
      ],
    ];

    int maxQ = 0;
    for (final s in submissions) {
      maxQ = max(maxQ, max(s.totalQuestions, s.answers.length));
      for (final a in s.answers) {
        maxQ = max(maxQ, a.canonicalQuestionNumber);
      }
    }

    const letters = ['A', 'B', 'C', 'D', 'E'];

    for (var qNum = 1; qNum <= maxQ; qNum++) {
      final qAnswers = submissions
          .expand((s) => s.answers)
          .where((a) => a.canonicalQuestionNumber == qNum)
          .toList();
      if (qAnswers.isEmpty) continue;

      final totalAns = qAnswers.length;
      final hits = qAnswers.where((a) => a.isCorrect).length;
      final rate = (hits / totalAns) * 100.0;

      String canonicalKey = 'A';
      for (final a in qAnswers) {
        final corr = a.effectiveCanonicalCorrect.trim().toUpperCase();
        if (corr.isNotEmpty) {
          canonicalKey = corr;
          break;
        }
      }

      final counts = <String, int>{
        for (final l in letters) l: 0,
        'Branco': 0,
      };

      for (final a in qAnswers) {
        final sel = a.effectiveCanonicalSelected.trim().toUpperCase();
        if (sel.isEmpty || sel == 'EM BRANCO' || sel == 'BRANCO') {
          counts['Branco'] = (counts['Branco'] ?? 0) + 1;
        } else if (letters.contains(sel)) {
          counts[sel] = (counts[sel] ?? 0) + 1;
        }
      }

      var mostMarked = 'A';
      var mostCount = -1;
      for (final l in letters) {
        final c = counts[l] ?? 0;
        if (c > mostCount) {
          mostCount = c;
          mostMarked = l;
        }
      }
      if (mostCount <= 0 && (counts['Branco'] ?? 0) > 0) {
        mostMarked = 'Branco';
        mostCount = counts['Branco']!;
      }
      final mostPct =
          totalAns > 0 && mostCount > 0 ? ((mostCount / totalAns) * 100.0) : 0.0;

      String pctOf(String key) {
        final c = counts[key] ?? 0;
        final p = totalAns > 0 ? (c / totalAns) * 100.0 : 0.0;
        return '${p.toStringAsFixed(0)}%';
      }

      rows.add([
        'Questão $qNum',
        totalAns.toString(),
        hits.toString(),
        rate.toStringAsFixed(1),
        canonicalKey,
        '$mostMarked (${mostPct.toStringAsFixed(0)}%)',
        pctOf('A'),
        pctOf('B'),
        pctOf('C'),
        pctOf('D'),
        pctOf('E'),
        pctOf('Branco'),
      ]);
    }

    return rows;
  }

  List<List<String>> _buildAnswerMatrixRows(List<SubmissionRecord> submissions) {
    int maxQ = 0;
    for (final s in submissions) {
      maxQ = max(maxQ, max(s.totalQuestions, s.answers.length));
      for (final a in s.answers) {
        maxQ = max(maxQ, a.canonicalQuestionNumber);
      }
    }

    final header = <String>[
      'Turma',
      'Prova',
      'Aluno',
      'Variante',
      for (var q = 1; q <= maxQ; q++) ...[
        'Q${q}_Marcada',
        'Q${q}_Gabarito',
        'Q${q}_Resultado',
      ],
    ];

    final rows = <List<String>>[header];

    for (final sub in submissions) {
      final byCanonicalQ = {
        for (final a in sub.answers) a.canonicalQuestionNumber: a,
      };
      final row = <String>[
        sub.className,
        sub.examTitle,
        sub.studentName,
        sub.variantCode,
      ];
      for (var q = 1; q <= maxQ; q++) {
        final ans = byCanonicalQ[q];
        if (ans == null) {
          row.addAll(const ['-', '-', '-']);
        } else {
          row.addAll([
            ans.effectiveCanonicalSelected,
            ans.effectiveCanonicalCorrect,
            ans.isCorrect ? 'ACERTO' : 'ERRO',
          ]);
        }
      }
      rows.add(row);
    }

    return rows;
  }

  void _writeCsvRow(StringBuffer buffer, List<String> cells) {
    final escaped = cells.map((cell) {
      if (cell.contains(',') ||
          cell.contains(';') ||
          cell.contains('"') ||
          cell.contains('\n') ||
          cell.contains('\r')) {
        return '"${cell.replaceAll('"', '""')}"';
      }
      return cell;
    }).join(',');
    buffer.writeln(escaped);
  }
}
