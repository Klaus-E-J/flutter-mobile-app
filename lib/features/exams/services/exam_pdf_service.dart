import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../correction/models/omr_layout_spec.dart';
import '../models/exam_variant.dart';

/// Serviço responsável pela geração de documentos PDF para impressão:
/// Cadernos de Prova, Folhas de Resposta OMR com QR Code e Marcadores Fiduciais,
/// e Resumo de Gabaritos do Professor (N3-03).
class ExamPdfService {
  const ExamPdfService();

  /// Gera apenas os Cadernos de Questões (multi-páginas A4) para as [variants].
  Future<Uint8List> generateExamBookletPdf({
    required String examTitle,
    required List<String> classNames,
    required List<ExamVariant> variants,
  }) async {
    final doc = pw.Document();
    final classesLabel =
        classNames.isNotEmpty ? classNames.join(', ') : 'Turma Geral';

    for (final variant in variants) {
      _addVariantBookletPages(
        doc: doc,
        examTitle: examTitle,
        classesLabel: classesLabel,
        variant: variant,
      );
    }

    return doc.save();
  }

  /// Gera apenas as Folhas de Respostas OMR (1 folha A4 por variante) com
  /// 4 marcadores fiduciais nos cantos, QR Code de identificação e grade de bolhas.
  Future<Uint8List> generateAnswerSheetsPdf({
    required String examTitle,
    required List<String> classNames,
    required List<ExamVariant> variants,
  }) async {
    final doc = pw.Document();
    final classesLabel =
        classNames.isNotEmpty ? classNames.join(', ') : 'Turma Geral';

    for (final variant in variants) {
      doc.addPage(
        _buildOmrAnswerSheetPage(
          examTitle: examTitle,
          classesLabel: classesLabel,
          variant: variant,
        ),
      );
    }

    return doc.save();
  }

  /// Gera o pacote completo para impressão (Caderno de Questões + Folha de Respostas OMR
  /// para cada variante, além da página final opcional com o Gabarito Oficial do Professor).
  Future<Uint8List> generateCompleteExamPackagePdf({
    required String examTitle,
    required List<String> classNames,
    required List<ExamVariant> variants,
    bool includeTeacherAnswerKey = true,
  }) async {
    final doc = pw.Document();
    final classesLabel =
        classNames.isNotEmpty ? classNames.join(', ') : 'Turma Geral';

    for (final variant in variants) {
      _addVariantBookletPages(
        doc: doc,
        examTitle: examTitle,
        classesLabel: classesLabel,
        variant: variant,
      );
      doc.addPage(
        _buildOmrAnswerSheetPage(
          examTitle: examTitle,
          classesLabel: classesLabel,
          variant: variant,
        ),
      );
    }

    if (includeTeacherAnswerKey && variants.isNotEmpty) {
      doc.addPage(
        _buildTeacherAnswerKeyPage(
          examTitle: examTitle,
          classesLabel: classesLabel,
          variants: variants,
        ),
      );
    }

    return doc.save();
  }

  void _addVariantBookletPages({
    required pw.Document doc,
    required String examTitle,
    required String classesLabel,
    required ExamVariant variant,
  }) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey800, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      examTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Turma(s): ${variant.className ?? classesLabel}',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      variant.studentName != null
                          ? 'Aluno(a): ${variant.studentName}'
                          : 'Aluno(a): ________________________________________________',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'VARIANTE',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      variant.code,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Avalia Pro | ${variant.label}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'INSTRUÇÕES: Leia atentamente cada questão, marque apenas uma alternativa por questão '
              'e transcreva suas respostas para a Folha de Respostas OMR utilizando caneta azul ou preta.',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          for (final q in variant.questions)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Questão ${q.questionNumber}. ${q.statement}',
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  for (final alt in q.alternatives)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 22,
                            child: pw.Text(
                              '(${alt.letter})',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              alt.text,
                              style: const pw.TextStyle(fontSize: 9.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Page _buildOmrAnswerSheetPage({
    required String examTitle,
    required String classesLabel,
    required ExamVariant variant,
  }) {
    final pageWidth = PdfPageFormat.a4.width;
    final pageHeight = PdfPageFormat.a4.height;
    const margin = OmrLayoutSpec.pdfFiducialMarginPt;
    const fiducialSize = OmrLayoutSpec.pdfFiducialSizePt;
    final frameWidth = pageWidth - (2 * margin);
    final frameHeight = pageHeight - (2 * margin);
    final bubbleRadiusPt = OmrLayoutSpec.normalizedBubbleRadius * frameWidth;

    final totalQuestions = variant.questions.length.clamp(
      1,
      OmrLayoutSpec.maxQuestionsPerSheet,
    );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        final stackChildren = <pw.Widget>[];

        // 1. 4 Marcadores Fiduciais pretos nos cantos centrados em (margin, margin), etc.
        final corners = [
          (x: margin, y: margin),
          (x: pageWidth - margin, y: margin),
          (x: margin, y: pageHeight - margin),
          (x: pageWidth - margin, y: pageHeight - margin),
        ];

        for (final corner in corners) {
          stackChildren.add(
            pw.Positioned(
              left: corner.x - (fiducialSize / 2),
              top: corner.y - (fiducialSize / 2),
              child: pw.Container(
                width: fiducialSize,
                height: fiducialSize,
                color: PdfColors.black,
              ),
            ),
          );
        }

        // 2. Cabeçalho institucional + QR Code dentro do quadro fiducial
        stackChildren.add(
          pw.Positioned(
            left: margin + (0.04 * frameWidth),
            top: margin + (0.02 * frameHeight),
            child: pw.Container(
              width: 0.66 * frameWidth,
              height: 0.21 * frameHeight,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FOLHA DE RESPOSTAS OMR - ${examTitle.toUpperCase()}',
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Turma: ${variant.className ?? classesLabel}   |   Variante: ${variant.label} (${variant.code})',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    variant.studentName != null
                        ? 'Aluno(a): ${variant.studentName}'
                        : 'Aluno(a): ___________________________________________',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'INSTRUÇÃO: Preencha totalmente a bolha correspondente à alternativa escolhida com caneta preta ou azul.',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 3. QR Code na região padronizada OmrLayoutSpec.qrRegion
        final qrLeft = margin + (OmrLayoutSpec.qrRegion.uMin * frameWidth);
        final qrTop = margin + (OmrLayoutSpec.qrRegion.vMin * frameHeight);
        final qrWidth =
            (OmrLayoutSpec.qrRegion.uMax - OmrLayoutSpec.qrRegion.uMin) *
                frameWidth;
        final qrHeight =
            (OmrLayoutSpec.qrRegion.vMax - OmrLayoutSpec.qrRegion.vMin) *
                frameHeight;

        stackChildren.add(
          pw.Positioned(
            left: qrLeft,
            top: qrTop,
            child: pw.Container(
              width: qrWidth,
              height: qrHeight,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: variant.qrPayload,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${variant.code} | ${variant.id}',
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 4. Cabeçalhos das colunas A B C D E
        for (var col = 0; col < 2; col++) {
          if (col == 1 && totalQuestions <= OmrLayoutSpec.questionsPerColumn) {
            continue;
          }
          final firstQInCol = (col * OmrLayoutSpec.questionsPerColumn) + 1;
          for (var aIdx = 0; aIdx < OmrLayoutSpec.letters.length; aIdx++) {
            final norm = OmrLayoutSpec.bubbleCenterNormalized(
              questionNumber: firstQInCol,
              altIndex: aIdx,
            );
            final xPt = margin + (norm.u * frameWidth);
            final yPt = margin + ((norm.v - 0.032) * frameHeight);

            stackChildren.add(
              pw.Positioned(
                left: xPt - bubbleRadiusPt,
                top: yPt - bubbleRadiusPt,
                child: pw.Container(
                  width: bubbleRadiusPt * 2,
                  height: bubbleRadiusPt * 2,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    OmrLayoutSpec.letters[aIdx],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // 5. Grade determinística de bolhas OMR
        for (var qNum = 1; qNum <= totalQuestions; qNum++) {
          final firstBubbleNorm = OmrLayoutSpec.bubbleCenterNormalized(
            questionNumber: qNum,
            altIndex: 0,
          );
          final labelX = margin + ((firstBubbleNorm.u - 0.065) * frameWidth);
          final labelY = margin + (firstBubbleNorm.v * frameHeight);

          stackChildren.add(
            pw.Positioned(
              left: labelX - 12,
              top: labelY - 6,
              child: pw.SizedBox(
                width: 24,
                child: pw.Text(
                  qNum.toString().padLeft(2, '0'),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          );

          final qMapping = variant.questions[qNum - 1];
          final altCount = qMapping.alternatives.length.clamp(
            2,
            OmrLayoutSpec.letters.length,
          );

          for (var aIdx = 0; aIdx < altCount; aIdx++) {
            final norm = OmrLayoutSpec.bubbleCenterNormalized(
              questionNumber: qNum,
              altIndex: aIdx,
            );
            final cx = margin + (norm.u * frameWidth);
            final cy = margin + (norm.v * frameHeight);

            stackChildren.add(
              pw.Positioned(
                left: cx - bubbleRadiusPt,
                top: cy - bubbleRadiusPt,
                child: pw.Container(
                  width: bubbleRadiusPt * 2,
                  height: bubbleRadiusPt * 2,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.black, width: 1.2),
                  ),
                  child: pw.Text(
                    OmrLayoutSpec.letters[aIdx],
                    style: const pw.TextStyle(
                      fontSize: 6.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return pw.Stack(children: stackChildren);
      },
    );
  }

  pw.Page _buildTeacherAnswerKeyPage({
    required String examTitle,
    required String classesLabel,
    required List<ExamVariant> variants,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Text(
          'MAPA DE GABARITOS POR VARIANTE (USO DO PROFESSOR)',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Prova: $examTitle | Turma(s): $classesLabel',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 16),
        for (final variant in variants)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${variant.label} (Código: ${variant.code})',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (final q in variant.questions)
                      pw.Text(
                        'Q${q.questionNumber.toString().padLeft(2, '0')}: ${variant.answerKey[q.questionNumber] ?? q.correctLetter}',
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
