import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_one_controller.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_two_controller.dart';
import 'package:BlueEra/features/common/map/controller/category_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:BlueEra/widgets/visiting_hour_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddPlaceStepOneScreen extends StatefulWidget {
  AddPlaceStepOneScreen({Key? key}) : super(key: key);

  @override
  State<AddPlaceStepOneScreen> createState() => _AddPlaceStepOneScreenState();
}

class _AddPlaceStepOneScreenState extends State<AddPlaceStepOneScreen> {
  final AddPlaceStepOneController controller =
      Get.put(AddPlaceStepOneController());

  @override
  void dispose() {
    // TODO: implement dispose
    Get.delete<AddPlaceStepOneController>();
    Get.delete<AddPlaceStepTwoController>();
    Get.delete<VisitingHoursSelector>();
    Get.delete<CategoryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unFocus(),
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: "Add a place (Step 1 of 2)",
        ),
        body: Obx(() {
          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(SizeConfig.size15),
                  child: CommonCardWidget(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: SizeConfig.size8,
                        ),

                        // Select Category
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteHelper.getCategorySelectionScreenRoute(),
                            );
                          },
                          child: CommonTextField(
                            readOnly: true,
                            textEditController: controller.categoryController,
                            title: "Select Category (Non-commercial only)",
                            hintText: "E.g., Temple, Hospital, Park",
                            isValidate: false,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            onChange: (value) => controller.validateForm(),
                          ),
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          "*Enter only non-commercial place types such as: temple, mosque, govt hospital, park, school, police station, etc.",
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.grey6D,
                        ),
                        SizedBox(height: SizeConfig.size20),

                        // Place Name
                        CommonTextField(
                          textEditController: controller.placesController,
                          title: "Place Name (Only public places)",
                          hintText: 'E.g., Shiv Temple, Govt Girls School',
                          isValidate: false,
                          regularExpression:
                              RegularExpressionUtils.alphabetSpacePattern,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          onChange: (value) => controller.validateForm(),
                        ),
                        SizedBox(height: SizeConfig.size20),

                        // Add Photos
                        CustomText(
                          "Add Photos of the Place (Max 5 Images)",
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Obx(() => SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ///LOCAL.....
                                  Row(
                                    children: List.generate(
                                        controller.selectedImages.length,
                                        (uploadIndex) {
                                      return _buildImageContainer(
                                          controller
                                              .selectedImages[uploadIndex],
                                          uploadIndex,
                                          context);
                                    }),
                                  ),

                                  ///EMPTY.....
                                  (5 - controller.selectedImages.length > 0)
                                      ? Row(
                                          children: List.generate(
                                              (5 -
                                                  controller.selectedImages
                                                      .length), (index) {
                                            return _buildImageContainer(
                                                "", 0, context);
                                          }),
                                        )
                                      : SizedBox(),
                                ],
                              ),
                            )),
                        SizedBox(height: SizeConfig.size20),

                        // Use Current Location
                        InkWell(
                          onTap: () => controller.fetchLocation(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              LocalAssets(
                                  imagePath: AppIconAssets.currentLocationIcon),
                              SizedBox(width: SizeConfig.size6),
                              CustomText("Use Current Location",
                                  color: AppColors.primaryColor)
                            ],
                          ),
                        ),
                        SizedBox(height: SizeConfig.size20),

                        // Address
                        CommonTextField(
                          textEditController: controller.landmarkController,
                          title: "Address or Landmark",
                          hintText: 'E.g., Sector 18, Noida',
                          isValidate: false,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          regularExpression:
                              RegularExpressionUtils.alphabetSpacePattern,
                          onChange: (value) => controller.validateForm(),
                        ),
                        SizedBox(height: SizeConfig.size12),

                        // Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Obx(() => CustomCheckBox(
                                  isChecked: controller.isConfirmCheck.value,
                                  onChanged: () =>
                                      controller.toggleConfirmCheck(),
                                  size: SizeConfig.size20,
                                  activeColor: AppColors.primaryColor,
                                  borderColor: AppColors.whiteB0,
                                )),
                            SizedBox(width: SizeConfig.size10),
                            Expanded(
                              child: CustomText(
                                "I confirm this is not a business or commercial place.",
                                fontSize: SizeConfig.small,
                                color: AppColors.black30,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size25),

                        // Next Button
                        Obx(() => CustomBtn(
                              onTap: (controller.validate.value)
                                  ? () {
                                      if (controller.lat.value.isNotEmpty &&
                                          controller.long.isNotEmpty) {
                                        Navigator.pushNamed(
                                          context,
                                          RouteHelper
                                              .getAddPlaceStepTwoScreenRoute(),
                                        );
                                      } else {
                                        commonSnackBar(
                                            message: "Location is required");
                                      }
                                    }
                                  : null,
                              title: 'Next',
                              isValidate: controller.validate.value,
                            ))
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.isFetchLocationLoading.value) CircularIndicator()
            ],
          );
        }),
      ),
    );
  }

  Widget _buildImageContainer(
      String? imagePath, int index, BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (imagePath == "") {
              final imgStr = await controller.captureImageFromCamera();
              if (imgStr != null && imgStr.isNotEmpty) {
                controller.addImage(imgStr);
              }
            }
          },
          child: Container(
            height: SizeConfig.size130,
            width: SizeConfig.size130,
            margin: EdgeInsets.only(right: SizeConfig.size8),
            decoration: BoxDecoration(
              color: AppColors.whiteED,
              borderRadius: BorderRadius.circular(10),
              image: imagePath != null && imagePath.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == ""
                ? Center(
                    child: LocalAssets(imagePath:AppIconAssets.profile_camera_pic),
                  )
                : null,
          ),
        ),
        if (imagePath != "")
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(50)),
              child: GestureDetector(
                onTap: () => controller.removeImage(index),
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
