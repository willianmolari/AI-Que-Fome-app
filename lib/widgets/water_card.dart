import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Contador de água do dia em formato compacto.
class WaterCard extends StatelessWidget {
  final AppState state;
  final DateTime date;

  const WaterCard({super.key, required this.state, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ml = state.waterFor(date);
    final goal = state.profile.waterGoalMl > 0
        ? state.profile.waterGoalMl
        : 2000;
    final progress = (ml / goal).clamp(0.0, 1.0).toDouble();
    final color = theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined, size: 17, color: color),
                const SizedBox(width: 6),
                Text(
                  'Água',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${ml.round()} ml',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}% de ${goal.round()} ml',
                  style: TextStyle(fontSize: 11, color: muted(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final amount in [200.0, 300.0, 500.0])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      height: 26,
                      child: ActionChip(
                        avatar: const Icon(Icons.add, size: 13),
                        label: Text(
                          '${amount.round()}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => state.addWater(date, amount),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                const Spacer(),
                if (ml > 0)
                  SizedBox(
                    height: 26,
                    child: ActionChip(
                      avatar: const Icon(Icons.remove, size: 13),
                      label: const Text('200', style: TextStyle(fontSize: 11)),
                      onPressed: () => state.addWater(date, -200),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
