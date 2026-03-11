import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
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

class AddGrocerySnapSearchScreen extends StatefulWidget {
  const AddGrocerySnapSearchScreen({super.key});

  @override
  State<AddGrocerySnapSearchScreen> createState() => _AddGrocerySnapSearchScreenState();
}

class _AddGrocerySnapSearchScreenState extends State<AddGrocerySnapSearchScreen> {
  final controller = getOrPut(() => GroceryController());

  @override
  dispose(){
    deleteIfRegistered<GroceryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: "Grocery Items",
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

        final bool canSubmit = controller.canSubmitProducts;
        print('can submit-- $canSubmit');

        final int productCount = controller.selectedProductVariants.keys.length;
        final variantCount = controller.selectedProductVariants.values.fold(0, (sum, list) => sum + list.length);
        final bool loading = controller.isAddGroceryProductsLoading.value;

        return SafeArea(
          child: CustomBtn(
            onTap: canSubmit && !loading
                ? () => controller.addGroceryProductNewVariant(
              isSnapSearch: true
            )
                : null,
            isValidate: canSubmit,
            radius: SizeConfig.size8,
            bgColor: canSubmit ? AppColors.primaryColor : Colors.grey,
            title: 'Publish $productCount Products, $variantCount Variants',
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
          const CustomText("Bulk Upload Shop Product Photos", fontWeight: FontWeight.bold),
          const SizedBox(height: 14),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            // Use the config list length
            itemCount: controller.grocerySnapSearchConfig.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final config = controller.grocerySnapSearchConfig[index];
              final String title = config['title']!;
              final String placeholder = config['image']!;

              return Obx(() {
                final File? capturedFile = controller.grocerySnapSearchImagesMap[title];
                final bool hasImage = capturedFile != null;

                return Column(
                  children: [
                    InkWell(
                      onTap: hasImage
                          ? () => navigatePushTo(
                        context,
                        ImageViewScreen(
                          appBarTitle: title,
                          imageUrls: [capturedFile.path],
                          initialIndex: 0,
                        ),
                      )
                          : () => controller.addImagesBySlot(title),
                      child: Stack(
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
                                  // Swaps between static asset and captured file
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
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      title,
                      fontSize: 12,
                      color: hasImage ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      fontWeight: hasImage ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                );
              });
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: CustomBtn(
              width: 80,
              height: 35,
              title: "Submit",
              textColor: AppColors.primaryColor,
              bgColor: AppColors.white,
              borderColor: AppColors.primaryColor,
              radius: 8.0,
              onTap: () => controller.fetchGrocerySnapSearchApi(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      final response = controller.grocerySnapSearchResponse.value;
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
          // Summary Header (Items Found vs Missing)
          _buildSummaryHeader(searchData),

          // Result View: Either the List or the Empty State
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
        const EmptyStateWidget(
          message: 'We couldn’t identify any products from this photo. \n'
              'Try capturing a clearer shot or searching for individual items!',
        ),
        SizedBox(height: SizeConfig.paddingL),
        CustomBtn(
          width: SizeConfig.size120,
          title: "Retry",
          textColor: AppColors.white,
          bgColor: AppColors.primaryColor,
          radius: 10.0,
          onTap: () => controller.fetchGrocerySnapSearchApi(),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          ),
          child: CustomText(
            "Search Manually",
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget  _buildSummaryHeader(var data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            "${data.foundCount ?? 0} Items Found",
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          InkWell(
            onTap: () {
              // Future navigation logic for missing items
            },
            child: CustomText(
              "${data.missingCount ?? 0} Items missing",
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(FoundProducts foundProducts){

    GroceryProductData? groceryItem = foundProducts.productDetails;

    if(groceryItem==null) return SizedBox();

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
                  child:  (groceryItem.images!=null &&  groceryItem.images!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: groceryItem.images!.first.url??'',
                    fit: BoxFit.contain,
                    // fit: BoxFit.cover,
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
                          groceryItem.name,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: SizeConfig.size8),

                      /// --- Variant Column ---
                      Obx(() {
                        final groceryVariants = groceryItem.variants ?? [];

                        return Column(
                          children: List.generate(groceryVariants.length, (variantIndex) {
                            final v = groceryVariants[variantIndex];

                            return Padding(
                              padding: EdgeInsets.zero,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: controller.isVariantSelected(
                                      groceryItem.sId ?? '',
                                      v.sId ?? '',
                                    ),
                                    onChanged: (_) {
                                      controller.toggleVariant(
                                        groceryItem.sId ?? '',
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
                                    '${v.quantity}',
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

                                  // Safe access for pricing array
                                  CustomText(
                                    "₹${(v.pricing != null && v.pricing!.isNotEmpty) ? v.pricing![0].mrp : '0'}",
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
                                    "Selling- ₹${(v.pricing != null && v.pricing!.isNotEmpty) ? v.pricing![0].sellingPrice : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const Spacer(),

                                  InkWell(
                                    onTap: () {
                                      controller.openEditVariantDialog(
                                        context: context,
                                        title: groceryItem.name ?? 'Edit Variant',
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