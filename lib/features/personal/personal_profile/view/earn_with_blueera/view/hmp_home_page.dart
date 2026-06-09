import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/admin_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/hmp_view_all_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_contact_map_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_gallery_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_qr_code_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_testimonial_card.dart';
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

  // Fixed width ratio for the horizontal product strip; the height is
  // derived from the card's own content (see AdminProductCard.gridCardHeight).
  static const double _productCardWidthRatio = 0.42;

  @override
  void initState() {
    super.initState();
    earnProfileController = getOrPut(() => EarnProfileController());
    earnServiceController = getOrPut(() => EarnServiceController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      earnServiceController.fetchOwnProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        8,
        SizeConfig.size12,
        8,
        4 * kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductSection(),
          SizedBox(height: SizeConfig.size12),
          Obx(() => EarnServiceGalleryCard(
                gallery: earnProfileController.earnProfile.value?.galleryImages,
                onAddImage: _pickAndUploadGalleryImage,
                onRemoveImage: earnProfileController.removeGalleryImage,
              )),
          EarnServiceTestimonialCard(testimonials: const []),
          EarnServiceContactMapCard(controller: earnProfileController),
          EarnServiceQrCodeWidget(controller: earnProfileController),
        ],
      ),
    );
  }

  // ─── Home Made Product Section — clean white section card mirroring the
  // home_made_food_home_page section style.
  Widget _buildProductSection() {
    return Obx(() {
      final isLoading = earnServiceController.isOwnProductDataFirstLoading.value;
      final products = earnServiceController.ownProductDataList;
      final hasProducts = products.isNotEmpty;

      return _section(
        AppStrings.homeMadeProductSection,
        isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : !hasProducts
                ? _buildEmptyProductState()
                : _buildProductList(products.take(20).toList()),
        trailing: hasProducts
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editChip(
                    onTap: _onAddProductTap,
                    label: AppStrings.add,
                    icon: Icons.add,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  _editChip(
                    onTap: () =>
                        Get.to(() => const HomeMadeProductsViewAllScreen()),
                    label: AppStrings.viewAll,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ],
              )
            : null,
      );
    });
  }

  Widget _buildProductList(List products) {
    final cardWidth = SizeConfig.screenWidth * _productCardWidthRatio;
    return SizedBox(
      height: AdminProductCard.gridCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final product = products[index];
          return SizedBox(
            width: cardWidth,
            child: AdminProductCard(
              product: product,
              deleteProductApi: () {},
              width: cardWidth,
              isGridShow: true,
              showAttributes: false,
              onUpdatePrice: earnServiceController.updateProductVariantPrice,
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
                  AppStrings.youHaveNotAddedAnyProduct,
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
                        AppStrings.addHomeMadeProduct,
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
      title: AppStrings.uploadPhotoTitle,
    );
    if (path == null || path.isEmpty) return;
    await earnProfileController.addGalleryImage(File(path));
  }

  // ─────────────────────────────────────────────
  // SECTION SHELL — clean white card + plain bold heading, mirroring the
  // home_made_food_home_page section style.
  // ─────────────────────────────────────────────
  Widget _section(String title, Widget child,
      {Widget? trailing}) {
    return CustomFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _sectionHeading(title)),
              if (trailing != null) trailing,

            ],
          ),
          SizedBox(height: SizeConfig.size12),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return CustomText(
      text,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: AppColors.mainTextColor,
      letterSpacing: 0.2,
    );
  }

  Widget _editChip({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
