import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showUpdateWebsiteBottomSheet(BuildContext context) {
  final controller = Get.find<ViewBusinessDetailsController>();
  final websiteController = TextEditingController(
    text: controller.businessProfileDetails.value?.data?.websiteUrl ?? '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (ctx) {
      return GestureDetector(
        onTap: () => FocusScope.of(ctx).unfocus(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomText(
                      'Update Website',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    const CloseButton(),
                  ],
                ),
                const SizedBox(height: 20),
                HttpsTextField(
                  controller: websiteController,
                  title: 'Website URL',
                  hintText: 'e.g. https://www.example.com',
                  isUrlValidate: true,
                ),
                const SizedBox(height: 24),
                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  title: AppStrings.save,
                  onTap: () async {
                    String? error = ValidationMethod.urlValidation(
                        websiteController.text.trim());
                    if (error != null) {
                      commonSnackBar(message: error);
                      return;
                    }
                    final params = <String, dynamic>{
                      ApiKeys.businessId: businessId,
                      ApiKeys.website_url: websiteController.text.trim(),
                    };
                    await controller.updateBusinessProfileDetails(params);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
        ),
      );
    },
  );
}
