import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_v2_section_card.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_screen.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The two QR cards that close the v2 page, side by side as drawn.
///
///   LEFT  — the emergency / vehicle-safety QR. Reads exactly as v1's
///           [EmergencyQrWidget]: a real scannable code once the account has
///           emergency data, and a greyed placeholder plus "Generate Now"
///           until then.
///   RIGHT — this account's own profile QR: name, category, the code, the
///           @handle, and a "Scan & Visit" affordance.
///
/// Built here rather than reusing [EmergencyQrWidget] / [QrDesignOptionsWidget]
/// directly: both of those are FULL-WIDTH cards (a 200px QR, a 50-px-padded
/// button, a horizontal sticker carousel) and neither survives being squeezed
/// into half a screen. The data and the destinations are the same — the same
/// controller, the same `navigateToCreateProfile()`, the same designs screen —
/// only the geometry is new.
class DiscoverQrPair extends StatelessWidget {
  const DiscoverQrPair({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(child: _EmergencyQrCard()),
          SizedBox(width: 12),
          Expanded(child: _ProfileQrCard()),
        ],
      ),
    );
  }
}

/// Shared geometry so the two cards line up whatever they contain.
const double _kQrSize = 128;
const double _kBadge = 34;

class _EmergencyQrCard extends StatelessWidget {
  const _EmergencyQrCard();

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => EmergencyProfileController());

    return Obx(() {
      final active = controller.hasEmergencyData.value;
      return DiscoverV2Card(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              AppStrings.vehicleSafetyParkingQrCode.tr,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
              maxLines: 2,
              height: 1.3,
            ),
            const SizedBox(height: 12),
            _QrBlock(
              // A live emergency profile encodes the real scan target; the
              // placeholder deliberately encodes the marketing site, so a
              // curious scan of the greyed code still lands somewhere real.
              data: active
                  ? 'https://emergency.beapp.in/$userId'
                  : 'https://beapp.in',
              faded: !active,
            ),
            const SizedBox(height: 12),
            CustomText(
              AppStrings.pasteItToSaveLives.tr,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xffD7A302),
              textAlign: TextAlign.center,
              maxLines: 2,
              height: 1.3,
            ),
            const SizedBox(height: 12),
            _CardButton(
              label: active
                  ? AppStrings.viewMoreDesigns.tr
                  : AppStrings.generateNow.tr,
              outlined: true,
              onTap: () {
                if (!active) {
                  controller.navigateToCreateProfile();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrDesignOptionsScreen(
                      userName: controller.fullName.value,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class _ProfileQrCard extends StatelessWidget {
  const _ProfileQrCard();

  @override
  Widget build(BuildContext context) {
    // Business accounts identify by the shop; individuals by their own name.
    // Both fall back to the app name rather than rendering an empty heading.
    final title = businessNameGlobal.isNotEmpty
        ? businessNameGlobal
        : (userNameGlobal.isNotEmpty ? userNameGlobal : AppStrings.appName);
    final category = businessCategoryGlobal;
    final handle = userNameAtGlobal;

    return DiscoverV2Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            title,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            height: 1.3,
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: CustomText(
                category,
                fontSize: 10.5,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            // Keeps the two cards' QR codes on the same baseline when this
            // account has no category to show.
            const SizedBox(height: 6 + 21),
          const SizedBox(height: 12),
          _QrBlock(data: profileDeepLink(userId: userId)),
          const SizedBox(height: 12),
          CustomText(
            handle.isNotEmpty ? '@$handle' : ' ',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _CardButton(
            label: AppStrings.scanAndVisit.tr,
            outlined: false,
            // The owner cannot scan their own code, so the tap hands the
            // target to someone who can — the OS share sheet with the same
            // deep link the QR encodes.
            onTap: () => ShareService.instance.openShareSheet(
              text: profileDeepLink(userId: userId),
              subject: title,
            ),
          ),
        ],
      ),
    );
  }
}

/// The code itself, with the round "BE" badge punched through the middle.
///
/// Error correction is fixed at H on the live codes: the badge covers ~7% of
/// the symbol, and at a lower level that occlusion makes the code unreadable
/// rather than merely denser.
class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.data, this.faded = false});

  final String data;

  /// The "nothing generated yet" state — the code is drawn grey at 25% so the
  /// card keeps its shape and its meaning is obvious without a placeholder box.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final Color ink = faded ? Colors.grey : const Color(0xFF1A1A2E);

    return SizedBox(
      width: _kQrSize,
      height: _kQrSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: faded ? 0.25 : 1,
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: _kQrSize,
              gapless: true,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ink,
              ),
              errorStateBuilder: (_, __) => Center(
                child: CustomText(AppStrings.qrError.tr, fontSize: 11),
              ),
            ),
          ),
          Container(
            width: _kBadge,
            height: _kBadge,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ink, width: 2),
            ),
            alignment: Alignment.center,
            child: CustomText(
              'BE',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ink,
              letterSpacing: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.outlined,
    required this.onTap,
  });

  final String label;

  /// Outlined = the primary action of the pair (blue rim, blue text); the
  /// other card's button is neutral so the two do not compete.
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: outlined ? AppColors.primaryColor : AppColors.whiteE5,
          ),
        ),
        child: CustomText(
          label,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color:
              outlined ? AppColors.primaryColor : AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
