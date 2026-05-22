import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';

import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/features/me/medical/model/snap_search_result_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical/view/medical_level2_category_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AddMedicalSnapSearchScreen extends StatefulWidget {
  const AddMedicalSnapSearchScreen({super.key});

  @override
  State<AddMedicalSnapSearchScreen> createState() => _AddMedicalSnapSearchScreenState();
}

class _AddMedicalSnapSearchScreenState extends State<AddMedicalSnapSearchScreen> {
  final controller = getOrPut(() => MedicalController());

  @override
  void initState() {
    super.initState();
    controller.fetchGroceryNestedCategory();
  }

  @override
  dispose(){
    deleteIfRegistered<MedicalController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.medicalItemsTitle.tr,
      ),
      bottomNavigationBar: _buildBottomAction(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size15,
          horizontal: SizeConfig.size8
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBulkUploadSection(),
            SizedBox(height: SizeConfig.size15),

            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.greyE5)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomText(AppStrings.medicalOr,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600),
                ),
                Expanded(child: Divider(color: AppColors.greyE5)),
              ],
            ),

            SizedBox(height: SizeConfig.size15),

            // Browse Categories Grid
            _buildCategoryGrid(),
            _buildProductList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Obx(() {

        if (controller.productSnapSearchData.value == null) {
          return const SizedBox.shrink();
        }

        final bool canSubmit = controller.canSubmitSnapSearchProducts;

        final int productCount = controller.selectedSnapSearchProductVariants.keys.length;
        final variantCount = controller.selectedSnapSearchProductVariants.values.fold(0, (sum, list) => sum + list.length);
        final bool loading = controller.isAddMedicalSnapSearchProductsLoading.value;

        return SafeArea(
          child: CustomBtn(
            onTap: canSubmit && !loading
                ? () => controller.addMedicalSnapSearchProductNewVariant(
              isSnapSearch: true
            )
                : null,
            isValidate: canSubmit,
            radius: SizeConfig.size8,
            bgColor: canSubmit ? AppColors.primaryColor : Colors.grey,
            title: '${AppStrings.medicalPublishPrefix.tr} $productCount ${AppStrings.medicalPublishProductsLabel.tr}, $variantCount ${AppStrings.medicalPublishVariantsLabel.tr}',
            isLoading: loading,
          ),
        );
      }),
    );
  }

  Widget _buildBulkUploadSection() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.medicalUploadBulkProduct, fontWeight: FontWeight.bold),
          const SizedBox(height: 14),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.medicalSnapSearchConfig.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final config = controller.medicalSnapSearchConfig[index];
              final String title = config['title']!;
              final String placeholder = config['image']!;

              return Obx(() {
                final File? capturedFile = controller.medicalSnapSearchImagesMap[title];
                final bool hasImage = capturedFile != null;

                final bool isAnyImageSelected = controller.medicalSnapSearchImagesMap.values.any((v) => v != null);

                final bool isBlocked = isAnyImageSelected && !hasImage;

                return Column(
                  children: [
                    InkWell(
                      onTap: isBlocked
                          ? null
                          : hasImage
                          ? () => navigatePushTo(
                        context,
                        ImageViewScreen(
                          appBarTitle: title,
                          imageUrls: [capturedFile.path],
                          initialIndex: 0,
                        ),
                      )
                          : () => controller.addImagesBySlot(title),
                      child: Opacity(
                        opacity: isBlocked ? 0.5 : 1.0,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hasImage ? AppColors.primaryColor : AppColors.greyE5,
                                    width: hasImage ? 2 : 1,
                                  ),
                                  image: DecorationImage(
                                    image: (hasImage
                                        ? FileImage(capturedFile)
                                        : AssetImage(placeholder)) as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            if (hasImage)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => controller.removeImageBySlot(title),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      title,
                      fontSize: 12,
                      color: hasImage
                          ? AppColors.primaryColor
                          : isBlocked
                          ? AppColors.greyE5
                          : AppColors.secondaryTextColor,
                      fontWeight: hasImage ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                );
              });
            },
          ),
          const SizedBox(height: 10),
          CustomText(
            AppStrings.medicalUploadPicMenuHint,
            fontWeight: FontWeight.w400,
            color: AppColors.red,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _staticCategories = [
    {'title': AppStrings.medicalAyurvedaNutrition, 'key': 'AYURVEDA_NUTRITION', 'image': 'assets/category/medical/AyurvedaNutrition.png'},
    {'title': AppStrings.medicalHomePatientCare, 'key': 'HOME_PATIENT_CARE', 'image': 'assets/category/medical/Home_Patient_Care.png'},
    {'title': AppStrings.medicalDevicesCat, 'key': 'MEDICAL_DEVICES', 'image': 'assets/category/medical/Medical_Devices.png'},
    {'title': AppStrings.medicalOtcMedicines, 'key': 'OTC_MEDICINES', 'image': 'assets/category/medical/OTC_Medicines.png'},
    {'title': AppStrings.medicalPersonalBabyCare, 'key': 'PERSONAL_BABY_CARE', 'image': 'assets/category/medical/Personal_Baby_Care.png'},
    {'title': AppStrings.medicalWoundCareFirstAid, 'key': 'WOUND_CARE_FIRST_AID', 'image': 'assets/category/medical/Wound_Care_First_Aid.png'},
  ];

  Widget _buildCategoryGrid() {
    return Obx(() {
      if (controller.medicalNestedCategoryLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final categories = controller.medicalNestedCategoryList;
      return CustomFormCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.medicalChooseYourMedicalProducts,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size12),
            MasonryGridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              primary: false,
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: EdgeInsets.zero,
              itemCount: _staticCategories.length,
              itemBuilder: (context, index) {
                final cat = _staticCategories[index];
                return _buildCategoryItem(
                  title: cat['title']!,
                  imagePath: cat['image']!,
                  onTap: () {
                    logs("cat['key']!== ${cat['key']!}");
                    final matched = _findApiCategory(
                      cat['key']!,
                      categories,
                    );
                    logs("matched=== ${matched}");
                    if (matched == null) {
                      return;
                    }
                    final children = matched.children ?? [];
                    if (children.isEmpty) return;
                    Get.to(() => MedicalLevel2CategoryScreen(
                      title: cat['title']!.tr.replaceAll('\n', ' '),
                      level2Categories: children,
                    ));
                  },
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryItem({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: SizeConfig.size60,
              width: SizeConfig.size60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                height: SizeConfig.size60,
                width: SizeConfig.size60,
              ),
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            SizedBox(
              height: 30,
              child: CustomText(
                title,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  MedicalNestedCategoryModel? _findApiCategory(
    String staticKey,
    List<MedicalNestedCategoryModel> categories,
  ) {
    final normalizedKey = staticKey.toUpperCase().replaceAll(' ', '_');
    for (final level0 in categories) {
      if ((level0.key ?? '').toUpperCase().replaceAll(' ', '_') == normalizedKey) {
        return level0;
      }
      for (final level1 in (level0.children ?? <MedicalNestedCategoryModel>[])) {
        if ((level1.key ?? '').toUpperCase().replaceAll(' ', '_') == normalizedKey) {
          return level1;
        }
      }
    }
    return null;
  }

  Widget _buildProductList() {
    return Obx(() {
      final response = controller.medicalSnapSearchResponse.value;
      final searchData = controller.productSnapSearchData.value;

      // 1. Initial State
      if (response.status == Status.INITIAL) return const SizedBox();

      // 2. Loading State
      if (response.status == Status.LOADING) return _buildLoadingState();

      final foundProducts = searchData?.foundProducts ?? [];

      if (searchData == null || foundProducts.isEmpty) {
        return _buildEmptyState();
      }

      // 3. Success State
      return Column(
        children: [
          _buildSummaryHeader(searchData),

          foundProducts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foundProducts.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              return _buildProductCard(foundProducts[index]);
            },
          ),
        ],
      );
    });
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Image.asset(
          'assets/images/grocery_loading_indicator.gif',
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: SizeConfig.paddingL),
        EmptyStateWidget(
          message: AppStrings.medicalNoProductsIdentified.tr,
        ),
        SizedBox(height: SizeConfig.paddingL),
        CustomBtn(
          width: SizeConfig.size120,
          title: AppStrings.medicalRetry.tr,
          textColor: AppColors.white,
          bgColor: AppColors.primaryColor,
          radius: 10.0,
          onTap: () => controller.fetchMedicalSnapSearchApi(),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          ),
          child: CustomText(
            AppStrings.medicalSearchManually,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(SnapSearchData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            "${data.foundCount ?? 0} ${AppStrings.medicalItemsFoundSuffix.tr}",
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          InkWell(
            onTap: () {
              // Future navigation logic for missing items
            },
            child: CustomText(
              "${data.missingCount ?? 0} ${AppStrings.medicalItemsMissingSuffix.tr}",
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(FoundProduct foundProduct){

    MedicalProductData? medicalItem = foundProduct.productDetails;

    if(medicalItem==null) return SizedBox();

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(
          bottom: SizeConfig.size12
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child:  (medicalItem.images!=null &&  medicalItem.images!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: medicalItem.images!.first.url??'',
                    fit: BoxFit.contain,
                    height: SizeConfig.size80,
                    width: SizeConfig.size80,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                      : LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.fill,
                      height: SizeConfig.size80,
                      width: SizeConfig.size80
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// --- Product Title ---
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: CustomText(
                          medicalItem.name,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: SizeConfig.size8),

                      /// --- Variant Column ---
                      Obx(() {
                        final medicalVariants = medicalItem.variants ?? [];

                        return Column(
                          children: List.generate(medicalVariants.length, (variantIndex) {
                            final v = medicalVariants[variantIndex];

                            return Padding(
                              padding: EdgeInsets.zero,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: controller.isSnapSearchVariantSelected(
                                      medicalItem.sId ?? '',
                                      v.sId ?? '',
                                    ),
                                    onChanged: (_) {
                                      controller.toggleSnapSearchVariant(
                                        medicalItem.sId ?? '',
                                        v,
                                      );
                                    },
                                    checkColor: Colors.white,
                                    activeColor: AppColors.primaryColor,
                                    side: const BorderSide(
                                      color: AppColors.secondaryTextColor,
                                      width: 1.5,
                                    ),
                                  ),

                                  CustomText(
                                    '${v.weight ?? ''}${v.unit ?? ''}',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const SizedBox(width: 6),

                                  Container(
                                    width: 2.0,
                                    height: SizeConfig.size16,
                                    color: AppColors.greyLite,
                                  ),

                                  const SizedBox(width: 6),

                                  CustomText(
                                    "â‚¹${(v.pricing != null && v.pricing!.isNotEmpty) ? v.pricing![0].mrp : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const SizedBox(width: 6),

                                  Container(
                                    width: 2.0,
                                    height: SizeConfig.size16,
                                    color: AppColors.greyLite,
                                  ),

                                  const SizedBox(width: 6),

                                  CustomText(
                                    "${AppStrings.medicalSellingRupeePrefix.tr} ${(v.pricing != null && v.pricing!.isNotEmpty) ? v.pricing![0].sellingPrice : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const Spacer(),

                                  InkWell(
                                    onTap: () {
                                      controller.openSnapSearchEditVariantDialog(
                                        context: context,
                                        title: medicalItem.name ?? AppStrings.medicalEditVariant.tr,
                                        variant: v,
                                      );
                                    },
                                    child: LocalAssets(
                                      imagePath: AppIconAssets.pen_line,
                                      imgColor: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      })

                    ],
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }


}
