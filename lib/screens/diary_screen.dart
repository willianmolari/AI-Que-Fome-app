import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/macro_bar.dart';
import '../widgets/portion_editor.dart';
import '../widgets/water_card.dart';
import '../widgets/week_calendar.dart';
import '../widgets/weekly_chart.dart';

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const _weekdays = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String formatDatePt(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  return '$weekday, ${date.day} de ${_months[date.month - 1]}';
}

const _mealIcons = <String, IconData>{
  'cafe': Icons.coffee_outlined,
  'almoco': Icons.lunch_dining_outlined,
  'jantar': Icons.dinner_dining_outlined,
  'lanches': Icons.cookie_outlined,
};

const _mealColors = <String, Color>{
  'cafe': Color(0xFFFF9F0A),
  'almoco': Color(0xFF007AFF),
  'jantar': Color(0xFF5E5CE6),
  'lanches': Color(0xFFAF52DE),
};

class DiaryScreen extends StatelessWidget {
  final AppState state;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  /// Recebe a chave da refeição onde os alimentos serão adicionados.
  final ValueChanged<String> onAddFood;

  const DiaryScreen({
    super.key,
    required this.state,
    required this.date,
    required this.onDateChanged,
    required this.onAddFood,
  });

  Future<void> _editEntry(BuildContext context, DiaryEntry entry) async {
    final edited = await showPortionEditor(
      context,
      PortionData(
        name: entry.foodName,
        amount: entry.grams,
        unit: entry.unit,
        kcal: entry.kcal,
        protein: entry.protein,
        carbs: entry.carbs,
        fat: entry.fat,
      ),
      title: 'Editar alimento',
    );
    if (edited == null || !context.mounted) return;
    await state.updateEntry(
      entry.copyWith(
        foodName: edited.name,
        grams: edited.amount,
        unit: edited.unit,
        kcal: edited.kcal,
        protein: edited.protein,
        carbs: edited.carbs,
        fat: edited.fat,
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${edited.name} atualizado.')),
    );
  }

  Future<void> _copyMeal(BuildContext context, String mealKey) async {
    String source = 'previous';
    String targetMeal = mealKey;
    String targetWhen = 'today';
    bool replace = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.content_copy_outlined),
              const SizedBox(width: 10),
              const Expanded(child: Text('Copiar refeição')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Origem',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: source,
                  decoration: const InputDecoration(labelText: 'Copiar de'),
                  items: const [
                    DropdownMenuItem(
                      value: 'previous',
                      child: Text('Dia anterior (mesma refeição)'),
                    ),
                    DropdownMenuItem(
                      value: 'current',
                      child: Text('Este dia (mesma refeição)'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => source = value ?? 'previous'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Destino',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: targetMeal,
                  decoration: const InputDecoration(labelText: 'Refeição'),
                  items: AppState.meals
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.$1,
                          child: Text(m.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => targetMeal = value ?? mealKey),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: targetWhen,
                  decoration: const InputDecoration(labelText: 'Data'),
                  items: const [
                    DropdownMenuItem(value: 'today', child: Text('Este dia')),
                    DropdownMenuItem(
                      value: 'tomorrow',
                      child: Text('Próximo dia'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => targetWhen = value ?? 'today'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: replace,
                  onChanged: (value) =>
                      setState(() => replace = value ?? false),
                  title: const Text('Substituir itens existentes'),
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
              child: const Text('Copiar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final fromDate = source == 'previous'
        ? dateKey(date.subtract(const Duration(days: 1)))
        : dateKey(date);
    final toDate = targetWhen == 'tomorrow'
        ? dateKey(date.add(const Duration(days: 1)))
        : dateKey(date);

    final count = await state.copyMeal(
      fromDate: fromDate,
      fromMeal: mealKey,
      toDate: toDate,
      toMeal: targetMeal,
      replace: replace,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'A refeição de origem está vazia.'
              : '$count ${count == 1 ? 'alimento copiado' : 'alimentos copiados'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = dateKey(date);
    final totals = state.totalsFor(key);
    final goal = state.profile;
    final entries = state.entriesFor(key);
    final isToday = dateKey(DateTime.now()) == key;

    final daysWithEntries = state.entries.map((e) => e.date).toSet();
    final kcalByDay = <String, double>{};
    for (final entry in state.entries) {
      kcalByDay[entry.date] = (kcalByDay[entry.date] ?? 0) + entry.kcal;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meu diário',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDatePt(date),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (!isToday)
                IconButton.filledTonal(
                  tooltip: 'Voltar para hoje',
                  onPressed: () => onDateChanged(DateTime.now()),
                  icon: const Icon(Icons.today_outlined),
                ),
            ],
          ),
        ),
        WeekCalendar(
          selected: date,
          daysWithEntries: daysWithEntries,
          kcalByDay: kcalByDay,
          goalKcal: goal.goalKcal,
          onDateChanged: onDateChanged,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
            children: [
              _SummaryCard(totals: totals, goal: goal),
              const SizedBox(height: 14),
              WaterCard(state: state, date: date),
              const SizedBox(height: 14),
              WeeklyChart(state: state, date: date),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      'Refeições',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${entries.length} ${entries.length == 1 ? 'item' : 'itens'}',
                      style: TextStyle(fontSize: 12, color: muted(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...AppState.meals.map(
                (meal) => _MealCard(
                  mealKey: meal.$1,
                  mealLabel: meal.$2,
                  entries: entries.where((e) => e.meal == meal.$1).toList(),
                  onAdd: () => onAddFood(meal.$1),
                  onEdit: (entry) => _editEntry(context, entry),
                  onCopy: () => _copyMeal(context, meal.$1),
                  onDelete: (id) => state.removeEntry(id),
                ),
              ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Toque em “+” em uma refeição para buscar e adicionar '
                    'vários alimentos de uma vez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted(context),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, double> totals;
  final UserProfile goal;

  const _SummaryCard({required this.totals, required this.goal});

  @override
  Widget build(BuildContext context) {
    final kcal = totals['kcal'] ?? 0;
    final percent = goal.goalKcal > 0 ? kcal / goal.goalKcal : 0.0;
    final remaining = goal.goalKcal - kcal;
    final clamped = percent.clamp(0.0, 1.0).toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A58C2), Color(0xFF2E8BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALORIAS CONSUMIDAS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${kcal.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'kcal',
                            style: TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Meta de ${goal.goalKcal.round()} kcal',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          remaining >= 0
                              ? 'Restam ${remaining.round()} kcal'
                              : '${(-remaining).round()} kcal acima da meta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: clamped,
                        strokeWidth: 9,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percent * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'da meta',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                MacroBar(
                  label: 'Proteína',
                  value: totals['protein'] ?? 0,
                  goal: goal.goalProtein,
                  color: const Color(0xFF007AFF),
                ),
                const SizedBox(height: 12),
                MacroBar(
                  label: 'Carboidratos',
                  value: totals['carbs'] ?? 0,
                  goal: goal.goalCarbs,
                  color: const Color(0xFFD98C3F),
                ),
                const SizedBox(height: 12),
                MacroBar(
                  label: 'Gordura',
                  value: totals['fat'] ?? 0,
                  goal: goal.goalFat,
                  color: const Color(0xFF8A6BB0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String mealKey;
  final String mealLabel;
  final List<DiaryEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<DiaryEntry> onEdit;
  final VoidCallback onCopy;
  final ValueChanged<String> onDelete;

  const _MealCard({
    required this.mealKey,
    required this.mealLabel,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<double>(0, (sum, e) => sum + e.kcal);
    final color = _mealColors[mealKey] ?? Theme.of(context).colorScheme.primary;
    final icon = _mealIcons[mealKey] ?? Icons.restaurant_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entries.length} ${entries.length == 1 ? 'alimento' : 'alimentos'}',
                        style: TextStyle(fontSize: 11, color: muted(context)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${kcal.round()} kcal',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                IconButton.filledTonal(
                  tooltip: 'Copiar refeição',
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy_outlined, size: 18),
                ),
                IconButton.filledTonal(
                  tooltip: 'Buscar e adicionar alimentos',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Buscar alimento'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    ...entries.map(
                      (entry) => Dismissible(
                        key: ValueKey(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => onDelete(entry.id),
                        child: ListTile(
                          onTap: () => onEdit(entry),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            radius: 4,
                            backgroundColor: color,
                          ),
                          title: Text(
                            entry.foodName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${entry.grams.toStringAsFixed(0)} ${entry.unit} • '
                            'P ${entry.protein.round()} • C ${entry.carbs.round()} • '
                            'G ${entry.fat.round()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${entry.kcal.round()} kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: muted(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
