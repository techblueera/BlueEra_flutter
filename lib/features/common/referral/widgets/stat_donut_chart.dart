import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One slice on the [StatDonutChart] — a colored arc whose angular
/// size is proportional to [value] relative to the sum of all slices'
/// values in the chart.
class DonutSegment {
  final Color color;
  final num value;
  const DonutSegment({required this.color, required this.value});
}

/// Donut / ring chart used by the Statics tab. Renders the supplied
/// [segments] as proportional arcs around a rounded track, with an
/// optional [center] widget (typically a big rupee value + label).
///
/// Looks intentional, but only uses [CustomPaint] + plain Material
/// widgets — no third-party chart library needed.
class StatDonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final Widget? center;
  final double size;
  final double strokeWidth;
  final Color trackColor;

  const StatDonutChart({
    super.key,
    required this.segments,
    this.center,
    this.size = 110,
    this.strokeWidth = 8,
    this.trackColor = const Color(0xFFEDEFF4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(
              segments: segments,
              strokeWidth: strokeWidth,
              trackColor: trackColor,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final Color trackColor;

  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Underlying track so empty arcs still read as a ring.
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = segments.fold<num>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    // Start at the top (−90°) and walk clockwise. A tiny gap between
    // segments stops adjacent colors from blending into a single arc.
    const startOffset = -math.pi / 2;
    const gap = 0.04; // ~2.3° gap
    double cursor = startOffset;
    for (final s in segments) {
      final sweep = (s.value / total) * (math.pi * 2);
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      // Subtract the gap from the sweep, but never go below 1% of the
      // intended arc so single-segment "tiny" values still show.
      final effectiveSweep =
          (sweep - gap).clamp(sweep * 0.01, math.pi * 2).toDouble();
      canvas.drawArc(rect, cursor, effectiveSweep, false, paint);
      cursor += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor;
}
