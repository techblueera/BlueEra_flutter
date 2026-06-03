import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EarnServiceQrCodeWidget extends StatelessWidget {
  final EarnProfileController controller;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const EarnServiceQrCodeWidget({
    super.key,
    required this.controller,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.earnProfile.value;
      final qrData = profile?.id ?? profile?.serviceName ?? '';
      if (qrData.isEmpty) return const SizedBox.shrink();

      return CustomFormCard(
        padding: const EdgeInsets.all(10.0),
        margin: const EdgeInsets.only(top: 10.0),
        child: Column(
          children: [
            const SizedBox(height: 14),
            CustomText(
              profile?.serviceName ?? '',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            if ((profile?.profileType ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  _profileTypeLabel(profile!.profileType!),
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildQrContainer(qrData),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: AppIconAssets.downloadIcon,
                  label:AppStrings.download.tr,
                  onTap: onDownload,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  icon: AppIconAssets.reelShare,
                  label: AppStrings.share.tr,
                  onTap: onShare,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQrContainer(String qrData) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: SizeConfig.screenWidth - (2 * SizeConfig.size80),
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        gapless: true,
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyE5, width: 1.0),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Row(
          children: [
            LocalAssets(
              imagePath: icon,
              height: 20,
              width: 20,
              boxFix: BoxFit.cover,
              imgColor: AppColors.secondaryTextColor,
            ),
            const SizedBox(width: 10),
            CustomText(
              label,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  String _profileTypeLabel(String raw) {
    switch (raw) {
      case 'homeMadeFood':
        return 'Home Made Food';
      case 'homeMadeProduct':
        return 'Home Made Product';
      case 'homeService':
        return 'Home Service';
      default:
        return raw;
    }
  }
}
