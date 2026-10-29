import 'dart:async';
import 'package:flutter/foundation.dart';

import '../classes/data/class_repository.dart';
import '../correction/data/submission_repository.dart';
import '../exams/data/exam_repository.dart';

class DashboardStats {
  const DashboardStats({
    this.examCount = 0,
    this.classCount = 0,
    this.pendingCount = 0,
    this.submissionCount = 0,
    this.isLoading = true,
  });

  final int examCount;
  final int classCount;
  final int pendingCount;
  final int submissionCount;
  final bool isLoading;
}

/// ViewModel para o Dashboard, seguindo o padrão MVVM recomendado.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    ExamRepository? examRepository,
    ClassRepository? classRepository,
    SubmissionRepository? submissionRepository,
  })  : _examRepository = examRepository ?? ExamRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _submissionRepository = submissionRepository ?? SubmissionRepository() {
    _startListening();
  }

  final ExamRepository _examRepository;
  final ClassRepository _classRepository;
  final SubmissionRepository _submissionRepository;

  DashboardStats _stats = const DashboardStats();
  DashboardStats get stats => _stats;

  StreamSubscription<dynamic>? _examSub;
  StreamSubscription<dynamic>? _classSub;
  StreamSubscription<dynamic>? _submissionSub;

  List<ExamRecord> _exams = [];
  List<ClassRecord> _classes = [];
  List<SubmissionRecord> _submissions = [];

  void _startListening() {
    _examSub = _examRepository.watchExams().listen(
      (exams) {
        _exams = exams;
        _recalculate();
      },
      onError: (_) {
        _stats = DashboardStats(
          examCount: _stats.examCount,
          classCount: _stats.classCount,
          pendingCount: _stats.pendingCount,
          submissionCount: _stats.submissionCount,
          isLoading: false,
        );
        notifyListeners();
      },
    );

    _classSub = _classRepository.watchClasses().listen(
      (classes) {
        _classes = classes;
        _recalculate();
      },
      onError: (_) {
        _recalculate();
      },
    );

    _submissionSub = _submissionRepository.watchSubmissions().listen(
      (submissions) {
        _submissions = submissions;
        _recalculate();
      },
      onError: (_) {
        _recalculate();
      },
    );
  }

  void _recalculate() {
    final correctedExamIds = _submissions.map((s) => s.examId).toSet();
    final pendingCount = _exams.where((e) => !correctedExamIds.contains(e.id)).length;

    _stats = DashboardStats(
      examCount: _exams.length,
      classCount: _classes.length,
      pendingCount: pendingCount,
      submissionCount: _submissions.length,
      isLoading: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _examSub?.cancel();
    _classSub?.cancel();
    _submissionSub?.cancel();
    super.dispose();
  }
}
