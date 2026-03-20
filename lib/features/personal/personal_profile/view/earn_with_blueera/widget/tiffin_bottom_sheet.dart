import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/tiffin_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TiffinBottomSheet extends StatelessWidget {
  final TiffinController tiffinController = Get.find<TiffinController>();

  TiffinBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TiffinBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonDraggableBottomSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (scrollController) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.size8,
              right: SizeConfig.size8,
              bottom: SizeConfig.size8,
            ),
            child: Column(
              children: [

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      'Edit',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        size: 22,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Form(
                      key: tiffinController.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upload Image
                          CustomText(
                            'Upload Image',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.mainTextColor,
                          ),
                          SizedBox(height: SizeConfig.size8),
                          _buildImageUploader(),

                          SizedBox(height: SizeConfig.size16),

                          // Tiffin Name
                          CommonTextField(
                            title: 'Morning Tiffin / Lunch Name',
                            hintText: 'E.g. Short-circuit & power failure repair....',
                            isValidate: true,
                            maxLength: 50,
                            textEditController:
                            tiffinController.tiffinNameController,
                            isCounterVisible: true,
                            onChange: (text) {},
                          ),

                          SizedBox(height: SizeConfig.size16),

                          // Food Type & Cooking Method
                          Obx(() => Row(
                            children: [
                              Expanded(
                                child: CommonDropdownDialog<String>(
                                  items: tiffinController.foodTypeList,
                                  selectedValue: tiffinController.selectedFoodType.value.isEmpty
                                      ? null
                                      : tiffinController.selectedFoodType.value,
                                  title: 'Food Type',
                                  hintText: 'E.g.  Veg',
                                  displayValue: (value) => value,
                                  onChanged: (value) {
                                    tiffinController.selectedFoodType.value = value ?? '';
                                  },
                                ),
                              ),

                              SizedBox(width: SizeConfig.size12),
                              Expanded(
                                child: CommonDropdownDialog<String>(
                                  items: tiffinController.cookingMethodList,
                                  selectedValue: tiffinController.selectedCookingMethod.value.isEmpty
                                      ? null
                                      : tiffinController.selectedCookingMethod.value,
                                  title: 'Cooking Method',
                                  hintText: 'E.g.  Boiled',
                                  displayValue: (value) => value,
                                  onChanged: (value) {
                                    tiffinController.selectedCookingMethod.value = value ?? '';
                                  },
                                ),
                              ),
                            ],
                          )),

                          SizedBox(height: SizeConfig.size16),

                          // Price MRP & Selling Price
                          Row(
                            children: [
                              Expanded(
                                child: CommonTextField(
                                  title: 'Price (MRP)',
                                  hintText: 'E.g. ₹159',
                                  validator: ValidationMethod().validateMRP,
                                  keyBoardType: TextInputType.number,
                                  textEditController: tiffinController
                                      .mrpPriceController,
                                  onChange: (text) {},
                                ),
                              ),
                              SizedBox(width: SizeConfig.size12),
                              Expanded(
                                child: CommonTextField(
                                  title: 'Selling Price',
                                  hintText: 'E.g. ₹100',
                                  validator: (value) => ValidationMethod().validatePrice(
                                      tiffinController.sellingPriceController.text, tiffinController.mrpPriceController.text),
                                  keyBoardType: TextInputType.number,
                                  textEditController: tiffinController
                                      .sellingPriceController,
                                  onChange: (text) {},
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: SizeConfig.size16),

                          // Tiffin Time
                          CustomText(
                            'Morning Tiffin / Lunch',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mainTextColor,
                          ),
                          SizedBox(height: SizeConfig.size8),
                          Obx(() => Row(
                            children: [
                              Expanded(
                                child: CommonDropdownDialog<String>(
                                  items: tiffinController.startTimeList,
                                  selectedValue: tiffinController.selectedStartTime.value.isEmpty
                                      ? null
                                      : tiffinController.selectedStartTime.value,
                                  title: '',
                                  hintText: '7:00 AM',
                                  displayValue: (value) => value,
                                  onChanged: (value) {
                                    tiffinController.selectedStartTime.value = value ?? '';
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CommonDropdownDialog<String>(
                                  items: tiffinController.endTimeList,
                                  selectedValue: tiffinController.selectedEndTime.value.isEmpty
                                      ? null
                                      : tiffinController.selectedEndTime.value,
                                  title: '',
                                  hintText: '2:00 PM',
                                  displayValue: (value) => value,
                                  onChanged: (value) {
                                    tiffinController.selectedEndTime.value = value ?? '';
                                  },
                                ),
                              ),
                            ],
                          )),

                        ],
                      ),
                    ),
                  ),
                ),

                // Go Live Button
                CustomBtn(
                  height: SizeConfig.size40,
                  title: 'Go Live',
                  onTap: tiffinController.onGoLive,
                  bgColor: AppColors.primaryColor,
                  radius: 10,
                ),

                SizedBox(height: 10)

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageUploader() {
    return Obx(() {
      final file = tiffinController.tiffinImageFile.value;

      return InkWell(
        onTap: () {
          if (file == null) {
            tiffinController.pickImage();
          } else {
            Get.to(
                  () => ImageViewScreen(
                appBarTitle: 'Tiffin Image',
                imageUrls: [file.path],
                initialIndex: 0,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppColors.greyE5),
            boxShadow: [AppShadows.textFieldShadow],
          ),
          child: file == null
              ? Padding(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(imagePath: AppIconAssets.documentUploadIcon),
                SizedBox(width: SizeConfig.size8),
                CustomText(
                  'Upload',
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          )
              : SizedBox(
            height: SizeConfig.size150,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () =>
                    tiffinController.tiffinImageFile.value = null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}