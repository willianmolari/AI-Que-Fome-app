import 'package:flutter/material.dart';

/// Três pontinhos discretos que evocam a barra de janelas do macOS.
class MacWindowDots extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;

  const MacWindowDots({
    super.key,
    this.size = 9,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFF5F57),
      Color(0xFFFEBC2E),
      Color(0xFF28C840),
    ];
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final color in colors)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
