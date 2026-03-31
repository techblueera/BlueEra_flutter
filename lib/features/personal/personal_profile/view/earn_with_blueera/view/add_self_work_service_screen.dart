import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/service_selection_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSelfServiceScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  final String designation;
  final EarnServiceTypes serviceSubType;

  const AddSelfServiceScreen({
    super.key,
    this.fromBottomNavBar = false,
    required this.designation,
    required this.serviceSubType,
  });

  @override
  State<AddSelfServiceScreen> createState() => _AddSelfServiceScreenState();
}

class _AddSelfServiceScreenState extends State<AddSelfServiceScreen> {
  final controller = getOrPut(() => SelfWorkServiceController());

  @override
  void initState() {
    super.initState();
    controller.designation = widget.designation;
    if (controller.designation == null) return;
    controller.fetchPredefinedCategoryServiceType(
      designation: controller.designation!,
      selectedServiceKey: SelfWorkServiceController.keyServiceTypes,
    );
  }

  @override
  void dispose() {
    super.dispose();
    deleteIfRegistered<SelfWorkServiceController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: controller.designation,
        isLeading: !widget.fromBottomNavBar,
      ),
      body: SafeArea(
        child: Obx(() => AbsorbPointer(
              absorbing: controller.isCreateServiceLoading.value,
              child: Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    // ─── Progress Bar ───
                    _buildProgressBar(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.size15,
                          horizontal: SizeConfig.size12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('📸  Work Photos'),
                            SizedBox(height: SizeConfig.size8),
                            _buildPhotoUploader(),

                            SizedBox(height: SizeConfig.size20),

                            _buildSectionLabel('🏅  Experience'),
                            SizedBox(height: SizeConfig.size8),
                            _buildExperienceRow(),

                            SizedBox(height: SizeConfig.size20),

                            _buildSectionLabel('🔧  Service Types'),
                            SizedBox(height: SizeConfig.size8),
                            _buildServiceTypeChips(),

                            SizedBox(height: SizeConfig.size20),

                            _buildSectionLabel('📂  Service Categories'),
                            SizedBox(height: SizeConfig.size8),
                            _buildCategoryList(),

                            SizedBox(height: SizeConfig.size20),

                            _buildSectionLabel('📝  About You'),
                            SizedBox(height: SizeConfig.size8),
                            _buildAboutSection(),

                            SizedBox(height: SizeConfig.size24),

                            // ─── Next Button ───
                            Obx(() => CustomBtn(
                                  title: controller.isCreateServiceLoading.value
                                      ? null
                                      : 'Submit & Continue',
                                  onTap: () => controller.createEarnServiceApi(
                                      serviceSubType: widget.serviceSubType),
                                  bgColor: AppColors.primaryColor,
                                  isLoading:
                                      controller.isCreateServiceLoading.value,
                                )),

                            const SizedBox(
                                height: 40 + kBottomNavigationBarHeight),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  // ─── Progress Bar ───
  Widget _buildProgressBar() {
    return Obx(() {
      int completed = 0;
      if (controller.selectedImages.isNotEmpty) completed++;
      if (controller.selectedExperienceYear.value != null) completed++;
      if (controller.selectedServiceTypes.isNotEmpty) completed++;
      if (controller.selectedCategoryMap.values.any((v) => v.isNotEmpty))
        completed++;
      if (controller.aboutController.text.isNotEmpty) completed++;

      final progress = completed / 5;

      return Container(
        color: AppColors.white,
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  'Profile Completion',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
                CustomText(
                  '$completed/5 Steps',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.greyE5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─── Section Label ───
  Widget _buildSectionLabel(String label) {
    return CustomText(
      label,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w600,
      color: AppColors.mainTextColor,
    );
  }

  // ─── Photo Uploader ───
  Widget _buildPhotoUploader() {
    return Obx(() => CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Uploaded images
                  ...List.generate(controller.selectedImages.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(right: SizeConfig.size10),
                      child: InkWell(
                        onTap: () => navigatePushTo(
                          context,
                          ImageViewScreen(
                            subTitle: '',
                            appBarTitle: AppStrings.imageViewer,
                            imageUrls: controller.selectedImages,
                            initialIndex: index,
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(controller.selectedImages[index]),
                                width: SizeConfig.size80,
                                height: SizeConfig.size80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Remove button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    controller.selectedImages.removeAt(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                            // Badge
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4)),
                                child: CustomText('${index + 1}/2',
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Add photo slot
                  if (controller.selectedImages.length < 2)
                    GestureDetector(
                      onTap: () async {
                        final imgStr =
                            await SelectProfilePictureDialog.showLogoDialog(
                          context,
                          AppStrings.gallery,
                          cropAspectRatio: CropAspectRatio(width: 3, height: 4),
                        );
                        if (imgStr != null)
                          controller.selectedImages.add(imgStr);
                      },
                      child: Container(
                        width: SizeConfig.size80,
                        height: SizeConfig.size80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.05),
                          border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.35),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primaryColor, size: 24),
                            SizedBox(height: SizeConfig.size4),
                            CustomText('Add Photo',
                                fontSize: 9,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600),
                          ],
                        ),
                      ),
                    ),

                  // Hint text when empty
                  if (controller.selectedImages.isEmpty) ...[
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText('Show your work!',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor),
                          SizedBox(height: SizeConfig.size4),
                          CustomText(
                              'Upload up to 2 photos that showcase your skills',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // ─── Tips row ───
              if (controller.selectedImages.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size10,
                      vertical: SizeConfig.size6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        'Good photos increase your chances by 3x',
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ));
  }

  // ─── Experience Row ───
  Widget _buildExperienceRow() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Years'),
                SizedBox(height: SizeConfig.size6),
                CommonDropdown<String>(
                  items: controller.experienceYears,
                  selectedValue: controller.selectedExperienceYear.value,
                  hintText: 'Select Year',
                  onChanged: (val) =>
                      controller.selectedExperienceYear.value = val,
                  displayValue: (val) => val,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Months'),
                SizedBox(height: SizeConfig.size6),
                CommonDropdown<String>(
                  items: controller.experienceMonths,
                  selectedValue: controller.selectedExperienceMonth.value,
                  hintText: 'Select Month',
                  onChanged: (val) =>
                      controller.selectedExperienceMonth.value = val,
                  displayValue: (val) => val,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Service Types as Chips ─── (replaces checkboxes — much more modern)
  Widget _buildServiceTypeChips() {
    return Obx(() {
      if (controller.isPredefinedCategoryServiceTypeLoading.value) {
        return CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      return CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'Tap to select services you offer',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(height: SizeConfig.size10),
            Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: controller.serviceTypes.map((item) {
                final isSelected =
                    controller.selectedServiceTypes.contains(item);
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      controller.selectedServiceTypes.remove(item);
                    } else {
                      controller.selectedServiceTypes.add(item);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12,
                      vertical: SizeConfig.size8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primaryColor : AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.greyE5,
                        width: isSelected ? 0 : 1,
                      ),
                      boxShadow: isSelected ? [] : [AppShadows.textFieldShadow],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check,
                              size: 14, color: Colors.white),
                          SizedBox(width: SizeConfig.size4),
                        ],
                        CustomText(
                          item,
                          fontSize: SizeConfig.small,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Selection count
            if (controller.selectedServiceTypes.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size10),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      '${controller.selectedServiceTypes.length} service${controller.selectedServiceTypes.length > 1 ? 's' : ''} selected',
                      fontSize: SizeConfig.small,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ─── Category List ───
  Widget _buildCategoryList() {
    return Column(
      children: controller.selectedCategoryMap.entries.map((item) {
        return Obx(() {
          final selectedKey = item.key;
          final selectedItems = item.value;
          final displayTitle =
              controller.categoryTitleMap[selectedKey] ?? selectedKey;
          final isLastItem =
              controller.selectedCategoryMap.keys.last == selectedKey;

          return Padding(
            padding:
                EdgeInsets.only(bottom: isLastItem ? 0 : SizeConfig.size10),
            child: selectedItems.isNotEmpty
                ? _buildExpansionTile(
                    title: displayTitle,
                    selectedItems: selectedItems.toList(),
                    onAddTap: () =>
                        _navigateToSelection(selectedKey, displayTitle),
                  )
                : _buildEmptyCategoryRow(
                    title: displayTitle,
                    onTap: () =>
                        _navigateToSelection(selectedKey, displayTitle),
                  ),
          );
        });
      }).toList(),
    );
  }

  // ─── Empty Category Row ───
  Widget _buildEmptyCategoryRow(
      {required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomFormCard(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: AppColors.primaryColor, size: 20),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(title,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainTextColor),
                  SizedBox(height: SizeConfig.size2),
                  CustomText('Tap to add details',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Expansion Tile ───
  Widget _buildExpansionTile({
    required String title,
    required List<String> selectedItems,
    required VoidCallback onAddTap,
  }) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          dense: false,
          tilePadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14, vertical: SizeConfig.size4),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 18),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(title,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    CustomText(
                        '${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''} added',
                        fontSize: SizeConfig.small,
                        color: Colors.green,
                        fontWeight: FontWeight.w400),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.keyboard_arrow_down,
              color: AppColors.secondaryTextColor),
          children: [
            Divider(color: AppColors.greyE5, height: 1),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...selectedItems.map((item) => Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle,
                                  size: 5, color: AppColors.primaryColor),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: CustomText(item,
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      )),

                  SizedBox(height: SizeConfig.size4),
                  Divider(color: AppColors.greyE5, height: 1),
                  SizedBox(height: SizeConfig.size8),

                  // Add More
                  GestureDetector(
                    onTap: onAddTap,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                              size: 16, color: AppColors.primaryColor),
                          SizedBox(width: SizeConfig.size4),
                          CustomText('Add More',
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── About Section ───
  Widget _buildAboutSection() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI generate button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText('Tell clients about yourself',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400),
              Obx(() => !controller.isGenerateDescLoading.value
                  ? GestureDetector(
                      onTap: () {
                        if (controller.selectedExperienceYear.value == null ||
                            controller.selectedExperienceMonth.value == null) {
                          commonSnackBar(
                              message:
                                  "Please select experience year and month first");
                          return;
                        }
                        controller.generateDescriptions(bodyRequest: {
                          ApiKeys.category: controller.designation,
                          ApiKeys.expYears:
                              controller.selectedExperienceYear.value,
                          ApiKeys.expMonths:
                              controller.selectedExperienceMonth.value,
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size10,
                            vertical: SizeConfig.size4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LocalAssets(
                                height: 14,
                                width: 14,
                                imgColor: AppColors.primaryColor,
                                imagePath: AppIconAssets.ai_generative),
                            SizedBox(width: SizeConfig.size4),
                            CustomText('AI Write',
                                fontSize: SizeConfig.small,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.0, color: AppColors.primaryColor),
                    )),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            textEditController: controller.aboutController,
            maxLine: 5,
            hintText:
                "E.g. I have 5 years of experience in electrical work, specialising in home wiring and repairs...",
            maxLength: 250,
            isCounterVisible: true,
            isValidate: true,
            validator: ValidationMethod().professionDescValidation,
          ),
        ],
      ),
    );
  }

  // ─── Field Label ───
  Widget _fieldLabel(String label) => CustomText(
        label,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w500,
        color: AppColors.mainTextColor,
      );

  void _navigateToSelection(String key, String title) {
    final selectedItems = controller.selectedCategoryMap[key] ?? <String>[].obs;
    Get.to(() => ServiceSelectionScreen(
          controller: controller,
          designation: controller.designation ?? ELECTRICIAN,
          selectedCategoryKey: key,
          pageTitle: title,
          preSelectedOptions: selectedItems,
          isDataUpdate: false,
        ));
  }
}
