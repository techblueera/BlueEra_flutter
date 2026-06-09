import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/add_more_details_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerStep2Section extends StatefulWidget {
  final ManufacturerProductController controller;
  const ManufacturerStep2Section({super.key, required this.controller});

  @override
  State<ManufacturerStep2Section> createState() =>
      _ManufacturerStep2SectionState();
}

class _ManufacturerStep2SectionState extends State<ManufacturerStep2Section> {
  late List<TextEditingController> tempFeatureControllers;
  late TextEditingController tempLinkController;
  late List<ManufacturerProductMoreDetails> tempDetailsList;

  @override
  void initState() {
    super.initState();

    // 🔹 Copy old values into local variables
    tempFeatureControllers = widget.controller.featureControllers
        .map((c) => TextEditingController(text: c.text))
        .toList();

    tempLinkController =
        TextEditingController(text: widget.controller.linkController.text);

    tempDetailsList =
        List<ManufacturerProductMoreDetails>.from(widget.controller.detailsList);
  }

  void _restoreOldValues() {
    widget.controller.featureControllers.clear();
    for (final c in tempFeatureControllers) {
      widget.controller.featureControllers
          .add(TextEditingController(text: c.text));
    }

    widget.controller.linkController.text = tempLinkController.text;

    widget.controller.detailsList.value = tempDetailsList.map((spec) {
      return ManufacturerProductMoreDetails(
        title: spec.title,
        details: spec.details,
      );
    }).toList();
  }

  Future<bool> _handleBackPress(BuildContext context) async {
    bool shouldPop = false;

    await showCommonDialog(
      context: context,
      text: AppStrings.changesWillBeLost,
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
      confirmCallback: () {
        _restoreOldValues(); // Restore previous values
        Get.close(2); // Close two screens
        shouldPop = true;
      },
      cancelCallback: () {
        Navigator.of(context).pop(); // Close the dialog
        shouldPop = false;
      },
    );

    return shouldPop;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackPress(context);
        if (shouldPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.productFeature,
          onBackTap: () async {
            final shouldPop = await _handleBackPress(context);
            if (shouldPop) {
              Navigator.of(context).maybePop();
            }
          },
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
          child: Form(
            key: widget.controller.formKeyStep2,
            child: Column(
              children: [
                CustomFormCard(
                  margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      CustomText(
                        widget.controller.productNameController.text,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      CustomText(
                        widget.controller.selectedCategory.isNotEmpty ?? false
                            ? widget.controller.selectedCategory.value
                            : '-',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size12),
                _buildProductFeaturesSection(widget.controller),
                SizedBox(height: SizeConfig.size12),
                _buildAddOption(context),
                SizedBox(height: SizeConfig.size30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                  child: CustomBtn(
                    title: AppStrings.save,
                    onTap: () => Get.back(),
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    height: SizeConfig.size40,
                    radius: 10.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductFeaturesSection(ManufacturerProductController controller) {
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.addProductFeatures,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size16),
          Obx(() => Column(
                children:
                    List.generate(controller.featureControllers.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CommonTextField(
                            title: '${AppStrings.feature.tr} ${i + 1}',
                            hintText: AppStrings.hintProductFeature,
                            textEditController: controller.featureControllers[i],
                            maxLine: 2,
                            validator: (value) =>
                                ValidationMethod().validateFeatures(value, i),
                            maxLength: 140,
                            isCounterVisible: true,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        if (controller.featureControllers.length > 1)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => controller.removeFeature(i),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    EdgeInsets.only(top: SizeConfig.size20),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: AppColors.primaryColor,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              )),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: controller.addFeature,
            child: Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                SizedBox(width: SizeConfig.size10),
                CustomText(AppStrings.addMoreOption,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: controller.showLinkField.toggle,
            child: Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                SizedBox(width: SizeConfig.size10),
                CustomText(AppStrings.addLinkReferenceWebsite,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
          Obx(() => controller.showLinkField.isTrue
              ? Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size15),
                  child: HttpsTextField(
                      title: AppStrings.linkReferenceWebsite,
                      hintText: AppStrings.httpsExampleCom,
                      controller: controller.linkController,
                      isUrlValidate: false),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildAddOption(BuildContext context) {
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: Column(
        children: [
          Obx(() => widget.controller.detailsList.isNotEmpty
              ? Column(
                  children: List.generate(
                    widget.controller.detailsList.length,
                    (index) {
                      final item = widget.controller.detailsList[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index == 0) ...[
                              CustomText(
                                AppStrings.details,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                              SizedBox(height: SizeConfig.size12),
                            ],
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        boxShadow: [AppShadows.textFieldShadow],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.greyE5,
                                        )),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CustomText(
                                                item.title,
                                                fontSize: SizeConfig.large,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.mainTextColor,
                                              ),
                                              const SizedBox(height: 4),
                                              CustomText(
                                                item.details,
                                                fontSize: SizeConfig.medium,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    AppColors.secondaryTextColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                    right: 6,
                                    top: -15,
                                    child: InkWell(
                                      onTap: () =>
                                          widget.controller.removeDetail(index),
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: AppColors.white,
                                            boxShadow: [
                                              AppShadows.textFieldShadow
                                            ],
                                            border: Border.all(
                                              color: AppColors.greyE5,
                                            ),
                                            shape: BoxShape.circle),
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                      ),
                                    ))
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : SizedBox.shrink()),
          InkWell(
            onTap: () => showAddMoreDetailsDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  AppStrings.addMoreDetails,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                Container(
                  width: 32,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAddMoreDetailsDialog(BuildContext context) async {
    if (widget.controller.detailsList.length == 5) {
      commonSnackBar(message: AppStrings.youCantAddMoreThanFiveDetail.tr);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddMoreDetailsDialog(
          fromScreen: RouteConstant.manufacturerAddProductViaAiStep2),
    );
  }
}
