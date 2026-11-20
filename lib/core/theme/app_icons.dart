import 'package:flutter/material.dart';

/// Catálogo único de ícones do app, organizado pelo significado.
///
/// Regra: um conceito = um ícone, sempre no estilo "outlined". A versão
/// preenchida só aparece no item selecionado da barra de navegação.
/// Use sempre `AppIcons.x` em vez de `Icons.x` nas telas.
abstract final class AppIcons {
  // ─── Navegação principal ─────────────────────────────────────────────
  static const home = Icons.home_outlined;
  static const homeSelected = Icons.home;
  static const classes = Icons.groups_outlined;
  static const classesSelected = Icons.groups;
  static const exams = Icons.description_outlined;
  static const examsSelected = Icons.description;
  static const correction = Icons.document_scanner_outlined;
  static const correctionSelected = Icons.document_scanner;
  static const results = Icons.insights_outlined;
  static const resultsSelected = Icons.insights;
  static const settings = Icons.settings_outlined;

  // ─── Domínio ─────────────────────────────────────────────────────────
  static const student = Icons.person_outline;
  static const addStudent = Icons.person_add_outlined;
  static const institution = Icons.school_outlined;

  /// Marca do app (logo na tela de login e em "Sobre").
  static const brand = Icons.school;
  static const questions = Icons.quiz_outlined;
  static const quickAnswerKey = Icons.grid_on_outlined;
  static const answerKey = Icons.fact_check_outlined;
  static const statistics = Icons.bar_chart_outlined;
  static const pending = Icons.pending_actions_outlined;
  static const print = Icons.print_outlined;
  static const shuffle = Icons.shuffle;
  static const qrCode = Icons.qr_code_2;
  static const scanQr = Icons.qr_code_scanner;
  static const pickImage = Icons.add_photo_alternate_outlined;
  static const spreadsheet = Icons.table_chart_outlined;
  static const cameraOn = Icons.videocam_outlined;
  static const cameraOff = Icons.videocam_off_outlined;
  static const cloudOn = Icons.cloud_done_outlined;
  static const cloudOff = Icons.cloud_off_outlined;

  // ─── Arquivos ────────────────────────────────────────────────────────
  /// Trazer dados para o app (planilha de alunos).
  static const import = Icons.upload_file_outlined;

  /// Levar dados para fora do app (planilha de notas).
  static const export = Icons.file_download_outlined;
  static const share = Icons.share_outlined;

  // ─── Ações genéricas ─────────────────────────────────────────────────
  static const add = Icons.add;
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outline;
  static const confirm = Icons.check;
  static const close = Icons.close;
  static const back = Icons.arrow_back;
  static const retry = Icons.refresh;
  static const validate = Icons.playlist_add_check;
  static const increase = Icons.add_circle_outline;
  static const decrease = Icons.remove_circle_outline;
  static const openExternal = Icons.open_in_new;
  static const chevron = Icons.chevron_right;
  static const expandMore = Icons.expand_more;
  static const expandLess = Icons.expand_less;
  static const dropdown = Icons.arrow_drop_down;
  static const login = Icons.login;
  static const logout = Icons.logout;

  // ─── Formulários ─────────────────────────────────────────────────────
  static const email = Icons.email_outlined;
  static const password = Icons.lock_outline;
  static const show = Icons.visibility_outlined;
  static const hide = Icons.visibility_off_outlined;
  static const key = Icons.key_outlined;

  // ─── Status e feedback ───────────────────────────────────────────────
  static const success = Icons.check_circle_outline;
  static const correct = Icons.check_circle_outline;
  static const incorrect = Icons.cancel_outlined;
  static const error = Icons.error_outline;
  static const warning = Icons.warning_amber_outlined;
  static const info = Icons.info_outline;
  static const empty = Icons.inbox_outlined;
  static const radioOn = Icons.radio_button_checked;
  static const radioOff = Icons.radio_button_unchecked;
}
