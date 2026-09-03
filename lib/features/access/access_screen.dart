import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_text_field.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  _AccessView _view = _AccessView.chooseAccess;
  bool _codeSaved = false;

  final TextEditingController _codeController = TextEditingController();

  // Mock temporário.
  // O valor real será fornecido pela camada de autenticação posteriormente.
  static const String _mockAccessCode = 'AVALIA-2026-7K4P';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_view) {
                  _AccessView.chooseAccess => _buildChooseAccess(),
                  _AccessView.firstAccess => _buildFirstAccess(),
                  _AccessView.showCode => _buildShowCode(),
                  _AccessView.existingCode => _buildExistingCode(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChooseAccess() {
    return Column(
      key: const ValueKey(_AccessView.chooseAccess),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(
          title: 'Acesse o Avalia Pro',
          subtitle:
          'Entre no aplicativo para gerenciar suas turmas, '
        'provas e correções.',
        ),

        const SizedBox(height: 32),

        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Primeiro acesso',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie seu acesso para começar a usar o aplicativo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Criar meu acesso',
                icon: Icons.add_circle_outline,
                expanded: true,
                onPressed: () {
                  setState(() {
                    _view = _AccessView.firstAccess;
                    _codeSaved = false;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Já tenho um código',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use um código de acesso que já foi criado anteriormente.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Usar código existente',
                icon: Icons.key_outlined,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: () {
                  setState(() {
                    _view = _AccessView.existingCode;
                    _codeController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFirstAccess() {
    return Column(
      key: const ValueKey(_AccessView.firstAccess),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackButton(
          onPressed: () {
            setState(() {
              _view = _AccessView.chooseAccess;
            });
          },
        ),

        const SizedBox(height: 24),

        const AppHeader(
          title: 'Criar meu acesso',
          subtitle:
          'Será criado um código para identificar seu acesso '
        'ao aplicativo.',
        ),

        const SizedBox(height: 32),

        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Seu código de acesso',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No fluxo real, esse código será fornecido pela '
              'camada de autenticação.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Gerar meu código',
                icon: Icons.vpn_key_outlined,
                expanded: true,
                onPressed: () {
                  setState(() {
                    _view = _AccessView.showCode;
                    _codeSaved = false;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShowCode() {
    return Column(
      key: const ValueKey(_AccessView.showCode),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(
          title: 'Seu código de acesso',
          subtitle:
          'Guarde este código. Ele será usado para acessar '
        'novamente seus dados.',
        ),

        const SizedBox(height: 32),

        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Código',
                style: Theme.of(context).textTheme.labelLarge,
              ),

              const SizedBox(height: 12),

              SelectableText(
                _mockAccessCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              AppButton(
                label: 'Copiar código',
                icon: Icons.copy_outlined,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: _copyAccessCode,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        AppCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _codeSaved,
                onChanged: (value) {
                  setState(() {
                    _codeSaved = value ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Eu salvei meu código em um lugar seguro.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        AppButton(
          label: 'Continuar',
          expanded: true,
          onPressed: _codeSaved
          ? () {
            _goToDashboard();
          }
          : null,
        ),

        const SizedBox(height: 12),

        AppButton(
          label: 'Voltar',
          variant: AppButtonVariant.text,
          expanded: true,
          onPressed: () {
            setState(() {
              _view = _AccessView.firstAccess;
              _codeSaved = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildExistingCode() {
    return Column(
      key: const ValueKey(_AccessView.existingCode),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackButton(
          onPressed: () {
            setState(() {
              _view = _AccessView.chooseAccess;
            });
          },
        ),

        const SizedBox(height: 24),

        const AppHeader(
          title: 'Usar código existente',
          subtitle:
          'Digite o código de acesso que você já possui.',
        ),

        const SizedBox(height: 32),

        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _codeController,
                label: 'Código de acesso',
                hint: 'Digite ou cole seu código',
                prefixIcon: Icons.key_outlined,
                onChanged: (_) {
                  // A validação continua sendo simulada nesta entrega.
                  setState(() {});
                },
              ),

              const SizedBox(height: 20),

              AppButton(
                label: 'Entrar',
                icon: Icons.login_outlined,
                expanded: true,
                onPressed: _codeController.text.trim().isEmpty
                ? null
                : _validateExistingCode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton({
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'Voltar',
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }

  Future<void> _copyAccessCode() async {
    await Clipboard.setData(
      const ClipboardData(
        text: _mockAccessCode,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado.'),
      ),
    );
  }

  void _validateExistingCode() {
    final code = _codeController.text.trim();

    if (code == _mockAccessCode) {
      _goToDashboard();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código de acesso inválido.'),
      ),
    );
  }

  void _goToDashboard() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.dashboard,
    );
  }
}

enum _AccessView {
  chooseAccess,
  firstAccess,
  showCode,
  existingCode,
}
