import 'dart:ui';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_strings.dart';

/// Frosted "Refer & Earn" pill shown in the profile / business top bars.
///
/// Deliberately **static**. It used to pulse and blink between orange and pink;
/// that attention now belongs to [GoLivePill], and two pills competing in the
/// same top bar cancelled each other out. The warm orange still makes it stand
/// out without animating.
class ReferEarnPill extends StatelessWidget {
  const ReferEarnPill({super.key, this.onTap, this.showShadow = false});

  final VoidCallback? onTap;

  /// Adds a drop shadow so the pill lifts off a busy background (e.g. a cover
  /// photo). Off by default so flat placements stay flat — pass `true` only
  /// where the pill sits over an image (currently the social dashboard header).
  final bool showShadow;

  /// The vivid orange the blink used to start from — kept as the resting
  /// colour so the pill reads the same at a glance.
  static const Color _accent = Color(0xFFFF6D00);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => ReferralPage()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
            // Optional drop shadow (flagged) to lift the pill off a busy
            // background such as a cover photo.
            if (showShadow)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
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
                  color: _accent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_outlined, size: 14, color: _accent),
                  SizedBox(width: SizeConfig.size6),
                  Flexible(
                    child: CustomText(
                      AppStrings.referAndEarn.tr,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                      letterSpacing: 0.2,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
