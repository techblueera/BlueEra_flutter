import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Countdown to a **server-authored** deadline (`lifecycle.deadlines.*`).
///
/// Two rules this widget exists to enforce (guide §3.1 / §6):
///
///  1. It is driven from the deadline the server sent, never from
///     `createdAt + constant`. That mismatch — server one hour, app twenty-four
///     — is what let a shop and a customer disagree about the same order for
///     twenty-three hours.
///  2. When the clock hits zero it shows a neutral *"Checking…"* and asks the
///     card to refresh **once**. It never flips the card to expired itself;
///     only the server's next payload may do that.
class OrderDeadlineCountdown extends StatefulWidget {
  /// The deadline. A null value renders nothing — "no clock running for this
  /// step" is not the same as "expired".
  final DateTime? deadline;

  /// Prefix shown before the remaining time, e.g. "Confirm within".
  final String label;

  /// Shown once the deadline passes, while the refresh is in flight.
  final String elapsedLabel;

  /// Called exactly once when the countdown reaches zero.
  final VoidCallback? onElapsed;

  final Color? color;

  /// Gentle pulse — used on the owner's side of a `placed` order so a new
  /// order is hard to miss.
  final bool pulse;

  const OrderDeadlineCountdown({
    super.key,
    required this.deadline,
    this.label = '',
    this.elapsedLabel = 'Checking…',
    this.onElapsed,
    this.color,
    this.pulse = false,
  });

  @override
  State<OrderDeadlineCountdown> createState() => _OrderDeadlineCountdownState();
}

class _OrderDeadlineCountdownState extends State<OrderDeadlineCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _elapsedFired = false;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
    }
    _sync();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
  }

  @override
  void didUpdateWidget(covariant OrderDeadlineCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh deadline (the shop extended the prep ETA) restarts the clock and
    // re-arms the single elapsed callback.
    if (oldWidget.deadline != widget.deadline) {
      _elapsedFired = false;
      _sync();
    }
  }

  void _sync() {
    final target = widget.deadline;
    if (target == null) {
      if (_remaining != Duration.zero && mounted) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }
    final left = target.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
    }
    if (left.isNegative && !_elapsedFired) {
      _elapsedFired = true;
      _timer?.cancel();
      widget.onElapsed?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (widget.deadline == null) return const SizedBox.shrink();

    final isElapsed = _remaining == Duration.zero;
    final color = isElapsed
        ? AppColors.grayText
        : (widget.color ??
            (_remaining.inMinutes < 5 ? Colors.deepOrange : AppColors.grayText));

    final text = isElapsed
        ? widget.elapsedLabel
        : (widget.label.isEmpty
            ? OrderDeadlineCountdownFormat.remaining(_remaining)
            : '${widget.label} ${OrderDeadlineCountdownFormat.remaining(_remaining)}');

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isElapsed ? Icons.sync : Icons.schedule, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: CustomText(
            text,
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w600,
            color: color,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final pulse = _pulseController;
    if (pulse == null || isElapsed) return child;
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.45).animate(
        CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
      ),
      child: child,
    );
  }
}

/// How a remaining duration is written out.
///
/// Pulled out of the widget so it can be exercised directly: `1h 04m` above an
/// hour, `4:31` below it, `< 1 min` in the last minute, and a clamped `0:00`
/// once the deadline passes — a countdown must never render a negative time.
class OrderDeadlineCountdownFormat {
  const OrderDeadlineCountdownFormat._();

  static String remaining(Duration d) {
    if (d.inSeconds <= 0) return '0:00';
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${h}h ${m}m';
    }
    if (d.inSeconds < 60) return '< 1 min';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
