import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class BlockUserDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final String? userName;

  const BlockUserDialog({
    super.key,
    required this.onConfirm,
    required this.userName,
  });

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // String userName = (isIndividualUser()) ? userNameGlobal : businessOwnerNameGlobal;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 16),
            CustomText(
              userName != null && (userName?.isNotEmpty ?? false)
                  ? "${AppStrings.block.tr} ${userName ?? "${AppStrings.thisUser.tr}"} ?"
                  : "${AppStrings.blockThisUser.tr} ?",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                children: [
                   TextSpan(
                    text:
                        AppStrings.blockUserDescription.tr,
                  ),
                  TextSpan(
                    text: "${AppStrings.learnMore.tr}...",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _launchURL('https://bluecs.in/privacypolicy');
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const CustomText(AppStrings.cancel,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: CustomBtn(
                    title: AppStrings.block,
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    textColor: AppColors.white,
                    bgColor: AppColors.red,
                    borderColor: AppColors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
