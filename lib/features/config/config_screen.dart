import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/widgets/app_dialog.dart';

// Paleta neutra local, alinhada ao Figma (fundo cinza claro, cards
// brancos, texto quase preto, azul só para ação principal). Escopada
// a esta tela para não alterar o tema compartilhado (app_theme.dart).
class _ConfigColors {
  static const background = Color(0xFFF5F6F8);
  static const cardBackground = Colors.white;
  static const cardBorder = Color(0xFFE5E7EB);
  static const panelBackground = Color(0xFFF9FAFB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const iconMuted = Color(0xFF9CA3AF);
  static const primaryBlue = Color(0xFF2563EB);
  static const primaryBlueSoft = Color(0xFFEFF4FE);
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  // Dados mockados. Persistência, autenticação e Firebase
  // serão implementados posteriormente.
  static const _schoolName = 'Escola Municipal Exemplo';
  static const _appVersion = '1.0.0';

  String _accessCode = 'PROF-8421';
  bool _isCodeRevealed = false;
  bool _isAccessExpanded = false;
  bool _isAboutExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ConfigColors.background,
      appBar: AppBar(
        backgroundColor: _ConfigColors.background,
        foregroundColor: _ConfigColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(context),

                  const SizedBox(height: 28),

                  const Text(
                    'Preferências e dados',
                    style: TextStyle(
                      color: _ConfigColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _AccessCodeMenuItem(
                    isExpanded: _isAccessExpanded,
                    isCodeRevealed: _isCodeRevealed,
                    maskedCode: _maskedCode,
                    accessCode: _accessCode,
                    onTap: () {
                      setState(() {
                        _isAccessExpanded = !_isAccessExpanded;
                      });
                    },
                    onToggleReveal: _handleToggleReveal,
                    onGenerateNewCode: _handleGenerateNewCode,
                  ),

                  const SizedBox(height: 12),

                  const _SimpleMenuItem(
                    icon: Icons.sync_outlined,
                    title: 'Firebase e sincronização',
                    enabled: false,
                  ),

                  const SizedBox(height: 12),

                  const _SimpleMenuItem(
                    icon: Icons.file_download_outlined,
                    title: 'Exportação e dados',
                    enabled: false,
                  ),

                  const SizedBox(height: 12),

                  const _SimpleMenuItem(
                    icon: Icons.tune_outlined,
                    title: 'Preferências',
                    enabled: false,
                  ),

                  const SizedBox(height: 12),

                  _AboutMenuItem(
                    isExpanded: _isAboutExpanded,
                    appVersion: _appVersion,
                    onTap: () {
                      setState(() {
                        _isAboutExpanded = !_isAboutExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _ConfigColors.primaryBlueSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: _ConfigColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _schoolName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ConfigColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Perfil da instituição',
                style: TextStyle(
                  fontSize: 13,
                  color: _ConfigColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _maskedCode {
    final prefix = _accessCode.contains('-')
        ? _accessCode.split('-').first
        : _accessCode.substring(0, min(4, _accessCode.length));

    return '$prefix-••••';
  }

  void _handleToggleReveal() {
    if (_isCodeRevealed) {
      setState(() {
        _isCodeRevealed = false;
      });
      return;
    }

    AppDialog.show(
      context: context,
      title: 'Visualizar código de acesso',
      message: 'Este código dá acesso completo aos seus dados. '
          'Deseja exibi-lo na tela?',
      confirmLabel: 'Visualizar',
      cancelLabel: 'Cancelar',
      onConfirm: () {
        setState(() {
          _isCodeRevealed = true;
        });
        _showFeedback('Código exibido.', isSuccess: true);
      },
    );
  }

  void _handleGenerateNewCode() {
    AppDialog.show(
      context: context,
      title: 'Gerar novo código',
      message: 'O código atual deixará de funcionar imediatamente. '
          'Esta ação não pode ser desfeita. Deseja continuar?',
      confirmLabel: 'Gerar novo código',
      cancelLabel: 'Cancelar',
      onConfirm: () {
        // Geração e persistência reais (via Firestore) serão implementadas
        // posteriormente. Por enquanto, simulamos localmente, incluindo
        // uma chance de falha para representar o estado de erro.
        final random = Random();
        final didSucceed = random.nextDouble() > 0.2;

        if (!didSucceed) {
          _showFeedback(
            'Não foi possível gerar um novo código. Tente novamente.',
            isSuccess: false,
          );
          return;
        }

        setState(() {
          _accessCode = _generateMockCode();
          _isCodeRevealed = true;
        });
        _showFeedback('Novo código gerado com sucesso.', isSuccess: true);
      },
    );
  }

  void _showFeedback(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateMockCode() {
    final random = Random();
    final digits = List.generate(4, (_) => random.nextInt(10)).join();
    return 'PROF-$digits';
  }
}

/// Item de menu no estilo do Figma: card branco arredondado sobre
/// fundo cinza claro, título à esquerda e seta `>` à direita.
class _SimpleMenuItem extends StatelessWidget {
  const _SimpleMenuItem({
    required this.icon,
    required this.title,
    this.enabled = true,
    this.onTap,
    this.trailingChild,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? trailingChild;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ConfigColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _ConfigColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? _ConfigColors.textSecondary
                    : _ConfigColors.iconMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? _ConfigColors.textPrimary
                        : _ConfigColors.iconMuted,
                  ),
                ),
              ),
              if (!enabled)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _ConfigColors.panelBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _ConfigColors.cardBorder),
                    ),
                    child: const Text(
                      'Em breve',
                      style: TextStyle(
                        fontSize: 11,
                        color: _ConfigColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              trailingChild ??
                  const Icon(
                    Icons.chevron_right,
                    color: _ConfigColors.iconMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessCodeMenuItem extends StatelessWidget {
  const _AccessCodeMenuItem({
    required this.isExpanded,
    required this.isCodeRevealed,
    required this.maskedCode,
    required this.accessCode,
    required this.onTap,
    required this.onToggleReveal,
    required this.onGenerateNewCode,
  });

  final bool isExpanded;
  final bool isCodeRevealed;
  final String maskedCode;
  final String accessCode;
  final VoidCallback onTap;
  final VoidCallback onToggleReveal;
  final VoidCallback onGenerateNewCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SimpleMenuItem(
          icon: Icons.key_outlined,
          title: 'Acesso e código',
          onTap: onTap,
          trailingChild: Icon(
            isExpanded ? Icons.expand_less : Icons.chevron_right,
            color: _ConfigColors.iconMuted,
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ConfigColors.panelBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _ConfigColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Código de acesso',
                  style: TextStyle(
                    fontSize: 12,
                    color: _ConfigColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _ConfigColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _ConfigColors.cardBorder),
                  ),
                  child: Text(
                    isCodeRevealed ? accessCode : maskedCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: _ConfigColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggleReveal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ConfigColors.textPrimary,
                          side: const BorderSide(
                            color: _ConfigColors.cardBorder,
                          ),
                          backgroundColor: _ConfigColors.cardBackground,
                        ),
                        icon: Icon(
                          isCodeRevealed
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        label: Text(
                          isCodeRevealed ? 'Ocultar' : 'Visualizar',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onGenerateNewCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: _ConfigColors.primaryBlue,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Gerar novo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _AboutMenuItem extends StatelessWidget {
  const _AboutMenuItem({
    required this.isExpanded,
    required this.appVersion,
    required this.onTap,
  });

  final bool isExpanded;
  final String appVersion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SimpleMenuItem(
          icon: Icons.fact_check_outlined,
          title: 'Sobre o aplicativo',
          onTap: onTap,
          trailingChild: Icon(
            isExpanded ? Icons.expand_less : Icons.chevron_right,
            color: _ConfigColors.iconMuted,
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ConfigColors.panelBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _ConfigColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: _ConfigColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avalia Pro',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ConfigColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Versão $appVersion',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _ConfigColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}