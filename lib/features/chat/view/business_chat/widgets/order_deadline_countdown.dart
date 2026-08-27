import 'dart:async';

import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:flutter/material.dart';

/// **One second-ticker for the whole app**, not one per card (guide §8.1).
///
/// A chat screen can hold a dozen order cards; a dozen `Timer.periodic`s all
/// rebuilding on their own phase is both wasteful and visibly jittery. This is
/// a single timer that only runs while something is listening to it.
class OrderClock extends ChangeNotifier {
  OrderClock._();
  static final OrderClock instance = OrderClock._();

  Timer? _timer;
  DateTime now = DateTime.now();

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      now = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// Countdown to a **server-authored** deadline (`lifecycle.deadlines.*`),
/// rendered as a pill chip.
///
/// The rules it exists to enforce (guide §8.1):
///
/// | Condition | Render |
/// |---|---|
/// | `deadline == null` | **nothing** — null means "no clock for this step", not expired |
/// | > 1h | `2h 14m`, muted |
/// | 10–60m | `18m`, normal |
/// | < 10m | `4m 12s`, accent, ticking, tabular figures |
/// | hits 0 | *"Checking…"* + **one** `/actions` |
/// | past 0 | *"12m over"*, amber — **never flip the card to terminal yourself** |
class OrderDeadlineCountdown extends StatefulWidget {
  /// The deadline. Null renders nothing.
  final DateTime? deadline;

  /// Prefix shown before the remaining time, e.g. "Confirm within".
  final String label;

  /// Shown for the moment after zero, while the single refresh is in flight.
  final String elapsedLabel;

  /// Called exactly once when the countdown reaches zero.
  final VoidCallback? onElapsed;

  /// Gentle pulse — used on the shop's side of a `placed` order so a new order
  /// is hard to miss. Never on the customer's side: they are not the one being
  /// waited on.
  final bool pulse;

  /// Past-deadline wording. A prep overrun says "12m over" and nobody is
  /// cancelled for being slow (guide §6.4).
  final String overdueSuffix;

  const OrderDeadlineCountdown({
    super.key,
    required this.deadline,
    this.label = '',
    this.elapsedLabel = 'Checking…',
    this.onElapsed,
    this.pulse = false,
    this.overdueSuffix = 'over',
  });

  @override
  State<OrderDeadlineCountdown> createState() => _OrderDeadlineCountdownState();
}

class _OrderDeadlineCountdownState extends State<OrderDeadlineCountdown> {
  final OrderClock _clock = OrderClock.instance;
  bool _elapsedFired = false;
  DateTime? _firedAt;

  /// How long "Checking…" holds before the chip admits the deadline is simply
  /// past. Long enough for the refresh to land, short enough not to lie.
  static const Duration _checkingWindow = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _clock.addListener(_tick);
    // Fire on the first frame if the deadline is already behind us.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void didUpdateWidget(covariant OrderDeadlineCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh deadline (the shop extended the prep ETA) restarts the clock and
    // re-arms the single elapsed callback.
    if (oldWidget.deadline != widget.deadline) {
      _elapsedFired = false;
      _firedAt = null;
    }
  }

  @override
  void dispose() {
    _clock.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    final target = widget.deadline;
    if (target == null) return;
    final left = target.difference(DateTime.now());
    if (left.isNegative && !_elapsedFired) {
      _elapsedFired = true;
      _firedAt = DateTime.now();
      // One refresh, then render whatever the server sends back. Never a
      // client-side terminal state.
      widget.onElapsed?.call();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.deadline;
    if (target == null) return const SizedBox.shrink();

    final left = target.difference(DateTime.now());

    if (left.isNegative) {
      final firedAt = _firedAt;
      final stillChecking = firedAt != null &&
          DateTime.now().difference(firedAt) < _checkingWindow;
      if (stillChecking) {
        return _chip(
          icon: Icons.sync,
          tone: OrderTone.muted,
          text: widget.elapsedLabel,
        );
      }
      // Past the deadline and the server has not moved the card on. Say so
      // plainly, counting UP — and do not invent a cancellation.
      return _chip(
        icon: Icons.error_outline,
        tone: OrderTone.warning,
        text:
            '${OrderCountdownFormat.overdue(left.abs())} ${widget.overdueSuffix}',
      );
    }

    final urgent = left.inMinutes < 10;
    final tone = urgent ? OrderTone.accent : OrderTone.muted;
    final text = widget.label.isEmpty
        ? OrderCountdownFormat.remaining(left)
        : '${widget.label} ${OrderCountdownFormat.remaining(left)}';

    return _chip(
      icon: Icons.schedule,
      tone: tone,
      text: text,
      pulse: widget.pulse && urgent,
      bold: urgent,
    );
  }

  Widget _chip({
    required IconData icon,
    required OrderTone tone,
    required String text,
    bool pulse = false,
    bool bold = false,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: OrderSpace.s, vertical: OrderSpace.xs),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(OrderRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone.color),
          const SizedBox(width: OrderSpace.xs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OrderType.label.copyWith(
                color: tone.color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                // Tabular so the row does not jitter as digits change width.
                fontFeatures: OrderType.tabular,
              ),
            ),
          ),
        ],
      ),
    );

    if (!pulse) return chip;
    return _Pulse(child: chip);
  }
}

class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.45)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}

/// How a remaining duration is written out (guide §8.1).
///
/// Pulled out of the widget so it can be exercised directly: `2h 14m` above an
/// hour, `18m` between ten and sixty minutes, `4m 12s` in the last ten so the
/// seconds are visible, and a clamped `0m 00s` once the deadline passes — a
/// countdown must never render a negative time.
class OrderCountdownFormat {
  const OrderCountdownFormat._();

  static String remaining(Duration d) {
    if (d.inSeconds <= 0) return '0m 00s';
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${h}h ${m}m';
    }
    if (d.inMinutes >= 10) return '${d.inMinutes}m';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }

  /// "12m over" / "1h 04m over" — counting up, past the deadline.
  static String overdue(Duration d) {
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${h}h ${m}m';
    }
    final m = d.inMinutes;
    if (m < 1) return '<1m';
    return '${m}m';
  }
}

/// Kept so the existing regression test's import keeps resolving.
typedef OrderDeadlineCountdownFormat = OrderCountdownFormat;
