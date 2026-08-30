import 'package:flutter/material.dart';

import '../../features/access/access_screen.dart';
import '../../features/classes/classes_screen.dart';
import '../../features/correction/correction_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/exams/exams_screen.dart';
import '../../features/export/export_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/statistics/statistics_screen.dart';

import '../../features/ui_preview/ui_preview_screen.dart';

abstract final class AppRoutes {
  static const access = '/';
  static const dashboard = '/dashboard';
  static const classes = '/classes';
  static const exams = '/exams';
  static const correction = '/correction';
  static const results = '/results';
  static const statistics = '/statistics';
  static const export = '/export';
  static const uiPreview = '/ui-preview';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case access:
        return _page(const AccessScreen());

      case dashboard:
        return _page(const DashboardScreen());

      case classes:
        return _page(const ClassesScreen());

      case exams:
        return _page(const ExamsScreen());

      case correction:
        return _page(const CorrectionScreen());

      case results:
        return _page(const ResultsScreen());

      case statistics:
        return _page(const StatisticsScreen());

      case export:
        return _page(const ExportScreen());

      case uiPreview:
        return _page(const UiPreviewScreen());

      default:
        return _page(
          const Scaffold(body: Center(child: Text('Página não encontrada'))),
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
