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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estatísticas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Seletor de turma
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      hint: const Text('Selecione a turma'),
                      items: _classes.map((className) {
                        return DropdownMenuItem(
                          value: className,
                          child: Text('Turma: $className'),
                        );
                      }).toList(),
                      onChanged: _onClassChanged,
                    ),
                  ),
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
      return const Center(child: Text('Nenhuma turma disponível'));
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
