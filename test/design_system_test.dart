import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garante que as telas usem os padrões visuais centrais do app.
void main() {
  final screens = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String rel(File f) => f.path.replaceAll('\\', '/');

  List<String> offenders(RegExp pattern, {Set<String> allowed = const {}}) {
    return [
      for (final file in screens)
        if (!allowed.any(rel(file).endsWith) &&
            pattern.hasMatch(file.readAsStringSync()))
          rel(file),
    ];
  }

  test('ícones vêm sempre do catálogo AppIcons', () {
    expect(
      offenders(RegExp(r'\bIcons\.'), allowed: {'core/theme/app_icons.dart'}),
      isEmpty,
      reason: 'Use AppIcons.x (lib/core/theme/app_icons.dart) em vez de Icons.x.',
    );
  });

  test('avisos usam AppSnackBar', () {
    expect(
      offenders(
        RegExp(r'[^p]SnackBar\('),
        allowed: {'core/widgets/app_snack_bar.dart'},
      ),
      isEmpty,
      reason: 'Use AppSnackBar.show/success/error.',
    );
  });

  test('botões de excluir usam AppDeleteButton (lixeira vermelha)', () {
    expect(
      offenders(
        RegExp(r'IconButton\(\s*icon:\s*(const\s+)?Icon\(AppIcons\.delete'),
        allowed: {'core/widgets/app_delete_button.dart'},
      ),
      isEmpty,
      reason: 'Use AppDeleteButton para excluir/remover.',
    );
  });

  test('cor de sucesso vem de AppColors', () {
    expect(
      offenders(
        RegExp(r'0xFF16A34A|Colors\.green'),
        allowed: {'core/theme/app_colors.dart'},
      ),
      isEmpty,
      reason: 'Use AppColors.success.',
    );
  });
}
