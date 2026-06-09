import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared, reactive home-page background for the profile / home ("me" tab)
/// screens. Drop-in replacement for the old per-screen `_buildPatternBackground`
/// (which hard-coded `AppImageAssets.chatDefaultBg`).
///
/// Returns a [Positioned.fill] so it can sit directly as the bottom layer of a
/// screen's `Stack` — same contract the old method had. It rebuilds whenever
/// the user changes their banner in [AppBackgroundController], so banner updates
/// take effect immediately.
///
///  - A banner is selected → that image (BoxFit.cover).
///  - No banner ('')        → the chosen app background colour
///                            ([AppColors.appBackgroundColor]), so the colour
///                            setting is visible and the two settings stay
///                            independent.
class AppHomeBackground extends StatelessWidget {
  const AppHomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = getOrPut(() => AppBackgroundController(), permanent: true);
    return Positioned.fill(
      child: Obx(() {
        final asset = ctrl.bannerAsset.value;
        if (asset.isNotEmpty) {
          return Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.appBackgroundColor),
          );
        }
        return Container(color: AppColors.appBackgroundColor);
      }),
    );
  }
}
