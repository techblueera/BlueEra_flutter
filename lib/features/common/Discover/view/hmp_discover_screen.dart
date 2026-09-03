import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/hmp_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmp_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmp_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/earn_profile_store_list.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/hmp_profile_screen.dart';
import 'package:BlueEra/widgets/blinking_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HmpDiscoverScreen extends StatefulWidget {
  final bool isShowInGrid;

  const HmpDiscoverScreen({super.key, this.isShowInGrid = false});

  @override
  State<HmpDiscoverScreen> createState() => _HmpDiscoverScreenState();
}

class _HmpDiscoverScreenState extends State<HmpDiscoverScreen> {
  static const String _profileType = 'homeMadeProduct';
  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  final controller = getOrPut(
    () => EarnProfilesDiscoverController(profileType: _profileType),
    tag: _profileType,
  );

  // Shared cart for the whole home made product flow — registered here (the
  // flow entry) so it survives entering / leaving the store details screen.
  final cartController = getOrPut(() => HmpCartController());

  final List<String> _bannerImages = const [
    // Same verified set as [HmpDiscoverScreenV2] — see the note there. The
    // freepik links these replace served vaccination templates, a
    // business-card mockup and a guitar thumbnail.
    "https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?w=1380&q=80",
    "https://images.unsplash.com/photo-1493106641515-6b5631de4bb9?w=1380&q=80",
    "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=1380&q=80",
  ];

  @override
  void dispose() {
    deleteIfRegistered<EarnProfilesDiscoverController>(tag: _profileType);
    deleteIfRegistered<HmpCartController>();
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
                'Leave without ordering?',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CustomText(
                'Your cart will be cleared if you go back.',
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
                      child: CustomText('Leave',
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
                        Get.to(() => const HmpCartScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText('View Cart',
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
              if (isIndividualUser())
                Positioned(
                  right: 16,
                  bottom: 0,
                  child: SafeArea(
                    child: Obx(() {
                      final cartVisible = !cartController.isEmpty;
                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(bottom: cartVisible ? 84 : 16),
                        child: BlinkingWidget(child: _buildPostFab()),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
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
          cartLabel: stores > 1 ? 'View Carts' : 'View Cart',
          itemLabel: stores > 1
              ? '$stores sellers  •  $count ${count == 1 ? 'item' : 'items'}'
              : '$count ${count == 1 ? 'item' : 'items'}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: () => Get.to(() => const HmpCartScreen()),
        ),
      );
    });
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(),
        Expanded(
          child: EarnProfileStoreList(
            controller: controller,
            footerLabel: 'View Products',
            emptyMessage: 'No home made product sellers found nearby.',
            bottomPadding: 96,
            adKeyPrefix: 'hmp_store_native_ad',
            onStoreTap: (store) =>
                Get.to(() => HmpStoreDetailsDiscoverScreen(store: store)),
          ),
        ),
      ],
    );
  }

  /// Floating "Add Product" action — a gradient extended FAB pill, so the add
  /// affordance no longer crowds the banner header.
  Widget _buildPostFab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onPostTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDeep],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_business_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              CustomText(
                'Add Product',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.2,
              ),
            ],
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
    if (viewProfileController.earnProfileType.contains('homeMadeProduct')) {
      Get.to(() => const EarnServiceDashboardView(earnType: 'homeMadeProduct'));
    } else {
      Get.to(() => const HomeProfileScreen());
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
            'Home Product Sellers Near You',
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
}
