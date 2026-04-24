import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/user_subscription_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Animated, interactive card showing the user's currently-live plan.
///
/// Single source of truth for the trial-active (`status == 'authenticated'`)
/// and the paid-active (`status == 'active'`) states. Used by both
/// [SinglePlanSubscriptionView] (subscription bottom sheet / drawer page)
/// and [SubscriptionStatusView] (per-Me-screen statistics tab) so the live
/// plan chrome stays byte-for-byte identical across surfaces.
///
/// Visual treatment:
///   - One-shot fade + slide + scale entry reveal (TweenAnimationBuilder).
///   - Continuously breathing premium icon at the top.
///   - Pulsing live dot inside the status pill.
///   - Days-remaining count-up + gradient progress bar with a shimmer band.
///   - Always-on diagonal sheen sweeping across the entire card.
///   - Press-to-scale + light haptic on tap.
///   - Tap to toggle the expanded billing details panel.
///
/// Other lifecycle states (offer / paused / cancelled) are NOT handled
/// here — the calling surfaces decide what to render in those cases.
class SubscriptionLivePlanCard extends StatefulWidget {
  final UserSubscription userSub;

  const SubscriptionLivePlanCard({super.key, required this.userSub});

  @override
  State<SubscriptionLivePlanCard> createState() =>
      _SubscriptionLivePlanCardState();
}

class _SubscriptionLivePlanCardState extends State<SubscriptionLivePlanCard>
    with TickerProviderStateMixin {
  late final SubscriptionController _controller;

  // _pulseController feeds both the breathing premium icon and the live
  // status dot. _shimmerController sweeps the diagonal sheen across the
  // card and the highlight band across the days-remaining bar.
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  bool _expanded = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = getOrPut(() => SubscriptionController());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userSub = widget.userSub;
    switch (userSub.status) {
      case 'authenticated':
        return _buildTrial(userSub);
      case 'active':
        return _buildActive(userSub);
      default:
        // Defensive — callers should only mount this widget for live states.
        return const SizedBox.shrink();
    }
  }

  // ─── Variant builders ────────────────────────────────────────────────

  Widget _buildActive(UserSubscription userSub) {
    final plan = userSub.subscriptionPlanData;
    final priceText =
        '${AppConstants.rupeeSymbol}${plan.amount != null ? (plan.amount! / 100).toStringAsFixed(0) : '0'}';
    final periodText = (plan.period ?? '').capitalizeFirst ?? '';

    // The backend doesn't tell us when the current cycle started, so we
    // approximate the bar by assuming a fresh cycle of length [_cycleDaysFor]
    // and compute days-remaining from validUpto. Calendar-day math (not
    // raw Duration.inDays) so a plan ending tomorrow at 08:16 reads as
    // "1 day left" instead of "0".
    final endDate = _toDate(userSub.validUpto);
    final totalDays = _cycleDaysFor(plan);
    final daysRemaining = endDate != null
        ? _calendarDaysBetween(DateTime.now(), endDate).clamp(0, totalDays)
        : 0;

    const liveGreen = Color(0xFF22C55E);

    return _verticalBlock(
      card: _animatedEntry(
        child: _interactiveCard(
          onTap: () => setState(() => _expanded = !_expanded),
          child: _withSheen(_planCardChrome(
            plan: plan,
            tagText: 'Active',
            tagLeading: _pulsingDot(liveGreen),
            priceText: priceText,
            periodText: periodText,
            bodyText:
                'Your subscription is active. Enjoy uninterrupted access to all premium features.',
            extraBlocks: [
              SizedBox(height: SizeConfig.paddingM),
              _daysRemainingBlock(
                daysRemaining: daysRemaining,
                totalDays: totalDays,
                accent: liveGreen,
                label: 'Time remaining',
              ),
              SizedBox(height: SizeConfig.paddingM),
              _validUntilRow(formatISO8601Date(userSub.validUpto)),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _activeExtraDetails(userSub)
                    : const SizedBox(width: double.infinity),
              ),
              _expandToggle(),
            ],
            perks: plan.perks ?? const [],
          )),
        ),
      ),
      // cta: _cancelButton(userSub),
    );
  }

  Widget _buildTrial(UserSubscription userSub) {
    final plan = userSub.subscriptionPlanData;

    // Trial progress is computed from the real start/end timestamps. Falls
    // back to a 3-day window if the API didn't include them. Uses
    // calendar-day math (not Duration.inDays) so a 3-day trial whose end
    // timestamp is one millisecond earlier in the day than the start
    // doesn't read as "2 days" — see _calendarDaysBetween for the why.
    final start = _toDate(userSub.trialStart);
    final end = _toDate(userSub.trialEnd);
    int totalDays = 3;
    int daysRemaining = 3;
    if (start != null && end != null) {
      final diff = _calendarDaysBetween(start, end);
      if (diff > 0) totalDays = diff;
      daysRemaining =
          _calendarDaysBetween(DateTime.now(), end).clamp(0, totalDays);
    }

    return _verticalBlock(
      card: _animatedEntry(
        child: _interactiveCard(
          onTap: () => setState(() => _expanded = !_expanded),
          child: _withSheen(_planCardChrome(
            plan: plan,
            tagText: 'Trial Active',
            tagLeading: _pulsingDot(AppColors.primaryColor),
            priceText: 'Active',
            periodText: 'Free Trial',
            bodyText:
                'Congratulations! Enjoy your free trial — explore every premium feature.',
            extraBlocks: [
              SizedBox(height: SizeConfig.paddingM),
              _daysRemainingBlock(
                daysRemaining: daysRemaining,
                totalDays: totalDays,
                accent: AppColors.primaryColor,
                label: 'Trial progress',
              ),
              SizedBox(height: SizeConfig.paddingM),
              _datesRow(
                startLabel: 'Start',
                startDate: formatISO8601Date(userSub.trialStart),
                endLabel: 'End',
                endDate: formatISO8601Date(userSub.trialEnd),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _trialExtraDetails(userSub)
                    : const SizedBox(width: double.infinity),
              ),
              _expandToggle(),
            ],
            perks: plan.perks ?? const [],
          )),
        ),
      ),
    );
  }

  /// Stretches a card + optional CTA into a vertical column with the same
  /// spacing as the standalone subscription page.
  ///
  /// Wrapped in a [SingleChildScrollView] because the card is often hosted
  /// inside a fixed-height parent (e.g. a dashboard slot) — without this
  /// an expanded trial card can overflow on small devices.
  Widget _verticalBlock({required Widget card, Widget? cta}) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          if (cta != null) ...[
            SizedBox(height: SizeConfig.paddingL),
            cta,
          ],
        ],
      ),
    );
  }

  // ignore: unused_element  — kept for the commented-out cta: hook above.
  Widget _cancelButton(UserSubscription userSub) {
    return CustomBtn(
      width: double.infinity,
      title: 'Cancel Subscription',
      bgColor: AppColors.white,
      borderColor: AppColors.red,
      textColor: AppColors.red,
      radius: 10.0,
      onTap: () {
        _controller.cancelSubscriptionController(params: {
          'subscriptionId': userSub.subscriptionId,
          'cancel_at_cycle_end': true,
        });
      },
    );
  }

  // ─── Animation / interaction primitives ──────────────────────────────

  /// Auto-playing fade + slide + scale entry reveal. Uses
  /// [TweenAnimationBuilder] so the animation runs the first time the card
  /// mounts without needing a controller or post-frame trigger.
  Widget _animatedEntry({required Widget child, double slide = 60}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, t, ch) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * slide),
            child: Transform.scale(
              scale: 0.90 + 0.10 * t,
              child: ch,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Press-down scale + light haptic on tap. Makes the card feel tactile
  /// instead of like a static panel.
  Widget _interactiveCard({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  /// Continuous diagonal sheen sweeping across the card. A rotated white
  /// gradient band rides on [_shimmerController] and translates from off-
  /// left to off-right every cycle, keeping the surface alive at all times.
  Widget _withSheen(Widget card) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          card,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      final w = constraints.maxWidth;
                      final t = _shimmerController.value;
                      final dx = -w + t * (w * 2);
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            top: -24,
                            bottom: -24,
                            left: dx,
                            width: w * 0.55,
                            child: Transform.rotate(
                              angle: -0.38,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.22),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Breathing live indicator. Solid centre dot + expanding/fading halo.
  Widget _pulsingDot(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value;
        final ringSize = 12.0 + t * 8.0;
        final ringOpacity = (1 - t) * 0.55;
        return SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: ringOpacity),
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Days-remaining count-up + linear progress bar with a continuous
  /// shimmer band sweeping across it.
  Widget _daysRemainingBlock({
    required int daysRemaining,
    required int totalDays,
    required Color accent,
    required String label,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final animatedDays = (daysRemaining * t).round();
        final fraction = totalDays == 0
            ? 0.0
            : (animatedDays / totalDays).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  label,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$animatedDays',
                        style: TextStyle(
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: ' / $totalDays days left',
                        style: TextStyle(
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            SizedBox(
              height: 10,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: AppColors.greyE5.withValues(alpha: 0.6),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fraction,
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withValues(alpha: 0.55),
                                accent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          final s = _shimmerController.value;
                          return FractionallySizedBox(
                            widthFactor: 0.35,
                            heightFactor: 1,
                            alignment: Alignment(s * 2.4 - 1.2, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _expandToggle() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              _expanded ? 'Hide details' : 'Show details',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size4),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
          Expanded(
            child: CustomText(
              value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _validUntilRow(String date) {
    return Row(
      children: [
        Icon(Icons.event_available_outlined,
            size: 16, color: AppColors.primaryColor),
        SizedBox(width: SizeConfig.size8),
        CustomText(
          'Valid until $date',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }

  Widget _datesRow({
    required String startLabel,
    required String startDate,
    required String endLabel,
    required String endDate,
  }) {
    Widget cell(String label, String date) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size2),
            CustomText(
              date,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        cell(startLabel, startDate),
        cell(endLabel, endDate),
      ],
    );
  }

  Widget _activeExtraDetails(UserSubscription userSub) {
    final plan = userSub.subscriptionPlanData;
    final period = (plan.period ?? '').capitalizeFirst ?? '';
    final intervalRaw = plan.interval?.toString() ?? '';
    final cycle = '$intervalRaw $period'.trim();
    final subId = userSub.subscriptionId.toString();
    return Container(
      margin: EdgeInsets.only(top: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Status', 'Active · Auto renewing'),
          if (cycle.isNotEmpty) _detailRow('Billing cycle', cycle),
          _detailRow('Next billing', formatISO8601Date(userSub.validUpto)),
          if (subId.isNotEmpty) _detailRow('Subscription ID', subId),
        ],
      ),
    );
  }

  Widget _trialExtraDetails(UserSubscription userSub) {
    final subId = userSub.subscriptionId.toString();
    return Container(
      margin: EdgeInsets.only(top: SizeConfig.size8),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Plan', 'Free Trial'),
          _detailRow('Trial start', formatISO8601Date(userSub.trialStart)),
          _detailRow('Trial end', formatISO8601Date(userSub.trialEnd)),
          if (subId.isNotEmpty) _detailRow('Subscription ID', subId),
        ],
      ),
    );
  }

  /// Best-effort cycle length so the active-state progress bar has a total
  /// to fill against. Inferred from the plan period × interval since the
  /// backend doesn't return a cycle-start timestamp.
  int _cycleDaysFor(SubscriptionPlanData plan) {
    final period = (plan.period ?? '').toLowerCase();
    int interval = plan.interval ?? 1;
    if (interval < 1) interval = 1;
    switch (period) {
      case 'year':
        return 365 * interval;
      case 'month':
        return 30 * interval;
      case 'week':
        return 7 * interval;
      case 'day':
        return interval;
      default:
        return 365;
    }
  }

  /// Tolerant date parser — the API has historically returned both ISO
  /// strings and serialised DateTimes for trial/validUpto fields.
  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  /// Whole-day distance between two timestamps, ignoring the time-of-day
  /// component. Required because [Duration.inDays] truncates the raw
  /// millisecond delta — so a trial spanning Apr 9 08:16:46 → Apr 12
  /// 08:16:45 (one millisecond shy of 3 × 24h) reads as 2 days, not 3.
  /// Comparing date-only values gives the calendar-correct answer.
  /// Both args are normalised to local time first; if [from] is in the
  /// future relative to [to], the result is negative.
  int _calendarDaysBetween(DateTime from, DateTime to) {
    final fromLocal = from.toLocal();
    final toLocal = to.toLocal();
    final fromDate =
        DateTime(fromLocal.year, fromLocal.month, fromLocal.day);
    final toDate = DateTime(toLocal.year, toLocal.month, toLocal.day);
    return toDate.difference(fromDate).inDays;
  }

  // ─── Card chrome ─────────────────────────────────────────────────────
  // Self-contained chrome for the live plan card. Mirrors the shape of
  // [SinglePlanSubscriptionView]'s `_planCard` (background image, premium
  // icon, status pill, big price/period, body text, perks list) but with
  // the breathing icon and pill-leading dot hooks the live card needs.

  Widget _planCardChrome({
    required SubscriptionPlanData plan,
    required String tagText,
    Widget? tagLeading,
    required String priceText,
    required String periodText,
    required String bodyText,
    List<Widget> extraBlocks = const [],
    required List<String> perks,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppImageAssets.subscriptionBgCard,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPremiumIcon(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (plan.mode?.toLowerCase() == 'test') ...[
                          _testBadge(),
                          SizedBox(width: SizeConfig.size8),
                        ],
                        _tagPill(tagText, leading: tagLeading),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$priceText / ',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                      TextSpan(
                        text: periodText,
                        style: TextStyle(
                          fontSize: SizeConfig.extraLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size12),
                CustomText(
                  bodyText,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                  maxLines: 4,
                ),
                ...extraBlocks,
                SizedBox(height: SizeConfig.paddingM),
                Container(height: 1, color: AppColors.greyE5),
                SizedBox(height: SizeConfig.paddingM),
                ...perks.map(_perkItem),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Always-on breathing scale + halo on the premium icon.
  Widget _buildPremiumIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value;
        final scale = 0.94 + 0.10 * t;
        final glow = 0.20 + 0.35 * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: glow),
                  blurRadius: 14 + 8 * t,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: LocalAssets(
                    imagePath: AppImageAssets.planTagIcon,
                    height: 22,
                    width: 22,
                    boxFix: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _testBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: CustomText(
        'TEST',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );
  }

  Widget _tagPill(String text, {Widget? leading}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1000, sigmaY: 1000),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size15,
            vertical: SizeConfig.size5,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.white),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                SizedBox(width: SizeConfig.size6),
              ],
              CustomText(
                text,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _perkItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
