import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../access/data/auth_repository.dart';
import '../access/data/user_profile.dart';

/// Tela de Configurações (FE-14).
///
/// Apresenta dados reais do perfil do professor logado via Firebase Auth
/// e Cloud Firestore, permitindo gerenciar o código de acesso e encerrar a sessão.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const _appVersion = '1.0.0';

  late final AuthRepository _authRepository;
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;

  String _accessCode = 'PROF-8421';
  bool _isCodeRevealed = false;
  bool _isAccessExpanded = false;
  bool _isAboutExpanded = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (FirebaseService.isInitialized && FirebaseService.currentUser != null) {
        final profile = await _authRepository.getCurrentProfile();
        if (mounted) {
          setState(() {
            _userProfile = profile;
            if (profile != null && profile.accessCode.isNotEmpty) {
              _accessCode = profile.accessCode;
            }
            _isLoadingProfile = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

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
      onConfirm: () async {
        final newCode = AuthRepository.generateAccessCode();

        try {
          if (_userProfile != null) {
            final updated = _userProfile!.copyWith(
              accessCode: newCode,
              updatedAt: DateTime.now(),
            );
            await _authRepository.updateProfile(updated);
            _userProfile = updated;
          }

          if (mounted) {
            setState(() {
              _accessCode = newCode;
              _isCodeRevealed = true;
            });
            _showFeedback('Novo código gerado com sucesso.', isSuccess: true);
          }
        } catch (e) {
          _showFeedback(
            'Não foi possível atualizar o código: $e',
            isSuccess: false,
          );
        }
      },
    );
  }

  void _handleSignOut() {
    AppDialog.show(
      context: context,
      title: 'Sair da conta',
      message: 'Tem certeza que deseja encerrar sua sessão neste dispositivo?',
      confirmLabel: 'Sair da conta',
      cancelLabel: 'Cancelar',
      onConfirm: () async {
        try {
          await _authRepository.signOut();
        } catch (_) {}

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.access,
          (route) => false,
        );
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
              // Cabeçalho da instituição / perfil
              _buildProfileHeader(),

              const SizedBox(height: 28),

              // Seção de dados
              _buildSectionLabel('Preferências e dados'),
              const SizedBox(height: 12),

              // Código de acesso (expansível)
              _buildAccessCodeItem(),
              const SizedBox(height: 10),

              // Firebase e sincronização (ativo)
              _buildMenuItem(
                icon: Icons.cloud_done_outlined,
                title: 'Firebase e sincronização em tempo real',
                subtitle: FirebaseService.isInitialized
                    ? 'Conectado à nuvem'
                    : 'Modo local',
                enabled: true,
              ),
              const SizedBox(height: 10),

              // Exportação e dados
              _buildMenuItem(
                icon: Icons.file_download_outlined,
                title: 'Exportação e dados',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.export);
                },
              ),
              const SizedBox(height: 10),

              _buildMenuItem(
                icon: Icons.tune_outlined,
                title: 'Preferências de visualização',
                enabled: false,
              ),

              const SizedBox(height: 28),

              // Seção Sobre
              _buildSectionLabel('Informações'),
              const SizedBox(height: 12),

              // Sobre o app (expansível)
              _buildAboutItem(),

              const SizedBox(height: 28),

              // Seção Sessão / Logout
              _buildSectionLabel('Sessão'),
              const SizedBox(height: 12),
              _buildSignOutItem(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    final displayName = _userProfile?.displayName ??
        FirebaseService.currentUser?.displayName ??
        'Professor';

    final schoolName = (_userProfile?.school.isNotEmpty ?? false)
        ? _userProfile!.school
        : 'Escola / Instituição de ensino';

    final email = _userProfile?.email.isNotEmpty == true
        ? _userProfile!.email
        : (FirebaseService.currentUser?.email ??
            (FirebaseService.currentUser?.isAnonymous == true
                ? 'Sessão convidado (anônima)'
                : 'Conta ativa'));

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
                  _isLoadingProfile ? 'Carregando perfil...' : displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  schoolName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
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
    String? subtitle,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.outlineVariant,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
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
          else if (onTap != null)
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
                  'Acesso e código institucional',
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
            'Código de acesso do professor',
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

  Widget _buildSignOutItem() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: _handleSignOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.logout,
            size: 20,
            color: colorScheme.error,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Sair da conta',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.error.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );
  }
}
