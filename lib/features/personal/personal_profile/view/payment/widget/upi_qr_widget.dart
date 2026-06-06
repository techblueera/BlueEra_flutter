import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Builds a standard UPI deep-link payload so any UPI app can scan the QR and
/// pay this VPA. e.g. `upi://pay?pa=name@oksbi&pn=SBI&cu=INR`.
String upiQrPayload(String upiId, {String? payeeName}) {
  final pa = Uri.encodeComponent(upiId.trim());
  final pn = (payeeName != null && payeeName.trim().isNotEmpty)
      ? '&pn=${Uri.encodeComponent(payeeName.trim())}'
      : '';
  return 'upi://pay?pa=$pa$pn&cu=INR';
}

/// Inline QR preview generated live from a UPI ID — used in the Add screen so
/// the user can see (and others can scan) the QR for the UPI ID they entered.
class UpiQrPreview extends StatelessWidget {
  final String upiId;
  final String? bankName;

  const UpiQrPreview({super.key, required this.upiId, this.bankName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.boxBg),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CustomText(
            AppStrings.scanToPay,
            fontSize: SizeConfig.size12,
            color: AppColors.grayText,
          ),
          SizedBox(height: SizeConfig.size12),
          QrImageView(
            data: upiQrPayload(upiId, payeeName: bankName),
            version: QrVersions.auto,
            size: SizeConfig.size160,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            gapless: true,
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            upiId,
            fontSize: SizeConfig.size14,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Opens a dialog showing the QR generated from a saved UPI ID, with a copy
/// affordance — used from the Payment Settings UPI card.
void showUpiQrDialog({required String upiId, String? bankName}) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              AppStrings.upiQrTitle,
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w700,
            ),
            if (bankName != null && bankName.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size4),
              CustomText(
                bankName,
                fontSize: SizeConfig.size12,
                color: AppColors.grayText,
              ),
            ],
            SizedBox(height: SizeConfig.size16),
            QrImageView(
              data: upiQrPayload(upiId, payeeName: bankName),
              version: QrVersions.auto,
              size: SizeConfig.size200,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              gapless: true,
            ),
            SizedBox(height: SizeConfig.size16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: CustomText(
                    upiId,
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: upiId));
                    commonSnackBar(message: AppStrings.upiIdCopied.tr);
                  },
                  child: Icon(
                    Icons.copy,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size20),
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomText(
                    AppStrings.close,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
