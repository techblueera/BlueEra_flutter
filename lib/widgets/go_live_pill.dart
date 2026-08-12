import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Shared frosted-glass "Go live" toggle pill — the single Go Live UI, used by
/// every "Me" business/profile home top bar and by [ProfileTopBar] (rider, cab,
/// self-employed).
///
/// The visual is identical everywhere — frosted white pill, hairline `#C9CDD5`
/// border, a 30×18 toggle track (ON = primary, OFF = white) with a 14×14 thumb.
/// Only the *state source* and *tap handler* differ per screen, so those are
/// injected. A couple of screens omit the soft outer drop shadow ([showShadow])
/// and one or two use a different [label]; the reactive screens flip
/// [isUpdating] to show a spinner while the status call is in flight.
///
/// **It blinks.** The pill pulses its border + glow continuously so it's the
/// one thing that catches the eye in the top bar — the attention that used to
/// sit on `ReferEarnPill`, which is now static so the two don't compete. The
/// blink pauses while [isUpdating] (a pulsing spinner reads as a glitch) and
/// can be turned off per-placement with [blink].
///
/// **The clock.** Schedule-driven placements (every business dashboard + the
/// professional/consultant one) pass [onScheduleTap], which renders a small
/// clock button immediately to the LEFT of the pill. That button — not the
/// pill — is where visiting hours are set and edited, so the pill itself is
/// left free to be a plain on/off switch. Placements whose go-live is a direct
/// online/offline flip (rider, self-employed) omit it and are unchanged.
class GoLivePill extends StatefulWidget {
  const GoLivePill({
    super.key,
    required this.value,
    required this.onTap,
    this.isUpdating = false,
    this.label,
    this.showShadow = true,
    this.blink = true,
    this.onScheduleTap,
  });

  /// Whether the shop is currently live (toggle ON). The screen owns this.
  final bool value;

  /// Tap handler — flips the live state. Disabled while [isUpdating].
  final VoidCallback onTap;

  /// Opens the visiting-hours control. When non-null a clock button is drawn
  /// just left of the pill; null (the default) draws the pill alone.
  final VoidCallback? onScheduleTap;

  /// Shows a spinner in place of the toggle while a status update is pending.
  final bool isUpdating;

  /// Pill label. Defaults to `AppStrings.goLive.tr`.
  final String? label;

  /// Whether to paint the soft outer drop shadow behind the pill.
  final bool showShadow;

  /// Whether the attention blink runs. On by default — pass `false` for a
  /// placement where a constantly animating pill would be noise.
  final bool blink;

  @override
  State<GoLivePill> createState() => _GoLivePillState();
}

class _GoLivePillState extends State<GoLivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  /// Resting border — the hairline the pill has always had. The blink lerps
  /// from here toward [_blinkAccent] and back.
  static const Color _restBorder = Color(0xFFC9CDD5);
  static const Color _blinkAccent = AppColors.primaryColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant GoLivePill old) {
    super.didUpdateWidget(old);
    // `blink` or `isUpdating` may flip at any time (e.g. the status call starts).
    if (widget.blink != old.blink || widget.isUpdating != old.isUpdating) {
      _syncAnimation();
    }
  }

  /// Run the loop only when it should be visible — an animation ticking behind
  /// a spinner or a disabled blink is wasted frames on every screen with a
  /// top bar.
  void _syncAnimation() {
    final shouldRun = widget.blink && !widget.isUpdating;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = GestureDetector(
      onTap: widget.isUpdating ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          // 0 → 1 → 0 loop; pinned at 0 (resting look) when not blinking.
          final t = (widget.blink && !widget.isUpdating) ? _pulse.value : 0.0;
          return _buildPill(t);
        },
      ),
    );

    if (widget.onScheduleTap == null) return pill;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _scheduleButton(),
        SizedBox(width: SizeConfig.size6),
        pill,
      ],
    );
  }

  /// Clock button that opens the visiting-hours control. Deliberately static —
  /// it sits beside a blinking pill, and two competing animations in one corner
  /// of the header read as noise.
  Widget _scheduleButton() {
    return GestureDetector(
      onTap: widget.isUpdating ? null : widget.onScheduleTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (widget.showShadow)
              const BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 3,
                offset: Offset(0, -1),
              ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            // Sized to match the notification / menu circle buttons beside it
            // (36 box, 20 icon) — a smaller circle in the same row reads as a
            // different class of control rather than a sibling.
            child: Container(
              height: SizeConfig.size36,
              width: SizeConfig.size36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _restBorder, width: 1),
              ),
              child: Icon(
                Icons.schedule_rounded,
                size: 20,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(double t) {
    final borderColor = Color.lerp(_restBorder, _blinkAccent, t)!;

    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10,
            vertical: SizeConfig.size6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1 + 0.6 * t),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                widget.label ?? AppStrings.goLive.tr,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                // Warms toward the accent on each pulse so the label blinks
                // with the border rather than sitting flat inside it.
                color: Color.lerp(AppColors.secondaryTextColor, _blinkAccent, t),
              ),
              SizedBox(width: SizeConfig.size6),
              if (widget.isUpdating)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                )
              else
                _toggle(),
            ],
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Pulsing glow — the actual "blink". Grows and brightens with t.
          if (t > 0)
            BoxShadow(
              color: _blinkAccent.withValues(alpha: 0.15 + 0.35 * t),
              blurRadius: 6 + 12 * t,
              spreadRadius: 0.5 + 1.5 * t,
            ),
          if (widget.showShadow)
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
        ],
      ),
      child: pill,
    );
  }

  Widget _toggle() {
    return Container(
      width: 30,
      height: 18,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: widget.value ? AppColors.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondaryTextColor.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        alignment:
            widget.value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            color: widget.value ? Colors.white : AppColors.secondaryTextColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
