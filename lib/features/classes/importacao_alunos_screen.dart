import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_loading.dart';

/// Tela de Importação de Alunos (FE-08).
///
/// Fluxo completamente mockado:
/// 1. Seleção de arquivo (simulada).
/// 2. Prévia dos alunos que seriam importados.
/// 3. Confirmação → sucesso ou erro.
/// 4. Cancelamento em qualquer etapa.
///
/// Nenhum parser real ou persistência é realizado.
class ImportacaoAlunosScreen extends StatefulWidget {
  const ImportacaoAlunosScreen({
    super.key,
    required this.nomeTurma,
  });

  final String nomeTurma;

  @override
  State<ImportacaoAlunosScreen> createState() => _ImportacaoAlunosScreenState();
}

class _ImportacaoAlunosScreenState extends State<ImportacaoAlunosScreen> {
  _ImportStep _step = _ImportStep.selecao;
  String? _nomeArquivo;
  bool _isLoading = false;

  // Alunos mockados que seriam lidos do arquivo
  static const _alunosMock = [
    'Adriana Ferreira',
    'Bruno Henrique',
    'Camila Souza',
    'Daniel Ribeiro',
    'Eduarda Lima',
    'Felipe Torres',
    'Gabriela Nunes',
    'Henrique Oliveira',
    'Isabela Costa',
    'João Pedro Alves',
    'Karina Mendes',
    'Lucas Carvalho',
  ];

  // ─── Ações ──────────────────────────────────────────────────────────────

  Future<void> _selecionarArquivo() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _nomeArquivo = 'lista_alunos_${widget.nomeTurma.replaceAll(' ', '_')}.csv';
      _step = _ImportStep.previa;
    });
  }

  Future<void> _confirmarImportacao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar importação'),
        content: Text(
          'Serão adicionados ${_alunosMock.length} alunos à turma '
          '"${widget.nomeTurma}". Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (!(confirmar ?? false) || !mounted) return;

    setState(() {
      _isLoading = true;
      _step = _ImportStep.importando;
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Simula 90% de sucesso
    final sucesso = DateTime.now().millisecondsSinceEpoch % 10 != 0;

    setState(() {
      _isLoading = false;
      _step = sucesso ? _ImportStep.sucesso : _ImportStep.erro;
    });
  }

  void _reiniciar() {
    setState(() {
      _step = _ImportStep.selecao;
      _nomeArquivo = null;
    });
  }

  Future<bool> _confirmarCancelamento() async {
    if (_step == _ImportStep.selecao || _step == _ImportStep.sucesso) {
      return true;
    }

    final sair = await AppDialog.show(
      context: context,
      title: 'Cancelar importação?',
      message: 'Se sair agora, os dados selecionados serão descartados.',
      confirmLabel: 'Sair',
      cancelLabel: 'Continuar',
    );
    return false; // AppDialog doesn't return bool directly
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _ImportStep.selecao || _step == _ImportStep.sucesso,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancelar importação?'),
            content: const Text(
              'Se sair agora, os dados selecionados serão descartados.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Continuar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if ((result ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Importar alunos'),
        ),
        body: SafeArea(
          child: _isLoading && _step == _ImportStep.importando
              ? const AppLoading(message: 'Importando alunos...')
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _ImportStep.selecao:
        return _buildSelecao();
      case _ImportStep.previa:
        return _buildPrevia();
      case _ImportStep.importando:
        return const AppLoading(message: 'Importando alunos...');
      case _ImportStep.sucesso:
        return _buildSucesso();
      case _ImportStep.erro:
        return _buildErro();
    }
  }

  // ─── Etapa 1: Seleção de arquivo ─────────────────────────────────────────

  Widget _buildSelecao() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Importar lista de alunos',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Adicione vários alunos de uma vez enviando um arquivo CSV ou Excel.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),

        const SizedBox(height: 32),

        // Área de seleção de arquivo
        AppCard(
          onTap: _isLoading ? null : _selecionarArquivo,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Selecionar arquivo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque para escolher um arquivo CSV ou XLSX do seu dispositivo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Instruções de formato
        Text(
          'Formato esperado',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormatoItem(
                '1ª coluna',
                'Nome completo do aluno',
                Icons.person_outlined,
              ),
              const SizedBox(height: 10),
              _buildFormatoItem(
                'Cabeçalho',
                'Opcional — será ignorado automaticamente',
                Icons.table_rows_outlined,
              ),
              const SizedBox(height: 10),
              _buildFormatoItem(
                'Codificação',
                'UTF-8 recomendado para acentos',
                Icons.code_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatoItem(String label, String descricao, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                descricao,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Etapa 2: Prévia dos alunos ──────────────────────────────────────────

  Widget _buildPrevia() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Cabeçalho da prévia
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prévia da importação',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arquivo: $_nomeArquivo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Resumo
              AppCard(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_alunosMock.length} alunos serão adicionados '
                        'à turma "${widget.nomeTurma}"',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Lista de prévia
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: _alunosMock.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          colorScheme.primaryContainer,
                      child: Text(
                        _alunosMock[index][0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _alunosMock[index],
                        style:
                            const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Ações fixas no rodapé
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'Confirmar importação',
                  icon: Icons.check,
                  expanded: true,
                  onPressed: _confirmarImportacao,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.text,
                  expanded: true,
                  onPressed: _reiniciar,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Etapa 3: Sucesso ─────────────────────────────────────────────────────

  Widget _buildSucesso() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Importação concluída!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_alunosMock.length} alunos foram adicionados à turma '
              '"${widget.nomeTurma}".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Voltar para a turma',
              icon: Icons.arrow_back,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Etapa 4: Erro ────────────────────────────────────────────────────────

  Widget _buildErro() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Falha na importação',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível importar os alunos. Verifique o arquivo e '
              'tente novamente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              expanded: true,
              onPressed: _confirmarImportacao,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Escolher outro arquivo',
              variant: AppButtonVariant.secondary,
              icon: Icons.folder_open_outlined,
              expanded: true,
              onPressed: _reiniciar,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImportStep { selecao, previa, importando, sucesso, erro }
