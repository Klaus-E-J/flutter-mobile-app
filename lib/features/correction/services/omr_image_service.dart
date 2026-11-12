import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';
import 'package:zxing2/qrcode.dart';

import '../../exams/models/exam_variant.dart';
import '../models/omr_layout_spec.dart';

/// Ponto 2D em coordenadas de imagem (pixels).
class OmrPoint {
  const OmrPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  String toString() => 'OmrPoint(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Resultado da leitura OMR de uma única questão na folha de respostas.
class OmrQuestionScanResult {
  const OmrQuestionScanResult({
    required this.questionNumber,
    required this.markedLetters,
    required this.fillRatios,
  });

  final int questionNumber;
  final List<String> markedLetters;
  final Map<String, double> fillRatios;

  bool get isBlank => markedLetters.isEmpty;
  bool get isMultipleMarks => markedLetters.length > 1;
  bool get isValidSingleMark => markedLetters.length == 1;
  String? get singleMarkedLetter =>
      markedLetters.length == 1 ? markedLetters.first : null;
}

/// Resultado completo do processamento de uma imagem de folha de respostas OMR (N3-04).
class OmrSheetScanResult {
  const OmrSheetScanResult({
    required this.questions,
    required this.detectedCorners,
    required this.perspectiveCorrected,
    this.qrPayload,
    this.rawQrText,
  });

  final ExamQrPayload? qrPayload;
  final String? rawQrText;
  final List<OmrPoint> detectedCorners;
  final bool perspectiveCorrected;
  final Map<int, OmrQuestionScanResult> questions;
}

/// Serviço de Visão Computacional em Dart puro para leitura automatizada
/// de folhas de respostas: decodificação de QR Code, detecção dos 4 marcadores
/// fiduciais, retificação de perspectiva e leitura de densidade OMR das bolhas (N3-04).
class OmrImageService {
  const OmrImageService();

  /// Limiar de preenchimento da área interna da bolha (0.0 a 1.0) para considerá-la marcada.
  static const double defaultFillThreshold = 0.35;

  /// Processa os bytes (PNG/JPEG) de uma foto ou imagem de folha de respostas.
  OmrSheetScanResult processSheetBytes({
    required Uint8List imageBytes,
    required int expectedQuestions,
    int alternativesPerQuestion = 5,
    double fillThreshold = defaultFillThreshold,
  }) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException(
        'Não foi possível decodificar a imagem da folha de respostas.',
      );
    }
    return processImage(
      source: decoded,
      expectedQuestions: expectedQuestions,
      alternativesPerQuestion: alternativesPerQuestion,
      fillThreshold: fillThreshold,
    );
  }

  /// Processa um objeto [img.Image] já decodificado.
  OmrSheetScanResult processImage({
    required img.Image source,
    required int expectedQuestions,
    int alternativesPerQuestion = 5,
    double fillThreshold = defaultFillThreshold,
  }) {
    // 1. Detectar os 4 marcadores fiduciais nos cantos da imagem
    final corners = detectFiducialCorners(source);
    late final img.Image canonical;
    final bool perspectiveCorrected;

    if (corners != null) {
      canonical = rectifyPerspective(
        source: source,
        topLeft: corners[0],
        topRight: corners[1],
        bottomLeft: corners[2],
        bottomRight: corners[3],
      );
      perspectiveCorrected = true;
    } else {
      canonical = img.copyResize(
        source,
        width: OmrLayoutSpec.canonicalWidth,
        height: OmrLayoutSpec.canonicalHeight,
      );
      perspectiveCorrected = false;
    }

    // 2. Decodificar o QR Code (primeiro na região canônica do cabeçalho, depois na imagem toda)
    String? rawQr = _tryDecodeQrInRegion(canonical) ?? _tryDecodeQr(source);
    final qrPayload = rawQr != null ? ExamQrPayload.tryParse(rawQr) : null;

    // 3. Calcular limiar adaptativo global/local (Otsu simplificado) e medir densidade das bolhas
    final thresholdLuminance = _computeAdaptiveDarkThreshold(canonical);
    final totalQ = expectedQuestions.clamp(1, OmrLayoutSpec.maxQuestionsPerSheet);
    final altCount = alternativesPerQuestion.clamp(2, OmrLayoutSpec.letters.length);

    final questionsMap = <int, OmrQuestionScanResult>{};

    for (var qNum = 1; qNum <= totalQ; qNum++) {
      final fillRatios = <String, double>{};
      final markedLetters = <String>[];

      for (var aIdx = 0; aIdx < altCount; aIdx++) {
        final letter = OmrLayoutSpec.letters[aIdx];
        final bubble = OmrLayoutSpec.bubbleCenterPixel(
          questionNumber: qNum,
          altIndex: aIdx,
        );

        final ratio = _sampleBubbleFillRatio(
          canonical: canonical,
          centerX: bubble.x,
          centerY: bubble.y,
          radius: bubble.radius,
          darkLuminanceThreshold: thresholdLuminance,
        );
        fillRatios[letter] = ratio;

        if (ratio >= fillThreshold) {
          markedLetters.add(letter);
        }
      }

      questionsMap[qNum] = OmrQuestionScanResult(
        questionNumber: qNum,
        markedLetters: markedLetters,
        fillRatios: fillRatios,
      );
    }

    return OmrSheetScanResult(
      qrPayload: qrPayload,
      rawQrText: rawQr,
      detectedCorners: corners ??
          [
            const OmrPoint(0, 0),
            OmrPoint(source.width.toDouble(), 0),
            OmrPoint(0, source.height.toDouble()),
            OmrPoint(source.width.toDouble(), source.height.toDouble()),
          ],
      perspectiveCorrected: perspectiveCorrected,
      questions: questionsMap,
    );
  }

  /// Localiza os centros dos 4 marcadores fiduciais pretos nos quadrantes de canto,
  /// isolando o marcador mais próximo de cada vértice externo para não interferir com o QR Code.
  List<OmrPoint>? detectFiducialCorners(img.Image image) {
    final w = image.width;
    final h = image.height;
    if (w < 100 || h < 100) return null;

    final qW = (w * 0.25).round();
    final qH = (h * 0.25).round();

    final tl = _findOuterCornerFiducial(image, 0, 0, qW, qH, 0, 0);
    final tr = _findOuterCornerFiducial(image, w - qW, 0, w - 1, qH, w - 1, 0);
    final bl = _findOuterCornerFiducial(image, 0, h - qH, qW, h - 1, 0, h - 1);
    final br = _findOuterCornerFiducial(
      image,
      w - qW,
      h - qH,
      w - 1,
      h - 1,
      w - 1,
      h - 1,
    );

    if (tl == null || tr == null || bl == null || br == null) {
      return null;
    }
    return [tl, tr, bl, br];
  }

  OmrPoint? _findOuterCornerFiducial(
    img.Image image,
    int xMin,
    int yMin,
    int xMax,
    int yMax,
    int cornerX,
    int cornerY,
  ) {
    int? bestSeedX;
    int? bestSeedY;
    int bestPaperLum = 220;
    var bestDistSq = 1 << 30;

    for (var y = yMin; y <= yMax; y += 2) {
      for (var x = xMin; x <= xMax; x += 2) {
        final lum = _pixelLuminance(image.getPixel(x, y));
        if (lum < 105) {
          final ringCheck = _checkBrightPaperRing(image, x, y, lum);
          if (!ringCheck.isEnclosedByPaper) continue;

          final dx = x - cornerX;
          final dy = y - cornerY;
          final distSq = (dx * dx) + (dy * dy);
          if (distSq < bestDistSq) {
            bestDistSq = distSq;
            bestSeedX = x;
            bestSeedY = y;
            bestPaperLum = ringCheck.meanPaperLum;
          }
        }
      }
    }

    if (bestSeedX == null || bestSeedY == null) return null;

    final darkCutoff = max(85, bestPaperLum - 50);

    // Passo 1: centro de massa na vizinhança imediata (22px) da semente
    final firstPass = _computeClusterCentroid(
      image: image,
      centerX: bestSeedX,
      centerY: bestSeedY,
      radius: 22,
      darkCutoff: darkCutoff,
    );
    if (firstPass == null) return null;

    // Passo 2: recentraliza na janela de 20px ao redor do centroide para precisão sub-pixel
    return _computeClusterCentroid(
          image: image,
          centerX: firstPass.x.round(),
          centerY: firstPass.y.round(),
          radius: 20,
          darkCutoff: darkCutoff,
        ) ??
        firstPass;
  }

  /// Verifica se um pixel escuro `(cx, cy)` pertence a um marcador fiducial interno
  /// à página branca (cercado por papel claro num anel de raio 26px), descartando
  /// bordas de mesa escuras fora da folha A4.
  ({bool isEnclosedByPaper, int meanPaperLum}) _checkBrightPaperRing(
    img.Image image,
    int cx,
    int cy,
    int pixelLum,
  ) {
    const ringRadius = 26;
    const offsets = <(int, int)>[
      (26, 0),
      (24, 10),
      (18, 18),
      (10, 24),
      (0, 26),
      (-10, 24),
      (-18, 18),
      (-24, 10),
      (-26, 0),
      (-24, -10),
      (-18, -18),
      (-10, -24),
      (0, -26),
      (10, -24),
      (18, -18),
      (24, -10),
    ];

    if (cx < ringRadius ||
        cy < ringRadius ||
        cx >= image.width - ringRadius ||
        cy >= image.height - ringRadius) {
      return (isEnclosedByPaper: false, meanPaperLum: 0);
    }

    var brightCount = 0;
    var sumBrightLum = 0;

    for (final (dx, dy) in offsets) {
      final rx = cx + dx;
      final ry = cy + dy;
      final rLum = _pixelLuminance(image.getPixel(rx, ry));
      if (rLum >= 110 && (rLum - pixelLum) >= 45) {
        brightCount++;
        sumBrightLum += rLum;
      }
    }

    if (brightCount < 12) {
      return (isEnclosedByPaper: false, meanPaperLum: 0);
    }
    return (
      isEnclosedByPaper: true,
      meanPaperLum: (sumBrightLum / brightCount).round(),
    );
  }

  OmrPoint? _computeClusterCentroid({
    required img.Image image,
    required int centerX,
    required int centerY,
    required int radius,
    required int darkCutoff,
  }) {
    final lxMin = max(0, centerX - radius);
    final lxMax = min(image.width - 1, centerX + radius);
    final lyMin = max(0, centerY - radius);
    final lyMax = min(image.height - 1, centerY + radius);

    double sumX = 0;
    double sumY = 0;
    int count = 0;
    int minX = image.width;
    int maxX = 0;
    int minY = image.height;
    int maxY = 0;

    for (var y = lyMin; y <= lyMax; y++) {
      for (var x = lxMin; x <= lxMax; x++) {
        final lum = _pixelLuminance(image.getPixel(x, y));
        if (lum < darkCutoff) {
          sumX += x;
          sumY += y;
          count++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (count < 16) return null;
    final clusterW = maxX - minX + 1;
    final clusterH = maxY - minY + 1;
    if (clusterW < 6 || clusterH < 6) return null;

    return OmrPoint(sumX / count, sumY / count);
  }

  /// Realiza a correção de perspectiva mapeando o quadrilátero definido pelos
  /// 4 marcadores fiduciais para o retângulo canônico `1000 x 1414`.
  img.Image rectifyPerspective({
    required img.Image source,
    required OmrPoint topLeft,
    required OmrPoint topRight,
    required OmrPoint bottomLeft,
    required OmrPoint bottomRight,
  }) {
    const dstW = OmrLayoutSpec.canonicalWidth;
    const dstH = OmrLayoutSpec.canonicalHeight;
    final out = img.Image(width: dstW, height: dstH);

    final srcMaxX = (source.width - 1).toDouble();
    final srcMaxY = (source.height - 1).toDouble();

    for (var y = 0; y < dstH; y++) {
      final v = y / (dstH - 1);
      final oneMinusV = 1.0 - v;

      for (var x = 0; x < dstW; x++) {
        final u = x / (dstW - 1);
        final oneMinusU = 1.0 - u;

        final srcX = (oneMinusU * oneMinusV * topLeft.x) +
            (u * oneMinusV * topRight.x) +
            (oneMinusU * v * bottomLeft.x) +
            (u * v * bottomRight.x);

        final srcY = (oneMinusU * oneMinusV * topLeft.y) +
            (u * oneMinusV * topRight.y) +
            (oneMinusU * v * bottomLeft.y) +
            (u * v * bottomRight.y);

        final sx = srcX.clamp(0.0, srcMaxX).round();
        final sy = srcY.clamp(0.0, srcMaxY).round();
        final pixel = source.getPixel(sx, sy);
        out.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          255,
        );
      }
    }

    return out;
  }

  double _sampleBubbleFillRatio({
    required img.Image canonical,
    required int centerX,
    required int centerY,
    required int radius,
    required int darkLuminanceThreshold,
  }) {
    // Calcula a luminância local do papel no anel externo (1.25r a 1.65r) ao redor da bolha
    // para tornar a leitura imune a sombras e gradientes de iluminação na folha.
    final localPaperLum = _sampleLocalPaperAnnulusLuminance(
      canonical: canonical,
      centerX: centerX,
      centerY: centerY,
      radius: radius,
    );
    final effectiveDarkThreshold = localPaperLum != null
        ? (localPaperLum * 0.68).round().clamp(45, 185)
        : darkLuminanceThreshold;

    // Amostra apenas o disco interno (70% do raio) para ignorar o anel impresso da bolha.
    final innerRadius = max(3, (radius * 0.70).round());
    final rSquared = innerRadius * innerRadius;

    var totalPixels = 0;
    var darkPixels = 0;

    final minX = max(0, centerX - innerRadius);
    final maxX = min(canonical.width - 1, centerX + innerRadius);
    final minY = max(0, centerY - innerRadius);
    final maxY = min(canonical.height - 1, centerY + innerRadius);

    for (var y = minY; y <= maxY; y++) {
      final dy = y - centerY;
      for (var x = minX; x <= maxX; x++) {
        final dx = x - centerX;
        if ((dx * dx) + (dy * dy) <= rSquared) {
          totalPixels++;
          final lum = _pixelLuminance(canonical.getPixel(x, y));
          if (lum < effectiveDarkThreshold) {
            darkPixels++;
          }
        }
      }
    }

    if (totalPixels == 0) return 0.0;
    return darkPixels / totalPixels;
  }

  int? _sampleLocalPaperAnnulusLuminance({
    required img.Image canonical,
    required int centerX,
    required int centerY,
    required int radius,
  }) {
    final rInner = max(radius + 4, (radius * 1.25).round());
    final rOuter = max(rInner + 3, (radius * 1.65).round());
    final rInnerSq = rInner * rInner;
    final rOuterSq = rOuter * rOuter;

    final minX = max(0, centerX - rOuter);
    final maxX = min(canonical.width - 1, centerX + rOuter);
    final minY = max(0, centerY - rOuter);
    final maxY = min(canonical.height - 1, centerY + rOuter);

    var sumLum = 0;
    var count = 0;

    for (var y = minY; y <= maxY; y += 2) {
      final dy = y - centerY;
      for (var x = minX; x <= maxX; x += 2) {
        final dx = x - centerX;
        final dSq = (dx * dx) + (dy * dy);
        if (dSq >= rInnerSq && dSq <= rOuterSq) {
          sumLum += _pixelLuminance(canonical.getPixel(x, y));
          count++;
        }
      }
    }

    if (count == 0) return null;
    return (sumLum / count).round();
  }

  int _computeAdaptiveDarkThreshold(img.Image image) {
    var minLum = 255;
    var maxLum = 0;

    for (var y = 0; y < image.height; y += 8) {
      for (var x = 0; x < image.width; x += 8) {
        final lum = _pixelLuminance(image.getPixel(x, y));
        if (lum < minLum) minLum = lum;
        if (lum > maxLum) maxLum = lum;
      }
    }

    // Ponto médio ponderado entre o fundo claro do papel e a tinta escura
    return ((minLum + maxLum) * 0.55).round().clamp(90, 185);
  }

  int _pixelLuminance(img.Pixel p) {
    return ((0.299 * p.r) + (0.587 * p.g) + (0.114 * p.b)).round();
  }

  String? _tryDecodeQrInRegion(img.Image canonical) {
    final x = (OmrLayoutSpec.qrRegion.uMin * canonical.width).round();
    final y = (OmrLayoutSpec.qrRegion.vMin * canonical.height).round();
    final w = ((OmrLayoutSpec.qrRegion.uMax - OmrLayoutSpec.qrRegion.uMin) *
            canonical.width)
        .round();
    final h = ((OmrLayoutSpec.qrRegion.vMax - OmrLayoutSpec.qrRegion.vMin) *
            canonical.height)
        .round();

    final cropped = img.copyCrop(
      canonical,
      x: max(0, x - 10),
      y: max(0, y - 10),
      width: min(canonical.width - x, w + 20),
      height: min(canonical.height - y, h + 20),
    );
    return _tryDecodeQr(cropped);
  }

  String? _tryDecodeQr(img.Image image) {
    try {
      final width = image.width;
      final height = image.height;
      final pixels = Int32List(width * height);

      var idx = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final p = image.getPixel(x, y);
          final r = p.r.toInt() & 0xFF;
          final g = p.g.toInt() & 0xFF;
          final b = p.b.toInt() & 0xFF;
          pixels[idx++] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }

      final source = RGBLuminanceSource(width, height, pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      return result.text;
    } catch (_) {
      return null;
    }
  }

  /// Renderiza uma imagem PNG sintética de alta fidelidade de uma Folha de Respostas OMR
  /// com QR Code real, 4 marcadores fiduciais, bolhas impressas e marcações de aluno,
  /// opcionalmente aplicando distorção de perspectiva para testes e validação em emulador/desktop.
  Uint8List renderSyntheticSheetPng({
    required String qrPayload,
    required int totalQuestions,
    required Map<int, List<String>> markedAnswers,
    int alternativesPerQuestion = 5,
    bool simulatePerspectiveSkew = false,
    bool simulateDarkBorder = false,
    bool simulateLightingGradient = false,
  }) {
    const outW = 1120;
    const outH = 1540;
    final canvas = img.Image(width: outW, height: outH);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    if (simulateLightingGradient) {
      // Simula gradiente de iluminação / sombra diagonal de sala de aula (255 no topo-esquerdo até ~130 no canto inferior-direito)
      for (var y = 0; y < outH; y++) {
        final fy = y / outH;
        for (var x = 0; x < outW; x++) {
          final fx = x / outW;
          final shade = (255 - ((0.45 * fx + 0.55 * fy) * 125)).round().clamp(125, 255);
          canvas.setPixelRgba(x, y, shade, shade, shade, 255);
        }
      }
    }

    if (simulateDarkBorder) {
      // Simula borda escura de mesa/bancada fora das margens da folha A4 (20px de espessura, luminância ~30)
      const border = 20;
      final deskColor = img.ColorRgb8(30, 28, 25);
      img.fillRect(canvas, x1: 0, y1: 0, x2: outW - 1, y2: border, color: deskColor);
      img.fillRect(canvas, x1: 0, y1: outH - 1 - border, x2: outW - 1, y2: outH - 1, color: deskColor);
      img.fillRect(canvas, x1: 0, y1: 0, x2: border, y2: outH - 1, color: deskColor);
      img.fillRect(canvas, x1: outW - 1 - border, y1: 0, x2: outW - 1, y2: outH - 1, color: deskColor);
    }

    final tl = simulatePerspectiveSkew
        ? const OmrPoint(68, 58)
        : const OmrPoint(60, 63);
    final tr = simulatePerspectiveSkew
        ? const OmrPoint(1042, 44)
        : const OmrPoint(1060, 63);
    final bl = simulatePerspectiveSkew
        ? const OmrPoint(46, 1468)
        : const OmrPoint(60, 1477);
    final br = simulatePerspectiveSkew
        ? const OmrPoint(1064, 1486)
        : const OmrPoint(1060, 1477);

    OmrPoint mapNormToCanvas(double u, double v) {
      final oneMinusU = 1.0 - u;
      final oneMinusV = 1.0 - v;
      final x = (oneMinusU * oneMinusV * tl.x) +
          (u * oneMinusV * tr.x) +
          (oneMinusU * v * bl.x) +
          (u * v * br.x);
      final y = (oneMinusU * oneMinusV * tl.y) +
          (u * oneMinusV * tr.y) +
          (oneMinusU * v * bl.y) +
          (u * v * br.y);
      return OmrPoint(x, y);
    }

    // 1. Desenhar os 4 marcadores fiduciais pretos (32x32 px) centrados em tl, tr, bl, br
    const fidHalf = 16;
    for (final corner in [tl, tr, bl, br]) {
      final cx = corner.x.round();
      final cy = corner.y.round();
      img.fillRect(
        canvas,
        x1: cx - fidHalf,
        y1: cy - fidHalf,
        x2: cx + fidHalf,
        y2: cy + fidHalf,
        color: img.ColorRgb8(0, 0, 0),
      );
    }

    // 2. Desenhar o QR Code real dentro de OmrLayoutSpec.qrRegion
    final qrCode = QrCode.fromData(
      data: qrPayload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final modules = qrImage.moduleCount;
    const quietZone = 4;
    final totalModules = modules + (2 * quietZone);

    final uSpan = OmrLayoutSpec.qrRegion.uMax - OmrLayoutSpec.qrRegion.uMin;
    final vSpan = OmrLayoutSpec.qrRegion.vMax - OmrLayoutSpec.qrRegion.vMin;

    // Amostragem densa na região do QR Code para preservar nitidez sob perspectiva
    const qrSubSteps = 260;
    for (var sy = 0; sy < qrSubSteps; sy++) {
      final fracV = sy / qrSubSteps;
      final mRow = (fracV * totalModules).floor() - quietZone;
      for (var sx = 0; sx < qrSubSteps; sx++) {
        final fracU = sx / qrSubSteps;
        final mCol = (fracU * totalModules).floor() - quietZone;
        if (mRow >= 0 &&
            mRow < modules &&
            mCol >= 0 &&
            mCol < modules &&
            qrImage.isDark(mRow, mCol)) {
          final u = OmrLayoutSpec.qrRegion.uMin + (fracU * uSpan);
          final v = OmrLayoutSpec.qrRegion.vMin + (fracV * vSpan);
          final pt = mapNormToCanvas(u, v);
          final px = pt.x.round().clamp(0, outW - 1);
          final py = pt.y.round().clamp(0, outH - 1);
          img.fillRect(
            canvas,
            x1: px,
            y1: py,
            x2: min(outW - 1, px + 1),
            y2: min(outH - 1, py + 1),
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }

    // 3. Desenhar as bolhas de todas as questões (e preencher as marcadas pelo aluno)
    final clampedQ = totalQuestions.clamp(1, OmrLayoutSpec.maxQuestionsPerSheet);
    final clampedAlt = alternativesPerQuestion.clamp(2, OmrLayoutSpec.letters.length);
    final radiusPx =
        (OmrLayoutSpec.normalizedBubbleRadius * OmrLayoutSpec.canonicalWidth)
            .round();

    for (var qNum = 1; qNum <= clampedQ; qNum++) {
      final markedForQ = markedAnswers[qNum] ?? const <String>[];
      for (var aIdx = 0; aIdx < clampedAlt; aIdx++) {
        final letter = OmrLayoutSpec.letters[aIdx];
        final norm = OmrLayoutSpec.bubbleCenterNormalized(
          questionNumber: qNum,
          altIndex: aIdx,
        );
        final center = mapNormToCanvas(norm.u, norm.v);
        final cx = center.x.round();
        final cy = center.y.round();

        final isMarked = markedForQ.contains(letter);
        if (isMarked) {
          img.fillCircle(
            canvas,
            x: cx,
            y: cy,
            radius: (radiusPx * 0.85).round(),
            color: img.ColorRgb8(15, 15, 15),
          );
        } else {
          img.drawCircle(
            canvas,
            x: cx,
            y: cy,
            radius: radiusPx,
            color: img.ColorRgb8(80, 80, 80),
          );
        }
      }
    }

    return Uint8List.fromList(img.encodePng(canvas));
  }
}
