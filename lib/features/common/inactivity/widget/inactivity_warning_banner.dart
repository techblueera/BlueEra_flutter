import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/inactivity/controller/inactivity_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sticky nudge above the bottom navigation bar for an account the backend is
/// about to purge (docs/backend/FLUTTER_INACTIVE_USER_DATA_PURGE_GUIDE.md §5.2).
///
/// The copy reassures rather than alarms, because by the time anyone can read
/// this the danger is already over: the status call that raised the flag also
/// counted as activity, so opening the app has reset the clock. There is
/// deliberately no action button — there is nothing left to do.
///
/// Rendered next to [LocationPermissionBanner] and built the same way: a
/// self-hiding `Obx` that collapses to nothing when there is nothing to say,
/// so the host does not need to know whether it will draw.
class InactivityWarningBanner extends StatelessWidget {
  const InactivityWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InactivityController.to;
    return Obx(() {
      if (!controller.showWarning) return const SizedBox.shrink();

      final days = controller.daysUntilPurge;
      // Zero or a missing count both drop the number rather than printing
      // "in 0 days" or inventing one — `days_until_purge` is the server's to
      // say, and an app-side guess is exactly what §4 warns against.
      final body = (days != null && days > 0)
          ? AppStrings.inactivityWarningBody.trParams({'days': '$days'})
          : AppStrings.inactivityWarningBodyToday.tr;

      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.white,
            border: Border.all(color: AppColors.orangelite, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.orangelite.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orangelite.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.inactivityWarningTitle.tr,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      CustomText(
                        body,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey72,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: controller.dismissWarning,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.grey72,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
