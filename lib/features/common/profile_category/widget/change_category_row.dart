import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/profile_category/controller/profile_category_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Settings → Account → **Change category** (§4).
///
/// Three states, and the difference between the last two matters:
///
///  * `supported == false` — GUEST / BLUEFLY, or the state hasn't loaded.
///    Renders NOTHING. Not a disabled row: these accounts have no category at
///    all, so a greyed-out control would be describing something that doesn't
///    exist.
///  * `can_change == true` — tappable, with the current category as a subtitle
///    and the remaining allowance as a chip.
///  * `can_change == false` — VISIBLE but disabled, with the contact-support
///    line. Deliberately not hidden: a row that vanishes the day after someone
///    used it reads as a bug, and they'd have no way to find out what happened.
///
/// Shape follows the cards already on that screen rather than inventing a
/// layout, but it is its own widget because it is the only row there with a
/// subtitle, a disabled state and asynchronous state behind it.
class ChangeCategoryRow extends StatelessWidget {
  const ChangeCategoryRow({
    super.key,
    required this.controller,
    required this.onChangeRequested,
  });

  final ProfileCategoryController controller;

  /// Opens the picker. Only ever called when the change is still available —
  /// the disabled tap is handled here, in [_onDisabledTap], so every caller
  /// doesn't have to re-check.
  final VoidCallback onChangeRequested;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Reading `state.value` is what subscribes this Obx.
      final state = controller.state.value;
      if (!state.supported) return const SizedBox.shrink();

      final enabled = state.canChange;
      final currentName = state.current?.name ?? '';

      return Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.size10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          // Still tappable when disabled: the tap is what explains WHY it is
          // disabled. An inert row leaves the user pressing it repeatedly.
          onTap: enabled ? onChangeRequested : () => _onDisabledTap(context),
          child: Opacity(
            opacity: enabled ? 1 : 0.6,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.whiteE5, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          AppStrings.changeCategoryTitle.tr,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        if (currentName.isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            currentName,
                            fontSize: SizeConfig.small,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (enabled && state.changesRemaining > 0)
                    _chip(AppStrings.changeCategoryOneLeft.tr)
                  else if (!enabled)
                    _chip(AppStrings.changeCategoryUsed.tr),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// The allowance is spent. Support can hand it back — that's the admin
  /// panel's job — so the message points there rather than pretending the
  /// change is impossible.
  void _onDisabledTap(BuildContext context) {
    Get.snackbar(
      AppStrings.changeCategoryTitle.tr,
      AppStrings.changeCategoryLimitReached.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(SizeConfig.size12),
      backgroundColor: AppColors.white,
      colorText: AppColors.mainTextColor,
      duration: const Duration(seconds: 4),
    );
  }

  Widget _chip(String text) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomText(
          text,
          fontSize: SizeConfig.small,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w500,
        ),
      );
}
