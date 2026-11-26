import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../data/class_repository.dart';

/// Representa uma linha rejeitada ou duplicada durante a importação.
class StudentImportIssue {
  const StudentImportIssue({
    required this.lineNumber,
    required this.rawDescription,
    required this.reason,
  });

  final int lineNumber;
  final String rawDescription;
  final String reason;
}

/// Resultado do processamento de um arquivo de importação de alunos.
class StudentImportResult {
  const StudentImportResult({
    required this.fileName,
    required this.validStudents,
    this.duplicates = const [],
    this.rejectedRows = const [],
    this.warnings = const [],
    this.fatalError,
  });

  final String fileName;
  final List<StudentRecord> validStudents;
  final List<StudentImportIssue> duplicates;
  final List<StudentImportIssue> rejectedRows;
  final List<String> warnings;
  final String? fatalError;

  bool get hasErrors => fatalError != null || (validStudents.isEmpty && rejectedRows.isEmpty && duplicates.isEmpty);
}

/// Serviço responsável por ler, validar e normalizar arquivos CSV e Excel (.xlsx)
/// para importação de alunos (N3-01).
class StudentImportService {
  const StudentImportService();

  StudentImportResult parseBytes({
    required Uint8List bytes,
    required String fileName,
    List<StudentRecord> existingStudents = const [],
  }) {
    if (bytes.isEmpty) {
      return StudentImportResult(
        fileName: fileName,
        validStudents: const [],
        fatalError: 'O arquivo selecionado está vazio.',
      );
    }

    final lowerName = fileName.toLowerCase();
    List<List<String>> rows;

    try {
      if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
        rows = _parseExcel(bytes);
      } else {
        rows = _parseCsv(bytes);
      }
    } catch (error) {
      return StudentImportResult(
        fileName: fileName,
        validStudents: const [],
        fatalError: 'Não foi possível ler o arquivo "$fileName": $error',
      );
    }

    return _validateAndMapRows(
      fileName: fileName,
      rows: rows,
      existingStudents: existingStudents,
    );
  }

  List<List<String>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final rows = <List<String>>[];

    for (final table in excel.tables.values) {
      for (final row in table.rows) {
        final cells = row.map((cell) {
          final val = cell?.value;
          if (val == null) return '';
          return val.toString().trim();
        }).toList();
        if (cells.any((c) => c.isNotEmpty)) {
          rows.add(cells);
        }
      }
      if (rows.isNotEmpty) break; // Lê a primeira aba com dados
    }
    return rows;
  }

  List<List<String>> _parseCsv(Uint8List bytes) {
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      content = latin1.decode(bytes);
    }

    // Remove UTF-8 BOM se presente
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final lines = const LineSplitter().convert(content);
    final nonEmptyLines = lines.where((l) => l.trim().isNotEmpty).toList();
    if (nonEmptyLines.isEmpty) return const [];

    final delimiter = _detectDelimiter(nonEmptyLines.first);
    return nonEmptyLines
        .map((line) => _splitCsvLine(line, delimiter))
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
  }

  String _detectDelimiter(String firstLine) {
    final semicolonCount = ';'.allMatches(firstLine).length;
    final commaCount = ','.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;

    if (tabCount > semicolonCount && tabCount > commaCount) return '\t';
    if (semicolonCount > commaCount) return ';';
    return ',';
  }

  List<String> _splitCsvLine(String line, String delimiter) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (!inQuotes && char == delimiter) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  StudentImportResult _validateAndMapRows({
    required String fileName,
    required List<List<String>> rows,
    required List<StudentRecord> existingStudents,
  }) {
    if (rows.isEmpty) {
      return StudentImportResult(
        fileName: fileName,
        validStudents: const [],
        fatalError: 'Nenhum registro encontrado no arquivo.',
      );
    }

    int nameCol = 0;
    int? matriculaCol;
    int? emailCol;
    int startRow = 0;

    final firstRow = rows.first;
    if (_looksLikeHeader(firstRow)) {
      startRow = 1;
      int? detectedNameCol;
      for (var i = 0; i < firstRow.length; i++) {
        final header = _normalizeForComparison(firstRow[i]);
        if (detectedNameCol == null &&
            (header.contains('nome') ||
                header.contains('aluno') ||
                header.contains('estudante') ||
                header.contains('name') ||
                header.contains('student'))) {
          detectedNameCol = i;
        } else if (matriculaCol == null &&
            (header.contains('matric') ||
                header == 'ra' ||
                header.contains('registro') ||
                header.contains('codigo') ||
                header == 'id')) {
          matriculaCol = i;
        } else if (emailCol == null &&
            (header.contains('mail') || header.contains('contato'))) {
          emailCol = i;
        }
      }
      if (detectedNameCol != null) {
        nameCol = detectedNameCol;
      }
    } else if (firstRow.length >= 2) {
      matriculaCol = 1;
      if (firstRow.length >= 3) {
        emailCol = 2;
      }
    }

    final seenNames = <String>{
      for (final s in existingStudents) _normalizeForComparison(s.name),
    };
    final existingNames = <String>{
      for (final s in existingStudents) _normalizeForComparison(s.name),
    };
    final seenMatriculas = <String>{
      for (final s in existingStudents)
        if (s.matricula.trim().isNotEmpty) _normalizeForComparison(s.matricula),
    };
    final existingMatriculas = <String>{
      for (final s in existingStudents)
        if (s.matricula.trim().isNotEmpty) _normalizeForComparison(s.matricula),
    };
    final seenEmails = <String>{
      for (final s in existingStudents)
        if (s.email.trim().isNotEmpty) _normalizeForComparison(s.email),
    };
    final existingEmails = <String>{
      for (final s in existingStudents)
        if (s.email.trim().isNotEmpty) _normalizeForComparison(s.email),
    };

    final validStudents = <StudentRecord>[];
    final duplicates = <StudentImportIssue>[];
    final rejectedRows = <StudentImportIssue>[];
    final warnings = <String>[];

    for (var i = startRow; i < rows.length; i++) {
      final row = rows[i];
      final lineNumber = i + 1;

      final name = nameCol < row.length ? row[nameCol].trim() : '';
      final matricula = (matriculaCol != null && matriculaCol < row.length)
          ? row[matriculaCol].trim()
          : '';
      final email = (emailCol != null && emailCol < row.length)
          ? row[emailCol].trim()
          : '';

      if (name.isEmpty && matricula.isEmpty && email.isEmpty) {
        continue;
      }

      if (name.isEmpty || name.length < 2) {
        rejectedRows.add(
          StudentImportIssue(
            lineNumber: lineNumber,
            rawDescription: row.join(' | '),
            reason: 'Nome do aluno ausente ou inválido.',
          ),
        );
        continue;
      }

      final normalizedName = _normalizeForComparison(name);
      final normalizedMatricula = _normalizeForComparison(matricula);
      final normalizedEmail = _normalizeForComparison(email);

      if (seenNames.contains(normalizedName)) {
        final alreadyInClass = existingNames.contains(normalizedName);
        duplicates.add(
          StudentImportIssue(
            lineNumber: lineNumber,
            rawDescription: name,
            reason: alreadyInClass
                ? 'Aluno já cadastrado na turma.'
                : 'Nome duplicado no arquivo.',
          ),
        );
        continue;
      }

      if (normalizedMatricula.isNotEmpty &&
          seenMatriculas.contains(normalizedMatricula)) {
        final alreadyInClass = existingMatriculas.contains(normalizedMatricula);
        duplicates.add(
          StudentImportIssue(
            lineNumber: lineNumber,
            rawDescription: '$name ($matricula)',
            reason: alreadyInClass
                ? 'Matrícula já cadastrada na turma.'
                : 'Matrícula duplicada no arquivo.',
          ),
        );
        continue;
      }

      if (normalizedEmail.isNotEmpty &&
          email.contains('@') &&
          seenEmails.contains(normalizedEmail)) {
        final alreadyInClass = existingEmails.contains(normalizedEmail);
        duplicates.add(
          StudentImportIssue(
            lineNumber: lineNumber,
            rawDescription: '$name ($email)',
            reason: alreadyInClass
                ? 'E-mail já cadastrado na turma.'
                : 'E-mail duplicado no arquivo.',
          ),
        );
        continue;
      }

      if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
        warnings.add('Linha $lineNumber ($name): e-mail "$email" parece inválido.');
      }

      seenNames.add(normalizedName);
      if (normalizedMatricula.isNotEmpty) {
        seenMatriculas.add(normalizedMatricula);
      }
      if (normalizedEmail.isNotEmpty && email.contains('@')) {
        seenEmails.add(normalizedEmail);
      }

      validStudents.add(
        StudentRecord(
          id: '',
          name: name,
          matricula: matricula,
          email: email,
        ),
      );
    }

    return StudentImportResult(
      fileName: fileName,
      validStudents: validStudents,
      duplicates: duplicates,
      rejectedRows: rejectedRows,
      warnings: warnings,
    );
  }

  bool _looksLikeHeader(List<String> firstRow) {
    for (final cell in firstRow) {
      final normalized = _normalizeForComparison(cell);
      if (normalized == 'nome' ||
          normalized == 'nome completo' ||
          normalized == 'nome do aluno' ||
          normalized == 'aluno' ||
          normalized == 'estudante' ||
          normalized == 'matricula' ||
          normalized == 'ra' ||
          normalized == 'email' ||
          normalized == 'e-mail' ||
          normalized == 'name' ||
          normalized == 'student') {
        return true;
      }
    }
    return false;
  }

  String _normalizeForComparison(String value) {
    var s = value.trim().toLowerCase();
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    accents.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }
}
