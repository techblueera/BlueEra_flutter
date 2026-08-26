import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_floating_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_card.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/snap_scan_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AddFoodSnapSearchScreen extends StatefulWidget {
  const AddFoodSnapSearchScreen({super.key});

  @override
  State<AddFoodSnapSearchScreen> createState() => _AddFoodSnapSearchScreenState();
}

class _AddFoodSnapSearchScreenState extends State<AddFoodSnapSearchScreen> {
  final controller = getOrPut(() => FoodServiceController());

  @override
  initState(){
    super.initState();
    controller.resetControllerFields();
    // Snap-search results feed the same variant sheet, so it needs the same
    // already-stocked set to grey rows out with.
    controller.fetchStockedVariantIdsIfNeeded();
  }

  @override
  dispose(){
    // deleteIfRegistered<FoodServiceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.foodFoodItemsLabel.tr,
      ),
      // The floating cart replaces the previous bottomNavigationBar
      // publish button so newly-ticked variants accumulate visibly
      // while the variant bottom sheet remains the place to actually
      // tick them. See [FoodFloatingCart].
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: SizeConfig.size15,
                left: SizeConfig.size8,
                right: SizeConfig.size8,
                // Reserve space below so the last row stays scrollable
                // above the floating cart.
                bottom: FoodFloatingCart.reservedSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulkUploadSection(),
                  _buildProductList(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FoodFloatingCart(
                controller: controller,
                isSnapSearch: true,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBulkUploadSection() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.foodUploadBulkProduct.tr, fontWeight: FontWeight.bold),
          const SizedBox(height: 14),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.foodSnapSearchPhotos.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final config = controller.foodSnapSearchPhotos[index];
              final String title = config['title']!;
              final String placeholder = config['image']!;
              final String icon = config['icon']!;

              return Obx(() {
                final File? capturedFile = controller.foodSnapSearchImagesMap[title];
                final bool hasImage = capturedFile != null;
                final bool isAnyImageSelected =
                controller.foodSnapSearchImagesMap.values.any((v) => v != null);
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: SizedBox(
                            height: 180,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [

                                // ── Background ─────────────────────────────────
                                hasImage
                                    ? Image.file(capturedFile, fit: BoxFit.cover)
                                    : Image.asset(placeholder, fit: BoxFit.cover),

                                // ── Border overlay ──────────────────────────────
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: hasImage
                                          ? AppColors.primaryColor
                                          : AppColors.greyE5,
                                      width: hasImage ? 2 : 1,
                                    ),
                                  ),
                                ),

                                // ── Dark blur + center pill (empty state only) ──
                                if (!hasImage) ...[
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: AppColors.black.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.white.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.white.withValues(alpha: 0.1),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                LocalAssets(
                                                  imagePath: icon,
                                                  height: 18,
                                                  width: 18,
                                                  boxFix: BoxFit.scaleDown,
                                                  imgColor: AppColors.white,
                                                ),
                                                const SizedBox(width: 6),
                                                CustomText(
                                                  title,
                                                  fontSize: SizeConfig.small,
                                                  color: AppColors.white,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // ── Close button (image selected) ───────────────
                                if (hasImage)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => controller.removeImageBySlot(title),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
            AppStrings.foodUploadPictureMenu.tr,
            fontWeight: FontWeight.w400,
            color: AppColors.red,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Align(
          //   alignment: Alignment.centerRight,
          //   child: CustomBtn(
          //     width: 70,
          //     height: 30,
          //     title: "Submit",
          //     textColor: AppColors.primaryColor,
          //     bgColor: AppColors.white,
          //     borderColor: AppColors.primaryColor,
          //     radius: 10.0,
          //     onTap: () {
          //       controller.fetchFoodSnapSearchApi();
          //     },
          //
          //    ),
          // )
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {

      // if (controller.validSnapSearchImages.isEmpty) return SizedBox();

      final response = controller.foodSnapSearchResponse.value;
      final categoryList = controller.categoryFoundProductDataList;
      // final searchData = controller.productSnapSearchData;

      // 1. Handle Loading States
      if (response.status == Status.LOADING) return _buildLoadingState();
      if (response.status == Status.INITIAL) return const SizedBox();

      // 2. Check if the master list is empty after a search
      if (categoryList.isEmpty) {
        return _buildEmptyState();
      }

      // 3. Render success state using the master list
      return Column(
        children: [
          // if (searchData != null) _buildSummaryHeader(searchData),
          _buildSummaryHeader(),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              final foodItem = categoryList[index];

              return FoodProductCard(
                product: foodItem,
                onShowVariants: (p) => _showVariantSheet(context, p),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: SnapScanLoader(),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        EmptyStateWidget(
          message: AppStrings.foodSnapNoProductsFound.tr,
        ),
        const SizedBox(height: 20),
        CustomBtn(
          width: 120,
          title: AppStrings.foodRetryLabel.tr,
          textColor: AppColors.white,
          bgColor: AppColors.primaryColor,
          radius: 10.0,
          onTap: () => controller.fetchFoodSnapSearchApi(),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Get.back(),
          child: CustomText(
            AppStrings.foodSearchManuallyLabel.tr,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            // "${data.foundCount ?? 0} Items Found",
            "${controller.categoryFoundProductDataList.length} ${AppStrings.foodItemsFoundLabel.tr}",
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          CustomText(
            // "${data.missingCount ?? 0} Items missing",
            "${controller.missingProducts.length} ${AppStrings.foodItemsMissingLabel.tr}",
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  void _showVariantSheet(
      BuildContext context,
      CategoryFoodProductData product
      ) {
    Get.bottomSheet(
      ProductVariantBottomSheet(
        product: product,
        controller: controller,
        isSnapSearch: true,
      ),
      isScrollControlled: true,
    );
  }

}