import 'package:flutter/material.dart';

import 'models/correcao_models.dart';

/// Tela de resultados da correção (Step 4 — final).
///
/// Exibe um resumo da correção (total de provas, média, erros)
/// e a lista individual de alunos com suas notas.
/// O botão "Concluir" retorna à tela inicial do fluxo.
class ResultadoCorrecaoScreen extends StatelessWidget {
  const ResultadoCorrecaoScreen({
    super.key,
    required this.prova,
    required this.resultados,
    this.totalErros = 0,
  });

  final ProvaCorrecao prova;
  final List<ResultadoAluno> resultados;
  final int totalErros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _concluir(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultados'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () => _concluir(context),
              child: const Text('Concluir'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Resumo geral
            _buildResumo(theme),

            const SizedBox(height: 8),

            // Título da lista
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Detalhamento por aluno',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${resultados.length} aluno(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Lista de resultados
            Expanded(
              child: resultados.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma prova escaneada.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: resultados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return _ResultadoAlunoCard(
                          resultado: resultados[index],
                          posicao: index + 1,
                        );
                      },
                    ),
            ),
          ],
        ),

        // Botão de concluir
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _concluir(context),
              icon: const Icon(Icons.check),
              label: const Text('Concluir Correção'),
            ),
          ),
        ),
      ),
    );
  }

  void _concluir(BuildContext context) {
    // Retorna até a tela que chamou o fluxo de correção
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildResumo(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final mediaAcertos = resultados.isEmpty
        ? 0.0
        : resultados.fold<double>(
              0,
              (sum, r) => sum + r.percentual,
            ) /
            resultados.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Título da prova
          Text(
            prova.titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${prova.turma} · ${prova.disciplina}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Estatísticas
          Row(
            children: [
              _buildEstatistica(
                theme: theme,
                valor: '${resultados.length}',
                label: 'Corrigidas',
                cor: colorScheme.primary,
              ),
              _buildEstatistica(
                theme: theme,
                valor: '${mediaAcertos.toStringAsFixed(0)}%',
                label: 'Média',
                cor: mediaAcertos >= 60
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              _buildEstatistica(
                theme: theme,
                valor: '$totalErros',
                label: 'Erros',
                cor: totalErros > 0
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstatistica({
    required ThemeData theme,
    required String valor,
    required String label,
    required Color cor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card individual com o resultado de um aluno.
class _ResultadoAlunoCard extends StatelessWidget {
  const _ResultadoAlunoCard({
    required this.resultado,
    required this.posicao,
  });

  final ResultadoAluno resultado;
  final int posicao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final aprovado = resultado.percentual >= 60;
    final corNota = aprovado ? colorScheme.primary : colorScheme.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Posição
            SizedBox(
              width: 28,
              child: Text(
                '$posicao.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Nome do aluno
            Expanded(
              child: Text(
                resultado.nomeAluno,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // Nota / Percentual
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  resultado.nota,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: corNota,
                  ),
                ),
                Text(
                  '${resultado.percentual.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
