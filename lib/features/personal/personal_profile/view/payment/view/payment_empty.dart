import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class PaymentSettingEmptyScreen extends StatelessWidget {
  const PaymentSettingEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CommonBackAppBar(
        title: "Payment Setting",
        isLeading: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size24),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [

              Image.asset(
                "assets/images/empty_bank.png",
                height: 140,
              ),

              SizedBox(height: SizeConfig.size20),

              CustomText(
                "You Have Not Add Any\nBank Account",
                textAlign: TextAlign.center,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),

              SizedBox(height: SizeConfig.size8),

              GestureDetector(
                onTap: () {

                },
                child: CustomText(
                  "Add Now!",
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}