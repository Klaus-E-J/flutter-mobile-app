import '../../classes/data/class_repository.dart';
import '../../exams/models/exam_variant.dart';
import 'omr_image_service.dart';

/// Resultado da conferência do QR Code de uma folha de respostas.
class SheetQrMatch {
  const SheetQrMatch.ok(ExamVariant this.variant) : error = null;
  const SheetQrMatch.error(String this.error) : variant = null;

  /// Variante (com o aluno da folha já vinculado) usada para corrigir.
  final ExamVariant? variant;

  /// Motivo da recusa, pronto para exibir ao professor.
  final String? error;

  bool get isOk => variant != null;
}

/// Regras que impedem corrigir uma folha com o gabarito errado.
///
/// Nunca há "plano B" silencioso: se a folha não pertence à prova/turma em
/// correção, ela é recusada com uma mensagem clara.
class SheetQrValidator {
  const SheetQrValidator._();

  static const msgOtherExam =
      'Esta folha pertence a outra prova. Confira se a prova selecionada na aba Corrigir é a correta.';
  static const msgUnknownVariant =
      'Esta folha não corresponde a nenhuma prova atual desta turma. Ela pode ser de outra turma '
      'ou ter sido impressa antes de uma alteração nas questões ou de um novo embaralhamento. '
      'Reimprima a folha deste aluno.';
  static const msgStudentMismatch =
      'QR Code inconsistente: o aluno da folha não confere com a prova individual. Reimprima a folha.';
  static const msgStudentNotInClass =
      'O aluno desta folha não está cadastrado na turma selecionada.';
  static const msgSheetNotDetected =
      'Folha não reconhecida: os 4 quadrados pretos dos cantos não foram encontrados. '
      'Fotografe a folha inteira, reta e bem iluminada.';
  static const msgQrNotFound =
      'QR Code não encontrado na imagem. Fotografe a folha inteira ou escolha a prova do aluno '
      'na lista e toque em "Confirmar QR Code".';

  /// Confere o [payload] lido da folha contra a prova [examId] em correção.
  static SheetQrMatch match({
    required ExamQrPayload payload,
    required String examId,
    required List<ExamVariant> variants,
    List<StudentRecord> students = const [],
  }) {
    if (payload.examId != examId) {
      return const SheetQrMatch.error(msgOtherExam);
    }

    ExamVariant? variant;
    for (final v in variants) {
      if (v.id == payload.variantId) {
        variant = v;
        break;
      }
    }
    if (variant == null) {
      return const SheetQrMatch.error(msgUnknownVariant);
    }

    final qrStudentId = payload.studentId;
    if (qrStudentId == null || qrStudentId.isEmpty) {
      return SheetQrMatch.ok(variant);
    }

    final variantStudent = variant.studentId;
    if (variantStudent != null &&
        variantStudent.isNotEmpty &&
        variantStudent != qrStudentId) {
      return const SheetQrMatch.error(msgStudentMismatch);
    }

    if (students.isEmpty) {
      return SheetQrMatch.ok(variant.copyWith(studentId: qrStudentId));
    }

    StudentRecord? student;
    for (final s in students) {
      if (s.id == qrStudentId) {
        student = s;
        break;
      }
    }
    if (student == null) {
      return const SheetQrMatch.error(msgStudentNotInClass);
    }
    return SheetQrMatch.ok(
      variant.copyWith(
        studentId: student.id,
        studentName: student.name,
        studentMatricula: student.matricula,
      ),
    );
  }

  /// A imagem precisa ser uma folha do Avalia Pro (4 marcadores detectados);
  /// caso contrário as posições das bolhas não são confiáveis.
  static String? sheetError(OmrSheetScanResult scan) {
    return scan.perspectiveCorrected ? null : msgSheetNotDetected;
  }
}
