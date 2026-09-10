import 'package:flutter/material.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_loading.dart';

/// Tela de Exportação (FE-12).
///
/// Fluxo mockado:
/// 1. Selecionar conteúdo para exportar.
/// 2. Iniciar exportação → progresso simulado.
/// 3. Sucesso → compartilhar / salvar (simulado).
/// 4. Erro (com opção de tentar novamente).
///
/// Nenhuma exportação real é realizada nesta versão.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  // Seleção de conteúdo
  bool _incluirResultados = true;
  bool _incluirEstatisticas = false;
  bool _incluirListaAlunos = false;

  _ExportStatus _status = _ExportStatus.idle;
  String? _errorMessage;

  bool get _hasSelection =>
      _incluirResultados || _incluirEstatisticas || _incluirListaAlunos;

  /// Inicia o fluxo de exportação mockado.
  Future<void> _iniciarExportacao() async {
    if (!_hasSelection) return;

    setState(() {
      _status = _ExportStatus.loading;
      _errorMessage = null;
    });

    // Simula processamento
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Simula 90% de sucesso
    final sucesso = DateTime.now().millisecondsSinceEpoch % 10 != 0;

    if (sucesso) {
      setState(() => _status = _ExportStatus.success);
    } else {
      setState(() {
        _status = _ExportStatus.error;
        _errorMessage =
            'Não foi possível gerar o arquivo. Tente novamente.';
      });
    }
  }

  void _resetar() {
    setState(() {
      _status = _ExportStatus.idle;
      _errorMessage = null;
    });
  }

  Future<void> _compartilhar() async {
    await AppDialog.show(
      context: context,
      title: 'Compartilhar arquivo',
      message:
          'Em uma versão real, o arquivo seria aberto no sistema de '
          'compartilhamento do dispositivo. Nesta versão, a ação é '
          'simulada.',
      confirmLabel: 'Entendido',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportação'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ExportStatus.loading:
        return const AppLoading(message: 'Gerando arquivo...');

      case _ExportStatus.success:
        return _buildSuccess();

      case _ExportStatus.error:
        return _buildError();

      case _ExportStatus.idle:
        return _buildSelector();
    }
  }

  // ─── Estado idle: seleção de conteúdo ───────────────────────────────────

  Widget _buildSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Exportar dados',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecione o que deseja incluir no arquivo exportado.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),

        const SizedBox(height: 24),

        // Opções de seleção
        Text(
          'Conteúdo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _buildOpcao(
          icon: Icons.assignment_outlined,
          titulo: 'Resultados',
          descricao: 'Notas e acertos de cada aluno por prova.',
          valor: _incluirResultados,
          onChanged: (v) => setState(() => _incluirResultados = v),
        ),
        const SizedBox(height: 10),

        _buildOpcao(
          icon: Icons.bar_chart_outlined,
          titulo: 'Estatísticas',
          descricao: 'Médias, distribuição de notas e desempenho por questão.',
          valor: _incluirEstatisticas,
          onChanged: (v) => setState(() => _incluirEstatisticas = v),
        ),
        const SizedBox(height: 10),

        _buildOpcao(
          icon: Icons.people_outlined,
          titulo: 'Lista de alunos',
          descricao: 'Nomes e turmas dos alunos cadastrados.',
          valor: _incluirListaAlunos,
          onChanged: (v) => setState(() => _incluirListaAlunos = v),
        ),

        const SizedBox(height: 32),

        // Formato (informativo, mock)
        Text(
          'Formato',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.table_chart_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Planilha CSV',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compatível com Excel, Google Sheets e LibreOffice.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),

        const SizedBox(height: 32),

        AppButton(
          label: 'Exportar',
          icon: Icons.upload_outlined,
          expanded: true,
          onPressed: _hasSelection ? _iniciarExportacao : null,
        ),

        if (!_hasSelection) ...[
          const SizedBox(height: 8),
          Text(
            'Selecione ao menos um tipo de conteúdo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpcao({
    required IconData icon,
    required String titulo,
    required String descricao,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: valor,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2, left: 26),
          child: Text(
            descricao,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  // ─── Estado sucesso ──────────────────────────────────────────────────────

  Widget _buildSuccess() {
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
              'Arquivo gerado!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O arquivo foi gerado com sucesso e está pronto para '
              'ser compartilhado ou salvo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Compartilhar / Salvar',
              icon: Icons.share_outlined,
              expanded: true,
              onPressed: _compartilhar,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Nova exportação',
              variant: AppButtonVariant.secondary,
              icon: Icons.refresh,
              expanded: true,
              onPressed: _resetar,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Estado erro ─────────────────────────────────────────────────────────

  Widget _buildError() {
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
              'Falha na exportação',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              expanded: true,
              onPressed: _iniciarExportacao,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.text,
              expanded: true,
              onPressed: _resetar,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExportStatus { idle, loading, success, error }
