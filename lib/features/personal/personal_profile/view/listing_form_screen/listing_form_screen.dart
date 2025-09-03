import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'listing_form_screen_controller.dart';
import 'widgets/step1_section.dart';
import 'widgets/step2_section.dart';
import 'widgets/step3_section.dart';

class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  ManualListingScreenController controller =
      Get.put(ManualListingScreenController());

  final ScrollController _scrollController = ScrollController();
  late final Worker _stepWorker;

  @override
  void initState() {
    super.initState();
    // Scroll to top whenever step changes
    _stepWorker = ever<int>(controller.currentStep, (_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _stepWorker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // intercept system back
      onPopInvoked: (didPop) {
        if (didPop) return; // route already popped
        if (controller.currentStep.value > 1) {
          controller.onBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CommonBackAppBar(
          title: "Product Details",
          onBackTap: () {
            if (controller.currentStep.value > 1) {
              controller.onBack();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  // padding: EdgeInsets.all(SizeConfig.size16),
                  child: Form(
                    key: controller.formKey,
                    child: Obx(() => IndexedStack(
                          index: controller.currentStep.value - 1,
                          children: [
                            Expanded(
                              child: CustomFormCard(
                                child: Step1Section(controller: controller),
                                padding: EdgeInsets.all(SizeConfig.size16),
                                // margin: EdgeInsets.fromLTRB(SizeConfig.size16, 0, SizeConfig.size16, 0),
                              ),
                            ),
                            CustomFormCard(child: Step2Section(controller: controller)),
                            CustomFormCard(child: Step3Section(controller: controller)),
                          ],
                        )),
                  ),
                ),
              ),

              // Bottom Action Buttons
              Obx(() => Container(
                    padding: EdgeInsets.all(SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Save as Draft Button
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.primaryColor, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: controller.saveAsDraft,
                                borderRadius: BorderRadius.circular(8),
                                child: const Center(
                                  child: CustomText(
                                    'Save as draft',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: SizeConfig.size12),

                        // Post Product Button
                        Expanded(
                            child: CustomBtn(
                          title: controller.currentStep.value ==
                                  ManualListingScreenController.totalSteps
                              ? 'Submit'
                              : 'Next',
                          onTap: controller.onNext,
                          bgColor: AppColors.primaryColor,
                          textColor: AppColors.white,
                          height: 45,
                        )),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> items,
    required String? Function(String?) validator,
    required void Function(String?) onChanged,
    String? value,
  }) {
    // Ensure the bound value always exists in the current items to avoid assertion errors
    final String? effectiveValue =
        (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: 11, // Keep this small
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: effectiveValue,
              validator: validator,
              onChanged: onChanged,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                // This removes the inner border
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.grey9B,
                size: 20,
              ),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              style: TextStyle(
                color: AppColors.black,
                fontSize: SizeConfig.medium,
              ),
              menuMaxHeight: 200,
              hint: CustomText(
                hint,
                color: AppColors.secondaryTextColor,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: SizeConfig.medium,
                      color: AppColors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryDateSection(ManualListingScreenController controller) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Add Expiry Date (Optional)',
            fontSize: SizeConfig.medium,
            // fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size8),
          Obx(() => RestrictedDatePicker(
                selectedDay: controller.selectedDay.value == 0
                    ? null
                    : controller.selectedDay.value,
                selectedMonth: controller.selectedMonth.value == 0
                    ? null
                    : controller.selectedMonth.value,
                selectedYear: controller.selectedYear.value == 0
                    ? null
                    : controller.selectedYear.value,
                onDayChanged: controller.onDayChanged,
                onMonthChanged: controller.onMonthChanged,
                onYearChanged: controller.onYearChanged,
                isFutureYear: true,
              )),
        ],
      ),
    );
  }

  Widget _buildTagsSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Add Tags / Keywords',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Row(
            children: [
              Image.asset("assets/icons/tag_icon.png"),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextField(
                  controller: controller.tagsController,
                  decoration: const InputDecoration(
                    hintText: 'Tag people',
                    hintStyle: TextStyle(
                      color: AppColors.grey9B,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: controller.addTag,
                child: Image.asset("assets/icons/add_icon.png"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaUploadSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Upload product Images/ Videos',
          fontSize: SizeConfig.medium,
          // fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size12),
        SizedBox(
          height: 80,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 5,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: AppColors.fillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyE5, width: 1),
              ),
              child: Container(
                child: Icon(
                  Icons.photo,
                  color: AppColors.secondaryTextColor.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Short Description',
          fontSize: SizeConfig.medium,
          // fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          // textEditController: controller.shortDescriptionController,
          hintText: "Lorem ipsum dolor sit amet conseceter adisping...",
          maxLine: 3,
        )
      ],
    );
  }

  Widget _buildNonReturnableSection(ManualListingScreenController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'This is a non-returnable product',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
        Obx(() => CustomSwitch(
              containerHeight: 25,
              containerWidth: 50,
              value: controller.isNonReturnable.value,
              onChanged: (value) => controller.toggleNonReturnable(),
            )),
      ],
    );
  }

  Widget _buildMoreDetailsSection(ManualListingScreenController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'Add More Details',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        GestureDetector(
          onTap: controller.toggleMoreDetails,
          child: Container(
            width: 32,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(6),
              // shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
