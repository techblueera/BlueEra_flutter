import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pops the once-a-day "your QR code" promo on the business own-profile screen.
///
/// Presentation mirrors the Discover [SharePromoSheet] — a rounded bottom sheet
/// carrying one card ([BusinessQrCodeWidget]) that scrolls within a height cap.
/// Cadence mirrors [showAddProductPromptIfNeeded]: at most once per calendar
/// day, persisted in [SharedPreferenceUtils.qrPromoLastShownKey] so it survives
/// restarts and bottom-nav re-entry, with the in-memory [qrPromoShownForDay]
/// mirror guarding against two mounts racing the async write.
///
/// The QR needs the resolved business profile, so this waits for the permanent
/// controller's first fetch (same completer pattern the live-photo / add-product
/// gates use) rather than deciding off a null profile and opening an empty card.
Future<void> showBusinessQrPromoSheetIfNeeded({
  required BuildContext context,
  required ViewBusinessDetailsController controller,
}) async {
  final today = _todayKey();
  if (qrPromoShownForDay == today) return;

  final lastShown = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.qrPromoLastShownKey);
  if (lastShown == today) {
    // Already shown today on a previous launch — mirror it so the rest of this
    // session skips without re-reading secure storage on every mount.
    qrPromoShownForDay = today;
    return;
  }

  // The QR encodes the profile deep link, so hold until the profile resolves.
  final data = await _awaitBusinessData(controller);
  if (data == null || (data.userId ?? '').isEmpty) return;

  if (!context.mounted) return;
  // Something is already on top (a dialog, a pushed route). Leave the day
  // unburned and try again on the next visit.
  if (ModalRoute.of(context)?.isCurrent == false) return;

  qrPromoShownForDay = today;
  await SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.qrPromoLastShownKey, today);

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Open at 70% of the screen height; the card scrolls within that cap.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.70,
    ),
    builder: (_) => _BusinessQrPromoSheetBody(data: data),
  );
}

/// Whether the business profile has resolved; waits for the permanent
/// controller's first fetch. Returns null if it never resolves, which skips the
/// sheet — the safe default, since an empty QR card is worse than a missed pop.
Future<BusinessProfileDetails?> _awaitBusinessData(
    ViewBusinessDetailsController controller) async {
  if (controller.businessProfileDetails.value?.data == null) {
    final completer = Completer<void>();
    late final Worker worker;
    worker = ever(controller.businessProfileDetails, (val) {
      if (val?.data != null && !completer.isCompleted) completer.complete();
    });
    try {
      await completer.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Fall through — the null return below skips the sheet.
    } finally {
      worker.dispose();
    }
  }
  return controller.businessProfileDetails.value?.data;
}

/// Local `yyyy-MM-dd` key used to bucket the sheet to one show per day.
String _todayKey() {
  final now = DateTime.now();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '${now.year}-$m-$d';
}

class _BusinessQrPromoSheetBody extends StatelessWidget {
  final BusinessProfileDetails data;

  const _BusinessQrPromoSheetBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size10,
            SizeConfig.size8,
            SizeConfig.size10,
            SizeConfig.size12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handleRow(context),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                'Scan to visit my profile',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              BusinessQrCodeWidget(data: data),
            ],
          ),
        ),
      ),
    );
  }

  /// Drag handle centered, with a ✕ pinned to the trailing edge so the sheet
  /// can be dismissed by tap as well as by dragging down.
  Widget _handleRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        Expanded(
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.close_rounded,
                size: 22, color: AppColors.secondaryTextColor),
          ),
        ),
      ],
    );
  }
}
