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
import 'package:flutter/cupertino.dart';
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
    required this.serviceSubType});

  @override
  State<AddSelfServiceScreen> createState() => _AddSelfServiceScreenState();
}

class _AddSelfServiceScreenState extends State<AddSelfServiceScreen> {
  final controller = getOrPut(() => SelfWorkServiceController());

  @override
  initState(){
    super.initState();
    controller.designation = widget.designation;
    if(controller.designation==null) return;

    controller.fetchPredefinedCategoryServiceType(
        designation: controller.designation!,
        selectedServiceKey: SelfWorkServiceController.keyServiceTypes
    );
  }

  @override
  dispose(){
    super.dispose();
    deleteIfRegistered<SelfWorkServiceController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: controller.designation,
        isLeading: !widget.fromBottomNavBar
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8
          ),
          child: Obx(()=> AbsorbPointer(
            absorbing: controller.isCreateServiceLoading.value,
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [

                  // --- TOP CARD: Uploads & Dropdowns ---
                  CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// service work photo
                        _sectionTitle("Upload Your Work Photo"),
                        SizedBox(height: SizeConfig.size8),
                        Row(
                          children: [
                            ...List.generate(controller.selectedImages.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () async {
                                    navigatePushTo(
                                      context,
                                      ImageViewScreen(
                                        subTitle: '',
                                        appBarTitle: AppStrings.imageViewer,
                                        imageUrls: controller.selectedImages,
                                        initialIndex: index,
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                            File(controller.selectedImages[index]),
                                            width: SizeConfig.size80,
                                            height: SizeConfig.size80,
                                            fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () async {
                                            controller.selectedImages.removeAt(index);
                                          },
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: AppColors.blackMite,
                                            child: Icon(Icons.close, size: 12, color: AppColors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (controller.selectedImages.length < 2)
                              InkWell(
                                onTap: () async {
                                  final imgStr = await SelectProfilePictureDialog
                                      .showLogoDialog(
                                      context,
                                      AppStrings.gallery,
                                      cropAspectRatio: CropAspectRatio(width: 3, height: 4)
                                  );
                                  if (imgStr != null) {
                                    controller.selectedImages.add(imgStr);
                                  }
                                },
                                child: Container(
                                  width: SizeConfig.size80,
                                  height: SizeConfig.size80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.greyE5),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: LocalAssets(
                                      imagePath: AppIconAssets.chat_input_gallery,
                                      imgColor: AppColors.greyAF,
                                      height: SizeConfig.size20,
                                      width: SizeConfig.size20
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size15),

                        /// Experience
                        _sectionTitle("Your Experience"),
                        SizedBox(height: SizeConfig.size8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                      AppStrings.years,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.mainTextColor
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  CommonDropdown<String>(
                                    items: controller.experienceYears,
                                    selectedValue: controller.selectedExperienceYear.value,
                                    hintText: "E.g 1 Year..",
                                    onChanged: (val) {
                                      controller.selectedExperienceYear.value = val;
                                    },
                                    displayValue: (val) => val,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: SizeConfig.paddingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                      'Months',
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.mainTextColor
                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  CommonDropdown<String>(
                                    items: controller.experienceMonths,
                                    selectedValue: controller.selectedExperienceMonth.value,
                                    hintText: "E.g 3 Months..",
                                    onChanged: (val)=> controller.selectedExperienceMonth.value = val,
                                    displayValue: (val) => val,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size15),

                        /// Service Type
                        _sectionTitle("Service Type"),
                        SizedBox(height: SizeConfig.size8),
                        controller.isPredefinedCategoryServiceTypeLoading.value
                        ?  Center(
                          child: CircularProgressIndicator(),
                        )
                            : Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size4,
                              vertical: SizeConfig.size8
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: AppColors.greyE5),
                              boxShadow: [AppShadows.textFieldShadow]
                          ),
                              child: Column(
                              children: controller.serviceTypes.map((item) {
                              return Theme(
                                data: ThemeData(unselectedWidgetColor: Colors.grey.shade300),
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
                                  dense: true,
                                  activeColor: AppColors.primaryColor,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: CustomText(
                                    item,
                                    fontSize: SizeConfig.medium,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  value: controller.selectedServiceTypes.contains(item),
                                  onChanged: (val) {
                                    if (val == true) {
                                      controller.selectedServiceTypes.add(item);
                                    } else {
                                      controller.selectedServiceTypes.remove(item);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        )

                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.paddingM),

                  // --- EXPANSION CARDS ---
                  CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.paddingM),
                    child: Column(
                      children: controller.selectedCategoryMap.entries.map((item) {
                        return Obx(() {
                          final selectedKey = item.key;
                          final selectedItems = item.value;

                          // 1. Get Display Title
                          final displayTitle = controller.categoryTitleMap[selectedKey] ?? selectedKey;

                          Widget content;

                          if (selectedItems.isNotEmpty) {
                            // CASE 1: Data exists -> Show Expansion Tile
                            content = _buildDynamicExpansionTile(
                              title: displayTitle,
                              selectedItems: selectedItems.toList(),
                              onAddTap: () => _navigateToSelection(selectedKey, displayTitle),
                            );
                          } else {
                            // CASE 2: No Data -> Show Normal Container
                            content = _buildNormalContainer(
                              title: displayTitle,
                              onTap: () => _navigateToSelection(selectedKey, displayTitle),
                            );
                          }

                          // 2. Check if this is the last item to remove bottom padding
                          final isLastItem = controller.selectedCategoryMap.keys.last == selectedKey;

                          return Padding(
                            padding: EdgeInsets.only(bottom: isLastItem ? 0 : SizeConfig.size15),
                            child: content,
                          );
                        });
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- ABOUT SECTION ---
                  CustomFormCard(
                    padding: EdgeInsets.all(SizeConfig.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle("About"),
                            Obx(()=> !controller.isGenerateDescLoading.value
                                ? InkWell(
                                onTap: () {
                                  if(controller.selectedExperienceYear.value == null ||
                                      controller.selectedExperienceMonth.value == null){
                                    commonSnackBar(
                                        message: "Cannot generate description without Experience Year and Month"
                                    );
                                    return;
                                  }

                                  controller
                                      .generateDescriptions(bodyRequest: {
                                    ApiKeys.category: controller.designation,
                                    ApiKeys.expYears: controller.selectedExperienceYear.value,
                                    ApiKeys.expMonths: controller.selectedExperienceMonth.value,
                                  });
                                },
                                child: LocalAssets(
                                  height: 25,
                                  width: 25,
                                  imgColor: AppColors.primaryColor,
                                  imagePath: AppIconAssets.ai_generative,
                                )) : SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                )))
                          ],
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CommonTextField(
                          textEditController: controller.aboutController,
                          maxLine: 4,
                          hintText: "Horem ipsum dolor sit amet, consectetur adipiscing...",
                          maxLength: 250,
                          isCounterVisible: true,
                          isValidate: true,
                          validator: ValidationMethod().professionDescValidation
                        ),

                        SizedBox(height: SizeConfig.paddingL),

                        // NEXT BUTTON
                        CustomBtn(
                          title: controller.isCreateServiceLoading.value ? null : 'Next',
                          onTap: ()=> controller.createEarnServiceApi(serviceSubType: widget.serviceSubType),
                          bgColor: AppColors.primaryColor,
                          isLoading: controller.isCreateServiceLoading.value,
                        ),

                      ],
                    ),
                  ),


                  const SizedBox(height: 40 + kBottomNavigationBarHeight),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => CustomText(
      title,
      fontSize: SizeConfig.small,
      fontWeight: FontWeight.w400,
      color: AppColors.mainTextColor
  );

  // --- Widget 1: Normal Container (When list is empty) ---
  Widget _buildNormalContainer({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: [AppShadows.textFieldShadow]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              title,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w400,
              color: AppColors.mainTextColor,
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

// --- Widget 2: Expansion Tile (When list has data) ---
  Widget _buildDynamicExpansionTile({
    required String title,
    required List<String> selectedItems,
    required VoidCallback onAddTap,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: [AppShadows.textFieldShadow]
      ),
      child: Theme(
        // Remove divider colors from the ExpansionTile itself
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),

        child: ExpansionTile(
          initiallyExpanded: true,
          dense: true,
          visualDensity: const VisualDensity(vertical: 0), // Reduces height to minimum
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List Selected Items
                  ...selectedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 6, color: AppColors.secondaryTextColor),
                        ),
                        SizedBox(width: SizeConfig.size6),
                        Expanded(
                          child: CustomText(
                            item,
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  )),

                  SizedBox(height: SizeConfig.size10),

                  // "Add More" Button inside the tile
                  GestureDetector(
                    onTap: onAddTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                            CupertinoIcons.add,
                            size: 16,
                            color: AppColors.primaryColor
                        ),
                        SizedBox(width: 4),
                        CustomText(
                          "Add More",
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.medium,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navigateToSelection(String key, String title) {
    final selectedItems = controller.selectedCategoryMap[key] ?? <String>[].obs;

    Get.to(() => ServiceSelectionScreen(
      controller: controller,
      designation: controller.designation ?? ELECTRICIAN,
      selectedCategoryKey: key,
      pageTitle: title,
      preSelectedOptions: selectedItems,
      isDataUpdate: false
    ));
  }

}
