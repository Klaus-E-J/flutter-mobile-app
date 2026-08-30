import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_text_field.dart';

class UiPreviewScreen extends StatefulWidget {
  const UiPreviewScreen({super.key});

  @override
  State<UiPreviewScreen> createState() => _UiPreviewScreenState();
}

class _UiPreviewScreenState extends State<UiPreviewScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Preview')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const AppHeader(
            title: 'Componentes UI',
            subtitle:
                'Catálogo interno dos componentes reutilizáveis da aplicação.',
          ),

          const SizedBox(height: 32),

          _buildSection(
            context,
            title: 'Botões',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(label: 'Primário', onPressed: () {}),
                    AppButton(
                      label: 'Secundário',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Texto',
                      variant: AppButtonVariant.text,
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(
                      label: 'Com ícone',
                      icon: Icons.add,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Carregando',
                      isLoading: true,
                      onPressed: () {},
                    ),
                    const AppButton(label: 'Desabilitado', onPressed: null),
                  ],
                ),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Campo de texto',
            child: Column(
              children: [
                AppTextField(
                  label: 'Nome da prova',
                  hint: 'Digite o nome da prova',
                  controller: _controller,
                ),
                const SizedBox(height: 16),
                const AppTextField(
                  label: 'Código de acesso',
                  prefixIcon: Icons.key_outlined,
                ),
                const SizedBox(height: 16),
                const AppTextField(
                  label: 'Campo com erro',
                  errorText: 'Valor inválido',
                ),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Cards',
            child: Column(
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.class_outlined),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3º Ano A',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text('32 alunos'),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                const AppCard(child: Text('Card simples para conteúdo.')),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Estados',
            child: Column(
              children: [
                const SizedBox(
                  height: 180,
                  child: AppEmptyState(
                    title: 'Nenhuma prova cadastrada',
                    description: 'Crie uma prova para começar.',
                    icon: Icons.description_outlined,
                  ),
                ),

                const Divider(height: 32),

                const SizedBox(
                  height: 150,
                  child: AppLoading(message: 'Carregando...'),
                ),

                const Divider(height: 32),

                SizedBox(
                  height: 180,
                  child: AppErrorState(
                    description: 'Verifique sua conexão e tente novamente.',
                    onRetry: () {},
                  ),
                ),
              ],
            ),
          ),

          _buildSection(
            context,
            title: 'Diálogo',
            child: AppButton(
              label: 'Abrir diálogo',
              icon: Icons.open_in_new,
              onPressed: () {
                AppDialog.show(
                  context: context,
                  title: 'Exemplo de diálogo',
                  message: 'Este é o diálogo reutilizável da aplicação.',
                  cancelLabel: 'Cancelar',
                  confirmLabel: 'Confirmar',
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Fim do catálogo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
