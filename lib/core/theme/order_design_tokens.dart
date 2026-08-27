import 'dart:ui' show FontFeature;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// The order-flow design system (guide §3).
///
/// "Modern and professional" is a **system**, not a polish pass: one spacing
/// grid, one radius set, four type roles, six semantic colour roles. Every
/// order surface — chat card, checkout stepper, sheets, dialogs — reads from
/// here, so eleven screens look like one product.
///
/// These map onto the app's existing palette rather than introducing a second
/// one. What they add is **consistency** and, more importantly, *meaning*:
/// `OrderTone.warning` is not "amber", it is "money claimed, not confirmed".
class OrderSpace {
  /// The 8pt grid. No 7s, no 13s.
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}

class OrderRadius {
  /// The order card itself.
  static const double card = 16;

  /// Payment block, rider block, code box — anything nested in a card.
  static const double inner = 12;

  /// Chips, status dots, buttons.
  static const double pill = 999;
}

class OrderElevation {
  /// **Zero for cards.** Flat + hairline reads modern; shadows read 2016.
  static const double card = 0;

  /// Bottom sheets and dialogs only.
  static const double sheet = 8;
}

/// Four type roles. Nothing else.
class OrderType {
  /// ① the order-number line.
  static const TextStyle title =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  /// ② the banner, ④ detail body.
  static const TextStyle body =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400);

  /// Chips, countdowns, footnote.
  static const TextStyle label =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  /// Pickup code, UTR, ₹ amounts.
  ///
  /// **Tabular figures on every number that ticks.** A countdown that jitters
  /// because `1` is narrower than `8` looks broken even when it is right.
  static TextStyle mono(
          {double size = 20, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Any figure that changes in place — amounts, counters, countdowns.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];
}

/// Semantic colour roles — **never literal**. Meaning first, hue second.
enum OrderTone {
  /// Waiting on the other party. Muted text, no accent.
  neutral,

  /// **Waiting on you.** Accent border + filled primary button.
  accent,

  /// Money claimed, not confirmed. Always paired with an icon **and** a word.
  warning,

  /// Verified / completed. A green tick inline, never a full green card.
  success,

  /// Destructive action only. Text button, never a filled red button.
  danger,

  /// Terminal. Desaturated surface, reason still fully legible.
  muted,
}

extension OrderToneStyle on OrderTone {
  Color get color {
    switch (this) {
      case OrderTone.neutral:
        return AppColors.secondaryTextColor;
      case OrderTone.accent:
        return AppColors.primaryColor;
      case OrderTone.warning:
        return const Color(0xFFA96A00);
      case OrderTone.success:
        return const Color(0xFF1B9E4B);
      case OrderTone.danger:
        return const Color(0xFFD03A34);
      case OrderTone.muted:
        return AppColors.grayText;
    }
  }

  /// Tinted fill for a block in this tone.
  Color get surface {
    switch (this) {
      case OrderTone.warning:
        return const Color(0xFFFFF8E6);
      case OrderTone.muted:
        return const Color(0xFFF4F5F7);
      case OrderTone.neutral:
        return const Color(0xFFF7F8FA);
      default:
        return color.withValues(alpha: 0.07);
    }
  }

  Color get border {
    switch (this) {
      case OrderTone.warning:
        return const Color(0xFFE9A100);
      case OrderTone.neutral:
      case OrderTone.muted:
        return AppColors.greyE5;
      default:
        return color.withValues(alpha: 0.35);
    }
  }

  /// **Never encode meaning in colour alone.** Amber always ships with an icon
  /// and a word — for colour-blind users, and for glare on a shop counter at
  /// noon.
  IconData get icon {
    switch (this) {
      case OrderTone.neutral:
        return Icons.hourglass_top;
      case OrderTone.accent:
        return Icons.bolt;
      case OrderTone.warning:
        return Icons.warning_amber_rounded;
      case OrderTone.success:
        return Icons.check_circle;
      case OrderTone.danger:
        return Icons.error_outline;
      case OrderTone.muted:
        return Icons.cancel_outlined;
    }
  }
}

/// Motion budget (guide §3.4). Anything not listed here does not animate.
class OrderMotion {
  /// ② banner text swap.
  static const Duration bannerFade = Duration(milliseconds: 150);

  /// ⑤ a button appears or disappears.
  static const Duration actionShift = Duration(milliseconds: 200);

  /// ③ a zone appears.
  static const Duration zoneExpand = Duration(milliseconds: 250);

  /// Terminal desaturation.
  static const Duration terminal = Duration(milliseconds: 300);

  /// The radar ring easing to a new radius.
  static const Duration radar = Duration(milliseconds: 600);

  static const Curve curve = Curves.easeOutCubic;
}

// ─────────────────────────────────────────────────────────────────────────
//  Components built once, used everywhere (guide §3.3)
// ─────────────────────────────────────────────────────────────────────────

/// 8dp dot + label. **The dot pulses only while waiting on the other party** —
/// a permanently pulsing card is noise, not information.
class OrderStatusDot extends StatefulWidget {
  final OrderTone tone;
  final bool pulse;
  final double size;

  const OrderStatusDot({
    super.key,
    required this.tone,
    this.pulse = false,
    this.size = 8,
  });

  @override
  State<OrderStatusDot> createState() => _OrderStatusDotState();
}

class _OrderStatusDotState extends State<OrderStatusDot>
    with SingleTickerProviderStateMixin {
  /// Created only while the dot actually pulses. It stays null on the vast
  /// majority of cards — a resting dot needs no ticker, and a `late final`
  /// here would be *constructed inside `dispose()`* on every non-pulsing dot,
  /// which throws while the element tree is being torn down.
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _start();
  }

  void _start() {
    _c ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _c!.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant OrderStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse == oldWidget.pulse) return;
    if (widget.pulse) {
      _start();
    } else {
      _c?.stop();
      _c?.value = 1;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.tone.color,
        shape: BoxShape.circle,
      ),
    );
    final c = _c;
    if (!widget.pulse || c == null) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(c),
      child: dot,
    );
  }
}

/// Label / amount row. Amber background when paid ≠ due — the comparison the
/// shop must make before tapping "Payment received" has to be effortless.
class OrderMoneyRow extends StatelessWidget {
  final String label;
  final num? amount;
  final OrderTone tone;
  final bool emphasise;

  const OrderMoneyRow({
    super.key,
    required this.label,
    required this.amount,
    this.tone = OrderTone.neutral,
    this.emphasise = false,
  });

  static String money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OrderSpace.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: OrderType.label.copyWith(
              color: emphasise ? AppColors.mainTextColor : AppColors.grayText,
              fontWeight: emphasise ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            amount == null ? '—' : '₹${money(amount!)}',
            style: OrderType.mono(
              size: emphasise ? 18 : 15,
              weight: emphasise ? FontWeight.w800 : FontWeight.w700,
            ).copyWith(
                color: tone == OrderTone.neutral
                    ? AppColors.mainTextColor
                    : tone.color),
          ),
        ],
      ),
    );
  }
}

/// Shimmer of the card's zones. Used on a cold load — **never** a centred
/// spinner in a chat list, which reads as the whole list hanging.
class OrderCardSkeleton extends StatefulWidget {
  final int lines;
  const OrderCardSkeleton({super.key, this.lines = 3});

  @override
  State<OrderCardSkeleton> createState() => _OrderCardSkeletonState();
}

class _OrderCardSkeletonState extends State<OrderCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.75).animate(_c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.lines, (i) {
          return Container(
            height: 12,
            width: i.isEven ? double.infinity : 160,
            margin: const EdgeInsets.only(bottom: OrderSpace.s),
            decoration: BoxDecoration(
              color: AppColors.greyE5,
              borderRadius: BorderRadius.circular(OrderRadius.pill),
            ),
          );
        }),
      ),
    );
  }
}

/// The hairline that separates two zones of a card.
class OrderZoneDivider extends StatelessWidget {
  const OrderZoneDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.mainTextColor.withValues(alpha: 0.08),
      );
}
