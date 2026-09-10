import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';

/// Tela de Configurações (FE-14).
///
/// Dados mockados — nenhuma persistência real.
/// Integra visualmente com o restante do aplicativo
/// usando os componentes e ThemeData centrais.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const _schoolName = 'Escola Municipal Exemplo';
  static const _appVersion = '1.0.0';

  String _accessCode = 'PROF-8421';
  bool _isCodeRevealed = false;
  bool _isAccessExpanded = false;
  bool _isAboutExpanded = false;

  // ─── Lógica ──────────────────────────────────────────────────────────────

  String get _maskedCode {
    final prefix = _accessCode.contains('-')
        ? _accessCode.split('-').first
        : _accessCode.substring(0, min(4, _accessCode.length));
    return '$prefix-••••';
  }

  void _handleToggleReveal() {
    if (_isCodeRevealed) {
      setState(() => _isCodeRevealed = false);
      return;
    }

    AppDialog.show(
      context: context,
      title: 'Visualizar código de acesso',
      message:
          'Este código dá acesso completo aos seus dados. '
          'Deseja exibi-lo na tela?',
      confirmLabel: 'Visualizar',
      cancelLabel: 'Cancelar',
      onConfirm: () {
        setState(() => _isCodeRevealed = true);
        _showFeedback('Código exibido.', isSuccess: true);
      },
    );
  }

  void _handleGenerateNewCode() {
    AppDialog.show(
      context: context,
      title: 'Gerar novo código',
      message:
          'O código atual deixará de funcionar imediatamente. '
          'Esta ação não pode ser desfeita. Deseja continuar?',
      confirmLabel: 'Gerar novo código',
      cancelLabel: 'Cancelar',
      onConfirm: () {
        final random = Random();
        final didSucceed = random.nextDouble() > 0.2;

        if (!didSucceed) {
          _showFeedback(
            'Não foi possível gerar um novo código. Tente novamente.',
            isSuccess: false,
          );
          return;
        }

        final digits =
            List.generate(4, (_) => random.nextInt(10)).join();
        setState(() {
          _accessCode = 'PROF-$digits';
          _isCodeRevealed = true;
        });
        _showFeedback('Novo código gerado com sucesso.', isSuccess: true);
      },
    );
  }

  void _showFeedback(String message, {required bool isSuccess}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isSuccess ? colorScheme.primary : colorScheme.error,
          content: Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: isSuccess
                    ? colorScheme.onPrimary
                    : colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isSuccess
                        ? colorScheme.onPrimary
                        : colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho da instituição
              _buildProfileHeader(),

              const SizedBox(height: 28),

              // Seção de dados
              _buildSectionLabel('Preferências e dados'),
              const SizedBox(height: 12),

              // Código de acesso (expansível)
              _buildAccessCodeItem(),
              const SizedBox(height: 10),

              // Itens desabilitados (em breve)
              _buildMenuItem(
                icon: Icons.sync_outlined,
                title: 'Firebase e sincronização',
                enabled: false,
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.file_download_outlined,
                title: 'Exportação e dados',
                enabled: false,
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: Icons.tune_outlined,
                title: 'Preferências',
                enabled: false,
              ),

              const SizedBox(height: 28),

              // Seção Sobre
              _buildSectionLabel('Informações'),
              const SizedBox(height: 12),

              // Sobre o app (expansível)
              _buildAboutItem(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school_outlined,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _schoolName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perfil da instituição',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: enabled
                ? colorScheme.onSurfaceVariant
                : colorScheme.outlineVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.outlineVariant,
              ),
            ),
          ),
          if (!enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Em breve',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: colorScheme.outlineVariant,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAccessCodeItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: () => setState(
            () => _isAccessExpanded = !_isAccessExpanded,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.key_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Acesso e código',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                _isAccessExpanded
                    ? Icons.expand_less
                    : Icons.chevron_right,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildAccessCodePanel(),
          ),
          crossFadeState: _isAccessExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildAccessCodePanel() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Código de acesso',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Exibição do código
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SelectableText(
              _isCodeRevealed ? _accessCode : _maskedCode,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _isCodeRevealed ? 'Ocultar' : 'Visualizar',
                  icon: _isCodeRevealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _handleToggleReveal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Gerar novo',
                  icon: Icons.refresh,
                  onPressed: _handleGenerateNewCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: () =>
              setState(() => _isAboutExpanded = !_isAboutExpanded),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Sobre o aplicativo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                _isAboutExpanded
                    ? Icons.expand_less
                    : Icons.chevron_right,
                color: Theme.of(context).colorScheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppCard(
              color:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avalia Pro',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Versão $_appVersion',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          crossFadeState: _isAboutExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}