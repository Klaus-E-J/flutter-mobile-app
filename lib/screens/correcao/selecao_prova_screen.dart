import 'package:flutter/material.dart';

import '../../core/widgets/app_widgets.dart';
import 'models/correcao_models.dart';
import 'leitura_qr_gabarito_screen.dart';

/// Tela de seleção de prova para correção (Step 1).
///
/// Exibe uma lista mockada de provas disponíveis. Ao selecionar
/// uma prova, navega para a leitura de QR Code / Gabarito.
class SelecaoProvaScreen extends StatefulWidget {
  const SelecaoProvaScreen({super.key});

  @override
  State<SelecaoProvaScreen> createState() => _SelecaoProvaScreenState();
}

class _SelecaoProvaScreenState extends State<SelecaoProvaScreen> {
  late List<ProvaCorrecao> _provas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProvas();
  }

  Future<void> _carregarProvas() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _provas = gerarProvasMock();
      _isLoading = false;
    });
  }

  void _selecionarProva(ProvaCorrecao prova) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraQrGabaritoScreen(prova: prova),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corrigir Prova')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoading(message: 'Carregando provas...');
    }

    if (_provas.isEmpty) {
      return const AppEmptyState(
        icon: Icons.description_outlined,
        title: 'Nenhuma prova disponível',
        description: 'Crie uma prova antes de iniciar a correção.',
      );
    }

    return _buildLista();
  }

  Widget _buildLista() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instrução
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            'Selecione a prova que deseja corrigir:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Lista de provas
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _provas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final prova = _provas[index];
              return _ProvaCard(
                prova: prova,
                onTap: () => _selecionarProva(prova),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card que exibe as informações resumidas de uma prova.
class _ProvaCard extends StatelessWidget {
  const _ProvaCard({required this.prova, required this.onTap});

  final ProvaCorrecao prova;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prova.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prova.turma} · ${prova.disciplina}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${prova.totalQuestoes} questões · '
                      '${prova.totalAlunos} alunos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Seta
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
