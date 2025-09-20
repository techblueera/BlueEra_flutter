import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_more_details_screen/add_more_details_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';


class AddMoreDetailsDialog extends StatelessWidget {
  final String fromScreen;
  const AddMoreDetailsDialog({super.key, required this.fromScreen});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMoreDetailsController());

    return Dialog(
      insetPadding: const EdgeInsets.all(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: double.infinity,
        child: CustomFormCard(
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'Add More Details',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size15),

                // Title Field
                CustomText(
                  'Title',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: controller.titleController,
                  hintText: 'e.g. Title',
                  validator: controller.validateTitle,
                  maxLength: 50,
                  isCounterVisible: true
                ),

                SizedBox(height: SizeConfig.size20),

                // Variant Field
                CustomText(
                  'Details',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: controller.detailController,
                  hintText: 'e.g. Wireless Earbuds Bo....',
                  validator: controller.validateDetail,
                  maxLength: 200,
                  isCounterVisible: true
                ),

                SizedBox(height: SizeConfig.size30),

                // Save Button
                Obx(() => CustomBtn(
                  title: 'Save',
                  onTap: controller.isLoading.value
                      ? null
                      : ()=> controller.saveDetails(fromScreen: fromScreen),
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                  height: 45,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
