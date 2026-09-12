import 'package:flutter/material.dart';

/// Resultado de uma tentativa de leitura de arquivo de importação
/// de alunos.
class StudentImportResult {
  const StudentImportResult({
    required this.fileName,
    required this.isValid,
    this.studentNames = const [],
    this.errorMessage,
  });

  final String fileName;
  final bool isValid;
  final List<String> studentNames;
  final String? errorMessage;
}

/// Opção de arquivo oferecida na seleção (mockada nesta entrega).
class ImportFileOption {
  const ImportFileOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Contrato de leitura/parse de arquivos de importação de alunos.
///
/// O fluxo visual (ImportStudentsSheet) depende apenas desta interface,
/// não de uma implementação específica. Isso permite que a leitura real
/// de CSV/Excel seja implementada e conectada posteriormente sem
/// alterar a tela.
abstract class StudentImportParser {
  /// Arquivos disponíveis para seleção.
  List<ImportFileOption> get availableFiles;

  /// Executa a leitura/parse do arquivo escolhido.
  Future<StudentImportResult> parse(String fileId);
}

/// Implementação mockada usada nesta entrega. Simula um pequeno atraso
/// de leitura e retorna um resultado válido ou inválido dependendo do
/// arquivo escolhido, sem depender de seleção real do sistema de
/// arquivos, persistência ou Firebase.
class MockStudentImportParser implements StudentImportParser {
  const MockStudentImportParser();

  @override
  List<ImportFileOption> get availableFiles => const [
    ImportFileOption(
      id: 'valido',
      label: 'lista_alunos.csv',
      icon: Icons.description_outlined,
    ),
    ImportFileOption(
      id: 'invalido',
      label: 'arquivo_corrompido.txt',
      icon: Icons.insert_drive_file_outlined,
    ),
  ];

  @override
  Future<StudentImportResult> parse(String fileId) async {
    // Simula o tempo de leitura do arquivo.
    await Future.delayed(const Duration(milliseconds: 700));

    if (fileId == 'invalido') {
      return const StudentImportResult(
        fileName: 'arquivo_corrompido.txt',
        isValid: false,
        errorMessage:
            'Não foi possível ler o arquivo. Verifique se o formato é '
            '.csv ou .xlsx e tente novamente.',
      );
    }

    return const StudentImportResult(
      fileName: 'lista_alunos.csv',
      isValid: true,
      studentNames: [
        'Fernanda Lima',
        'Gustavo Pires',
        'Helena Cardoso',
        'Igor Tavares',
        'Juliana Ramos',
      ],
    );
  }
}
