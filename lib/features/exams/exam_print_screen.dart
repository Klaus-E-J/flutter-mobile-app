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
import 'models/exam_application_mode.dart';
import 'models/exam_variant.dart';
import 'services/exam_pdf_service.dart';
import 'services/exam_randomizer_service.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/app_dialog.dart';

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
    required this.applicationMode,
    this.initialQuestions,
    this.initialVariants,
    this.initialStudents,
    this.onExportDoc,
  });

  final String examId;
  final String examTitle;
  final List<String> classIds;
  final List<String> classNames;
  final ExamApplicationMode applicationMode;
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
  bool _nominalSheetsPerStudent = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// O modo atual embaralha algo? (só então faz sentido "Reembaralhar").
  bool get _modeShuffles =>
      widget.applicationMode.shuffleQuestions ||
      widget.applicationMode.shuffleAlternatives;

  String get _modeSummary {
    final mode = widget.applicationMode;
    if (mode.perStudent && _students.isEmpty) {
      return '${mode.description} Cadastre os alunos da turma para gerar a prova de cada um.';
    }
    return mode.description;
  }

  List<ExamVariant> get _effectiveAnswerSheetVariants {
    if (!widget.applicationMode.perStudent &&
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
        students = await _classRepository.getStudentsForClasses(
          classIds: widget.classIds,
          classNames: widget.classNames,
        );
      }

      // Variantes injetadas (testes) são usadas como estão. No app, as
      // variantes são sincronizadas pelo repositório, que nunca altera as
      // provas já geradas enquanto modo, semente e questões não mudarem.
      final variants = widget.initialVariants != null &&
              widget.initialVariants!.isNotEmpty
          ? widget.initialVariants!
          : await _examRepository.syncVariants(
              examId: widget.examId,
              questions: questions,
            );

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _students = students;
        _variants = _variantsForCurrentStudents(variants, students);
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

  /// Nos modos por aluno, lista/imprime só as provas dos alunos que estão
  /// hoje nas turmas (variantes de alunos removidos continuam salvas para
  /// que folhas já impressas ainda sejam reconhecidas na correção).
  List<ExamVariant> _variantsForCurrentStudents(
    List<ExamVariant> variants,
    List<StudentRecord> students,
  ) {
    if (!widget.applicationMode.perStudent || students.isEmpty) return variants;
    final ids = students.map((s) => s.id).toSet();
    final filtered =
        variants.where((v) => v.studentId == null || ids.contains(v.studentId)).toList();
    return filtered.isEmpty ? variants : filtered;
  }

  Future<void> _regerarVariantes() async {
    if (_questions.isEmpty) return;

    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Reembaralhar a prova?',
      message:
          'Será feito um novo sorteio da ordem das questões/alternativas. '
          'Folhas e cadernos já impressos desta prova deixarão de valer e '
          'precisarão ser impressos novamente.',
      confirmLabel: 'Reembaralhar',
      destructive: true,
    );
    if (!mounted || confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      List<ExamVariant> variants;
      if (widget.initialVariants != null && widget.initialVariants!.isNotEmpty) {
        variants = _randomizerService.generateVariantsForMode(
          examId: widget.examId,
          questions: _questions,
          mode: widget.applicationMode,
          students: _students,
          classId: widget.classIds.isNotEmpty ? widget.classIds.first : null,
          className: widget.classNames.isNotEmpty ? widget.classNames.first : null,
          seed: DateTime.now().microsecondsSinceEpoch,
        );
      } else {
        variants = await _examRepository.syncVariants(
          examId: widget.examId,
          questions: _questions,
          reshuffle: true,
        );
      }

      if (!mounted) return;
      setState(() {
        _variants = _variantsForCurrentStudents(variants, _students);
        _isLoading = false;
      });
      AppSnackBar.success(
        context,
        'Novo sorteio salvo: ${_variants.length} variante(s). Imprima as folhas novamente.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Não foi possível reembaralhar: $error');
    }
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
      AppSnackBar.success(context, 'Caderno editável ($fileName) exportado com sucesso!');
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Não foi possível exportar o arquivo .doc: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sheetVariants = _effectiveAnswerSheetVariants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Variantes e impressão'),
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
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_questions.length} questões • ${_variants.length} variante(s) • ${sheetVariants.length} folha(s) OMR com QR Code',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Aplicação da prova',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    widget.applicationMode.perStudent
                                        ? AppIcons.shuffle
                                        : AppIcons.exams,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(widget.applicationMode.label),
                                  subtitle: Text(_modeSummary),
                                ),
                                if (!widget.applicationMode.perStudent &&
                                    _students.isNotEmpty) ...[
                                  const Divider(height: 1),
                                  SwitchListTile.adaptive(
                                    value: _nominalSheetsPerStudent,
                                    title: const Text(
                                      'Folhas de resposta com nome do aluno',
                                    ),
                                    subtitle: Text(
                                      'Gera ${_students.length} folha(s) com nome, matrícula e QR Code de cada aluno.',
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
                          if (_modeShuffles)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _regerarVariantes,
                                icon: const Icon(AppIcons.shuffle, size: 18),
                                label: const Text('Reembaralhar agora'),
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          const SizedBox(height: 8),
                          Text(
                            'Documento para impressão',
                            style: theme.textTheme.titleMedium,
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
                            icon: AppIcons.print,
                            expanded: true,
                            onPressed: _abrirVisualizadorPdf,
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            label: 'Exportar Prova Editável (.doc)',
                            icon: AppIcons.exams,
                            variant: AppButtonVariant.secondary,
                            expanded: true,
                            onPressed: _exportarCadernoDoc,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Gabaritos por Variante (${_variants.length})',
                            style: theme.textTheme.titleMedium,
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
                                        AppIcons.qrCode,
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
