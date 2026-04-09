import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
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
  static const double _collapsedHeaderHeight = 100.0;
  static const double _expandedHeaderHeight = 44.0;

  bool _isExpanded = false;

  // Shared with SinglePlanSubscriptionView via getOrPut, so the header can
  // react to subscription state without waiting for the body to mount.
  final SubscriptionController _subController =
      getOrPut(() => SubscriptionController());

  @override
  void initState() {
    super.initState();
    // Canonical "fresh load on Me-screen entry" point. The peek mounts
    // once per Me-screen visit, so we always refetch here to keep the
    // user's plan/subscription state current — pricing changes, freshly
    // started trials and post-payment status flips all surface here. The
    // sibling consumers ([SubscriptionStatusView] in the statistics tab
    // and [SinglePlanSubscriptionView] embedded in the expanded sheet)
    // both guard their own initState fetches against INITIAL, so they
    // won't pile a duplicate request on top of this one.
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
      return _ctaPill(title: 'Go Live Now');
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
        return _ctaPill(title: 'Go Live Now');
    }
  }

  /// Solid primary pill used for "do something" states (offer / recharge).
  Widget _ctaPill({required String title}) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      alignment: Alignment.center,
      child: CustomText(
        title,
        fontSize: SizeConfig.large,
        color: AppColors.white,
        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.green39.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.green39, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded,
              size: 20, color: AppColors.green39),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: CustomText(
              daysText,
              fontSize: SizeConfig.medium,
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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.primaryColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: 22, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  '$tier Active',
                  fontSize: SizeConfig.medium,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
                CustomText(
                  'Valid until $validDate',
                  fontSize: SizeConfig.small,
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
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleSheet,
                child: _buildHeader(),
              ),
              if (_isExpanded)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxBodyHeight),
                  child: Container(
                    color: AppColors.whiteFC,
                    width: double.infinity,
                    // shrinkWrap = true makes the ListView take only the
                    // intrinsic height of its child (the plan view's natural
                    // Column), capped by the ConstrainedBox above. If the
                    // content is taller than the cap it scrolls; if shorter
                    // the bottom sheet shrinks to match.
                    child: ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: const [
                        SinglePlanSubscriptionView(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
              // Strong horizontal cyan→blue band at the top, fading to
              // transparent toward the bottom so the title row stays clean.
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF82FFFB), // cyan on the left
                      Color(0xFFB6E3FF), // mint blend in the middle
                      Color(0xFF7EC1FF), // blue on the right
                    ],
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: !_isExpanded
                        ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00FFFFFF), // colored band at the very top
                        Color(0xFFFFFFFF), // pure white below
                      ],
                      stops: [0.2, 0.7],
                    ) : null,
                    color: !_isExpanded ? null : AppColors.white
                  ),
                  child: const SizedBox.expand(),
                ),
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
                  size: 26,
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

    // Left flat portion of the bar, stopping short of the shoulder corner.
    path.moveTo(0, peakHeight);
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

    // Right flat portion of the bar.
    path.lineTo(w, peakHeight);

    // Down the right side, across the bottom, and close on the left.
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
