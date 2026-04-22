import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/user_subscription_model.dart';
import 'package:BlueEra/features/subscription/view/single_plan_subscription_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Persistent peek bottom sheet that sits above the host screen's bottom
/// navigation. Only the peak header is visible in the collapsed state; tapping
/// the header (or dragging it up) expands the sheet to reveal the
/// [SinglePlanSubscriptionView].
class SubscriptionDraggableSheet extends StatefulWidget {
  /// Extra space reserved beneath the sheet (e.g. for a bottom navigation bar
  /// living in a parent widget).
  final double bottomPadding;

  const SubscriptionDraggableSheet({
    super.key,
    this.bottomPadding = 0,
  });

  @override
  State<SubscriptionDraggableSheet> createState() =>
      _SubscriptionDraggableSheetState();
}

class _SubscriptionDraggableSheetState
    extends State<SubscriptionDraggableSheet> {
  // Header height in the two states. When expanded the title button is
  // hidden, so the header collapses to just the peak + a small bar strip.
  static const double _collapsedHeaderHeight = 110.0;
  static const double _expandedHeaderHeight = 35.0;

  bool _isExpanded = false;

  // Shared with SinglePlanSubscriptionView via getOrPut, so the header can
  // react to subscription state without waiting for the body to mount.
  final SubscriptionController _subController =
      getOrPut(() => SubscriptionController());

  @override
  void initState() {
    super.initState();
    _subController.userCurrentPlanApi();
    _subController.subscriptionPlansGetApi();
  }

  void _toggleSheet() {
    setState(() => _isExpanded = !_isExpanded);
  }

  /// Returns the title pill that sits in the collapsed peek header. The
  /// content depends on the user's current subscription state, mirroring
  /// the same status switch [SinglePlanSubscriptionView] uses for the body.
  Widget _buildHeaderTitle() {
    final list = _subController.currentPlansList;

    if (list.isEmpty) {
      return _trialCtaPill();
    }

    final userSub = list.first;
    switch (userSub.status) {
      case 'authenticated':
        return _trialActivePill(userSub);
      case 'active':
        return _activePill(userSub);
      case 'paused':
      case 'halted':
        return _ctaPill(
          title: userSub.status == 'paused'
              ? 'Plan Paused — Recharge Now'
              : 'Plan Expired — Recharge Now',
        );
      case 'cancelled':
        return _ctaPill(
          title: 'Resubscribe Now'
          // title: userSub.isTrial
          //     ? 'Go Live in Just ₹5'
          //     : 'Resubscribe Now',
        );
      default:
        return _trialCtaPill();
    }
  }

  /// Phone-width scaling helper — mirrors `_scaled` in
  /// [SinglePlanSubscriptionView] so the peek-header CTA and the expanded
  /// body CTA render at the same sizes across devices.
  double _scaled(double base) {
    if (SizeConfig.isTablet) return base * 1.25;
    final factor = (SizeConfig.screenWidth / 390.0).clamp(0.85, 1.15);
    return base * factor;
  }

  /// Picks the plan to show numbers for. Prefers an `active: true` plan,
  /// falls back to the first. Matches `_pickPlan` in
  /// [SinglePlanSubscriptionView] so the header and body stay in sync.
  SubscriptionPlanData? _pickPlan() {
    final list = _subController.subscriptionPlanDetailsNewModel.value.data;
    if (list == null || list.isEmpty) return null;
    for (final plan in list) {
      if (plan.active == true) return plan;
    }
    return list.first;
  }

  String _perkTypeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Items';
    final lower = type.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  /// Free-trial CTA pill shown in the collapsed peek header. Same two-line
  /// copy + typography as [SinglePlanSubscriptionView._trialCtaButton] so
  /// the pill and the expanded body CTA read as one continuous surface.
  Widget _trialCtaPill() {
    final plan = _pickPlan();
    final perkValue = plan?.perkValue ?? 0;
    final perkBonus = plan?.perkBonus ?? 0;
    final totalUnits = perkValue + perkBonus;
    final perkLabel = _perkTypeLabel(plan?.perkType);

    return Container(
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CustomText(
              'Start Free  —  Claim My $totalUnits $perkLabel',
              fontSize: _scaled(16),
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: SizeConfig.size2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CustomText(
              'Verify identity with ${AppConstants.rupeeSymbol}5  —  refunded within seconds.',
              fontSize: _scaled(12),
              fontWeight: FontWeight.w400,
              color: AppColors.yellow6C,
            ),
          ),
        ],
      ),
    );
  }

  /// Solid primary pill used for "do something" states (offer / recharge).
  Widget _ctaPill({required String title}) {
    return Container(
      padding: EdgeInsets.all(_scaled(14)),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomText(
          title,
          fontSize: _scaled(16),
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Trial-active info pill: shows "Trial active" with the days remaining.
  Widget _trialActivePill(UserSubscription userSub) {
    final daysLeft = _daysLeft(userSub.trialEnd);
    final daysText = daysLeft == null
        ? 'Trial active'
        : (daysLeft <= 0
            ? 'Trial ending today'
            : 'Trial active • $daysLeft day${daysLeft == 1 ? '' : 's'} left');
    return Container(
      padding: EdgeInsets.all(_scaled(12)),
      decoration: BoxDecoration(
        color: AppColors.green39.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.green39, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded,
              size: _scaled(20), color: AppColors.green39),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: CustomText(
              daysText,
              fontSize: _scaled(14),
              color: AppColors.green39,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Paid-active info pill: shows "Premium Active • Valid until <date>".
  Widget _activePill(UserSubscription userSub) {
    final tier = userSub.subscriptionPlanData.tier?.isNotEmpty == true
        ? userSub.subscriptionPlanData.tier!
        : 'Premium';
    final validDate = formatISO8601Date(userSub.validUpto);
    return Container(
      padding: EdgeInsets.all(_scaled(12)),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.primaryColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: _scaled(22), color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  '$tier Active',
                  fontSize: _scaled(14),
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
                CustomText(
                  'Valid until $validDate',
                  fontSize: _scaled(12),
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Days remaining between now and an ISO-8601 string. Returns null if
  /// the date is missing/unparseable.
  int? _daysLeft(String iso) {
    if (iso.isEmpty) return null;
    final end = DateTime.tryParse(iso);
    if (end == null) return null;
    final now = DateTime.now();
    return end.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // The body is allowed to grow up to ~70% of the visible area, but if the
    // SinglePlanSubscriptionView's natural content is shorter the
    // shrink-wrapping ListView below will collapse to that smaller height.
    final maxBodyHeight = (mq.size.height -
            mq.padding.top -
            mq.padding.bottom -
            widget.bottomPadding -
            _expandedHeaderHeight) *
        0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleSheet,
              child: _buildHeader(),
            ),
            AnimatedClipRect(
              isExpanded: _isExpanded,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              // Give the child a bounded height so the pinned-CTA layout
              // inside SinglePlanSubscriptionView can use Expanded + a
              // scrolling card without vertical-unbounded errors.
              // Dynamic-height body: caps at maxBodyHeight but shrinks to
              // the natural content size when the view is shorter, so short
              // states (trial-active, loading, etc.) don't leave a big
              // empty pane below the card.
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBodyHeight),
                child: SizedBox(
                  width: double.infinity,
                  child: ColoredBox(
                    // Body uses a single flat color — the same pale blue
                    // the header's radial fades into — so the expanded
                    // sheet reads as one calm surface below the header.
                    color: const Color(0xFFEEF8FF),
                    child: const SinglePlanSubscriptionView(pinCta: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final headerHeight =
        _isExpanded ? _expandedHeaderHeight : _collapsedHeaderHeight;
    return CustomPaint(
      painter: _PeakShadowPainter(),
      child: ClipPath(
        clipper: _PeakHeaderClipper(),
        child: SizedBox(
          width: double.infinity,
          height: headerHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base white layer.
              const ColoredBox(color: Color(0xFFFFFFFF)),
              // Header background:
              //   • Collapsed — keep the strong cyan→blue band that fades
              //     into white so the CTA pill stays legible.
              //   • Expanded — paint the same #DFFFFD → #FFFFFF → #DDEFFF
              //     gradient as the body so the header flows seamlessly
              //     into the expanded sheet surface.
              DecoratedBox(
                decoration: const BoxDecoration(
                  // Same radial glow for both collapsed and expanded states:
                  // a soft mint tint anchored at the top-right fading into a
                  // pale blue across the rest of the header.
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.0,
                    colors: [
                      Color(0xFFE4FFFE),
                      Color(0xFFEEF8FF),
                    ],
                  ),
                ),
                child: !_isExpanded
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.2, 0.7],
                          ),
                        ),
                        child: const SizedBox.expand(),
                      )
                    : const SizedBox.expand(),
              ),
              Stack(
          children: [
            // Chevron sits inside the flat plateau at the top of the peak.
            Positioned(
              top: 2,
              left: 0,
              right: 0,
              child: Center(
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: AppColors.mainTextColor,
                  size: _scaled(26),
                ),
              ),
            ),

                if (!_isExpanded)
                  Positioned(
                    left: SizeConfig.size16,
                    right: SizeConfig.size16,
                    top: _PeakHeaderClipper.peakHeight + 10,
                    child: Obx(() => _buildHeaderTitle()),
                  ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a soft outer glow around the peak silhouette so the white header
/// reads as a raised surface above the body content. Uses [BlurStyle.outer]
/// so the blur only renders outside the path (above and to the sides),
/// without darkening the header itself. This is what visually unifies the
/// peek header with the bottom navigation bar beneath it.
class _PeakShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _PeakHeaderClipper().getClip(size);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clipper that produces a full-width bar with a centered upward "tab" peak.
/// The peak has straight diagonal shoulders (not curves) and a flat plateau
/// across the top — basically a trapezoid sticking up out of the bar.
class _PeakHeaderClipper extends CustomClipper<Path> {
  static const double peakHeight = 25.0;

  // Anchor points as fractions of the total width.
  static const double _leftShoulderStart = 0.325; // bar → diagonal up begins
  static const double _plateauStart = 0.375; // diagonal up → plateau begins
  static const double _plateauEnd = 0.625; // plateau → diagonal down begins
  static const double _rightShoulderEnd = 0.675; // diagonal down → bar resumes

  // Small radius used to soften the four shoulder corners.
  static const double _cornerRadius = 6.0;

  // Rounded radius applied to the top-left and top-right corners of the
  // outer bar — gives the header a pill-like cap on both sides.
  static const double _outerCornerRadius = 20.0;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    final lShoulderX = _leftShoulderStart * w;
    final lPlateauX = _plateauStart * w;
    final rPlateauX = _plateauEnd * w;
    final rShoulderX = _rightShoulderEnd * w;

    // Direction vector for the left shoulder (going up & right).
    final dxL = lPlateauX - lShoulderX;
    final dyL = -peakHeight;
    final magL = math.sqrt(dxL * dxL + dyL * dyL);
    final uxL = dxL / magL;
    final uyL = dyL / magL;

    // Direction vector for the right shoulder (going down & right).
    final dxR = rShoulderX - rPlateauX;
    final dyR = peakHeight;
    final magR = math.sqrt(dxR * dxR + dyR * dyR);
    final uxR = dxR / magR;
    final uyR = dyR / magR;

    // Start just below the top-left, then round up to the bar edge so the
    // outer left corner is softened with [_outerCornerRadius].
    path.moveTo(0, peakHeight + _outerCornerRadius);
    path.quadraticBezierTo(
      0, peakHeight,
      _outerCornerRadius, peakHeight,
    );
    path.lineTo(lShoulderX - _cornerRadius, peakHeight);
    // Round the bottom-left shoulder corner: bar → diagonal up.
    path.quadraticBezierTo(
      lShoulderX, peakHeight,
      lShoulderX + uxL * _cornerRadius, peakHeight + uyL * _cornerRadius,
    );

    // Straight diagonal up to just before the top-left plateau corner.
    path.lineTo(
      lPlateauX - uxL * _cornerRadius,
      0 - uyL * _cornerRadius,
    );
    // Round the top-left plateau corner: diagonal → flat plateau.
    path.quadraticBezierTo(
      lPlateauX, 0,
      lPlateauX + _cornerRadius, 0,
    );

    // Flat plateau across the top of the peak (shortened on both sides).
    path.lineTo(rPlateauX - _cornerRadius, 0);
    // Round the top-right plateau corner: flat → diagonal down.
    path.quadraticBezierTo(
      rPlateauX, 0,
      rPlateauX + uxR * _cornerRadius, 0 + uyR * _cornerRadius,
    );

    // Straight diagonal down to just before the bottom-right shoulder corner.
    path.lineTo(
      rShoulderX - uxR * _cornerRadius,
      peakHeight - uyR * _cornerRadius,
    );
    // Round the bottom-right shoulder corner: diagonal → bar.
    path.quadraticBezierTo(
      rShoulderX, peakHeight,
      rShoulderX + _cornerRadius, peakHeight,
    );

    // Right flat portion of the bar, stopping short of the rounded corner.
    path.lineTo(w - _outerCornerRadius, peakHeight);
    // Round the top-right outer corner down into the right edge.
    path.quadraticBezierTo(
      w, peakHeight,
      w, peakHeight + _outerCornerRadius,
    );

    // Down the right side, across the bottom, and close on the left.
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Clips and animates a child's vertical reveal using [SizeTransition].
/// Works reliably on both Android and iOS — the child keeps its intrinsic
/// height (content-hugging) and the reveal fraction animates from 0 → 1.
class AnimatedClipRect extends StatefulWidget {
  final bool isExpanded;
  final Duration duration;
  final Curve curve;
  final Widget child;

  const AnimatedClipRect({
    super.key,
    required this.isExpanded,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  State<AnimatedClipRect> createState() => _AnimatedClipRectState();
}

class _AnimatedClipRectState extends State<AnimatedClipRect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedClipRect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: widget.child,
    );
  }
}

