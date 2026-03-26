import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_rider_consumer_controller.dart';
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

class GroceryRiderSnapSearchScreen extends StatefulWidget {
  const GroceryRiderSnapSearchScreen({super.key});

  @override
  State<GroceryRiderSnapSearchScreen> createState() =>
      _GroceryRiderSnapSearchScreenState();
}

class _GroceryRiderSnapSearchScreenState extends State<GroceryRiderSnapSearchScreen> {
  final controller = getOrPut(() => GroceryRiderConsumerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(title: "Search Grocery Items"),
      bottomNavigationBar: _buildBottomAction(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size15,
          horizontal: SizeConfig.size8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadSection(),
            _buildProductList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Obx(() {
      final int count = controller.totalItemsCount;
      if (count == 0) return const SizedBox.shrink();

      return Container(
        color: AppColors.white,
        padding: EdgeInsets.all(SizeConfig.size15),
        child: SafeArea(
          child: CustomBtn(
            onTap: () => Get.back(),
            radius: SizeConfig.size8,
            bgColor: AppColors.primaryColor,
            title: 'View Cart ($count items)',
          ),
        ),
      );
    });
  }

  Widget _buildUploadSection() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Upload Grocery List", fontWeight: FontWeight.bold),
          const SizedBox(height: 14),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.grocerySnapSearchConfig.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final config = controller.grocerySnapSearchConfig[index];
              final String title = config['title']!;
              final String placeholder = config['image']!;
              final String icon = config['icon']!;

              return Obx(() {
                final File? capturedFile =
                    controller.riderSnapSearchImagesMap[title];
                final bool hasImage = capturedFile != null;
                final bool isAnySelected = controller
                    .riderSnapSearchImagesMap.values
                    .any((v) => v != null);
                final bool isBlocked = isAnySelected && !hasImage;

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
                              : () => controller.addRiderImageBySlot(title),
                      child: Opacity(
                        opacity: isBlocked ? 0.5 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: SizedBox(
                            height: SizeConfig.size180,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                hasImage
                                    ? Image.file(capturedFile, fit: BoxFit.cover)
                                    : Image.asset(placeholder, fit: BoxFit.cover),

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

                                if (!hasImage) ...[
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 2, sigmaY: 2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: AppColors.black
                                                .withValues(alpha: 0.6),
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
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.white
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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

                                if (hasImage)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => controller
                                          .removeRiderImageBySlot(title),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            Colors.red.withValues(alpha: 0.8),
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
                      fontWeight:
                          hasImage ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                );
              });
            },
          ),
          const SizedBox(height: 10),
          const CustomText(
            "Upload a photo of your grocery list — up to 20 items at a time",
            fontWeight: FontWeight.w400,
            color: AppColors.red,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      final response = controller.riderSnapSearchResponse.value;
      final searchData = controller.riderSnapSearchData.value;

      if (response.status == Status.INITIAL) return const SizedBox();

      if (response.status == Status.LOADING) return _buildLoadingState();

      final foundProducts = searchData?.foundProducts ?? [];

      if (searchData == null || foundProducts.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: [
          _buildSummaryHeader(searchData),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foundProducts.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) =>
                _buildProductCard(foundProducts[index]),
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
          message: 'We couldn\'t identify any products from this photo.\n'
              'Try capturing a clearer shot!',
        ),
        SizedBox(height: SizeConfig.paddingL),
        CustomBtn(
          width: SizeConfig.size120,
          title: "Retry",
          textColor: AppColors.white,
          bgColor: AppColors.primaryColor,
          radius: 10.0,
          onTap: () => controller.fetchRiderGrocerySnapSearchApi(),
        ),
        SizedBox(height: SizeConfig.paddingXSL),
      ],
    );
  }

  Widget _buildSummaryHeader(ProductSnapSearchData data) {
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
          CustomText(
            "${data.missingCount ?? 0} Items missing",
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(FoundProducts foundProducts) {
    final GroceryProductData? groceryItem = foundProducts.productDetails;
    if (groceryItem == null) return const SizedBox();

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: (groceryItem.images != null &&
                      groceryItem.images!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: groceryItem.images!.first.url ?? '',
                      fit: BoxFit.contain,
                      height: SizeConfig.size80,
                      width: SizeConfig.size80,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
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
                      width: SizeConfig.size80,
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.size10),
                    child: CustomText(
                      groceryItem.name ?? '',
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Obx(() {
                    final variants = groceryItem.variants ?? [];
                    return Column(
                      children: List.generate(variants.length, (i) {
                        final v = variants[i];
                        final int qty =
                            controller.getQuantity(v.sId);
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 10, bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      '${v.quantity}',
                                      fontSize: SizeConfig.small,
                                      color: AppColors.mainTextColor,
                                    ),
                                    if (v.pricing != null &&
                                        v.pricing!.isNotEmpty)
                                      CustomText(
                                        "₹${v.pricing!.first.sellingPrice}",
                                        fontSize: SizeConfig.small,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  ],
                                ),
                              ),
                              _buildQtyControl(
                                qty: qty,
                                onAdd: () => controller.addToCart(
                                  v,
                                  productId: groceryItem.sId,
                                ),
                                onRemove: () =>
                                    controller.removeFromCart(v),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyControl({
    required int qty,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    if (qty == 0) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const CustomText(
            "ADD",
            fontSize: 12,
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.remove,
                size: 16, color: AppColors.primaryColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomText(
            '$qty',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor,
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add, size: 16, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}
