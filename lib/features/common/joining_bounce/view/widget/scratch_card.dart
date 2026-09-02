/// The scratch-card surface shared by both joining-bonus popups.
///
/// Public (not private to one dialog file) because BOTH the signed-in
/// [ClaimBonusDialog] and the guest [GuestClaimBonusDialog] scratch the same
/// card — only what sits under it differs. The confetti burst and the cover
/// painter stay private here; nothing outside this file needs them.
library;

import 'dart:math';

import 'package:flutter/material.dart';

/// Lays [child] (the reward) under a blue scratchable cover. As the user drags
/// across it, circular holes are punched into the cover (via [BlendMode.clear])
/// revealing the child. Once [threshold] of the card is scratched (default
/// 40%), [onRevealed] fires and the remaining cover fades away. Pass [revealed]
/// back so the cover stays gone after the parent rebuilds.
class ScratchCard extends StatefulWidget {
  final Widget child;

  /// Fires once the scratched area crosses [threshold]. The parent decides what
  /// happens (reveal the reward, or — for guests — just enable a CTA).
  final VoidCallback onRevealed;

  /// When true the cover fades away (full reveal). Parent-controlled, so a guest
  /// card can keep the cover on screen while still reacting to [onRevealed].
  final bool revealed;

  /// Fraction of the card that must be scratched before [onRevealed] fires.
  ///
  /// Measured on the coarse cell grid below, which counts a cell the moment the
  /// brush touches it — so the number reads HIGHER than the area actually
  /// cleared. 0.4 here lands at roughly a third of the surface scrubbed, which
  /// is the "more than 30%" feel both bonus cards are tuned to; raising it to a
  /// literal 0.3 would open the card noticeably sooner, not later.
  final double threshold;

  const ScratchCard({
    super.key,
    required this.child,
    required this.onRevealed,
    required this.revealed,
    this.threshold = 0.4,
  });

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard> {
  /// Scratch path — `null` marks a break between separate drags.
  final List<Offset?> _points = [];

  /// Coarse grid of touched cells, used to estimate the scratched fraction.
  final Set<int> _cells = {};
  static const int _cols = 14;
  static const int _rows = 9;

  Size _size = Size.zero;

  void _addPoint(Offset p) {
    if (widget.revealed) return;
    _points.add(p);
    if (_size.width > 0 && _size.height > 0) {
      final cx = (p.dx / _size.width * _cols).floor().clamp(0, _cols - 1);
      final cy = (p.dy / _size.height * _rows).floor().clamp(0, _rows - 1);
      _cells.add(cy * _cols + cx);
    }
    setState(() {});
    if (_cells.length >= (_cols * _rows * widget.threshold)) {
      widget.onRevealed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          widget.child,
          // Confetti — clipped to the card (so it stays inside the primary
          // border) and falling from the card's top once revealed.
          if (widget.revealed)
            const Positioned.fill(
              child: IgnorePointer(child: _Confetti()),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: widget.revealed,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: widget.revealed ? 0 : 1,
                child: LayoutBuilder(
                  builder: (context, c) {
                    _size = Size(c.maxWidth, c.maxHeight);
                    return GestureDetector(
                      onPanStart: (d) {
                        _points.add(null);
                        _addPoint(d.localPosition);
                      },
                      onPanUpdate: (d) => _addPoint(d.localPosition),
                      onTapDown: (d) => _addPoint(d.localPosition),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _ScratchCoverPainter(points: List.of(_points)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the blue scratch cover (gradient + faint coin pattern + a gift badge)
/// and erases circular holes along [points] so the reward shows through.
class _ScratchCoverPainter extends CustomPainter {
  final List<Offset?> points;
  static const double brush = 22;

  _ScratchCoverPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Isolate the cover in its own layer so BlendMode.clear erases only the
    // cover (revealing the child below) instead of punching through to white.
    canvas.saveLayer(rect, Paint());
    _paintCover(canvas, size);

    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = brush * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;

    Offset? prev;
    for (final p in points) {
      if (p == null) {
        prev = null;
        continue;
      }
      canvas.drawCircle(p, brush, dot);
      if (prev != null) canvas.drawLine(prev, p, clear);
      prev = p;
    }
    canvas.restore();
  }

  void _paintCover(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7BF0), Color(0xFF1A66D6)],
        ).createShader(rect),
    );

    // Faint coin pattern.
    final coin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.10);
    const step = 52.0;
    for (double y = 24; y < size.height; y += step) {
      for (double x = 24; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 11, coin);
      }
    }

    // Centre gift badge — dark disc + a simple white gift drawn with strokes
    // (no icon font, so it survives release icon tree-shaking).
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 42, Paint()..color = const Color(0xFF0E3E7E));
    final w = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Box body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, 8), width: 38, height: 26),
        const Radius.circular(4),
      ),
      w,
    );
    // Lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(0, -8), width: 46, height: 13),
        const Radius.circular(4),
      ),
      w,
    );
    // Ribbon.
    canvas.drawLine(c.translate(0, -14), c.translate(0, 21), w);
    // Bow.
    canvas.drawCircle(c.translate(-7, -18), 5, w);
    canvas.drawCircle(c.translate(7, -18), 5, w);
  }

  @override
  bool shouldRepaint(_ScratchCoverPainter old) =>
      old.points.length != points.length;
}

// ─────────────────────────────────────────────────────────────────────────
// Confetti
// ─────────────────────────────────────────────────────────────────────────

/// One-shot confetti burst — mostly rains down from the top, with a small
/// secondary burst rising from the bottom. Everything fades out (nothing stays
/// on screen). Played once when the scratch card is revealed.
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    const colors = [
      Color(0xFFEF4444),
      Color(0xFF2D7BF0),
      Color(0xFF34C77B),
      Color(0xFFFFC93C),
      Color(0xFF8B5CF6),
      Color(0xFFFF7A00),
    ];
    // Main burst — falls from the TOP through and off the bottom (more of
    // these, so most of the confetti rains down from above).
    final falling = List.generate(70, (_) {
      return _Particle(
        x0: rnd.nextDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.5,
        delay: rnd.nextDouble() * 0.25,
        color: colors[rnd.nextInt(colors.length)],
        w: 4 + rnd.nextDouble() * 6,
        h: 7 + rnd.nextDouble() * 8,
        rot0: rnd.nextDouble() * pi * 2,
        rotSpeed: (rnd.nextDouble() - 0.5) * 5,
      );
    });
    // A smaller burst rising up from the BOTTOM, fading as it climbs — just a
    // little to complement the main top-down rain.
    final rising = List.generate(18, (_) {
      return _Particle(
        x0: rnd.nextDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.4,
        delay: rnd.nextDouble() * 0.2,
        color: colors[rnd.nextInt(colors.length)],
        w: 4 + rnd.nextDouble() * 5,
        h: 6 + rnd.nextDouble() * 7,
        rot0: rnd.nextDouble() * pi * 2,
        rotSpeed: (rnd.nextDouble() - 0.5) * 4,
        fromBottom: true,
      );
    });
    _particles = [...falling, ...rising];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  final double x0; // 0..1 start x
  final double drift; // horizontal drift over life
  final double delay; // 0..1 staggered start
  final Color color;
  final double w;
  final double h;
  final double rot0;
  final double rotSpeed;

  /// When true the particle rises up from the bottom (the smaller secondary
  /// burst) instead of falling from the top. Both fade out — nothing stays on
  /// screen after the burst.
  final bool fromBottom;

  const _Particle({
    required this.x0,
    required this.drift,
    required this.delay,
    required this.color,
    required this.w,
    required this.h,
    required this.rot0,
    required this.rotSpeed,
    this.fromBottom = false,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final life = (t - p.delay) / (1 - p.delay);
      if (life <= 0 || life > 1) continue;
      final double x, y, angle, opacity;
      if (p.fromBottom) {
        // Rise from just below the bottom up to partway (about half height),
        // fading out as it climbs — a little accent, nothing stays.
        x = (p.x0 + p.drift * life) * size.width;
        y = (1.05 - 0.55 * life) * size.height;
        angle = p.rot0 + p.rotSpeed * life * pi * 2;
        opacity =
            (life < 0.7 ? 1.0 : (1 - (life - 0.7) / 0.3)).clamp(0.0, 1.0);
      } else {
        // Fall from above the top, through and off the bottom.
        x = (p.x0 + p.drift * life) * size.width;
        y = (-0.1 + 1.3 * life) * size.height;
        angle = p.rot0 + p.rotSpeed * life * pi * 2;
        opacity =
            (life < 0.8 ? 1.0 : (1 - (life - 0.8) / 0.2)).clamp(0.0, 1.0);
      }
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
