import 'package:flutter/material.dart';

import 'data/mock_statistics_repository.dart';
import 'data/statistics_repository.dart';
import 'views/class_stats_view.dart';
import 'views/student_stats_view.dart';

/// Tela principal de estatísticas.
///
/// Fluxo: selecionar turma → TabBar (Turma / Aluno).
/// A turma selecionada é compartilhada entre as duas abas.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // TODO: Substituir por implementação real quando o banco for integrado.
  final StatisticsRepository _repository = MockStatisticsRepository();

  List<String> _classes = [];
  String? _selectedClass;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await _repository.getAvailableClasses();
    if (!mounted) return;

    setState(() {
      _classes = classes;
      _selectedClass = classes.isNotEmpty ? classes.first : null;
      _isLoading = false;
    });
  }

  void _onClassChanged(String? value) {
    if (value != null && value != _selectedClass) {
      setState(() => _selectedClass = value);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Seletor de turma com DropdownButtonFormField padrão do Material 3
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  hint: const Text('Selecione a turma'),
                  items: _classes.map((className) {
                    return DropdownMenuItem(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: _onClassChanged,
                ),
              ),
              const SizedBox(height: 8),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Turma'),
                  Tab(text: 'Aluno'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedClass == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma turma disponível',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre turmas e realize correções para '
                'ver as estatísticas aqui.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: TabBarView(
        controller: _tabController,
        children: [
          ClassStatsView(
            key: ValueKey('class_$_selectedClass'),
            repository: _repository,
            className: _selectedClass!,
          ),
          StudentStatsView(
            key: ValueKey('student_$_selectedClass'),
            repository: _repository,
            className: _selectedClass!,
          ),
        ],
      ),
    );
  }
}
