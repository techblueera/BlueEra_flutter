import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/earn_profiles_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/home_made_food_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_store_details_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/earn_profile_store_list.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeMadeFoodDiscoverScreen extends StatefulWidget {
  const HomeMadeFoodDiscoverScreen({super.key});

  @override
  State<HomeMadeFoodDiscoverScreen> createState() => _HomeMadeFoodDiscoverScreenState();
}

class _HomeMadeFoodDiscoverScreenState extends State<HomeMadeFoodDiscoverScreen> {
  static const String _profileType = 'homeMadeFood';
  static const Color _warm = kEarnProfileWarm;

  final controller = getOrPut(
    () => EarnProfilesDiscoverController(profileType: _profileType),
    tag: _profileType,
  );

  // Shared cart for the whole home made food flow — registered here (the
  // flow entry) so it survives entering / leaving the store details screen.
  final cartController = getOrPut(() => HomeMadeFoodCartController());

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-indian-food-arrangement_23-2148723455.jpg?w=1380",
    "https://img.freepik.com/free-photo/high-angle-pakistani-meal-composition_23-2148825105.jpg?w=1380",
    "https://img.freepik.com/free-photo/delicious-indian-dosa-composition_23-2149086052.jpg?w=1380",
  ];

  @override
  void dispose() {
    deleteIfRegistered<EarnProfilesDiscoverController>(tag: _profileType);
    deleteIfRegistered<HomeMadeFoodCartController>();
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
                  color: _warm, size: 56),
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
                        final kitchen = cartController.store.value;
                        if (kitchen != null) {
                          Get.to(() => HomeMadeFoodCartScreen(store: kitchen));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _warm,
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
          backgroundColor: AppColors.appBackgroundColor,
          body: Stack(
            children: [
              NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: BannerCarousel(
                      images: _bannerImages,
                      onBack: _handleBack,
                      statusBarHeight: statusBarHeight,
                      backgroundColor:
                          AppColors.blue5CAF.withValues(alpha: 0.1),
                      bottomBorderSide: const BorderSide(
                        color: AppColors.white,
                        width: 2,
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
        if (isIndividualUser()) _buildPostCta(),
        _buildListHeader(),
        Expanded(
          child: EarnProfileStoreList(
            controller: controller,
            footerLabel: 'View Kitchen Menu',
            emptyMessage: 'No home made food kitchens found nearby.',
            bottomPadding: 96,
            onStoreTap: (store) =>
                Get.to(() => HomeMadeFoodStoreDetailsDiscoverScreen(store: store)),
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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_warm, kEarnProfileWarm2],
              ),
              boxShadow: [
                BoxShadow(
                  color: _warm.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.soup_kitchen_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'Add Your Own Home Made Food',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          'Start your home kitchen & reach nearby foodies',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
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
    final earnType = (viewProfileController.earnProfileType.value ?? '').trim();
    if (AppConstants.earnServiceProfileSlugs.contains(earnType)) {
      Get.toNamed(RouteHelper.getEarnServiceDashboardViewRoute());
    } else {
      Get.toNamed(RouteHelper.getChooseEarnServiceScreenRoute());
    }
  }

  // ── List header ──────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_warm, kEarnProfileWarm2],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Home Kitchens Near You',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  letterSpacing: 0.2,
                ),
                const SizedBox(height: 1),
                CustomText(
                  'Freshly made, just around the corner',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ],
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
      final kitchen = cartController.store.value;
      return Center(
        child: FloatingCartWidget(
          itemCount: count,
          displayImages: cartController.previewImages,
          cartLabel: 'View Cart',
          itemLabel:
              '$count ${count == 1 ? 'item' : 'items'}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: kitchen == null
              ? () {}
              : () => Get.to(() => HomeMadeFoodCartScreen(store: kitchen)),
        ),
      );
    });
  }
}
