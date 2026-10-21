import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import 'view_models/auth_view_model.dart';

enum _AuthMode { signIn, signUp }

/// Tela de autenticação e registro formal com Firebase Auth.
/// Permite login com e-mail/senha, criação de nova conta, redefinição de senha
/// e acesso temporário como convidado.
class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, this.viewModel});

  final AuthViewModel? viewModel;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  late final AuthViewModel _viewModel;
  bool _ownsViewModel = false;

  _AuthMode _mode = _AuthMode.signIn;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = AuthViewModel();
      _ownsViewModel = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _viewModel.clearMessages();
    });
  }

  Future<void> _handleSignIn() async {
    final success = await _viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  Future<void> _handleSignUp() async {
    final success = await _viewModel.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      school: _schoolController.text.trim().isEmpty
          ? null
          : _schoolController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  Future<void> _handleGuestSignIn() async {
    final success = await _viewModel.signInAsGuest();

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recuperar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Digite o e-mail da sua conta para receber o link de redefinição de senha.',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: resetEmailController,
                label: 'E-mail',
                hint: 'exemplo@escola.com.br',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                Navigator.pop(dialogContext);
                await _viewModel.sendPasswordReset(email);
              },
              child: const Text('Enviar link'),
            ),
          ],
        );
      },
    );

    resetEmailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header com logotipo e boas-vindas
                      _buildHeader(colorScheme, theme),

                      const SizedBox(height: 28),

                      // Segmented Tab (Entrar / Criar conta)
                      _buildModeSelector(colorScheme),

                      const SizedBox(height: 20),

                      // Banners de erro ou sucesso
                      if (_viewModel.errorMessage != null)
                        _buildErrorBanner(
                          _viewModel.errorMessage!,
                          colorScheme,
                        ),
                      if (_viewModel.successMessage != null)
                        _buildSuccessBanner(
                          _viewModel.successMessage!,
                          colorScheme,
                        ),

                      // Formulário
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _mode == _AuthMode.signIn
                              ? _buildSignInForm(colorScheme)
                              : _buildSignUpForm(colorScheme),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.school_rounded,
            size: 36,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Avalia Pro',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gestão de provas, turmas e correções para professores',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Entrar',
              isSelected: _mode == _AuthMode.signIn,
              onTap: () => _switchMode(_AuthMode.signIn),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Criar conta',
              isSelected: _mode == _AuthMode.signUp,
              onTap: () => _switchMode(_AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('sign_in_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acesse sua conta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _emailController,
          label: 'E-mail institucional ou pessoal',
          hint: 'exemplo@escola.com.br',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          enabled: !_viewModel.isLoading,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          enabled: !_viewModel.isLoading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _viewModel.isLoading ? null : _showForgotPasswordDialog,
            child: const Text('Esqueci minha senha'),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Entrar',
          icon: Icons.login,
          expanded: true,
          isLoading: _viewModel.isLoading,
          onPressed: _handleSignIn,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Acesso rápido como convidado',
          icon: Icons.person_outline,
          variant: AppButtonVariant.secondary,
          expanded: true,
          isLoading: _viewModel.isLoading,
          onPressed: _handleGuestSignIn,
        ),
      ],
    );
  }

  Widget _buildSignUpForm(ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('sign_up_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cadastre-se como professor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _nameController,
          label: 'Nome completo',
          hint: 'Prof. Carlos Silva',
          prefixIcon: Icons.person_outline,
          enabled: !_viewModel.isLoading,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _schoolController,
          label: 'Escola ou instituição (opcional)',
          hint: 'Escola Municipal Exemplo',
          prefixIcon: Icons.school_outlined,
          enabled: !_viewModel.isLoading,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _emailController,
          label: 'E-mail',
          hint: 'carlos@escola.com.br',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          enabled: !_viewModel.isLoading,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          label: 'Senha',
          hint: 'Mínimo de 6 caracteres',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          enabled: !_viewModel.isLoading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _confirmPasswordController,
          label: 'Confirmar senha',
          hint: 'Repita sua senha',
          obscureText: _obscureConfirmPassword,
          prefixIcon: Icons.lock_clock_outlined,
          enabled: !_viewModel.isLoading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Cadastrar e começar',
          icon: Icons.check_circle_outline,
          expanded: true,
          isLoading: _viewModel.isLoading,
          onPressed: _handleSignUp,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: colorScheme.onPrimaryContainer,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
