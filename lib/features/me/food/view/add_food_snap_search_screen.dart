import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_card.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
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
  }

  @override
  dispose(){
    // deleteIfRegistered<FoodServiceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: "Grocery Items",
      ),
      bottomNavigationBar: _buildBottomPublishBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size15,
              horizontal: SizeConfig.size8
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulkUploadSection(),
              _buildProductList(),
            ],
          ),
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
          const CustomText("Bulk Upload Shop Product Photos", fontWeight: FontWeight.bold),
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
              // Get the static data for this slot
              var item = controller.foodSnapSearchPhotos[index];
              String title = item['title']!;
              String staticPath = item['image']!;

              return Obx(() {
                File? capturedFile = controller.foodSnapSearchImagesMap[title];
                bool hasImage = capturedFile != null;

                return InkWell(
                  onTap: hasImage
                      ? () => navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: title,
                      imageUrls: [capturedFile.path],
                      initialIndex: 0,
                    ),
                  )
                      : () => controller.addImagesByTitle(title),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              height: SizeConfig.size180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: hasImage ? AppColors.primaryColor : AppColors.greyE5,
                                  width: hasImage ? 1.5 : 1,
                                ),
                                image: DecorationImage(
                                  image: (hasImage
                                      ? FileImage(capturedFile)
                                      : AssetImage(staticPath)) as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Remove button shows only when an image is captured
                          if (hasImage)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => controller.removeImageByTitle(title),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        title,
                        fontSize: SizeConfig.small,
                        color: hasImage ? AppColors.primaryColor : AppColors.secondaryTextColor,
                        fontWeight: hasImage ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ],
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CustomBtn(
              width: 70,
              height: 30,
              title: "Submit",
              textColor: AppColors.primaryColor,
              bgColor: AppColors.white,
              borderColor: AppColors.primaryColor,
              radius: 10.0,
              onTap: () {
                controller.fetchFoodSnapSearchApi();
              },

             ),
          )
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      final response = controller.foodSnapSearchResponse.value;
      final categoryList = controller.categoryFoodProductDataList;
      final searchData = controller.productSnapSearchData;

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
          if (searchData != null) _buildSummaryHeader(searchData),

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Image.asset(
          'assets/images/grocery_loading_indicator.gif',
          fit: BoxFit.contain,
          // height: 100,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        const EmptyStateWidget(
          message: 'We couldn’t identify any products from this photo. \n'
              'Try capturing a clearer shot or searching for individual items!',
        ),
        const SizedBox(height: 20),
        CustomBtn(
          width: 120,
          title: "Retry",
          textColor: AppColors.white,
          bgColor: AppColors.primaryColor,
          radius: 10.0,
          onTap: () => controller.fetchFoodSnapSearchApi(),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Get.back(),
          child: CustomText(
            "Search Manually",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(var data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            "${data.foundCount ?? 0} Items Found",
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          CustomText(
            "${data.missingCount ?? 0} Items missing",
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

  Widget _buildBottomPublishBar() {
    return Obx(() {
      // 1. Count of unique Products (Keys in the Map)
      final int productCount = controller.selectedVariantsMap.keys.length;

      // 2. Count of total individual Variants (Sum of all list lengths)
      final int totalVariantsCount = controller.selectedVariantsMap.values
          .fold(0, (sum, list) => sum + list.length);

      // Only show if at least one product is selected
      if (productCount == 0) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Left Side: Summary Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "$productCount Products Selected, $totalVariantsCount Total Variants ready",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    CustomText(
                      "Ready to publish to inventory",
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: PositiveCustomBtn(
                  onTap: () => controller.bulkPublishInventory(isSnapSearch: true),
                  title: "Publish All",
                ),
              ),
            ],
          ),
        ),
      );
    });
  }


}