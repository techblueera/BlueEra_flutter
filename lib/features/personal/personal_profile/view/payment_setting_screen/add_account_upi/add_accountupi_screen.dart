import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_upi/add_accountupi_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddAccountUpiScreen extends StatelessWidget {
  AddAccountUpiScreen({super.key});
  // final controller = Get.put(AddAccountupiController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddAccountupiController>(
        init: AddAccountupiController(),
        builder: (controller) {
          return Scaffold(
            appBar: CommonBackAppBar(
              title: controller.isUpdate.value
                  ? 'Update UPI Account'
                  : 'Add UPI Account',
              isLeading: true,
            ),
            body: Padding(
              padding: EdgeInsets.all(SizeConfig.size16),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: Get.width,
                      padding: EdgeInsets.all(SizeConfig.size10),
                      decoration: BoxDecoration(
                          color: AppColors.fillColor,
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "Bank Name",
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                          ),
                          SizedBox(
                            height: SizeConfig.size12,
                          ),
                          CommonTextField(
                            textEditController: controller.bankNameController,
                            hintText: 'E.g. State Bank Of India',
                            keyBoardType: TextInputType.text,
                            validator: controller.bankValidate,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size16,
                              vertical: SizeConfig.size12,
                            ),
                            borderColor: AppColors.greyE5,
                            borderWidth: 1,
                          ),
                          SizedBox(
                            height: SizeConfig.size12,
                          ),
                          CustomText(
                            "UPI ID",
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                          ),
                          SizedBox(
                            height: SizeConfig.size12,
                          ),
                          CommonTextField(
                            textEditController: controller.upiController,
                            hintText: 'E.g.0123456789',
                            keyBoardType: TextInputType.text,
                            validator: controller.upiValidate,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size16,
                              vertical: SizeConfig.size12,
                            ),
                            borderColor: AppColors.greyE5,
                            borderWidth: 1,
                          ),
                          SizedBox(
                            height: SizeConfig.size25,
                          ),
                          CustomBtn(
                            // onTap:
                            onTap: controller.isLoading.value
                                ? null
                                // : controller.AddUpiApi,
                                : controller.isUpdate.value
                                    ? () => controller.updateUpiAccount(
                                        id: controller.upiAccountId)
                                    : controller.AddUpiApi,
                            title: controller.isUpdate.value ? 'Update' : 'Add',
                            // title: "Add",
                            bgColor: AppColors.primaryColor,
                            textColor: AppColors.white,
                            radius: SizeConfig.size8,
                            height: SizeConfig.buttonXL,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.bold,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
