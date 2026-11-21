import 'package:flutter/material.dart';

import '../models/weight_record.dart';

/// Gráfico simples da evolução do peso, com linha do peso alvo.
class WeightChart extends StatelessWidget {
  final List<WeightRecord> records;
  final double targetKg;
  final Color lineColor;
  final Color targetColor;
  final Color gridColor;
  final Color labelColor;

  const WeightChart({
    super.key,
    required this.records,
    required this.targetKg,
    required this.lineColor,
    required this.targetColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    if (records.length < 2 && targetKg <= 0) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Registre pelo menos uma pesagem para ver o gráfico.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: labelColor),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: CustomPaint(
            size: Size.infinite,
            painter: _WeightChartPainter(
              records: records,
              targetKg: targetKg,
              lineColor: lineColor,
              targetColor: targetColor,
              gridColor: gridColor,
              labelColor: labelColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.show_chart, size: 14, color: lineColor),
            const SizedBox(width: 4),
            Text('Peso atual', style: TextStyle(fontSize: 11, color: labelColor)),
            const SizedBox(width: 16),
            Container(width: 14, height: 2, color: targetColor),
            const SizedBox(width: 4),
            Text('Peso alvo', style: TextStyle(fontSize: 11, color: labelColor)),
          ],
        ),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightRecord> records;
  final double targetKg;
  final Color lineColor;
  final Color targetColor;
  final Color gridColor;
  final Color labelColor;

  _WeightChartPainter({
    required this.records,
    required this.targetKg,
    required this.lineColor,
    required this.targetColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 42.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 26.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    if (width <= 0 || height <= 0) return;

    final values = records.map((r) => r.weightKg).toList();
    if (targetKg > 0) values.add(targetKg);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final lower = (minValue - 1).floorToDouble();
    final upper = (maxValue + 1).ceilToDouble();
    final range = upper - lower == 0 ? 1.0 : upper - lower;

    double yFor(double value) =>
        top + ((upper - value) / range) * height;

    // Grade horizontal e rótulos de escala.
    for (var i = 0; i <= 2; i++) {
      final value = lower + range * i / 2;
      final y = yFor(value);
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
      _drawLabel(
        canvas,
        value.toStringAsFixed(0),
        Offset(0, y - 6),
        alignment: TextAnchor.alignRight,
        maxWidth: left - 6,
      );
    }

    // Linha tracejada do peso alvo.
    if (targetKg > 0) {
      final y = yFor(targetKg);
      _drawDashedLine(
        canvas,
        Offset(left, y),
        Offset(size.width - right, y),
        targetColor,
      );
      _drawLabel(
        canvas,
        'alvo ${targetKg.toStringAsFixed(0)}',
        Offset(left + 4, y - 14),
      );
    }

    final positions = <Offset>[];
    for (var i = 0; i < records.length; i++) {
      final x = records.length == 1
          ? left + width / 2
          : left + (width * i / (records.length - 1));
      positions.add(Offset(x, yFor(records[i].weightKg)));
    }

    if (positions.length > 1) {
      canvas.drawLine(
        positions.first,
        positions.last,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      for (var i = 1; i < positions.length; i++) {
        canvas.drawLine(
          positions[i - 1],
          positions[i],
          Paint()
            ..color = lineColor
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    for (final point in positions) {
      canvas.drawCircle(point, 3.6, Paint()..color = lineColor);
      canvas.drawCircle(
        point,
        1.6,
        Paint()..color = labelColor.withValues(alpha: 0.9),
      );
    }

    if (records.isNotEmpty) {
      _drawLabel(
        canvas,
        _shortDate(records.first.date),
        Offset(left - 8, size.height - 18),
      );
      _drawLabel(
        canvas,
        _shortDate(records.last.date),
        Offset(size.width - right - 44, size.height - 18),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    const dash = 6.0;
    const gap = 5.0;
    final distance = (end.dx - start.dx).abs();
    var x = start.dx;
    while (x < end.dx) {
      final segmentEnd = (x + dash).clamp(x, end.dx).toDouble();
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(segmentEnd, start.dy),
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
      x += dash + gap;
    }
    if (distance <= dash) return;
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    TextAnchor alignment = TextAnchor.alignLeft,
    double maxWidth = 200,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 10),
      ),
      textAlign: alignment == TextAnchor.alignRight
          ? TextAlign.right
          : TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  static String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.records != records ||
      oldDelegate.targetKg != targetKg ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.targetColor != targetColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor;
}

enum TextAnchor { alignLeft, alignRight }
