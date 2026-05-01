import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/view/contribution_plans_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Persistent peek bottom sheet for the new "Contribution Plan" surface.
/// Mirrors the layout/animation of [SubscriptionDraggableSheet] — only the
/// expanded body content swaps in [ContributionPlansView] (which renders the
/// design from `assets/subscription_new_ui.png`).
class ContributionDraggableSheet extends StatefulWidget {
  /// Extra space reserved beneath the sheet (e.g. for a bottom navigation bar
  /// living in a parent widget).
  final double bottomPadding;

  const ContributionDraggableSheet({
    super.key,
    this.bottomPadding = 0,
  });

  @override
  State<ContributionDraggableSheet> createState() =>
      _ContributionDraggableSheetState();
}

class _ContributionDraggableSheetState
    extends State<ContributionDraggableSheet> {
  static const double _collapsedHeaderHeight = 110.0;
  static const double _expandedHeaderHeight = 35.0;

  bool _isExpanded = false;

  void _toggleSheet() {
    setState(() => _isExpanded = !_isExpanded);
  }

  double _scaled(double base) {
    if (SizeConfig.isTablet) return base * 1.25;
    final factor = (SizeConfig.screenWidth / 390.0).clamp(0.85, 1.15);
    return base * factor;
  }

  Widget _buildHeaderTitle() {
    return Container(
      width: SizeConfig.screenWidth,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: CustomText(
            'Kindly Contribute Us',
            fontSize: _scaled(16),
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
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
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBodyHeight),
                child: SizedBox(
                  width: double.infinity,
                  child: ColoredBox(
                    color: const Color(0xFFEEF8FF),
                    child: const ContributionPlansView(
                      pinCta: true,
                      showHeader: true,
                    ),
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
              const ColoredBox(color: Color(0xFFFFFFFF)),
              DecoratedBox(
                decoration: const BoxDecoration(
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
                      child: _buildHeaderTitle(),
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

class _PeakHeaderClipper extends CustomClipper<Path> {
  static const double peakHeight = 25.0;

  static const double _leftShoulderStart = 0.325;
  static const double _plateauStart = 0.375;
  static const double _plateauEnd = 0.625;
  static const double _rightShoulderEnd = 0.675;

  static const double _cornerRadius = 6.0;
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

    final dxL = lPlateauX - lShoulderX;
    final dyL = -peakHeight;
    final magL = math.sqrt(dxL * dxL + dyL * dyL);
    final uxL = dxL / magL;
    final uyL = dyL / magL;

    final dxR = rShoulderX - rPlateauX;
    final dyR = peakHeight;
    final magR = math.sqrt(dxR * dxR + dyR * dyR);
    final uxR = dxR / magR;
    final uyR = dyR / magR;

    path.moveTo(0, peakHeight + _outerCornerRadius);
    path.quadraticBezierTo(
      0, peakHeight,
      _outerCornerRadius, peakHeight,
    );
    path.lineTo(lShoulderX - _cornerRadius, peakHeight);
    path.quadraticBezierTo(
      lShoulderX, peakHeight,
      lShoulderX + uxL * _cornerRadius, peakHeight + uyL * _cornerRadius,
    );

    path.lineTo(
      lPlateauX - uxL * _cornerRadius,
      0 - uyL * _cornerRadius,
    );
    path.quadraticBezierTo(
      lPlateauX, 0,
      lPlateauX + _cornerRadius, 0,
    );

    path.lineTo(rPlateauX - _cornerRadius, 0);
    path.quadraticBezierTo(
      rPlateauX, 0,
      rPlateauX + uxR * _cornerRadius, 0 + uyR * _cornerRadius,
    );

    path.lineTo(
      rShoulderX - uxR * _cornerRadius,
      peakHeight - uyR * _cornerRadius,
    );
    path.quadraticBezierTo(
      rShoulderX, peakHeight,
      rShoulderX + _cornerRadius, peakHeight,
    );

    path.lineTo(w - _outerCornerRadius, peakHeight);
    path.quadraticBezierTo(
      w, peakHeight,
      w, peakHeight + _outerCornerRadius,
    );

    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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
