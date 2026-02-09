import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/help_and_support_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/snackbar_helper.dart';

class HelpAndSupportFormScreen extends StatelessWidget {
  HelpAndSupportFormScreen({super.key});

  final controller = Get.find<HelpAndSupportController>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.mailUs,
        ),
        body: Container(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size20, horizontal: SizeConfig.size14),
          margin: EdgeInsets.symmetric(horizontal: 8,vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.helpSupportQuestion,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              SizedBox(height: SizeConfig.size20),

              CommonTextField(
                textEditController: controller.emailController,
                keyBoardType: TextInputType.emailAddress,
                hintText: AppStrings.enterYourEmail,
                title: AppStrings.email,
              ),
              // Email Input

              SizedBox(height: SizeConfig.size16),

              // Message Input
              CommonTextField(
                textEditController: controller.messageController,
                keyBoardType: TextInputType.multiline,
                onChange: controller.setMessage,
                hintText: AppStrings.enterYourMessage,
                title: AppStrings.message,
                maxLine: 5,
              ),
              // _buildInputField(
              //   label: 'Message',
              //   hintText: AppStrings.enterYourMessage,
              //   onChanged: controller.setMessage,
              //   maxLines: 4,
              //   keyboardType: TextInputType.multiline,
              //   controller: controller.messageController,
              // ),
              SizedBox(height: SizeConfig.size24),

              // Submit Button
              PositiveCustomBtn(
                  onTap:
                      controller.isLoading.value ? null : controller.submitForm,
                  title: AppStrings.submit),
            ],
          ),
        ));
  }
}
