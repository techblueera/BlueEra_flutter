import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/product/widget/own_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_products_view_all_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_contact_map_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_gallery_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_profile_header.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_qr_code_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_stats.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_testimonial_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/product_price_edit_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeProductHomePage extends StatefulWidget {
  const HomeMadeProductHomePage({super.key});

  @override
  State<HomeMadeProductHomePage> createState() =>
      _HomeMadeProductHomePageState();
}

class _HomeMadeProductHomePageState extends State<HomeMadeProductHomePage> {
  late final EarnProfileController earnProfileController;
  late final EarnServiceController earnServiceController;

  // Fixed dimensions used for the horizontal product strip.
  static const double _productCardHeight = 220;
  static const double _productCardWidthRatio = 0.42;

  @override
  void initState() {
    super.initState();
    earnProfileController = getOrPut(() => EarnProfileController());
    earnServiceController = getOrPut(() => EarnServiceController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      earnProfileController.fetchEarnProfile();
      earnServiceController.fetchOwnProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
      child: Column(
        children: [
          EarnServiceProfileHeader(controller: earnProfileController),
          EarnServiceStats(controller: earnProfileController),
          _buildProductSection(),
          Obx(() => EarnServiceGalleryCard(
                gallery: earnProfileController.earnProfile.value?.galleryImages,
                onAddImage: _pickAndUploadGalleryImage,
                onRemoveImage: earnProfileController.removeGalleryImage,
              )),
          EarnServiceTestimonialCard(testimonials: const []),
          EarnServiceContactMapCard(controller: earnProfileController),
          EarnServiceQrCodeWidget(controller: earnProfileController),
          SizedBox(height: SizeConfig.size150),
        ],
      ),
    );
  }

  // ─── Product Section ──────────────────────────────────────────
  Widget _buildProductSection() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: const EdgeInsets.only(top: 10),
      child: Obx(() {
        final isLoading = earnServiceController.isOwnProductDataFirstLoading.value;
        final products = earnServiceController.ownProductDataList;
        final hasProducts = products.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Home Made Product',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                ),
                if (hasProducts) ...[
                  InkWell(
                    onTap: _onAddProductTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size8,
                          vertical: SizeConfig.size4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add,
                              size: 14, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          CustomText('Add',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  InkWell(
                    onTap: () => Get.to(
                        () => const HomeMadeProductsViewAllScreen()),
                    child: CustomText(
                      'View All',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            if (isLoading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!hasProducts)
              _buildEmptyProductState()
            else
              _buildProductList(products.take(20).toList()),
          ],
        );
      }),
    );
  }

  Widget _buildProductList(List products) {
    final cardWidth = SizeConfig.screenWidth * _productCardWidthRatio;
    return SizedBox(
      height: _productCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final product = products[index];
          return SizedBox(
            width: cardWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: OwnProductCard(
                    product: product,
                    deleteProductApi: () {},
                    width: cardWidth,
                    isGridShow: true,
                    showAttributes: false,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: InkWell(
                    onTap: () => ProductPriceEditSheet.show(
                      context: context,
                      product: product,
                      controller: earnServiceController,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: AppColors.primaryColor, width: 1.0),
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.pen_line,
                        imgColor: AppColors.primaryColor,
                        height: 14,
                        width: 14,
                        boxFix: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Empty state styled like BusinessCommonGalleryCard._buildEmptyState.
  Widget _buildEmptyProductState() {
    return InkWell(
      onTap: _onAddProductTap,
      child: Container(
        height: SizeConfig.size200,
        width: SizeConfig.screenWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          image: DecorationImage(
            image: AssetImage(AppImageAssets.homeMadeFoodBanner),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: AppColors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppImageAssets.noMeContent,
                  height: SizeConfig.size80,
                  width: SizeConfig.size80,
                ),
                const SizedBox(height: 6.0),
                CustomText(
                  'You Have Not Added Any Product',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: AppColors.primaryColor,
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                      child: CustomText(
                        'Add Home Made Product',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAddProductTap() {
    Get.toNamed(
      RouteHelper.getAddProductViaAiStep1Route(),
      arguments: {
        ApiKeys.id: userId,
        ApiKeys.providerType: ProviderType.user,
      },
    );
  }

  Future<void> _pickAndUploadGalleryImage() async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: 'Upload Photo',
    );
    if (path == null || path.isEmpty) return;
    await earnProfileController.addGalleryImage(File(path));
  }
}
