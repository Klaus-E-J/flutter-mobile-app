import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  bool _showCodeInput = false;

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
              child: _showCodeInput
              ? _buildExistingAccess()
              : _buildWelcome(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLogo(),

        const SizedBox(height: 40),

        Text(
          'Acesse o Avalia Pro',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Use seu acesso para gerenciar turmas, '
        'provas e correções.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context)
          .colorScheme
          .onSurfaceVariant,
        ),
        ),

        const SizedBox(height: 40),

        FilledButton(
          onPressed: _createAccess,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Criar meu acesso'),
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: () {
            setState(() {
              _showCodeInput = true;
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Já tenho um código'),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IconButton(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _showCodeInput = false;
            });
          },
          icon: const Icon(Icons.arrow_back),
        ),

        const SizedBox(height: 24),

        Text(
          'Acessar com código',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Digite o código do seu acesso para continuar.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 32),

        TextField(
          decoration: const InputDecoration(
            labelText: 'Código de acesso',
            hintText: 'Digite seu código',
            prefixIcon: Icon(Icons.key_outlined),
          ),
        ),

        const SizedBox(height: 20),

        FilledButton(
          onPressed: _useExistingCode,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Continuar'),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.fact_check_outlined,
          size: 40,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  void _createAccess() {
    // Fluxo real de criação de acesso será implementado posteriormente.
    //
    // Por enquanto, simulamos que o acesso foi criado
    // para permitir testar o fluxo da aplicação.
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.dashboard,
    );
  }

  void _useExistingCode() {
    // Validação real do código será implementada posteriormente.
    //
    // Por enquanto, simulamos um código válido.
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.dashboard,
    );
  }
}
