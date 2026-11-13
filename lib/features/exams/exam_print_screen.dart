import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_loading.dart';
import '../../screens/provas/models/questao_model.dart';
import '../classes/data/class_repository.dart';
import 'data/exam_repository.dart';
import 'models/exam_variant.dart';
import 'services/exam_pdf_service.dart';
import 'services/exam_randomizer_service.dart';

enum ExamPdfDocumentType {
  completePackage,
  bookletsOnly,
  answerSheetsOnly,
}

/// Tela de Geração e Impressão de Provas, Folhas de Resposta OMR e Caderno `.doc` (N3-02 / N3-03).
///
/// Permite visualizar as variantes geradas (Cadernos A-D ou Individuais por Aluno),
/// configurar embaralhamento de questões/alternativas, gerar folhas OMR nominais por aluno
/// mesmo em prova única, exportar caderno editável `.doc` e imprimir/compartilhar PDF.
class ExamPrintScreen extends StatefulWidget {
  const ExamPrintScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    required this.classIds,
    required this.classNames,
    required this.sameExamForEveryone,
    this.initialQuestions,
    this.initialVariants,
    this.initialStudents,
    this.onExportDoc,
  });

  final String examId;
  final String examTitle;
  final List<String> classIds;
  final List<String> classNames;
  final bool sameExamForEveryone;
  final List<Questao>? initialQuestions;
  final List<ExamVariant>? initialVariants;
  final List<StudentRecord>? initialStudents;
  final Future<void> Function(Uint8List bytes, String fileName)? onExportDoc;

  @override
  State<ExamPrintScreen> createState() => _ExamPrintScreenState();
}

class _ExamPrintScreenState extends State<ExamPrintScreen> {
  final ExamRepository _examRepository = ExamRepository();
  final ClassRepository _classRepository = ClassRepository();
  final ExamRandomizerService _randomizerService = const ExamRandomizerService();
  final ExamPdfService _pdfService = const ExamPdfService();

  List<Questao> _questions = [];
  List<ExamVariant> _variants = [];
  List<StudentRecord> _students = [];
  ExamPdfDocumentType _docType = ExamPdfDocumentType.completePackage;
  int _variantCount = 4;
  bool _shuffleQuestions = true;
  bool _shuffleAlternatives = true;
  bool _nominalSheetsPerStudent = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<ExamVariant> get _effectiveAnswerSheetVariants {
    if (widget.sameExamForEveryone &&
        _nominalSheetsPerStudent &&
        _students.isNotEmpty) {
      return _randomizerService.buildNominalAnswerSheetVariants(
        baseVariants: _variants,
        students: _students,
        classId: widget.classIds.isNotEmpty ? widget.classIds.first : null,
        className:
            widget.classNames.isNotEmpty ? widget.classNames.first : null,
      );
    }
    return _variants;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions =
          widget.initialQuestions ?? await _examRepository.getQuestions(widget.examId);

      if (questions.isEmpty) {
        if (!mounted) return;
        setState(() {
          _questions = [];
          _variants = [];
          _isLoading = false;
        });
        return;
      }

      List<StudentRecord> students = [];
      if (widget.initialStudents != null) {
        students = List<StudentRecord>.from(widget.initialStudents!);
      } else if (widget.classIds.isNotEmpty) {
        for (final classId in widget.classIds) {
          try {
            final classStudents = await _classRepository.getStudents(classId);
            students.addAll(classStudents);
          } catch (_) {}
        }
      }

      var variants = widget.initialVariants ?? <ExamVariant>[];
      if (variants.isEmpty) {
        try {
          variants = await _examRepository.getVariants(widget.examId);
        } catch (_) {}
      }

      // Verifica se a lista de alunos da turma mudou no modo individual
      bool needsRegeneration = variants.isEmpty;
      if (!needsRegeneration && !widget.sameExamForEveryone) {
        if (students.isEmpty) {
          needsRegeneration = variants.any(
            (v) => v.studentId != null && v.studentId!.isNotEmpty,
          );
        } else if (variants.length != students.length) {
          needsRegeneration = true;
        } else {
          final studentMap = {for (final s in students) s.id: s};
          for (final v in variants) {
            final s = v.studentId != null ? studentMap[v.studentId] : null;
            if (s == null ||
                v.studentName != s.name ||
                (v.studentMatricula ?? '') != s.matricula) {
              needsRegeneration = true;
              break;
            }
          }
        }
      }

      if (needsRegeneration) {
        variants = _randomizerService.generateVariants(
          examId: widget.examId,
          questions: questions,
          sameExamForEveryone: widget.sameExamForEveryone,
          students: students,
          classId: widget.classIds.isNotEmpty ? widget.classIds.first : null,
          className: widget.classNames.isNotEmpty ? widget.classNames.first : null,
          variantCount: _variantCount,
          shuffleQuestions: _shuffleQuestions,
          shuffleAlternatives: _shuffleAlternatives,
        );
        try {
          await _examRepository.saveVariants(widget.examId, variants);
        } catch (_) {}
      } else if (widget.sameExamForEveryone &&
          const [1, 2, 4].contains(variants.length)) {
        _variantCount = variants.length;
      }

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _students = students;
        _variants = variants;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível preparar os documentos: $error';
      });
    }
  }

  Future<void> _regerarVariantes() async {
    if (_questions.isEmpty) return;
    setState(() => _isLoading = true);

    final newSeed = DateTime.now().microsecondsSinceEpoch;
    final variants = _randomizerService.generateVariants(
      examId: widget.examId,
      questions: _questions,
      sameExamForEveryone: widget.sameExamForEveryone,
      students: _students,
      classId: widget.classIds.isNotEmpty ? widget.classIds.first : null,
      className: widget.classNames.isNotEmpty ? widget.classNames.first : null,
      variantCount: _variantCount,
      shuffleQuestions: _shuffleQuestions,
      shuffleAlternatives: _shuffleAlternatives,
      seed: newSeed,
    );

    try {
      await _examRepository.saveVariants(widget.examId, variants);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _variants = variants;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${variants.length} variante(s) gerada(s) com sucesso!'),
      ),
    );
  }

  Future<Uint8List> _buildPdfBytes() {
    final sheetVariants = _effectiveAnswerSheetVariants;
    switch (_docType) {
      case ExamPdfDocumentType.completePackage:
        return _pdfService.generateCompleteExamPackagePdf(
          examTitle: widget.examTitle,
          classNames: widget.classNames,
          variants: _variants,
          answerSheetVariants: sheetVariants,
          includeTeacherAnswerKey: true,
        );
      case ExamPdfDocumentType.bookletsOnly:
        return _pdfService.generateExamBookletPdf(
          examTitle: widget.examTitle,
          classNames: widget.classNames,
          variants: _variants,
        );
      case ExamPdfDocumentType.answerSheetsOnly:
        return _pdfService.generateAnswerSheetsPdf(
          examTitle: widget.examTitle,
          classNames: widget.classNames,
          variants: sheetVariants,
        );
    }
  }

  void _abrirVisualizadorPdf() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text('PDF • ${widget.examTitle}'),
          ),
          body: PdfPreview(
            build: (_) => _buildPdfBytes(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName:
                '${widget.examTitle.replaceAll(' ', '_').toLowerCase()}_avalia_pro.pdf',
          ),
        ),
      ),
    );
  }

  Future<void> _exportarCadernoDoc() async {
    try {
      final docBytes = _pdfService.generateExamBookletDoc(
        examTitle: widget.examTitle,
        classNames: widget.classNames,
        variants: _variants,
        includeTeacherAnswerKey: true,
      );
      final sanitizedTitle = widget.examTitle
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
          .toLowerCase();
      final fileName = '${sanitizedTitle.isEmpty ? "prova" : sanitizedTitle}_caderno.doc';

      if (widget.onExportDoc != null) {
        await widget.onExportDoc!(docBytes, fileName);
      } else {
        String? savedPath;
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
          await file.writeAsBytes(docBytes, flush: true);
          savedPath = file.path;
        } catch (_) {}

        const mimeType = 'application/msword';
        final xFile = savedPath != null
            ? XFile(savedPath, mimeType: mimeType, name: fileName)
            : XFile.fromData(docBytes, mimeType: mimeType, name: fileName);

        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            fileNameOverrides: [fileName],
            subject: 'Caderno de Prova Editável - ${widget.examTitle}',
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caderno editável ($fileName) exportado com sucesso!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível exportar o arquivo .doc: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sheetVariants = _effectiveAnswerSheetVariants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Variantes e Impressão PDF'),
        actions: [
          if (!_isLoading && _questions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: 'Reembaralhar variantes',
              onPressed: _regerarVariantes,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoading(message: 'Gerando variantes e gabaritos...')
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_errorMessage!, textAlign: TextAlign.center),
                    ),
                  )
                : _questions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Cadastre ao menos uma questão na prova antes de gerar os documentos para impressão.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            widget.examTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_questions.length} questões • ${_variants.length} variante(s) • ${sheetVariants.length} folha(s) OMR com QR Code',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          if (widget.sameExamForEveryone) ...[
                            Text(
                              'Quantidade de variantes (Cadernos)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 1, label: Text('1 (A)')),
                                ButtonSegment(value: 2, label: Text('2 (A-B)')),
                                ButtonSegment(value: 4, label: Text('4 (A-D)')),
                              ],
                              selected: {_variantCount},
                              onSelectionChanged: (selection) {
                                setState(() => _variantCount = selection.first);
                                _regerarVariantes();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Opções de embaralhamento e identificação',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                SwitchListTile.adaptive(
                                  value: _shuffleQuestions,
                                  title: const Text('Embaralhar ordem das questões'),
                                  subtitle: const Text(
                                    'Altera a sequência das questões em cada variante.',
                                  ),
                                  onChanged: (val) {
                                    setState(() => _shuffleQuestions = val);
                                    _regerarVariantes();
                                  },
                                ),
                                const Divider(height: 1),
                                SwitchListTile.adaptive(
                                  value: _shuffleAlternatives,
                                  title: const Text('Embaralhar alternativas (A–E)'),
                                  subtitle: const Text(
                                    'Permuta a ordem das alternativas mantendo o gabarito sincronizado.',
                                  ),
                                  onChanged: (val) {
                                    setState(() => _shuffleAlternatives = val);
                                    _regerarVariantes();
                                  },
                                ),
                                if (widget.sameExamForEveryone &&
                                    _students.isNotEmpty) ...[
                                  const Divider(height: 1),
                                  SwitchListTile.adaptive(
                                    value: _nominalSheetsPerStudent,
                                    title: const Text(
                                      'Folhas OMR nominais por aluno',
                                    ),
                                    subtitle: Text(
                                      'Gera ${_students.length} folha(s) de resposta identificadas com nome, matrícula e QR Code individual de cada aluno.',
                                    ),
                                    onChanged: (val) {
                                      setState(
                                        () => _nominalSheetsPerStudent = val,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Documento para impressão',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RadioGroup<ExamPdfDocumentType>(
                            groupValue: _docType,
                            onChanged: (val) {
                              if (val != null) setState(() => _docType = val);
                            },
                            child: Column(
                              children: [
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: const RadioListTile<ExamPdfDocumentType>(
                                    value: ExamPdfDocumentType.completePackage,
                                    title: Text('Pacote Completo (Prova + Folha OMR + Gabarito)'),
                                    subtitle: Text(
                                      'Cadernos de questões, folhas de respostas com QR Code e mapa de gabaritos.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: const RadioListTile<ExamPdfDocumentType>(
                                    value: ExamPdfDocumentType.bookletsOnly,
                                    title: Text('Apenas Cadernos de Questões'),
                                    subtitle: Text('Questões e alternativas sem corte entre páginas.'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: const RadioListTile<ExamPdfDocumentType>(
                                    value: ExamPdfDocumentType.answerSheetsOnly,
                                    title: Text('Apenas Folhas de Respostas OMR'),
                                    subtitle: Text('Folhas A4 com marcadores fiduciais e QR Code.'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: 'Visualizar e Imprimir PDF',
                            icon: Icons.picture_as_pdf_outlined,
                            expanded: true,
                            onPressed: _abrirVisualizadorPdf,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Exportar Prova Editável (.doc)',
                            icon: Icons.description_outlined,
                            variant: AppButtonVariant.secondary,
                            expanded: true,
                            onPressed: _exportarCadernoDoc,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Reembaralhar questões e alternativas',
                            icon: Icons.shuffle,
                            variant: AppButtonVariant.secondary,
                            expanded: true,
                            onPressed: _regerarVariantes,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Gabaritos por Variante (${_variants.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final variant in _variants) ...[
                            AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          variant.code,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          variant.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.qr_code_2,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      for (final q in variant.questions)
                                        Chip(
                                          visualDensity: VisualDensity.compact,
                                          label: Text(
                                            'Q${q.questionNumber}: ${variant.answerKey[q.questionNumber] ?? q.correctLetter}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
      ),
    );
  }
}
