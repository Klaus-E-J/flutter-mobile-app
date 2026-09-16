import 'package:flutter/material.dart';

import 'models/correcao_models.dart';
import 'leitura_qr_screen.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

/// Tela inicial do fluxo de correção — Selecionar prova/turma.
///
/// Layout fiel ao Figma (tela 11):
/// - Título "Iniciar correção" + subtítulo
/// - Dropdown para selecionar a prova/turma
/// - Card de info (turma, alunos, questões)
/// - Botão "Iniciar leitura"
/// - Rodapé "Etapas: QR Code → Gabarito → Resultado"
class SelecaoProvaScreen extends StatefulWidget {
  const SelecaoProvaScreen({super.key});

  @override
  State<SelecaoProvaScreen> createState() => _SelecaoProvaScreenState();
}

class _SelecaoProvaScreenState extends State<SelecaoProvaScreen> {
  final List<ProvaCorrecao> _provas = gerarProvasMock();
  ProvaCorrecao? _provaSelecionada;

  @override
  void initState() {
    super.initState();
    if (_provas.isNotEmpty) {
      _provaSelecionada = _provas.first;
    }
  }

  void _iniciarLeitura() {
    if (_provaSelecionada == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraQrScreen(prova: _provaSelecionada!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Correção')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Título
            Text(
              'Iniciar correção',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecione a prova que será corrigida',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Dropdown de seleção de prova
            DropdownButtonFormField<ProvaCorrecao>(
              initialValue: _provaSelecionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _provas.map((prova) {
                return DropdownMenuItem(
                  value: prova,
                  child: Text('${prova.titulo} · ${prova.turma}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _provaSelecionada = value);
              },
            ),

            const SizedBox(height: 12),

            // Card de informações da prova selecionada
            if (_provaSelecionada != null)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _provaSelecionada!.turma,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_provaSelecionada!.totalAlunos} alunos • '
                        '${_provaSelecionada!.totalQuestoes} questões',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_provaSelecionada!.provaIndividual) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.shuffle,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sequência diferente por aluno',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Botão "Iniciar leitura"
            AppButton(
              label: 'Iniciar leitura',
              expanded: true,
              onPressed: _provaSelecionada != null ? _iniciarLeitura : null,
            ),

            const SizedBox(height: 16),

            // Etapas do fluxo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEtapaChip('QR Code', Icons.qr_code, isActive: true),
                const _EtapaConector(),
                _buildEtapaChip('Gabarito', Icons.document_scanner_outlined),
                const _EtapaConector(),
                _buildEtapaChip('Resultado', Icons.assignment_outlined),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtapaChip(
    String label,
    IconData icon, {
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _EtapaConector extends StatelessWidget {
  const _EtapaConector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.arrow_forward,
        size: 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
