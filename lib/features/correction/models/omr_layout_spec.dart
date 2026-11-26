/// Especificação geométrica determinística da Folha de Respostas OMR (N3-03 / N3-04).
///
/// Compartilhada entre o gerador de PDF (`ExamPdfService`) e o motor de visão
/// computacional (`OmrImageService`) para garantir alinhamento exato das coordenadas
/// das bolhas após a retificação de perspectiva pelos 4 marcadores fiduciais.
class OmrLayoutSpec {
  const OmrLayoutSpec._();

  /// Largura canônica da imagem retificada entre os centros dos 4 marcadores fiduciais.
  static const int canonicalWidth = 1000;

  /// Altura canônica da imagem retificada (proporção A4 1:1.414).
  static const int canonicalHeight = 1414;

  /// Margem do centro dos marcadores fiduciais na página A4 em pontos (pt).
  static const double pdfFiducialMarginPt = 36.0;

  /// Tamanho do quadrado preto do marcador fiducial na página A4 em pontos (pt).
  static const double pdfFiducialSizePt = 20.0;

  /// Quantidade máxima de questões por coluna na grade OMR.
  static const int questionsPerColumn = 15;

  /// Quantidade máxima de questões por folha OMR (2 colunas x 15).
  static const int maxQuestionsPerSheet = 30;

  /// Letras suportadas nas colunas de alternativas.
  static const List<String> letters = ['A', 'B', 'C', 'D', 'E'];

  /// Raio normalizado da bolha em relação à largura do quadro fiducial.
  static const double normalizedBubbleRadius = 0.015;

  /// Região normalizada `(uMin, vMin, uMax, vMax)` onde o QR Code é posicionado
  /// dentro do quadro fiducial.
  static const ({double uMin, double vMin, double uMax, double vMax}) qrRegion = (
    uMin: 0.72,
    vMin: 0.02,
    uMax: 0.96,
    vMax: 0.22,
  );

  /// Retorna a coordenada normalizada `(u, v)` no intervalo `[0.0, 1.0]`
  /// para o centro da bolha da questão [questionNumber] (1..30) e alternativa
  /// de índice [altIndex] (0..4 correspondente a A..E).
  static ({double u, double v}) bubbleCenterNormalized({
    required int questionNumber,
    required int altIndex,
  }) {
    final zeroBased = (questionNumber - 1).clamp(0, maxQuestionsPerSheet - 1);
    final col = zeroBased ~/ questionsPerColumn;
    final row = zeroBased % questionsPerColumn;

    final baseU = col == 0 ? 0.16 : 0.63;
    final u = baseU + (altIndex * 0.065);
    final v = 0.34 + (row * 0.038);

    return (u: u, v: v);
  }

  /// Retorna a coordenada em pixels `(x, y)` na imagem canônica retificada
  /// (`1000 x 1414`) para a questão [questionNumber] e alternativa [altIndex].
  static ({int x, int y, int radius}) bubbleCenterPixel({
    required int questionNumber,
    required int altIndex,
  }) {
    final norm = bubbleCenterNormalized(
      questionNumber: questionNumber,
      altIndex: altIndex,
    );
    return (
      x: (norm.u * canonicalWidth).round(),
      y: (norm.v * canonicalHeight).round(),
      radius: (normalizedBubbleRadius * canonicalWidth).round(),
    );
  }
}
