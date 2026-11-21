import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

const List<String> _weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const List<String> _months = [
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

/// Calendário semanal compacto, com marcadores de dias registrados e barras
/// de calorias. O clique no mês abre uma grade completa.
class WeekCalendar extends StatelessWidget {
  final DateTime selected;
  final Set<String> daysWithEntries;
  final Map<String, double> kcalByDay;
  final double goalKcal;
  final ValueChanged<DateTime> onDateChanged;

  const WeekCalendar({
    super.key,
    required this.selected,
    required this.daysWithEntries,
    required this.kcalByDay,
    required this.goalKcal,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = selected.subtract(Duration(days: selected.weekday - 1));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Semana anterior',
                onPressed: () =>
                    onDateChanged(selected.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => _openMonthPicker(context),
                  child: Text(
                    '${_months[selected.month - 1]} ${selected.year}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Próxima semana',
                onPressed: () =>
                    onDateChanged(selected.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _DayCell(
                    date: days[i],
                    label: _weekDays[i],
                    selected: dateKey(days[i]) == dateKey(selected),
                    hasEntry: daysWithEntries.contains(dateKey(days[i])),
                    kcal: kcalByDay[dateKey(days[i])] ?? 0,
                    goalKcal: goalKcal,
                    color: color,
                    onTap: () => onDateChanged(days[i]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMonthPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MonthPickerSheet(
        initial: selected,
        daysWithEntries: daysWithEntries,
        kcalByDay: kcalByDay,
        goalKcal: goalKcal,
      ),
    );
    if (picked != null) onDateChanged(picked);
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final String label;
  final bool selected;
  final bool hasEntry;
  final double kcal;
  final double goalKcal;
  final Color color;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.label,
    required this.selected,
    required this.hasEntry,
    required this.kcal,
    required this.goalKcal,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = dateKey(date) == dateKey(DateTime.now());
    final ratio = goalKcal > 0 ? (kcal / goalKcal).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            if (label.isNotEmpty) ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? color : muted(context),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
            ],
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: isToday && !selected
                    ? Border.all(color: color, width: 1.5)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected || isToday
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : isToday
                          ? color
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasEntry ? color : Colors.transparent,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: color.withValues(
                  alpha: kcal <= 0 ? 0.10 : 0.30 + 0.70 * ratio,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initial;
  final Set<String> daysWithEntries;
  final Map<String, double> kcalByDay;
  final double goalKcal;

  const _MonthPickerSheet({
    required this.initial,
    required this.daysWithEntries,
    required this.kcalByDay,
    required this.goalKcal,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initial.year, widget.initial.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final leading = _month.weekday - 1;
    final cells = <Widget?>[
      ...List<Widget?>.filled(leading, null),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(_month.year, _month.month, day),
          label: '',
          selected: dateKey(DateTime(_month.year, _month.month, day)) ==
              dateKey(widget.initial),
          hasEntry: widget.daysWithEntries
              .contains(dateKey(DateTime(_month.year, _month.month, day))),
          kcal: widget.kcalByDay[
                  dateKey(DateTime(_month.year, _month.month, day))] ??
              0,
          goalKcal: widget.goalKcal,
          color: color,
          onTap: () => Navigator.pop(
            context,
            DateTime(_month.year, _month.month, day),
          ),
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final rows = <TableRow>[
      for (var i = 0; i < cells.length; i += 7)
        TableRow(
          children: [
            for (var j = 0; j < 7; j++) cells[i + j] ?? const SizedBox.shrink(),
          ],
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final day in _weekDays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: muted(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Table(children: rows),
        ],
      ),
    );
  }
}
