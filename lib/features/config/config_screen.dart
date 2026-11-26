import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
import '../access/data/auth_repository.dart';
import '../access/data/user_profile.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/app_snack_bar.dart';

/// Tela de Configurações (FE-14).
///
/// Apresenta dados reais do perfil do professor logado via Firebase Auth
/// e Cloud Firestore, permitindo editar o perfil e encerrar a sessão.
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
  bool _isAboutExpanded = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (widget.authRepository != null ||
          (FirebaseService.isInitialized &&
              FirebaseService.currentUser != null)) {
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

  Future<void> _handleEditProfile() async {
    final currentName = _userProfile?.name ??
        FirebaseService.currentUser?.displayName ??
        'Professor';
    final currentSchool = _userProfile?.school ?? '';

    final result = await showDialog<({String name, String school})>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: currentName,
        initialSchool: currentSchool,
      ),
    );

    if (!mounted || result == null) return;

    try {
      final baseProfile = _userProfile ??
          UserProfile(
            uid: FirebaseService.currentUser?.uid ?? 'local_user',
            name: result.name,
            email: FirebaseService.currentUser?.email ?? '',
            school: result.school,
            accessCode: _accessCode,
            isAnonymous: FirebaseService.currentUser?.isAnonymous ?? false,
          );
      final updated = baseProfile.copyWith(
        name: result.name,
        school: result.school,
        updatedAt: DateTime.now(),
      );
      if (widget.authRepository != null ||
          (FirebaseService.isInitialized &&
              FirebaseService.currentUser != null)) {
        await _authRepository.updateProfile(updated);
      }
      if (!mounted) return;
      setState(() {
        _userProfile = updated;
      });
      _showFeedback('Perfil atualizado com sucesso.', isSuccess: true);
    } catch (e) {
      _showFeedback(
        'Não foi possível salvar o perfil: $e',
        isSuccess: false,
      );
    }
  }

  void _handleSignOut() {
    AppDialog.show(
      context: context,
      title: 'Sair da conta',
      message: 'Tem certeza que deseja encerrar sua sessão neste dispositivo?',
      confirmLabel: 'Sair da conta',
      cancelLabel: 'Cancelar',
      destructive: true,
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
    isSuccess
        ? AppSnackBar.success(context, message)
        : AppSnackBar.error(context, message);
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
              _buildSectionLabel('Dados'),
              const SizedBox(height: 12),

              // Firebase e sincronização (ativo)
              _buildMenuItem(
                icon: AppIcons.cloudOn,
                title: 'Firebase e sincronização em tempo real',
                subtitle: FirebaseService.isInitialized
                    ? 'Conectado à nuvem'
                    : 'Modo local',
                enabled: true,
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
              AppIcons.institution,
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
                  style: Theme.of(context).textTheme.titleMedium,
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
          IconButton(
            icon: const Icon(AppIcons.edit),
            tooltip: 'Editar perfil',
            onPressed: _handleEditProfile,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.outlineVariant,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              AppIcons.chevron,
              color: colorScheme.outlineVariant,
              size: 20,
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
                AppIcons.info,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Sobre o aplicativo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(
                _isAboutExpanded
                    ? AppIcons.expandLess
                    : AppIcons.expandMore,
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
                    AppIcons.brand,
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
                            .textTheme.titleMedium,
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
            AppIcons.logout,
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
            AppIcons.chevron,
            color: colorScheme.error.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.initialSchool,
  });

  final String initialName;
  final String initialSchool;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _schoolController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _schoolController = TextEditingController(text: widget.initialSchool);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Informe o nome de exibição');
      return;
    }
    Navigator.pop(
      context,
      (name: name, school: _schoolController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Nome de exibição',
              hint: 'Ex.: Prof. Carlos Silva',
              controller: _nameController,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Escola / Instituição',
              hint: 'Ex.: Colégio Estadual Central',
              controller: _schoolController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
