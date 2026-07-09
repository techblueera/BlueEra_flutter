import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/type_of_business_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_bottom_sheet.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessContactMapCard extends StatelessWidget {
  final BusinessProfileDetails? businessProfileDetails;
  final bool showEditButton;

  const BusinessContactMapCard({
    super.key,
    this.businessProfileDetails,
    this.showEditButton = true,
  });

  Future<void> updateLocationDialog(
    BuildContext context,
    BusinessProfileDetails? details,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          backgroundColor: AppColors.white,
          contentPadding: EdgeInsets.zero,
          content: Container(
            margin: EdgeInsets.only(
                left: SizeConfig.size16,
                right: SizeConfig.size16,
                bottom: SizeConfig.size16,
                top: SizeConfig.size8),
            // vertical: SizeConfig.size30, horizontal: SizeConfig.size40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.close,
                        color: AppColors.secondaryTextColor,
                      ),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LocalAssets(imagePath: AppIconAssets.warningIcon),
                    SizedBox(width: SizeConfig.size5),
                    CustomText(
                      AppStrings.updateLocation,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size7,
                ),
                CustomText(AppStrings.updateLocationWarning,
                    fontSize: SizeConfig.medium,
                    textAlign: TextAlign.center,
                    color: AppColors.secondaryTextColor),
                SizedBox(height: SizeConfig.size15),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () => Get.back(),
                        title: AppStrings.cancel,
                        textColor: AppColors.secondaryTextColor,
                        bgColor: AppColors.white,
                        borderColor: AppColors.secondaryTextColor,
                        radius: 8.0,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(
                      child: CustomBtn(
                        height: SizeConfig.size45,
                        onTap: () {
                          Get.back();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => BusinessLocationBottomSheet(prevBusinessDetails: details),
                          );
                        },
                        title: AppStrings.confirm,
                        isValidate: true,
                        bgColor: AppColors.red02,
                        radius: 8.0,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = businessProfileDetails?.logo;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      // margin: EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.contactUs.tr,
                  fontSize: SizeConfig.large,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showEditButton)
                InkWell(
                  onTap: () => updateLocationDialog(context, businessProfileDetails),
                  child: LocalAssets(
                    height: 16,
                    imagePath: AppIconAssets.pen_line,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.greyE5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Logo + Name + Description ───
                Row(
                  children: [
                    Container(
                      key: ValueKey(logoUrl),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        image: DecorationImage(
                          image: (logoUrl != null && logoUrl.isNotEmpty)
                              ? NetworkImage(logoUrl) as ImageProvider
                              : AssetImage(AppIconAssets.place_holder_image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(businessProfileDetails?.businessName,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainTextColor),
                                SizedBox(height: 3),
                                CustomText(businessProfileDetails?.subCategoryDetails?.name ?? AppStrings.na,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor),
                              ],
                            ),
                          ),
                          // Name stays editable only until GST is verified —
                          // once verified the business name is locked to the
                          // GST record, so hide the rename chip.
                          if (showEditButton && businessProfileDetails?.gst?.gstVerification != true) ...[
                            const SizedBox(width: 6),
                            _updateChip(() => _openNameEditSheet(context)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(color: AppColors.greyE5, height: 30),

                _categoryItem(context),

                if (businessProfileDetails?.ownerDetails?[0].email?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.email, businessProfileDetails!.ownerDetails![0].email!),

                if (businessProfileDetails?.userContactNo?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.phone_outline, businessProfileDetails!.userContactNo!),

                if (businessProfileDetails?.address?.isNotEmpty ?? false)
                  _contactItem(AppIconAssets.location_new, businessProfileDetails!.address!),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ─── Map ───
          BusinessLocationMapWidget(
            latitude: businessProfileDetails?.businessLocation?.lat ?? 0.0,
            longitude: businessProfileDetails?.businessLocation?.lon ?? 0.0,
            businessName: businessProfileDetails?.businessName ?? '',
          ),
        ],
      ),
    );
  }

  /// Owner-only sheet to rename the business. Patches just the name via
  /// `updateBusinessProfileDetails` (same endpoint the website/cover edits use).
  void _openNameEditSheet(BuildContext context) {
    final controller = Get.find<ViewBusinessDetailsController>();
    final nameController = TextEditingController(text: businessProfileDetails?.businessName ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        'Update Business Name',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      const CloseButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CommonTextField(
                    textEditController: nameController,
                    title: 'Business Name',
                    hintText: 'Enter business name',
                    keyBoardType: TextInputType.text,
                    inputLength: AppConstants.inputCharterLimit50,
                    isValidate: false,
                  ),
                  const SizedBox(height: 24),
                  CustomBtn(
                    radius: 10,
                    bgColor: AppColors.primaryColor,
                    title: AppStrings.save,
                    onTap: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        commonSnackBar(message: AppStrings.businessNameRequired.tr);
                        return;
                      }
                      await controller.updateBusinessProfileDetails({
                        ApiKeys.businessId: businessProfileDetails?.id ?? '',
                        ApiKeys.business_name: name,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Business category row. Shows the current (sub-)category and, for the
  /// owner, an Update chip that opens the full category + sub-category picker.
  Widget _categoryItem(BuildContext context) {
    final label = businessProfileDetails?.categoryDetails?.name ?? '';
    // Hide entirely for visitors when there's no category to show.
    if (label.isEmpty && !showEditButton) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: AppIconAssets.principal,
            imgColor: AppColors.secondaryTextColor,
            height: 20,
            width: 20,
            boxFix: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              label.isEmpty ? 'Category not set' : label,
              fontSize: 15,
              color: AppColors.mainTextColor,
            ),
          ),
          if (showEditButton) _updateChip(() => _openCategoryEditSheet(context)),
        ],
      ),
    );
  }

  /// Small outlined "Update" pill used by the name + category rows.
  Widget _updateChip(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: CustomText(
          'Update',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  /// Owner-only sheet to change the business Category and Sub-category. Loads
  /// the categories for the business's type, pre-selects the current values,
  /// and saves both via `updateBusinessDetails`.
  void _openCategoryEditSheet(BuildContext context) {
    final controller = Get.find<ViewBusinessDetailsController>();

    // Seed the business type so getAllCategories pulls the right category list.
    controller.selectedTypeOfBusiness.value = BusinessCategory(
      type: businessProfileDetails?.typeOfBusiness ?? '',
      title: '',
      subTitle: '',
      icon: '',
    );
    controller.selectedCategory.value = null;
    controller.selectedSubCategory.value = null;
    controller.subCategoryList.clear();

    // Load categories, then pre-select the business's current category + sub.
    controller.getAllCategories().then((_) {
      final currentCatId = businessProfileDetails?.categoryOfBusiness ?? '';
      final currentSubName = businessProfileDetails?.subCategoryDetails?.name;

      CategoryData? matchCat;
      // 1. Parent category by id.
      for (final c in controller.categoryList) {
        if (currentCatId.isNotEmpty && c.id == currentCatId) {
          matchCat = c;
          break;
        }
      }
      // 2. Fallback — the category whose sub-categories include the current
      //    one (covers profiles that only carry the sub-category, e.g. when
      //    `category_Of_Business` is empty).
      if (matchCat == null && (currentSubName ?? '').isNotEmpty) {
        for (final c in controller.categoryList) {
          final subs = c.subCategories ?? const <SubCategories>[];
          if (subs.any((s) => s.name == currentSubName)) {
            matchCat = c;
            break;
          }
        }
      }
      // 3. Last fallback — the category name itself matches the shown label.
      if (matchCat == null && (currentSubName ?? '').isNotEmpty) {
        for (final c in controller.categoryList) {
          if (c.name == currentSubName) {
            matchCat = c;
            break;
          }
        }
      }

      if (matchCat != null) {
        controller.onCategorySelected(matchCat);
        for (final s in controller.subCategoryList) {
          if (s.name == currentSubName) {
            controller.selectedSubCategory.value = s;
            break;
          }
        }
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'Update Category',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    const CloseButton(),
                  ],
                ),
                const SizedBox(height: 16),
                CustomText('Category of Business', fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.isCategoriesLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return CommonDropdownDialog<CategoryData>(
                    items: controller.categoryList.toList(),
                    selectedValue: controller.selectedCategory.value,
                    hintText: 'Select Category',
                    title: 'Category of Business',
                    displayValue: (c) => c.name ?? '',
                    onChanged: (c) {
                      if (c != null) controller.onCategorySelected(c);
                    },
                  );
                }),
                const SizedBox(height: 16),
                CustomText('Sub-category', fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
                const SizedBox(height: 8),
                // Sub-category stays locked until a category is chosen.
                Obx(() {
                  final hasCategory = controller.selectedCategory.value != null;
                  return Opacity(
                    opacity: hasCategory ? 1.0 : 0.5,
                    child: AbsorbPointer(
                      absorbing: !hasCategory,
                      child: CommonDropdownDialog<SubCategories>(
                        items: controller.subCategoryList.toList(),
                        selectedValue: controller.selectedSubCategory.value,
                        hintText: hasCategory ? 'Select Sub-category' : 'Select a category first',
                        title: 'Sub-category',
                        displayValue: (s) => s.name ?? '',
                        onChanged: (s) => controller.selectedSubCategory.value = s,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Button-level loader (showProgress:false on the call) so the
                // global progress dialog doesn't cover the sheet.
                Obx(() => CustomBtn(
                      radius: 10,
                      bgColor: AppColors.primaryColor,
                      title: AppStrings.save,
                      isLoading: controller.isUpdateBusinessDetailsLoading.value,
                      onTap: () async {
                        final cat = controller.selectedCategory.value;
                        if (cat?.id == null || cat!.id!.isEmpty) {
                          commonSnackBar(message: 'Please select a category');
                          return;
                        }
                        final params = <String, dynamic>{
                          ApiKeys.businessId: businessProfileDetails?.id ?? '',
                          ApiKeys.category_Of_Business: cat.id,
                        };
                        final sub = controller.selectedSubCategory.value;
                        if (sub?.sId != null && sub!.sId!.isNotEmpty) {
                          params[ApiKeys.sub_category_Of_Business] = sub.sId;
                        }
                        await controller.updateBusinessDetails(params, showProgress: false);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    )),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contactItem(String icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // Same size + colour as the category icon so the left rail is uniform.
          LocalAssets(
            imagePath: icon,
            imgColor: AppColors.secondaryTextColor,
            height: 20,
            width: 20,
            boxFix: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(label, fontSize: 15, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }
}
