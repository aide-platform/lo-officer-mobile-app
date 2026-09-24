import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight donut chart for dashboard segments (no chart package).
class DashDonutChart extends StatelessWidget {
  const DashDonutChart({
    super.key,
    required this.segments,
    this.size = 120,
    this.centerHint,
  });

  final Map<String, int> segments;
  final double size;
  final String? centerHint;

  static const _colors = <Color>[
    Color(0xFF0055B8),
    Color(0xFF128807),
    Color(0xFFE87820),
    Color(0xFF7C3AED),
    Color(0xFF0284C7),
    Color(0xFFEA580C),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = segments.entries
        .where((e) => e.value > 0)
        .toList();
    final total = entries.fold<int>(0, (a, e) => a + e.value);
    if (total == 0) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No data')),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(
              values: entries.map((e) => e.value.toDouble()).toList(),
              colors: List.generate(
                entries.length,
                (i) => _colors[i % _colors.length],
              ),
            ),
            child: centerHint == null
                ? null
                : Center(
                    child: Text(
                      centerHint!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${entries[i].key} (${entries[i].value})',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = radius * 0.42;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

/// Horizontal bar row for org-type / VIP rankings.
class DashBarList extends StatelessWidget {
  const DashBarList({super.key, required this.entries});

  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No data');
    }
    final max = entries.map((e) => e.value).fold<int>(0, math.max);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: entries.take(8).map((e) {
        final frac = max == 0 ? 0.0 : e.value / max;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(e.key)),
                  Text(
                    '${e.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  color: primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
