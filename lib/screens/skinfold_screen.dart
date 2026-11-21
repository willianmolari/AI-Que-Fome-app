import 'package:flutter/material.dart';

import '../models/skinfold_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/skinfold_calculator.dart';

class SkinfoldScreen extends StatefulWidget {
  final AppState state;
  const SkinfoldScreen({super.key, required this.state});

  @override
  State<SkinfoldScreen> createState() => _SkinfoldScreenState();
}

class _SkinfoldScreenState extends State<SkinfoldScreen> {
  String _sex = 'male';
  late TextEditingController _age;
  late TextEditingController _weight;
  final List<TextEditingController> _sites = List.generate(
    7,
    (_) => TextEditingController(),
  );
  SkinfoldCalculation? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.profile;
    _sex = profile.sex;
    _age = TextEditingController(text: '${profile.age}');
    _weight = TextEditingController(
      text: profile.weightKg.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(covariant SkinfoldScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.profile != widget.state.profile) {
      final profile = widget.state.profile;
      setState(() {
        _sex = profile.sex;
        _age.text = '${profile.age}';
        _weight.text = profile.weightKg.toStringAsFixed(1);
      });
    }
  }

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    for (final controller in _sites) {
      controller.dispose();
    }
    super.dispose();
  }

  double _value(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
  }

  Future<void> _calculate() async {
    setState(() {
      _error = null;
      _result = null;
    });
    try {
      final sites = _currentSites();
      final result = SkinfoldCalculator.calculate(
        sex: _sex,
        age: int.tryParse(_age.text) ?? 0,
        weightKg: _value(_weight),
        sites: sites,
      );
      setState(() => _result = result);
      await widget.state.updateBodyFat(result.sevenSite.bodyFatPercent);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message.replaceFirst('Invalid argument(s): ', ''));
    }
  }

  void _clear() {
    setState(() {
      for (final controller in _sites) {
        controller.clear();
      }
      _result = null;
      _error = null;
    });
  }

  Future<void> _saveResult() async {
    final calculation = _result;
    if (calculation == null) return;

    final now = DateTime.now();
    var selected = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Salvar avaliação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${calculation.sevenSite.bodyFatPercent.toStringAsFixed(1)}% '
                  'de gordura pela equação de 7 sítios.',
                  style: TextStyle(color: muted(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: antes do treino, mesma dips cutânea',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selected,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(now.year + 1),
                          );
                          if (date == null || !context.mounted) return;
                          setDialogState(() {
                            selected = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selected.hour,
                              selected.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_formatDate(selected)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: selected.hour,
                              minute: selected.minute,
                            ),
                          );
                          if (time == null || !context.mounted) return;
                          setDialogState(() {
                            selected = DateTime(
                              selected.year,
                              selected.month,
                              selected.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          '${selected.hour.toString().padLeft(2, '0')}:'
                          '${selected.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final record = SkinfoldRecord.create(
      sex: _sex,
      age: int.tryParse(_age.text) ?? 0,
      weightKg: _value(_weight),
      sites: _currentSites(),
      calculation: calculation,
      notes: noteController.text,
      createdAt: selected,
    );
    await widget.state.addSkinfoldRecord(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação salva no histórico.')),
    );
  }

  SkinfoldSites _currentSites() => SkinfoldSites(
        chest: _value(_sites[0]),
        axilla: _value(_sites[1]),
        triceps: _value(_sites[2]),
        subscapular: _value(_sites[3]),
        abdomen: _value(_sites[4]),
        suprailiac: _value(_sites[5]),
        thigh: _value(_sites[6]),
      );

  void _loadRecord(SkinfoldRecord record) {
    final three = record.threeSite;
    if (three == null) return;
    setState(() {
      _sex = record.sex;
      _age.text = '${record.age}';
      _weight.text = record.weightKg.toStringAsFixed(1);
      final values = record.sites.values;
      for (var i = 0; i < _sites.length; i++) {
        _sites[i].text = _formatMeasurement(values[i]);
      }
      _result = SkinfoldCalculation(
        threeSite: three,
        sevenSite: record.sevenSite,
      );
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação carregada nos campos.')),
    );
  }

  Future<void> _deleteRecord(SkinfoldRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir avaliação?'),
        content: Text(
          'A avaliação de ${_formatDate(record.createdAt)} será removida '
          'do histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.state.removeSkinfoldRecord(record.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação excluída.')),
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
          'Todas as avaliações salvas serão removidas deste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.state.clearSkinfoldHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Histórico limpo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final threeSiteIndexes = _sex == 'male'
        ? const {0, 4, 6}
        : const {2, 5, 6};
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'Dobras cutâneas',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Jackson & Pollock — 3 e 7 sítios',
          style: TextStyle(color: muted(context)),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.accessibility_new_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Preencha as dobras em milímetros. As equações calculam '
                    'densidade corporal, percentual de gordura e massas '
                    'gorda/magra.',
                    style: TextStyle(fontSize: 12, color: muted(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'male', label: Text('Masculino')),
                    ButtonSegment(value: 'female', label: Text('Feminino')),
                  ],
                  selected: {_sex},
                  onSelectionChanged: (value) =>
                      setState(() => _sex = value.first),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Idade'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Medidas (mm)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clear,
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
                for (var i = 0; i < SkinfoldCalculator.siteLabels.length; i++)
                  _SiteField(
                    controller: _sites[i],
                    label: SkinfoldCalculator.siteLabels[i],
                    isThreeSite: threeSiteIndexes.contains(i),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Meça sempre no mesmo lado do corpo, com o mesmo caliper e '
                  'com a pele levantada suavemente entre o polegar e o indicador.',
                  style: TextStyle(fontSize: 12, color: muted(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calcular'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _saveResult,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar no histórico'),
                ),
              ),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _Notice(text: _error!, isError: true),
        ],
        if (_result != null) ...[
          const SizedBox(height: 18),
          Text(
            'Resultados',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _ResultCard(
            title: 'Equação de 3 sítios',
            result: _result!.threeSite,
          ),
          const SizedBox(height: 12),
          _ResultCard(title: 'Equação de 7 sítios', result: _result!.sevenSite),
          const SizedBox(height: 16),
          const _Notice(
            text: 'Estimativa com erro típico de ±3–4%. Não substitui avaliação '
                'profissional (DEXA, BIA ou hidrodensitometria).',
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Histórico',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (widget.state.skinfoldHistory.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Limpar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.state.skinfoldHistory.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_outlined,
                    size: 34,
                    color: muted(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma avaliação salva.',
                    style: TextStyle(color: muted(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calcule as dobras e toque em “Salvar no histórico”.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: muted(context)),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (final record in widget.state.skinfoldHistory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HistoryTile(
                    record: record,
                    onLoad: () => _loadRecord(record),
                    onDelete: () => _deleteRecord(record),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SiteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isThreeSite;

  const _SiteField({
    required this.controller,
    required this.label,
    required this.isThreeSite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isThreeSite) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '3 SÍTIOS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0,0',
              suffixText: 'mm',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final SkinfoldResult? result;

  const _ResultCard({required this.title, required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              r.sitesDescription,
              style: TextStyle(fontSize: 12, color: muted(context)),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: 'Gordura',
                              value: '${r.bodyFatPercent.toStringAsFixed(1)}%',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'Densidade',
                              value: '${r.density.toStringAsFixed(3)} g/cm³',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: 'Massa gorda',
                              value: '${r.fatMassKg.toStringAsFixed(1)} kg',
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'Massa magra',
                              value: '${r.leanMassKg.toStringAsFixed(1)} kg',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _BodyFatGauge(percent: r.bodyFatPercent),
              ],
            ),
            const SizedBox(height: 14),
            Chip(
              label: Text('Classificação: ${r.category}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyFatGauge extends StatelessWidget {
  final double percent;

  const _BodyFatGauge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 74,
          height: 74,
          child: CircularProgressIndicator(
            value: (percent / 45).clamp(0.0, 1.0).toDouble(),
            strokeWidth: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'gordura',
              style: TextStyle(fontSize: 9, color: muted(context)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: muted(context))),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

const _historyMonths = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} '
      '${_historyMonths[date.month - 1]} ${date.year}';
}

String _formatSex(String sex) => sex == 'male' ? 'Masculino' : 'Feminino';

String _formatMeasurement(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

class _HistoryTile extends StatelessWidget {
  final SkinfoldRecord record;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.record,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final labels = SkinfoldCalculator.siteLabels;
    final values = record.sites.values;
    final three = record.threeSite?.bodyFatPercent;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.monitor_heart_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          '${_formatDate(record.createdAt)} · '
          '${record.sevenSite.bodyFatPercent.toStringAsFixed(1)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatSex(record.sex)} · ${record.age} anos · '
          '${record.weightKg.toStringAsFixed(1)} kg'
          '${record.notes.isEmpty ? '' : ' · ${record.notes}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Chip(
                        label: Text(
                          '${labels[i]} ${_formatMeasurement(values[i])} mm',
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Gordura 3 sítios',
                        value: three == null
                            ? '—'
                            : '${three.toStringAsFixed(1)}%',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Gordura 7 sítios',
                        value:
                            '${record.sevenSite.bodyFatPercent.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Massa gorda',
                        value: '${record.sevenSite.fatMassKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Massa magra',
                        value:
                            '${record.sevenSite.leanMassKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    'Classificação: ${record.sevenSite.category}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onLoad,
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Carregar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onDelete,
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.error,
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Excluir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final bool isError;
  const _Notice({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outlineSoft(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red.shade700 : Colors.orange.shade700,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
