import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Glassmorphic "Refer & Earn" pill used in every personal- and
/// business-profile top bar.
///
/// Single source of truth — change the icon, label, route, or chrome here
/// and every header picks it up. Originally lifted out of
/// `self_employee_screen.dart::_buildReferEarnPill` so the same recipe the
/// rider dashboard uses can be dropped into Food, Grocery, Hospital,
/// Hotel, Lab, Medical, Others, School, Inventory, Vehicle, Automotive
/// Service, Professionals, etc.
///
/// Chrome recipe: outer drop shadow → ClipRRect → BackdropFilter →
/// white fill with the shared `0xFFC9CDD5` 1px border.
///
/// Defaults navigate via `Get.to(() => ReferralPage())`. Pass [onTap] to
/// override (analytics tagging, custom route stack, etc.) without forking
/// the visual.
class ReferEarnPill extends StatelessWidget {
  const ReferEarnPill({super.key, this.onTap});

  /// Tap handler. Defaults to opening [ReferralPage] via GetX.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => ReferralPage()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
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
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 14,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    'Refer & Earn',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryTextColor,
                    letterSpacing: 0.2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
