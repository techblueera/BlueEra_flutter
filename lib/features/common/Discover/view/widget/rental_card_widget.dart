import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalCardWidget extends StatelessWidget {
  const RentalCardWidget({super.key});

  static const Color _chipFill = Color(0xFFE3F2FD);
  static const Color _softBorder = Color(0xFFDDE2EE);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.paddingXSL),
          titleWidget(AppStrings.rentalServices.tr),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CommonCardWidget(
              cardMargin: 0,
              padding: 0,
              borderColorColor: _softBorder,
              borderRadius: 12.0,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Get.to(() => AllStayServiceScreen(
                        stayCategories: stayHomeItemsCategories,
                        selectedStayCategory: stayHomeItemsCategories[0]));
                  },
                  borderRadius: BorderRadius.circular(12),
                  // Lighter splash than the buttons so an outer-tap
                  // ripple feels like a card-level confirmation rather
                  // than competing with a button press.
                  splashColor: AppColors.primaryColor.withValues(alpha: 0.06),
                  highlightColor:
                      AppColors.primaryColor.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(children: _buildHeader()),
                        const SizedBox(height: 14),
                        const _DashedHorizontalLine(color: _softBorder),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _rentalAction(
                                label: AppStrings.houseRent.tr,
                                onTap: () {
                                  Get.to(() => AllStayServiceScreen(
                                      stayCategories: stayHomeItemsCategories,
                                      selectedStayCategory:
                                          stayHomeItemsCategories[0]));
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _rentalAction(
                                label: AppStrings.vehicleRent.tr,
                                onTap: () {
                                  Get.to(() => AllStayServiceScreen(
                                      stayCategories: stayHomeItemsCategories,
                                      selectedStayCategory: stayHomeItemsCategories[1]));
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _rentalAction(
                                label: AppStrings.otherRental.tr,
                                onTap: () {
                                  Get.to(() => AllStayServiceScreen(
                                      stayCategories: stayHomeItemsCategories,
                                      selectedStayCategory:
                                          stayHomeItemsCategories[1]));
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.paddingXSL),
        ],
      ),
    );
  }

  /// Hero row inside the inner card — the lock+key+house illustration on
  /// the left at flex 1, then the title + subtitle column at flex 3.
  /// flex ratio is intentional: the illustration is the visual anchor,
  /// the text is the message; 1:3 keeps the icon present without
  /// crowding the headline.
  List<Widget> _buildHeader() {
    return [
      Expanded(
        flex: 1,
        child: LocalAssets(
          imagePath: "assets/images/lock_key_icon.png",
          boxFix: BoxFit.contain,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.forRent.tr,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 4),
            CustomText(
              AppStrings.housesVehiclesMoreNearYou.tr,
              color: AppColors.secondaryTextColor,
              fontSize: 12,
            ),
          ],
        ),
      ),
    ];
  }

  Widget _rentalAction({
    required String label,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(10);
    return Material(
      color: _chipFill,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
        highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          child: Center(
            child: CustomText(
              label,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width 1px dashed line — used inside the rental card to separate
/// the "For Rent" header from the action buttons. Self-sized: stretches
/// to the parent's width and only takes [thickness] vertically, so it
/// drops into a `Column` without needing a `SizedBox` wrapper.
///
/// Lives in this file (not a shared widget) because it's the only place
/// in the codebase that currently needs a horizontal dashed rule. If
/// another screen ever wants the same separator, this should graduate
/// to `lib/widgets/` — until then keeping it private avoids polluting
/// the shared widget surface.
class _DashedHorizontalLine extends StatelessWidget {
  const _DashedHorizontalLine({this.color = const Color(0xFFDDE2EE)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _DashedLinePainter._thickness,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  // Stroke geometry baked in. Promoted to constructor params if/when a
  // second caller actually needs different values — until then keeping
  // them private avoids the unused-parameter analyzer warning that the
  // private widget triggers when its options never get overridden.
  static const double _dashWidth = 5;
  static const double _dashSpace = 4;
  static const double _thickness = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    double startX = 0;
    while (startX < size.width) {
      // Clamp the last dash so it doesn't overshoot the painted area —
      // matters when (width % stride) leaves a partial dash worth of
      // room at the end. Without the clamp the final stroke would be
      // truncated visibly mid-segment.
      final endX = (startX + _dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      startX += _dashWidth + _dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      color != old.color;
}
