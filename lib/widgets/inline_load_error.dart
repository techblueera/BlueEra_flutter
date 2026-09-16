import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// A failed load, drawn in the slot the thing that failed would have occupied.
///
/// For a field inside a form, where [LoadErrorWidget]'s full-page treatment
/// (a 64px icon, centred in whatever space it is given) would shove the rest
/// of the form off screen. This keeps the footprint of the picker it replaces:
/// one bordered row, the reason on the left, Retry on the right.
///
/// Used where an empty picker would otherwise be the only sign that anything
/// went wrong — an empty dropdown reads as "nothing to choose here", which is
/// a different and much more final statement than "this didn't load".
class InlineLoadError extends StatelessWidget {
  const InlineLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// Display-ready, or a translation key — it goes through `tr`, which returns
  /// anything it cannot translate unchanged.
  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final langController = getOrPut(() => LanguageListController());

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              langController.tr(message),
              fontSize: SizeConfig.small,
              color: AppColors.mainTextColor,
              maxLines: 2,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(SizeConfig.size6),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    langController.tr(AppStrings.retry),
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
