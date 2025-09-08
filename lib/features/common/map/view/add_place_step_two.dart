import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_two_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_hour_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddPlaceStepTwoScreen extends StatelessWidget {
  AddPlaceStepTwoScreen({Key? key}) : super(key: key);

  final AddPlaceStepTwoController controller =
      Get.put(AddPlaceStepTwoController());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unFocus(),
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: "(Step 2 of 2) Optional",
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Short Description
                  CommonTextField(
                    textEditController: controller.shortDescriptionController,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    inputLength: AppConstants.inputCharterLimit200,
                    title: "Short Description (optional)",
                    hintText:
                        "E.g., This park is open for morning walks and yoga...",
                    maxLine: 4,
                    maxLength: 200,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    isValidate: false,
                  ),
                  SizedBox(height: SizeConfig.size15),

                  // Phone Number
                  const CustomText("Landline/ Phone Number (optional)"),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: CommonTextField(
                          textEditController: controller.mobileCodeController,
                          isValidate: false,
                          hintText: countryCode,
                          maxLength: 4,
                          keyBoardType: TextInputType.phone,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.paddingXSL,
                              vertical: SizeConfig.paddingXSL),
                          regularExpression:
                              RegularExpressionUtils.phoneWithPrefixPattern,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        flex: 6,
                        child: CommonTextField(
                          textEditController: controller.mobileNumberController,
                          regularExpression:
                              RegularExpressionUtils.digitsPattern,
                          isValidate: false,
                          maxLength: 10,
                          validationType: ValidationTypeEnum.pNumber,
                          hintText: "e.g. 98765 43210",
                          keyBoardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size15),

                  // Email
                  CommonTextField(
                    textEditController: controller.emailController,
                    isValidate: true,
                    validationType: ValidationTypeEnum.email,
                    title: "Enter email",
                    hintText: "Enter email",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    onChange: (value) => controller.validateForm(),
                  ),

                  SizedBox(height: SizeConfig.size15),

                  // Visiting Hours
                  Row(
                    children: [
                      CustomText(
                        "Set Visiting Hours",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                      ),
                      CustomText(
                        " (optional)",
                        fontSize: SizeConfig.small,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    "Let others know when this place is open to the public.",
                    fontSize: SizeConfig.small,
                  ),

                  SizedBox(height: SizeConfig.size15),

                  VisitingHoursSelector(),

                  SizedBox(height: SizeConfig.size25),

                  // Submit Button
                  Obx(() => CustomBtn(
                        onTap: (controller.validate.value)
                            ? () async {
                                await controller.addPlaceController();
                                if (controller.addPlaceResponse.value.status ==
                                    Status.COMPLETE) {
                                  showUnderReviewDialog(context);
                                }
                              }
                            : null,
                        title: 'Submit Place',
                        isValidate: controller.validate.value,
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showUnderReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: AlertDialog(
          backgroundColor: AppColors.white, // dark blue-ish background
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          contentPadding: EdgeInsets.fromLTRB(SizeConfig.size40,
              SizeConfig.size25, SizeConfig.size40, SizeConfig.size25),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(imagePath: AppIconAssets.watchIcon),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    "Under Review",
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black30,
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size10),
              CustomText(
                "Your place submission has been received and is currently under review. We’ll notify you once it’s verified.",
                textAlign: TextAlign.center,
                fontSize: SizeConfig.medium,
                color: AppColors.black30,
              ),
              SizedBox(height: SizeConfig.size15),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Get.offAllNamed(
                          RouteHelper.getBottomNavigationBarScreenRoute(),
                          arguments: {ApiKeys.initialIndex: 0},
                        );
                      },
                      child: CustomText(
                        "Done",
                        fontSize: SizeConfig.large,
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomBtn(
                      height: SizeConfig.size45,
                      onTap: () {
                        Get.offAllNamed(
                          RouteHelper.getBottomNavigationBarScreenRoute(),
                          arguments: {ApiKeys.initialIndex: 0},
                        );
                      },
                      title: 'Add Another',
                      isValidate: true,
                      radius: 8.0,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
