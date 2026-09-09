import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// App Store update prompt — the iOS half of the app-open update check.
///
/// Android gets Play's own in-app update UI (see `_checkForUpdate` in
/// bottom_navigation_bar_screen.dart, which hands the whole flow to Play).
/// iOS has no equivalent, so the version comparison and the prompt are ours:
/// the caller only opens this once [VersionInfo.canUpdate] is true AND an
/// `appStoreLink` came back from the iTunes lookup, so the Update button
/// always has somewhere to go.
///
/// Deliberately allowed to STACK on whatever else the app-open sequence put on
/// screen (joining-bonus card, deposit-migration sheet). The store lookup is a
/// network round trip, so those usually get there first; dismissing this one
/// simply reveals them again, which beats dropping the update prompt for a
/// whole launch.
///
/// Advisory by design — "Not now" is always there. The App Store cannot
/// install over a running app the way Play's immediate flow does: tapping
/// Update just leaves BlueEra for the store, so an undismissable dialog would
/// strand anyone who can't update right now (no space, metered data, an
/// account they aren't signed into) with no way back into the app.
Future<void> showIosUpdateDialog(
  BuildContext context,
  VersionInfo versionInfo,
) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _IosUpdateDialog(versionInfo: versionInfo),
  );
}

class _IosUpdateDialog extends StatelessWidget {
  const _IosUpdateDialog({required this.versionInfo});

  final VersionInfo versionInfo;

  /// Opens the store listing. Returns false when the link can't be handled —
  /// the dialog then stays put rather than closing onto nothing.
  Future<bool> _openStore() async {
    try {
      final uri = Uri.parse(versionInfo.appStoreLink);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      logs("[UpdateCheck] iOS: could not open App Store link "
          "'${versionInfo.appStoreLink}' — $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  size: 36,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                AppStrings.updateAvailableTitle.tr,
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                AppStrings.updateAvailableMessage.tr,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
              SizedBox(height: SizeConfig.size10),
              // Versions, not translated: they're numbers either way.
              CustomText(
                "${versionInfo.localVersion}  →  ${versionInfo.storeVersion}",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SizeConfig.size20),
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      bgColor: AppColors.white,
                      borderColor: AppColors.primaryColor,
                      textColor: AppColors.primaryColor,
                      title: AppStrings.updateNotNow.tr,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: PositiveCustomBtn(
                      title: AppStrings.updateNow.tr,
                      onTap: () async {
                        final opened = await _openStore();
                        if (opened && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
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
