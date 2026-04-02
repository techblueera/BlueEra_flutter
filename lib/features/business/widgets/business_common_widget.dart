
import 'package:BlueEra/core/api/model/type_of_business_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down_icon_dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/api/apiService/api_keys.dart';

void openOwnerEditSheet({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController roleController,
  required TextEditingController emailController,
  required VoidCallback onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // important
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // close keyboard on tap outside
        child: Padding(
          // this ensures the bottom sheet moves *above* the keyboard

          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomText(
                      AppStrings.ownerDetails,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    CloseButton(),
                  ],
                ),
                const SizedBox(height: 20),
                CommonTextField(
                  textEditController: nameController,
                  inputLength: 50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                  title: AppStrings.yourName,
                  hintText: AppStrings.yourNameHint,
                  isValidate: false,
                  autoFillType: AutoFillType.name,
                ),
                const SizedBox(height: 16),
                CommonTextField(
                  textEditController: roleController,
                  inputLength: 50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                  title: AppStrings.yourRole,
                  hintText: AppStrings.yourRoleHint,
                  isValidate: false,
                ),
                const SizedBox(height: 16),
                CommonTextField(
                  textEditController: emailController,
                  inputLength: 50,
                  keyBoardType: TextInputType.emailAddress,
                  regularExpression: RegularExpressionUtils.emailPattern,
                  title: AppStrings.email,
                  hintText: AppStrings.emailHint,
                  isValidate: false,
                  autoFillType: AutoFillType.email,
                ),
                const SizedBox(height: 24),
                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  title: AppStrings.save,
                  onTap: onSave,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void openBusinessDetailsEditSheet(BuildContext context) {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final data = viewBusinessDetailsController.businessProfileDetails.value?.data;

  viewBusinessDetailsController.shopOpenTime.value =
      data?.openTime?.toString() ?? '';

  viewBusinessDetailsController.shopCloseTime.value =
      data?.closeTime?.toString() ?? '';
  // Controllers prSizeOfBusiness? selectedBusiness;e-filled with existing data
  TextEditingController specializationCtrl = TextEditingController(
    text: viewBusinessDetailsController
            .businessProfileDetails.value?.data?.specification ??
        '',
  );
  NatureOfBusiness? selectedBusiness;
  NatureOfBusiness? getBusinessFromString(String? input) {
    if (input == null) return null;

    return NatureOfBusiness.values.firstWhere(
      (e) => e.displayName.toLowerCase() == input.toLowerCase(),
      orElse: () => NatureOfBusiness.OTHERS,
    );
  }

  selectedBusiness = getBusinessFromString(viewBusinessDetailsController
      .businessProfileDetails.value?.data?.natureOfBusiness);

  final subCategoryTextController = TextEditingController(
      text: viewBusinessDetailsController
              .businessProfileDetails.value?.data?.category_other ??
          "");
  viewBusinessDetailsController.selectedCategory.value = CategoryData(
      id: viewBusinessDetailsController
          .businessProfileDetails.value?.data?.categoryDetails?.id,
      name: viewBusinessDetailsController
          .businessProfileDetails.value?.data?.categoryDetails?.name);
  viewBusinessDetailsController.selectedSubCategory.value = SubCategories(
      sId: viewBusinessDetailsController
          .businessProfileDetails.value?.data?.subCategoryDetails?.id,
      name: viewBusinessDetailsController
          .businessProfileDetails.value?.data?.subCategoryDetails?.name);

  final typeFromApi = viewBusinessDetailsController
      .businessProfileDetails.value?.data?.typeOfBusiness;

  final selectedCategory = getBusinessCategoryFromType(
    typeFromApi,
    typeOfBusinessList,
  );
  viewBusinessDetailsController.selectedTypeOfBusiness.value = selectedCategory;

  viewBusinessDetailsController.selectedBusinessType?.value =
      BusinessType.values.firstWhere(
    (e) => e.name == selectedCategory.type,
    orElse: () => BusinessType.Both,
  );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (context) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // dismiss keyboard on tap outside
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      // this ensures bottom padding adjusts dynamically with keyboard
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                CustomText(
                                  AppStrings.editBusinessDetails,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                CloseButton(),
                              ],
                            ),
                            const SizedBox(height: 20),

                            CustomText(
                              AppStrings.typeOfBusiness,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size10),

                            Obx(() {
                              return CommonDropdownIconDialog<BusinessCategory>(
                                items: typeOfBusinessList,
                                selectedValue: viewBusinessDetailsController
                                    .selectedTypeOfBusiness.value,
                                hintText: AppStrings.selectNatureOfBusiness.tr,
                                title: AppStrings.selectNatureOfBusiness.tr,
                                displayValue: (item) => item.title,
                                displayValueSubTitle: (item) => item.subTitle,
                                displayValueImagePath: (item) => item.icon,
                                onChanged: (value) {
                                  viewBusinessDetailsController
                                      .selectedTypeOfBusiness.value = value;

                                  /// 🔥 Load categories dynamically
                                  viewBusinessDetailsController
                                      .getAllCategories();
                                },
                              );
                            }),
                            SizedBox(height: SizeConfig.size10),

                            CustomText(
                              "${AppStrings.categoryOfBusiness.tr} ${viewBusinessDetailsController.selectedBusinessType?.value.name}",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                            ),
                            SizedBox(height: SizeConfig.size10),
                            Obx(() {
                              return CommonDropdownDialog<CategoryData>(
                                items:
                                    viewBusinessDetailsController.categoryList,
                                selectedValue: viewBusinessDetailsController
                                    .selectedCategory.value,
                                hintText: "Select Category",
                                title: "Select Category",
                                displayValue: (item) => item.name ?? "",
                                onChanged: (value) {
                                  if (value != null) {
                                    viewBusinessDetailsController
                                        .onCategorySelected(value);
                                  }
                                },
                              );
                            }),
                            SizedBox(height: SizeConfig.size10),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                AppStrings.subCategory,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size10),
                            Obx(() {
                              return CommonDropdownDialog<SubCategories>(
                                items: viewBusinessDetailsController
                                    .subCategoryList,
                                selectedValue: viewBusinessDetailsController
                                    .selectedSubCategory.value,
                                hintText: "Select Product / Service",
                                title: "Select Product / Service",
                                displayValue: (item) => item.name ?? "",
                                onChanged: (value) {
                                  if (viewBusinessDetailsController
                                      .subCategoryList.isEmpty) return;

                                  viewBusinessDetailsController
                                      .selectedSubCategory.value = value;
                                },
                              );
                            }),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        AppStrings.shopOpenTime,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.black,
                                      ),
                                      SizedBox(
                                        height: SizeConfig.size10,
                                      ),
                                      _buildDropdown(
                                          hint: AppStrings.shopOpenTime,
                                          value: viewBusinessDetailsController
                                              .shopOpenTime.value,
                                          items: List.generate(
                                            48,
                                            (i) =>
                                                "${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? "00" : "30")}",
                                          ),
                                          onChanged: (val) {
                                            viewBusinessDetailsController
                                                .shopOpenTime.value = val ?? '';
                                          }
                                          // addServiceController.startTime.value = val!,
                                          ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        AppStrings.shopCloseTime,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.black,
                                      ),
                                      SizedBox(
                                        height: SizeConfig.size10,
                                      ),
                                      _buildDropdown(
                                          hint: AppStrings.shopCloseTime,
                                          value: viewBusinessDetailsController
                                              .shopCloseTime.value,
                                          items: List.generate(
                                            48,
                                            (i) =>
                                                "${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? "00" : "30")}",
                                          ),
                                          onChanged: (val) {
                                            viewBusinessDetailsController
                                                .shopCloseTime
                                                .value = val ?? '';
                                          }
                                          // addServiceController.startTime.value = val!,
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            CustomBtn(
                              radius: 10,
                              bgColor: AppColors.primaryColor,
                              title: AppStrings.save,
                              onTap: () async {
                                final controller =
                                    Get.find<ViewBusinessDetailsController>();

                                if (controller
                                        .selectedTypeOfBusiness.value?.type ==
                                    null) {
                                  commonSnackBar(
                                      message:
                                          AppStrings.selectBusinessCategory);
                                  return;
                                } else if (controller
                                        .selectedCategory.value?.id ==
                                    null) {
                                  commonSnackBar(
                                      message: AppStrings.selectCategory);
                                  return;
                                } else if (controller
                                        .selectedSubCategory.value?.sId ==
                                    null) {
                                  commonSnackBar(
                                      message: AppStrings.selectSubCategory);
                                  return;
                                }


                                Map<String, dynamic> updatedParams = {
                                  ApiKeys.businessId: businessId,
                                  ApiKeys.opening_time:
                                      viewBusinessDetailsController
                                          .shopOpenTime.value,
                                  ApiKeys.closing_time:
                                      viewBusinessDetailsController
                                          .shopCloseTime.value,
                                  if (viewBusinessDetailsController
                                          .selectedBusinessType?.value.name
                                          .toLowerCase() ==
                                      "both")
                                    ApiKeys.category_other:
                                        subCategoryTextController.text,
                                  ApiKeys.category:
                                      viewBusinessDetailsController
                                          .selectedCategory.value?.id,
                                  ApiKeys.sub_category_Of_Business:
                                      viewBusinessDetailsController
                                          .selectedSubCategory.value?.sId,
                                  ApiKeys.type_of_business:
                                      viewBusinessDetailsController
                                              .selectedTypeOfBusiness
                                              .value
                                              ?.type ??
                                          '',
                                  // viewBusinessDetailsController
                                  //     .selectedTypeOfBusiness.value
                                  ApiKeys.specification:
                                      specializationCtrl.text.trim(),
                                  ApiKeys.category_Of_Business:
                                      // (viewBusinessDetailsController
                                      //             .selectedBusinessType
                                      //             ?.value
                                      //             .name
                                      //             .toLowerCase() ==
                                      //         "both")
                                      //     ? '68a80b766fdb4e82b42b77c0'
                                      //     :
                                      viewBusinessDetailsController
                                              .selectedCategory.value?.tagId,
                                  ApiKeys.Nature_of_Business:
                                      selectedBusiness ==
                                          selectedBusiness?.displayName,
                                };
                                await Get.find<ViewBusinessDetailsController>()
                                    .updateBusinessDetails(updatedParams);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildDropdown({
  required String hint,
  required String value,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  // Ensure the current value exists in items to avoid DropdownButton assertion error
  final effectiveItems = List<String>.from(items);
  if (value.isNotEmpty && !effectiveItems.contains(value)) {
    effectiveItems.add(value);
    effectiveItems.sort();
  }

  return Container(
    padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.greyE5),
      boxShadow: [AppShadows.textFieldShadow],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        value: value.isEmpty ? null : value,
        hint: CustomText(hint, color: Colors.grey[600]),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        style: TextStyle(color: Colors.black87, fontSize: 14),
        items: effectiveItems.map((String t) {
          return DropdownMenuItem<String>(
            value: t,
            child: Text(t),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget buildInfo(String title, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        title + ":",
        fontSize: SizeConfig.size12,
        color: AppColors.grayText,
        fontWeight: FontWeight.w400,
      ),
      SizedBox(width: SizeConfig.size6),
      Flexible(
        child: CustomText(
          value,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor,
        ),
      ),
    ],
  );
}
