import 'package:flutter/material.dart';
import 'exam_form_screen.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';

/// FE-06b — Criar/Editar Prova
///
/// Implementação exclusivamente de Front-End para a N1.
/// Os dados de turmas são mockados e nenhuma informação é persistida.
class ExamFormScreen extends StatefulWidget {
  const ExamFormScreen({
    super.key,
    this.initialName,
    this.initialClasses = const <String>[],
    this.initialSameExamForEveryone = true,
  });

  /// Quando informado, simula a edição de uma prova existente.
  final String? initialName;

  /// Turmas previamente vinculadas no modo de edição.
  final List<String> initialClasses;

  /// true  = mesma prova para todos, com ordem embaralhada.
  /// false = provas diferentes por aluno.
  final bool initialSameExamForEveryone;

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  static const List<String> _mockClasses = <String>[
    '9º Ano A',
    '8º Ano B',
    'Ensino Médio — 1A',
  ];

  late final TextEditingController _nameController;
  late Set<String> _selectedClasses;
  late bool _sameExamForEveryone;

  String? _nameError;
  String? _classesError;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedClasses = widget.initialClasses
        .where(_mockClasses.contains)
        .toSet();
    _sameExamForEveryone = widget.initialSameExamForEveryone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleClass(String className, bool selected) {
    setState(() {
      if (selected) {
        _selectedClasses.add(className);
      } else {
        _selectedClasses.remove(className);
      }

      if (_selectedClasses.isNotEmpty) {
        _classesError = null;
      }
    });
  }

  void _openQuestions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _QuestionsPlaceholderScreen(),
      ),
    );
  }

  void _saveExam() {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasClass = _selectedClasses.isNotEmpty;

    setState(() {
      _nameError = hasName ? null : 'Informe o nome da prova.';
      _classesError = hasClass ? null : 'Selecione pelo menos uma turma.';
    });

    if (!hasName || !hasClass) {
      return;
    }

    FocusScope.of(context).unfocus();

    final message = _isEditing
        ? 'Alterações salvas com sucesso (mock).'
        : 'Prova criada com sucesso (mock).';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar prova' : 'Criar prova'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Prova / questões',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing ? 'Editar prova' : 'Nova prova',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Defina os dados principais da avaliação. As questões serão gerenciadas em uma etapa separada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              AppTextField(
                label: 'Nome da prova',
                hint: 'Ex.: Avaliação Matemática',
                controller: _nameController,
                errorText: _nameError,
                onChanged: (value) {
                  if (_nameError != null && value.trim().isNotEmpty) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Turmas',
                subtitle: 'Vincule a prova a uma ou mais turmas.',
              ),
              const SizedBox(height: 12),
              ..._mockClasses.map(
                (className) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: CheckboxListTile(
                      value: _selectedClasses.contains(className),
                      onChanged: (value) =>
                          _toggleClass(className, value ?? false),
                      title: Text(className),
                      controlAffinity: ListTileControlAffinity.trailing,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                    ),
                  ),
                ),
              ),
              if (_classesError != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    _classesError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Modo da prova',
                subtitle: 'Escolha como a avaliação será aplicada aos alunos.',
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile.adaptive(
                  value: _sameExamForEveryone,
                  onChanged: (value) {
                    setState(() => _sameExamForEveryone = value);
                  },
                  title: Text(
                    _sameExamForEveryone
                        ? 'Mesma prova para todos'
                        : 'Provas diferentes por aluno',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _sameExamForEveryone
                          ? 'As questões e alternativas poderão ser apresentadas em ordem embaralhada.'
                          : 'Cada aluno receberá uma prova diferente.',
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Questões',
                subtitle:
                    'O cadastro e a edição das questões pertencem à FE-07.',
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Gerenciar questões',
                icon: Icons.quiz_outlined,
                variant: AppButtonVariant.secondary,
                expanded: true,
                onPressed: _openQuestions,
              ),
              const SizedBox(height: 24),

              AppButton(
                label: _isEditing ? 'Salvar alterações' : 'Salvar prova',
                icon: Icons.check,
                expanded: true,
                onPressed: _saveExam,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Placeholder local para cumprir o fluxo FE-06b -> FE-07 sem alterar
/// o arquivo central de rotas e sem implementar a tarefa de outro membro.
class _QuestionsPlaceholderScreen extends StatelessWidget {
  const _QuestionsPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar questões')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'FE-07 — Questões da prova',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta tela é apenas um placeholder. O cadastro, edição e remoção de questões será implementado na FE-07.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
