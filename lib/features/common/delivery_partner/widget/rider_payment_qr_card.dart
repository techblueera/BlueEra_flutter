import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/upi_payment_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/full_screen_qr_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The rider's collection QR, on the idle (preference) screen.
///
/// Two states, one card:
///   • **No UPI on file** — an invitation to add one, because a rider who
///     finishes a cash-less ride with no QR has no way to be paid.
///   • **UPI on file** — the QR itself, ready to hold up, plus the id under it
///     so the rider can check it is the right account at a glance.
///
/// Both route to [PaymentSettingScreen], which already owns adding and editing
/// payment methods — this card never becomes a second place to edit them.
class RiderPaymentQrCard extends StatefulWidget {
  const RiderPaymentQrCard({super.key});

  @override
  State<RiderPaymentQrCard> createState() => _RiderPaymentQrCardState();
}

class _RiderPaymentQrCardState extends State<RiderPaymentQrCard> {
  final UpiPaymentController _upiCtrl =
      getOrPut(() => UpiPaymentController());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (userId.isEmpty) return;
    await _upiCtrl.fetchUserUpi(userId);
  }

  /// What the customer's UPI app reads. No amount — the rider is being paid an
  /// arbitrary fare here, unlike the ride-completion QR which knows it.
  String _upiPayload(String upi) => 'upi://pay?pa=$upi&cu=INR';

  /// Keyed by the id so the inline code and the full-screen one match, and two
  /// different accounts can never share a flight.
  String _qrHeroTag(String upi) => 'rider-payment-qr-$upi';

  /// Reopens the payment settings and refreshes on return, so adding a UPI id
  /// there flips this card without needing the tab rebuilt.
  Future<void> _openPaymentSettings() async {
    await Get.to(() => PaymentSettingScreen());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final upi = _upiCtrl.upiId.value ?? '';
      return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: upi.isEmpty ? _buildEmptyState() : _buildQrState(upi),
      );
    });
  }

  Widget _buildEmptyState() {
    return Row(
      children: [
        Container(
          width: SizeConfig.size48,
          height: SizeConfig.size48,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.qr_code_2_rounded,
            color: AppColors.primaryColor,
            size: SizeConfig.size24,
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Add your payment QR',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                'Riders with a UPI QR can be paid the moment a ride ends.',
                fontSize: SizeConfig.small11,
                color: AppColors.secondaryTextColor,
                maxLines: 2,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        InkWell(
          onTap: _openPaymentSettings,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomText(
              'Add',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrState(String upi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                'Your payment QR',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            ),
            InkWell(
              onTap: _openPaymentSettings,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size6,
                  vertical: SizeConfig.size4,
                ),
                child: CustomText(
                  'Manage',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size12),
        Row(
          children: [
            // Tap to blow it up. At 100px this is a thumbnail of a QR, not a
            // scannable one — a customer's camera needs it filling the screen,
            // which is the whole point of the code being here.
            InkWell(
              onTap: () => showFullScreenQr(
                context: context,
                data: _upiPayload(upi),
                heroTag: _qrHeroTag(upi),
                // The id under the big code so the customer can check who they
                // are paying before they pay.
                caption: upi,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(SizeConfig.size8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.greyE5),
                ),
                child: Hero(
                  tag: _qrHeroTag(upi),
                  child: QrImageView(
                    data: _upiPayload(upi),
                    version: QrVersions.auto,
                    size: SizeConfig.size100,
                    padding: EdgeInsets.zero,
                    // Scanned off one phone by another, often in sunlight.
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    gapless: true,
                  ),
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Tap the code to show it full screen for scanning',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    upi,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
