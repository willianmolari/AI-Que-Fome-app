import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _weekLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

/// Gráfico dos últimos 7 dias. O seletor alterna entre calorias,
/// macronutrientes e água.
class WeeklyChart extends StatefulWidget {
  final AppState state;
  final DateTime date;

  const WeeklyChart({super.key, required this.state, required this.date});

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  String _metric = 'kcal';

  static const _metrics = [
    ('kcal', 'Calorias', Icons.local_fire_department_outlined, Color(0xFF1B7F5A)),
    ('protein', 'Proteína', Icons.fitness_center_outlined, Color(0xFF3F72AF)),
    ('carbs', 'Carbo', Icons.grain_outlined, Color(0xFFD98C3F)),
    ('fat', 'Gordura', Icons.opacity_outlined, Color(0xFF8A6BB0)),
    ('water', 'Água', Icons.water_drop_outlined, Color(0xFF2E7D9A)),
  ];

  double _valueFor(DateTime day) {
    if (_metric == 'water') return widget.state.waterFor(day);
    return widget.state.totalsFor(dateKey(day))[_metric] ?? 0;
  }

  double _goal() {
    final profile = widget.state.profile;
    return switch (_metric) {
      'kcal' => profile.goalKcal,
      'protein' => profile.goalProtein,
      'carbs' => profile.goalCarbs,
      'fat' => profile.goalFat,
      _ => profile.waterGoalMl,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metric = _metrics.firstWhere((m) => m.$1 == _metric);
    final end = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final days = List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
    final values = days.map(_valueFor).toList();
    final goal = _goal();
    final peak = values.fold<double>(0, (max, v) => v > max ? v : max);
    final scale = (peak > goal ? peak : goal) * 1.15;
    final safeScale = scale > 0 ? scale : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metric.$3, size: 18, color: metric.$4),
                const SizedBox(width: 8),
                Text(
                  'Últimos 7 dias',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Meta ${goal.round()}',
                  style: TextStyle(fontSize: 11, color: muted(context)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final option in _metrics)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(option.$2),
                        selected: _metric == option.$1,
                        onSelected: (_) => setState(() => _metric = option.$1),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              values[i] > 0 ? values[i].round().toString() : '–',
                              style: TextStyle(
                                fontSize: 9,
                                color: muted(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              height: 6 +
                                  76 * (values[i] / safeScale).clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: i == days.length - 1
                                    ? metric.$4
                                    : metric.$4.withValues(alpha: 0.35),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _weekLetters[days[i].weekday - 1],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: i == days.length - 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: muted(context),
                              ),
                            ),
                          ],
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
