import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_cart_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/earn_profile_store_list.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/hmf_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HmfStoreDiscoverScreen extends StatefulWidget {
  const HmfStoreDiscoverScreen({super.key});

  @override
  State<HmfStoreDiscoverScreen> createState() => _HmfStoreDiscoverScreenState();
}

class _HmfStoreDiscoverScreenState extends State<HmfStoreDiscoverScreen> {
  static const String _profileType = 'homeMadeFood';
  static const Color _primary = AppColors.primaryColor;

  final controller = getOrPut(
    () => EarnProfilesDiscoverController(profileType: _profileType),
    tag: _profileType,
  );

  // Shared cart for the whole home made food flow — registered here (the
  // flow entry) so it survives entering / leaving the store details screen.
  final cartController = getOrPut(() => HmfCartController());

  final List<String> _bannerImages = const [
    // Thali, biryani, paneer tikka — all downloaded and viewed before
    // committing. The freepik links these replace did serve food, but every
    // freepik hotlink comes back tiled with a "Magnific" watermark, and two of
    // the three were portrait crops that lost their subject in a 16:8 banner.
    "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=1380&q=80",
    "https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=1380&q=80",
    "https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=1380&q=80",
  ];

  @override
  void dispose() {
    deleteIfRegistered<EarnProfilesDiscoverController>(tag: _profileType);
    deleteIfRegistered<HmfCartController>();
    super.dispose();
  }

  void _handleBack() {
    if (cartController.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _showCartWarning();
  }

  void _showCartWarning() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_shopping_cart_rounded,
                  color: _primary, size: 56),
              const SizedBox(height: 16),
              CustomText(
                AppStrings.leaveWithoutOrdering.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CustomText(
                AppStrings.cartWillBeCleared.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        cartController.clear();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(AppStrings.leaveLabel.tr,
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const HmfCartScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(AppStrings.viewCart.tr,
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.onScrollEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.blue5CAF.withValues(alpha: 0.1),
                            AppColors.blue5CAF.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          BannerCarousel(
                            images: _bannerImages,
                            onBack: _handleBack,
                            statusBarHeight: statusBarHeight,
                            backgroundColor: Colors.transparent,
                            bottomBorderSide: const BorderSide(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                          if (isIndividualUser()) _buildPostCta(),
                          SizedBox(height: SizeConfig.size12),
                        ],
                      ),
                    ),
                  ),
                ],
                body: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: _buildContent(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(child: _buildCartBar()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(),
        Expanded(
          child: EarnProfileStoreList(
            controller: controller,
            footerLabel: AppStrings.viewKitchenMenu.tr,
            emptyMessage: AppStrings.noHomeMadeFoodKitchens.tr,
            bottomPadding: 96,
            adKeyPrefix: 'hmf_store_native_ad',
            onStoreTap: (store) => Get.to(
                () => HmfStoreDetailsDiscoverScreen(userId: store.userId ?? '')),
          ),
        ),
      ],
    );
  }

  // ── Post CTA (individual users only) ──────────────────────────────────────
  Widget _buildPostCta() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size14,
        SizeConfig.size12,
        SizeConfig.size4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onPostTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greyE5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.soup_kitchen_rounded,
                        color: _primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.addYourOwnHomeMadeFood.tr,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          AppStrings.startYourHomeKitchen.tr,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary.withValues(alpha: 0.10),
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppColors.secondaryTextColor, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPostTap() {
    if (isGuestUser() || isBusinessUser()) return;
    final viewProfileController =
        Get.isRegistered<ViewPersonalDetailsController>()
            ? Get.find<ViewPersonalDetailsController>()
            : getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    if (viewProfileController.earnProfileType.contains('homeMadeFood')) {
      Get.to(() => const EarnServiceDashboardView(earnType: 'homeMadeFood'));
    } else {
      Get.to(() => const HomeMadeFoodProfileScreen());
    }
  }

  // ── List header ──────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size16,
        SizeConfig.size14,
        SizeConfig.size8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomText(
            AppStrings.homeKitchensNearYou.tr,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: 0.2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating cart bar (shared cart) ──────────────────────────────────────
  Widget _buildCartBar() {
    return Obx(() {
      // ignore: unused_local_variable
      final _ = cartController.quantities.length; // subscribe to changes
      if (cartController.isEmpty) return const SizedBox.shrink();
      final count = cartController.totalItems;
      final stores = cartController.storeCount;
      return Center(
        child: FloatingCartWidget(
          itemCount: count,
          displayImages: cartController.previewImages,
          cartLabel: stores > 1 ? AppStrings.viewCarts.tr : AppStrings.viewCart.tr,
          itemLabel: stores > 1
              ? '$stores ${AppStrings.kitchensLabel.tr}  •  $count ${count == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}'
              : '$count ${count == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: () => Get.to(() => const HmfCartScreen()),
        ),
      );
    });
  }
}
