import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/business_description/business_description_controller.dart';
import 'package:BlueEra/features/business/widgets/description_preview_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Common reusable Business Description card.
/// Extracted from [BusinessProfileWidget] so it can be shared across screens.
class BusinessDescriptionCard extends StatefulWidget {
  const BusinessDescriptionCard({super.key});

  @override
  State<BusinessDescriptionCard> createState() =>
      _BusinessDescriptionCardState();
}

class _BusinessDescriptionCardState extends State<BusinessDescriptionCard> {
  final controller = Get.find<ViewBusinessDetailsController>();
  final businessDescriptionController =
      Get.put(BusinessDescriptionController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        margin: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  letterSpacing: 0.4,
                  AppStrings.businessDescription,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.secondaryTextColor,
                ),
                (controller.isListingDescriptionEdit.value)
                    ? Row(
                        children: [
                          Obx(() => !controller.isLoading.value
                              ? InkWell(
                                  onTap: () {
                                    controller.listingDescriptionController
                                            .value.text =
                                        controller.businessDescription.value
                                            .toString();
                                    businessDescriptionController
                                        .generateDescriptions(bodyRequest: {
                                      ApiKeys.business_name: controller
                                          .businessProfileDetails
                                          .value
                                          ?.data
                                          ?.businessName,
                                      ApiKeys.category: controller
                                          .businessProfileDetails
                                          .value
                                          ?.data
                                          ?.categoryDetails
                                          ?.name,
                                      ApiKeys.sub_category: controller
                                          .businessProfileDetails
                                          .value
                                          ?.data
                                          ?.subCategoryDetails
                                          ?.name,
                                      ApiKeys.city: controller
                                          .businessProfileDetails
                                          .value
                                          ?.data
                                          ?.cityStatePincode,
                                    });
                                    setState(() {
                                      controller.isListingDescriptionEdit
                                              .value =
                                          !controller
                                              .isListingDescriptionEdit.value;
                                    });
                                  },
                                  child: LocalAssets(
                                    height: 25,
                                    width: 25,
                                    imgColor: AppColors.primaryColor,
                                    imagePath: AppIconAssets.ai_generative,
                                  ))
                              : SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ))),
                          SizedBox(
                            width: SizeConfig.size10,
                          ),
                          InkWell(
                              onTap: () {
                                controller.listingDescriptionController.value
                                        .text =
                                    controller.businessDescription.value
                                        .toString();
                                setState(() {
                                  controller.isListingDescriptionEdit.value =
                                      !controller
                                          .isListingDescriptionEdit.value;
                                });
                              },
                              child: LocalAssets(
                                height: 16,
                                imagePath: AppIconAssets.pen_line,
                              )),
                        ],
                      )
                    : Row(
                        children: [
                          CustomBtn(
                              height: 24,
                              width: 56,
                              onTap: () {
                                businessDescriptionController
                                    .descriptionSuggestions
                                    .clear();
                                setState(() {
                                  controller.isListingDescriptionEdit.value =
                                      !controller
                                          .isListingDescriptionEdit.value;
                                });
                              },
                              title: AppStrings.cancel),
                          const SizedBox(
                            width: 8,
                          ),
                          CustomBtn(
                              height: 24,
                              width: 56,
                              bgColor: theme.colorScheme.primary,
                              onTap: () async {
                                if (controller.listingDescriptionController
                                    .value.text.isNotEmpty) {
                                  businessDescriptionController
                                      .descriptionSuggestions
                                      .clear();
                                  setState(() {
                                    controller.isListingDescriptionEdit.value =
                                        !controller
                                            .isListingDescriptionEdit.value;
                                  });
                                  Map<String, dynamic> params = {
                                    ApiKeys.description:
                                        "${controller.listingDescriptionController.value.text}"
                                  };
                                  await controller
                                      .updateBusinessDescription(params);
                                } else {
                                  commonSnackBar(
                                      message: AppStrings.descriptionEmpty);
                                }
                              },
                              title: AppStrings.save),
                        ],
                      )
              ],
            ),
            SizedBox(
              height: SizeConfig.size6,
            ),
            CustomText(
              AppStrings.tellCustomersWhatYouOffer,
              fontSize: SizeConfig.size12,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(
              height: SizeConfig.size6,
            ),
            (controller.isListingDescriptionEdit.value)
                ? SizedBox()
                : const SizedBox(
                    height: 4,
                  ),
            (controller.isListingDescriptionEdit.value &&
                    controller.businessDescription != '')
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.whiteE5),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [AppShadows.textFieldShadow],
                    ),
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 16),
                    padding:
                        EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                    child: Obx(() {
                      return DescriptionPreview(
                        text: controller.businessDescription.value,
                        dialogTitle: AppStrings.businessDescription,
                      );
                    }),
                  )
                : CommonTextField(
                    borderWidth: 0,
                    borderColor: Colors.transparent,
                    hintText: AppStrings.addBusinessDetails,
                    textEditController:
                        controller.listingDescriptionController.value,
                    maxLine: 5,
                    inputLength: 900,
                    isValidate: false,
                    maxLength: AppConstants.inputCharterLimit400,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        AppConstants.inputCharterLimit400,
                      ),
                      NoLeadingSpaceFormatter(),
                      NoConsecutiveSpacesFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.pleaseEnterBusinessDetails.tr;
                      }
                      if (value.trim().length < 50) {
                        return AppStrings.min50Characters.tr;
                      }
                      if (value.trim().length > 900) {
                        return AppStrings.max900Characters.tr;
                      }
                      return null;
                    },
                  ),
            Obx(() {
              return SizedBox(
                height: (controller.isListingDescriptionEdit.value)
                    ? 8
                    : SizeConfig.size18,
              );
            }),
          ],
        ),
      );
    });
  }
}
