import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Per-field copy for the add-product prompt. Each me-section admin home
/// passes the spec matching its own catalog — "dishes" for food, "medicines"
/// for medical — so the nudge names what that merchant actually sells rather
/// than saying "products" at everyone.
class AddProductPromptSpec {
  /// Field-specific headline, e.g. [AppStrings.addPromptTitleMedical].
  final String titleKey;

  /// Label on the primary button, e.g. [AppStrings.addFood] for restaurants.
  final String ctaKey;

  final IconData icon;

  const AddProductPromptSpec({
    required this.titleKey,
    required this.ctaKey,
    required this.icon,
  });
}

/// Pops the once-a-day "add your catalog" nudge on a merchant admin home.
///
/// Shows for every merchant regardless of how many products they already have
/// — the only cadence rule is once per calendar day, persisted in
/// [SharedPreferenceUtils.addProductPromptLastShownKey] so it survives
/// restarts and bottom-nav re-entry.
///
/// [onAddProduct] fires when the merchant taps the CTA, after the sheet pops.
/// Every caller wires it to `animateTo(2)` on its own TabController — the
/// button just moves the merchant to the Products tab, it doesn't open the add
/// flow itself.
///
/// Pass [livePhotoGate] on screens that also pop
/// `showBusinessLivePhotoBottomSheetIfNeeded` on the same landing (grocery,
/// food). Live photos take priority — they're marked required in that sheet's
/// own copy — so while the business has none we skip WITHOUT burning the day,
/// and this prompt gets its turn on the next visit instead of stacking a
/// second sheet on top.
Future<void> showAddProductPromptIfNeeded({
  required BuildContext context,
  required AddProductPromptSpec spec,
  required VoidCallback onAddProduct,
  ViewBusinessDetailsController? livePhotoGate,
}) async {
  final today = _todayKey();
  if (addProductPromptShownForDay == today) return;

  final lastShown = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.addProductPromptLastShownKey);
  if (lastShown == today) {
    // Already shown today on a previous launch — mirror it so the rest of this
    // session skips without re-reading secure storage on every mount.
    addProductPromptShownForDay = today;
    return;
  }

  if (livePhotoGate != null && !await _hasLivePhotos(livePhotoGate)) return;

  if (!context.mounted) return;
  // Something is already on top (the live-photo sheet, a dialog, a pushed
  // route). Leave the day unburned and try again next visit.
  if (ModalRoute.of(context)?.isCurrent == false) return;

  addProductPromptShownForDay = today;
  await SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.addProductPromptLastShownKey, today);

  if (!context.mounted) return;
  await showAddCatalogPromptSheet(
    context: context,
    spec: spec,
    onAddProduct: onAddProduct,
  );
}

/// The same sheet with NO cadence rule — it opens every time it is called.
///
/// For the case the once-a-day nudge above does not cover: a section that is
/// EMPTY and blocks the profile, where the prompt is not a reminder but the
/// screen's actual next step (the Services tab of an "other" business, which
/// cannot go live until one service exists). The caller owns the "should this
/// open at all" decision — typically "the list came back empty" — and is
/// responsible for not re-opening it on every rebuild.
Future<void> showAddCatalogPromptSheet({
  required BuildContext context,
  required AddProductPromptSpec spec,
  required VoidCallback onAddProduct,
}) async {
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddProductPromptContent(
      spec: spec,
      onAddProduct: onAddProduct,
    ),
  );
}

/// Local `yyyy-MM-dd` key used to bucket the prompt to one show per day.
String _todayKey() {
  final now = DateTime.now();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '${now.year}-$m-$d';
}

/// Whether the business has at least one live photo — the exact condition
/// `showBusinessLivePhotoBottomSheetIfNeeded` inverts to decide whether IT
/// shows. Waits for the permanent controller's first fetch the same way that
/// sheet does; deciding off a null profile would race it and open both.
///
/// Returns false if the profile never resolves, which skips this prompt — the
/// safe default, since a stacked pair of sheets is worse than a missed nudge.
Future<bool> _hasLivePhotos(ViewBusinessDetailsController controller) async {
  if (controller.businessProfileDetails.value == null) {
    final completer = Completer<void>();
    late final Worker worker;
    worker = ever(controller.businessProfileDetails, (val) {
      if (val != null && !completer.isCompleted) completer.complete();
    });
    try {
      await completer.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Fall through — the null check below reports "no photos" and we skip.
    } finally {
      worker.dispose();
    }
  }
  final photos = controller.businessProfileDetails.value?.data?.livePhotos;
  return photos != null && photos.any((p) => p.trim().isNotEmpty);
}

class _AddProductPromptContent extends StatelessWidget {
  final AddProductPromptSpec spec;
  final VoidCallback onAddProduct;

  const _AddProductPromptContent({
    required this.spec,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Icon(spec.icon, size: 30, color: AppColors.primaryColor),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            spec.titleKey.tr,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            AppStrings.addPromptSubtitle.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size20),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onAddProduct();
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue5CAF, AppColors.primaryColor],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CustomText(
                spec.ctaKey.tr,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: CustomText(
              AppStrings.addPromptNotNow.tr,
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
