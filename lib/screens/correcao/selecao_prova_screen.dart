import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../features/classes/data/class_repository.dart';
import '../../../features/exams/data/exam_repository.dart';
import '../provas/models/questao_model.dart';
import '../provas/prova_questoes_screen.dart';
import 'leitura_qr_screen.dart';
import 'models/correcao_models.dart';

/// Tela inicial do fluxo de correção — Selecionar prova/turma integrada com Firebase.
class SelecaoProvaScreen extends StatefulWidget {
  const SelecaoProvaScreen({super.key});

  @override
  State<SelecaoProvaScreen> createState() => _SelecaoProvaScreenState();
}

class _SelecaoProvaScreenState extends State<SelecaoProvaScreen> {
  final ExamRepository _examRepository = ExamRepository();
  final ClassRepository _classRepository = ClassRepository();

  List<ProvaCorrecao> _provas = [];
  ProvaCorrecao? _provaSelecionada;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarProvas();
  }

  Future<void> _carregarProvas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exams = await _examRepository.watchExams().first;
      final classes = await _classRepository.getClasses();
      final classMap = {for (final c in classes) c.id: c};

      final items = <ProvaCorrecao>[];
      for (final exam in exams) {
        if (exam.classIds.isEmpty) {
          items.add(
            ProvaCorrecao(
              id: exam.id,
              titulo: exam.title,
              turma: exam.classNames.isNotEmpty
                  ? exam.classNames.first
                  : 'Sem turma vinculada',
              disciplina: 'Geral',
              totalQuestoes: exam.questionCount,
              totalAlunos: 0,
              provaIndividual: !exam.sameExamForEveryone,
            ),
          );
        } else {
          for (int i = 0; i < exam.classIds.length; i++) {
            final classId = exam.classIds[i];
            final className = i < exam.classNames.length
                ? exam.classNames[i]
                : (classMap[classId]?.name ?? 'Turma');
            final classObj = classMap[classId];

            items.add(
              ProvaCorrecao(
                id: exam.id,
                titulo: exam.title,
                turma: className,
                disciplina: classObj?.grade.isNotEmpty == true
                    ? classObj!.grade
                    : 'Avaliação',
                totalQuestoes: exam.questionCount,
                totalAlunos: classObj?.studentCount ?? 0,
                provaIndividual: !exam.sameExamForEveryone,
                classId: classId,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _provas = items;
        _provaSelecionada = items.isNotEmpty ? items.first : null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as provas: $error';
      });
    }
  }

  Future<void> _iniciarLeitura() async {
    final prova = _provaSelecionada;
    if (prova == null) return;

    if (prova.totalQuestoes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta prova não tem questões cadastradas. Cadastre questões antes de iniciar.',
          ),
        ),
      );
      return;
    }

    List<Questao> questions = [];
    List<StudentRecord> students = [];

    try {
      questions = await _examRepository.watchQuestions(prova.id).first;
      if (prova.classId != null && prova.classId!.isNotEmpty) {
        students = await _classRepository.watchStudents(prova.classId!).first;
      }
    } catch (e) {
      debugPrint('Aviso ao carregar dados complementares: $e');
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeituraQrScreen(
          prova: prova,
          questions: questions,
          students: students,
        ),
      ),
    );
  }

  void _abrirQuestoes() {
    final prova = _provaSelecionada;
    if (prova == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvaQuestoesScreen(
          examId: prova.id,
          provaTitulo: prova.titulo,
        ),
      ),
    ).then((_) => _carregarProvas());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Correção')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _carregarProvas,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _provas.isEmpty
                ? AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Nenhuma prova encontrada',
                    description:
                        'Crie uma prova e vincule-a a uma turma para iniciar a correção.',
                    action: FilledButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.exams)
                            .then((_) => _carregarProvas());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Criar prova'),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
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
                              child: Text(
                                '${prova.titulo} · ${prova.turma}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _provaSelecionada = value);
                          },
                        ),
                        const SizedBox(height: 12),
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
                                    '${_provaSelecionada!.totalAlunos} alunos cadastrados • '
                                    '${_provaSelecionada!.totalQuestoes} questões',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (_provaSelecionada!.totalQuestoes == 0) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colorScheme.errorContainer
                                            .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 18,
                                            color: colorScheme.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Esta prova ainda não tem questões cadastradas.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme.onErrorContainer,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: _abrirQuestoes,
                                        icon: const Icon(Icons.edit_outlined),
                                        label:
                                            const Text('Cadastrar questões agora'),
                                      ),
                                    ),
                                  ],
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
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
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
                        AppButton(
                          label: 'Iniciar leitura',
                          expanded: true,
                          onPressed: (_provaSelecionada != null &&
                                  _provaSelecionada!.totalQuestoes > 0)
                              ? _iniciarLeitura
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEtapaChip(
                              'QR Code',
                              Icons.qr_code,
                              isActive: true,
                            ),
                            const _EtapaConector(),
                            _buildEtapaChip(
                              'Gabarito',
                              Icons.document_scanner_outlined,
                            ),
                            const _EtapaConector(),
                            _buildEtapaChip(
                              'Resultado',
                              Icons.assignment_outlined,
                            ),
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
