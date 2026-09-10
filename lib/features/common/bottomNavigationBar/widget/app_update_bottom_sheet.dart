import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The two sheets of the in-app update flow, driven by `_checkForUpdate` in
/// bottom_navigation_bar_screen.dart.
///
/// This replaces the old split where Android handed the whole thing to Play's
/// FULL-SCREEN immediate flow and iOS got a centre dialog. Nothing here decides
/// how an update is fetched — these are the prompts either side of it:
///
///  1. [showAppUpdateBottomSheet] — "a new version is out". Taps through to
///     Play's flexible download on Android (background, user stays in the app)
///     or the App Store listing on iOS.
///  2. [showUpdateReadyBottomSheet] — Android only, once the flexible download
///     has finished. Installing restarts the app, so it is asked, not done.
///
/// The immediate flow is deliberately no longer the default: it takes the
/// screen away with no way back until the update finishes, which is the wrong
/// trade for a routine release. It survives in exactly two places, both in
/// `_checkForUpdate` — resuming an update Play itself already started, and the
/// fallback for a build where Play reports the flexible flow isn't permitted.

/// Opens the "update available" sheet, unless this version has already been
/// offered today.
///
/// [versionTag] identifies the AVAILABLE version — the Play
/// `availableVersionCode` on Android, the store version string on iOS. It is
/// what makes the cadence per-release rather than global: dismissing today's
/// prompt quiets that version until tomorrow, but a NEW release that ships
/// tonight prompts on the next open instead of inheriting the silence.
///
/// Returns true only when the user actually tapped Update. False covers all
/// three of "throttled", "dismissed" and "tapped Not now", because the caller
/// does the same thing in every one of those cases: nothing.
Future<bool> showAppUpdateBottomSheet({
  required BuildContext context,
  required String versionTag,
  required String message,
  String? currentVersion,
  String? newVersion,
}) async {
  if (!await _shouldPrompt(versionTag)) return false;
  if (!context.mounted) return false;

  return _show(
    context,
    _AppUpdateSheetContent(
      title: AppStrings.updateAvailableTitle.tr,
      message: message,
      primaryLabel: AppStrings.updateNow.tr,
      secondaryLabel: AppStrings.updateNotNow.tr,
      currentVersion: currentVersion,
      newVersion: newVersion,
    ),
  );
}

/// Offers to install a flexible update that has finished downloading.
///
/// NOT throttled and NOT dismissible by tapping outside, unlike the prompt
/// above: the user already accepted this update, the bytes are on the device,
/// and the only thing left is a restart they have to actually decide about. A
/// stray tap on the scrim shouldn't count as "no".
///
/// Returns true when the user wants to restart now. On false the download
/// simply stays put — `_checkForUpdate` finds it again on the next app open
/// and asks once more.
Future<bool> showUpdateReadyBottomSheet({required BuildContext context}) {
  return _show(
    context,
    _AppUpdateSheetContent(
      title: AppStrings.updateReadyTitle.tr,
      message: AppStrings.updateReadyMessage.tr,
      primaryLabel: AppStrings.updateRestartNow.tr,
      secondaryLabel: AppStrings.updateLater.tr,
      icon: Icons.download_done_rounded,
    ),
    isDismissible: false,
  );
}

Future<bool> _show(
  BuildContext context,
  Widget child, {
  bool isDismissible = true,
}) async {
  if (!context.mounted) return false;
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => child,
  );
  return accepted ?? false;
}

/// One prompt per available version per calendar day.
///
/// Without this the prompt would be back on the very next cold start, which is
/// what makes an optional update feel like a nag — and unlike the immediate
/// flow, an optional one can be ignored indefinitely, so the cadence is the
/// only thing keeping it civil.
///
/// Records the show BEFORE the sheet opens rather than on dismissal: the
/// process can be killed with the sheet still up (Play's own consent dialog
/// moves us to the background), and a prompt the user has already seen
/// shouldn't reappear just because they never got to tap anything.
Future<bool> _shouldPrompt(String versionTag) async {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  final stamp = '$versionTag|$today';

  final lastShown = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.updatePromptLastShownKey);
  if (lastShown == stamp) return false;

  await SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.updatePromptLastShownKey, stamp);
  return true;
}

class _AppUpdateSheetContent extends StatelessWidget {
  const _AppUpdateSheetContent({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.icon = Icons.system_update_alt_rounded,
    this.currentVersion,
    this.newVersion,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final IconData icon;
  final String? currentVersion;
  final String? newVersion;

  @override
  Widget build(BuildContext context) {
    // Both versions or neither: "13.40.191 →" with a blank on the right reads
    // like a rendering bug, and the arrow is the whole point of the row.
    final showVersions = (currentVersion?.isNotEmpty ?? false) &&
        (newVersion?.isNotEmpty ?? false);

    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        top: SizeConfig.size12,
        bottom: MediaQuery.of(context).padding.bottom + SizeConfig.size16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: SizeConfig.size16),
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, size: 30, color: AppColors.primaryColor),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            message,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          if (showVersions) ...[
            SizedBox(height: SizeConfig.size12),
            // Versions, not translated: they're numbers either way.
            CustomText(
              '$currentVersion  →  $newVersion',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: SizeConfig.size20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomText(
                primaryLabel,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: CustomText(
              secondaryLabel,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
