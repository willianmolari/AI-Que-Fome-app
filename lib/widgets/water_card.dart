import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Contador de água do dia, com atalhos de quantidade.
class WaterCard extends StatelessWidget {
  final AppState state;
  final DateTime date;

  const WaterCard({super.key, required this.state, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ml = state.waterFor(date);
    final goal = state.profile.waterGoalMl > 0 ? state.profile.waterGoalMl : 2000;
    final progress = (ml / goal).clamp(0.0, 1.0).toDouble();
    final color = theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined, size: 19, color: color),
                const SizedBox(width: 8),
                Text(
                  'Água',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Meta ${goal.round()} ml',
                  style: TextStyle(fontSize: 11, color: muted(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: color.withValues(alpha: 0.12),
                        color: color,
                      ),
                    ),
                    Icon(Icons.local_drink_outlined, size: 22, color: color),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${ml.round()}',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ml',
                            style: TextStyle(
                              fontSize: 13,
                              color: muted(context),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        ml >= goal
                            ? 'Meta do dia concluída!'
                            : '${(goal - ml).round()} ml para a meta',
                        style: TextStyle(fontSize: 11, color: muted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final amount in [200.0, 300.0, 500.0])
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 15),
                    label: Text('${amount.round()} ml'),
                    onPressed: () => state.addWater(date, amount),
                    visualDensity: VisualDensity.compact,
                  ),
                if (ml > 0)
                  ActionChip(
                    avatar: const Icon(Icons.remove, size: 15),
                    label: const Text('200 ml'),
                    onPressed: () => state.addWater(date, -200),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
