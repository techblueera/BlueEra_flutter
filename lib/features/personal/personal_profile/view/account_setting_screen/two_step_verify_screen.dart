import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';



class TwoStepVerifyScreen extends StatefulWidget {

  const TwoStepVerifyScreen({
    super.key,
  });

  @override
  State<TwoStepVerifyScreen> createState() => _TwoStepVerifyScreenState();
}

class _TwoStepVerifyScreenState extends State<TwoStepVerifyScreen> {

  String get otpauthUrl {
    return 'otpauth://totp/YourApp:prabha@gmail.com?secret=AHSKDNceeij73&issuer=YourApp';
  }

  void copySecretKey() {
    Clipboard.setData(ClipboardData(text: "SHHDKSUDNSJD"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.enableTwoStepVerification,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              const SizedBox(height: 10),

              /// Title
              const CustomText(
                AppStrings.setupTwoStepVerification,

                  fontSize: 20,
                  fontWeight: FontWeight.bold,

              ),

              const SizedBox(height: 10),

              /// Instruction
              const CustomText(
                AppStrings.twoStepVerificationInstruction,
                textAlign: TextAlign.center,
               fontSize: 14, color: AppColors.grayText
              ),

              const SizedBox(height: 30),

              /// QR Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: otpauthUrl,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),

              const SizedBox(height: 30),

              /// Secret Key Label
              const Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  AppStrings.manualSetupCode,

                    fontSize: 16,
                    fontWeight: FontWeight.w600,

                ),
              ),

              const SizedBox(height: 10),

              /// Bordered Secret Key Box with Copy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    /// Secret Key Text
                    Expanded(
                      child: CustomText(
                        "SGGREF",
                          fontSize: 16,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                      ),
                    ),

                    /// Copy Button
                    InkWell(
                      onTap: copySecretKey,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.copy,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Info Text
              const CustomText(
                AppStrings.manualSetupCodeInstruction,
                textAlign: TextAlign.center,
                fontSize: 13, color: AppColors.grayText
              ),

              const Spacer(),

              /// Continue Button
             CustomBtn(onTap: (){},isValidate: true ,title: AppStrings.continueBtn.tr)
            ],
          ),
        ),
      ),
    );
  }
}