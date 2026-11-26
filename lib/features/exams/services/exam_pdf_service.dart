import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../correction/models/omr_layout_spec.dart';
import '../models/exam_variant.dart';

/// Serviço responsável pela geração de documentos PDF e Word (.doc) para impressão:
/// Cadernos de Prova (sem quebra de questão entre páginas), Folhas de Resposta OMR
/// com QR Code e Marcadores Fiduciais, e Resumo de Gabaritos do Professor (N3-03).
class ExamPdfService {
  const ExamPdfService();

  /// Normaliza caracteres tipográficos fora de ISO-8859-1 (Latin-1) para evitar
  /// avisos ou falhas de glifos ausentes nas fontes padrão Helvetica do PDF.
  static String _sanitizePdfText(String input) {
    final replaced = input
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2212', '-')
        .replaceAll('\u2022', '-')
        .replaceAll('\u2192', '->')
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u2026', '...')
        .replaceAll('\u2265', '>=')
        .replaceAll('\u2264', '<=')
        .replaceAll('\u2260', '!=')
        .replaceAll('\u2248', '~=')
        .replaceAll('\u03C0', 'pi')
        .replaceAll('\u221A', 'raiz');

    final buffer = StringBuffer();
    for (final rune in replaced.runes) {
      if (rune == 0x09 || rune == 0x0A || rune == 0x0D || (rune >= 0x20 && rune <= 0xFF)) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }

  static String _escapeHtml(String input) {
    return const HtmlEscape().convert(input);
  }

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

  /// Gera apenas as Folhas de Respostas OMR (1 folha A4 por variante/aluno) com
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
  /// para cada variante ou aluno em [answerSheetVariants], além da página final opcional
  /// com o Gabarito Oficial do Professor).
  Future<Uint8List> generateCompleteExamPackagePdf({
    required String examTitle,
    required List<String> classNames,
    required List<ExamVariant> variants,
    List<ExamVariant>? answerSheetVariants,
    bool includeTeacherAnswerKey = true,
  }) async {
    final doc = pw.Document();
    final classesLabel =
        classNames.isNotEmpty ? classNames.join(', ') : 'Turma Geral';
    final effectiveAnswerSheets = answerSheetVariants ?? variants;

    final hasDistinctNominalSheets = answerSheetVariants != null &&
        (answerSheetVariants.length != variants.length ||
            !List.generate(
              variants.length,
              (i) =>
                  answerSheetVariants[i].id == variants[i].id &&
                  answerSheetVariants[i].studentId == variants[i].studentId &&
                  answerSheetVariants[i].studentName ==
                      variants[i].studentName &&
                  answerSheetVariants[i].studentMatricula ==
                      variants[i].studentMatricula,
            ).every((same) => same));

    for (final variant in variants) {
      _addVariantBookletPages(
        doc: doc,
        examTitle: examTitle,
        classesLabel: classesLabel,
        variant: variant,
      );
      if (!hasDistinctNominalSheets) {
        doc.addPage(
          _buildOmrAnswerSheetPage(
            examTitle: examTitle,
            classesLabel: classesLabel,
            variant: variant,
          ),
        );
      }
    }

    if (hasDistinctNominalSheets) {
      for (final sheetVariant in effectiveAnswerSheets) {
        doc.addPage(
          _buildOmrAnswerSheetPage(
            examTitle: examTitle,
            classesLabel: classesLabel,
            variant: sheetVariant,
          ),
        );
      }
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

  /// Gera os Cadernos de Prova em formato editável `.doc` compatível com Microsoft Word,
  /// LibreOffice Writer e Google Docs, garantindo `page-break-inside: avoid` em cada
  /// bloco de questão para que nenhuma questão seja cortada ao meio entre páginas (requisito §4 e §6).
  Uint8List generateExamBookletDoc({
    required String examTitle,
    required List<String> classNames,
    required List<ExamVariant> variants,
    bool includeTeacherAnswerKey = true,
  }) {
    final classesLabel =
        classNames.isNotEmpty ? classNames.join(', ') : 'Turma Geral';
    final buffer = StringBuffer();

    buffer.writeln(
      '<html xmlns:o="urn:schemas-microsoft-com:office:office" '
      'xmlns:w="urn:schemas-microsoft-com:office:word" '
      'xmlns="http://www.w3.org/TR/REC-html40">',
    );
    buffer.writeln('<head>');
    buffer.writeln('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">');
    buffer.writeln('<title>${_escapeHtml(examTitle)}</title>');
    buffer.writeln('<style>');
    buffer.writeln('''
      @page Section1 {
        size: 595.3pt 841.9pt;
        margin: 36.0pt 36.0pt 36.0pt 36.0pt;
      }
      div.Section1 { page: Section1; }
      body {
        font-family: Arial, Helvetica, sans-serif;
        font-size: 10.5pt;
        color: #111111;
      }
      .header-box {
        border: 1pt solid #222222;
        padding: 10pt;
        margin-bottom: 12pt;
      }
      .instructions-box {
        background-color: #F3F4F6;
        padding: 8pt;
        margin-bottom: 14pt;
        font-size: 9pt;
      }
      .question-block {
        page-break-inside: avoid;
        break-inside: avoid;
        margin-bottom: 14pt;
        padding-bottom: 4pt;
      }
      .question-statement {
        font-weight: bold;
        margin-bottom: 6pt;
      }
      .alternative-row {
        margin-left: 12pt;
        margin-bottom: 3pt;
      }
      .page-break {
        page-break-before: always;
      }
      .answer-key-box {
        page-break-inside: avoid;
        break-inside: avoid;
        border: 1pt solid #555555;
        padding: 8pt;
        margin-bottom: 10pt;
      }
    ''');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<div class="Section1">');

    for (var vIdx = 0; vIdx < variants.length; vIdx++) {
      final variant = variants[vIdx];
      if (vIdx > 0) {
        buffer.writeln('<br clear="all" style="page-break-before:always" />');
      }

      final studentLine = variant.studentName != null
          ? 'Aluno(a): ${_escapeHtml(variant.studentName!)}${variant.studentMatricula != null && variant.studentMatricula!.isNotEmpty ? " - Matrícula: ${_escapeHtml(variant.studentMatricula!)}" : ""}'
          : 'Aluno(a): ________________________________________________';

      buffer.writeln('<div class="header-box">');
      buffer.writeln(
        '<div><strong>${_escapeHtml(examTitle.toUpperCase())}</strong> '
        '— <span><strong>Variante ${_escapeHtml(variant.code)} (${_escapeHtml(variant.label)})</strong></span></div>',
      );
      buffer.writeln(
        '<div>Turma(s): ${_escapeHtml(variant.className ?? classesLabel)}</div>',
      );
      buffer.writeln('<div>$studentLine</div>');
      buffer.writeln('</div>');

      buffer.writeln('<div class="instructions-box">');
      buffer.writeln(
        'INSTRUÇÕES: Leia atentamente cada questão, marque apenas uma alternativa por questão '
        'e transcreva suas respostas para a Folha de Respostas OMR utilizando caneta azul ou preta.',
      );
      buffer.writeln('</div>');

      for (final q in variant.questions) {
        buffer.writeln('<div class="question-block">');
        buffer.writeln(
          '<div class="question-statement">Questão ${q.questionNumber}. ${_escapeHtml(q.statement)}</div>',
        );
        for (final alt in q.alternatives) {
          buffer.writeln(
            '<div class="alternative-row"><strong>(${_escapeHtml(alt.letter)})</strong> ${_escapeHtml(alt.text)}</div>',
          );
        }
        buffer.writeln('</div>');
      }
    }

    if (includeTeacherAnswerKey && variants.isNotEmpty) {
      buffer.writeln('<br clear="all" style="page-break-before:always" />');
      buffer.writeln('<h2>MAPA DE GABARITOS POR VARIANTE (USO DO PROFESSOR)</h2>');
      buffer.writeln(
        '<p>Prova: ${_escapeHtml(examTitle)} | Turma(s): ${_escapeHtml(classesLabel)}</p>',
      );
      for (final variant in variants) {
        buffer.writeln('<div class="answer-key-box">');
        buffer.writeln(
          '<div><strong>${_escapeHtml(variant.label)} (Código: ${_escapeHtml(variant.code)})</strong></div>',
        );
        final keyPairs = variant.questions
            .map(
              (q) =>
                  'Q${q.questionNumber.toString().padLeft(2, '0')}: ${variant.answerKey[q.questionNumber] ?? q.correctLetter}',
            )
            .join(' &nbsp;|&nbsp; ');
        buffer.writeln('<div>$keyPairs</div>');
        buffer.writeln('</div>');
      }
    }

    buffer.writeln('</div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  void _addVariantBookletPages({
    required pw.Document doc,
    required String examTitle,
    required String classesLabel,
    required ExamVariant variant,
  }) {
    final safeExamTitle = _sanitizePdfText(examTitle);
    final safeClassesLabel = _sanitizePdfText(variant.className ?? classesLabel);
    final safeVariantLabel = _sanitizePdfText(variant.label);
    final safeStudentLine = variant.studentName != null
        ? _sanitizePdfText(
            'Aluno(a): ${variant.studentName}${variant.studentMatricula != null && variant.studentMatricula!.isNotEmpty ? ' (Matrícula: ${variant.studentMatricula})' : ''}',
          )
        : 'Aluno(a): ________________________________________________';

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
                      safeExamTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Turma(s): $safeClassesLabel',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      safeStudentLine,
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
                      _sanitizePdfText(variant.code),
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
                'Avalia Pro | $safeVariantLabel',
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
          // Envolve cada questão + alternativas em um pw.Row (canSpan == false),
          // garantindo que o MultiPage nunca corte uma questão ao meio entre duas páginas.
          // Caso uma única questão excepcional ultrapasse a altura útil de uma página A4
          // inteira (>38 linhas), permite quebra interna controlada para evitar TooManyPagesException.
          for (final q in variant.questions) _buildQuestionBlock(q),
        ],
      ),
    );
  }

  pw.Widget _buildQuestionBlock(VariantQuestionMapping q) {
    final sanitizedStatement = _sanitizePdfText(
      'Questão ${q.questionNumber}. ${q.statement}',
    );
    int estimatedLines = 0;
    for (final line in sanitizedStatement.split('\n')) {
      estimatedLines += (line.length / 82).ceil().clamp(1, 500);
    }
    for (final alt in q.alternatives) {
      for (final line in _sanitizePdfText(alt.text).split('\n')) {
        estimatedLines += (line.length / 76).ceil().clamp(1, 500);
      }
    }

    final questionChildren = <pw.Widget>[
      pw.Text(
        sanitizedStatement,
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
                  '(${_sanitizePdfText(alt.letter)})',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  _sanitizePdfText(alt.text),
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
            ],
          ),
        ),
      pw.SizedBox(height: 10),
    ];

    if (estimatedLines > 38) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: questionChildren,
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: questionChildren,
            ),
          ),
        ),
      ],
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
        final studentHeaderText = variant.studentName != null
            ? 'Aluno(a): ${variant.studentName}${variant.studentMatricula != null && variant.studentMatricula!.isNotEmpty ? '   |   Matrícula: ${variant.studentMatricula}' : ''}'
            : 'Aluno(a): ___________________________________________';

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
                    _sanitizePdfText(
                      'FOLHA DE RESPOSTAS OMR - ${examTitle.toUpperCase()}',
                    ),
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _sanitizePdfText(
                      'Turma: ${variant.className ?? classesLabel}   |   Variante: ${variant.label} (${variant.code})',
                    ),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    _sanitizePdfText(studentHeaderText),
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
                      data: _sanitizePdfText(variant.qrPayload),
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _sanitizePdfText(
                      variant.studentId != null && variant.studentId!.isNotEmpty
                          ? '${variant.code} | ${variant.studentId}'
                          : '${variant.code} | ${variant.id}',
                    ),
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
          _sanitizePdfText('Prova: $examTitle | Turma(s): $classesLabel'),
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 16),
        for (final variant in variants)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _sanitizePdfText(
                          '${variant.label} (Código: ${variant.code})',
                        ),
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
              ),
            ],
          ),
      ],
    );
  }
}
