import 'package:flutter/material.dart';

import '../models/body_measure_record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Seção de circunferências com fita, no padrão ISAK, com histórico local.
class BodyMeasuresSection extends StatefulWidget {
  final AppState state;

  const BodyMeasuresSection({super.key, required this.state});

  @override
  State<BodyMeasuresSection> createState() => _BodyMeasuresSectionState();
}

class _BodyMeasuresSectionState extends State<BodyMeasuresSection> {
  late final Map<String, TextEditingController> _controllers;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final site in bodyMeasureSites) site.$1: TextEditingController(),
    };
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  double _value(String key) {
    return double.tryParse(_controllers[key]!.text.replaceAll(',', '.')) ?? 0;
  }

  Map<String, double> _currentValues() => {
    for (final site in bodyMeasureSites) site.$1: _value(site.$1),
  };

  Future<void> _save() async {
    final values = _currentValues();
    if (!values.values.any((v) => v > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha ao menos uma medida em cm.')),
      );
      return;
    }

    final now = DateTime.now();
    var selected = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final noteController = TextEditingController(text: _notes.text);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Salvar medidas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${values.values.where((v) => v > 0).length} medida(s) '
                  'serão salvas no histórico.',
                  style: TextStyle(color: muted(context)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: mesma fita, duas repetições',
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
                        label: Text(formatMeasureDate(selected)),
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
    await widget.state.addBodyMeasure(
      BodyMeasureRecord.create(
        values: values,
        notes: noteController.text,
        createdAt: selected,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medidas salvas no histórico.')),
    );
  }

  void _load(BodyMeasureRecord record) {
    setState(() {
      for (final site in bodyMeasureSites) {
        final value = record.values[site.$1] ?? 0;
        _controllers[site.$1]!.text = value == 0
            ? ''
            : value.toStringAsFixed(1).replaceAll('.', ',');
      }
      _notes.text = record.notes;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medidas carregadas nos campos.')),
    );
  }

  Future<void> _delete(BodyMeasureRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir medidas?'),
        content: Text(
          'As medidas de ${formatMeasureDate(record.createdAt)} serão '
          'removidas do histórico.',
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
    await widget.state.removeBodyMeasure(record.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Medidas excluídas.')));
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text(
          'Todas as medidas salvas serão removidas deste dispositivo.',
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
    await widget.state.clearBodyMeasures();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Histórico de medidas limpo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          'Medidas com fita (ISAK)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Circunferências em centímetros — toque para recolher',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meça com fita flexível, sem comprimir a pele, sempre no '
                  'mesmo ponto e com a mesma posição (flexionado/relaxado).',
                  style: TextStyle(fontSize: 12, color: muted(context)),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 420;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final site in bodyMeasureSites)
                          SizedBox(
                            width: twoColumns
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth,
                            child: TextField(
                              controller: _controllers[site.$1],
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: site.$2,
                                suffixText: 'cm',
                                isDense: true,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: fita nova, duas medições',
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar medidas no histórico'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Histórico',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.state.bodyMeasures.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Limpar'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.state.bodyMeasures.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Nenhuma medida salva. Preencha os campos acima e '
                          'toque em “Salvar medidas no histórico”.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: muted(context)),
                        ),
                      ),
                    ),
                  )
                else
                  for (final record in widget.state.bodyMeasures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HistoryTile(
                        record: record,
                        onLoad: () => _load(record),
                        onDelete: () => _delete(record),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final BodyMeasureRecord record;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.record,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final filled = record.values.entries.where((e) => e.value > 0).toList();
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          formatMeasureDate(record.createdAt),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${filled.length} medida(s)'
          '${record.notes.isEmpty ? '' : ' · ${record.notes}'}',
          style: TextStyle(fontSize: 11, color: muted(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in filled)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            bodyMeasureLabel(entry.key),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(1).replaceAll('.', ',')} cm',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onLoad,
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: const Text('Carregar'),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Excluir',
                        style: TextStyle(color: theme.colorScheme.error),
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
