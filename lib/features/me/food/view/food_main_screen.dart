import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_verify_now_button.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_screen_preview.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/food/controller/home_food_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/food/view/discount_food_products_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:BlueEra/features/me/food/view/food_category_screen.dart';
import 'package:BlueEra/features/me/food/view/food_service_gallery/food_service_photos_screen.dart';
import 'package:BlueEra/features/me/food/view/my_food_product_screen.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_sheet.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Food main screen (v2) — same layout as MedicalHomeScreenV2:
///   • Pattern background + custom top bar (drawer / earn / notifications / go-live)
///   • Profile row with logo, name, type, verify-now and preview-as-visitor
///   • Pill tab bar (Order / Overview / Products / Post / Statistics)
///   • Body switches per selected tab — Overview composes banner, popular
///     dishes, live photos, gallery and contact card from the existing
///     [RestaurantController] and [ViewBusinessDetailsController] data.
class FoodMainScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const FoodMainScreen({super.key, this.fromBottomNavBar});

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen> {
  int _selectedTab = 1;
  bool _isGoLive = false;

  late final RestaurantController _foodController;
  late final ViewBusinessDetailsController _businessController;

  static const _tabs = [
    'Order',
    'Overview',
    'Products',
    'Post',
    'Statistics',
  ];

  static const int _discountPreviewLimit = 20;

  @override
  void initState() {
    super.initState();
    _foodController = getOrPut(() => RestaurantController());
    _businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    _loadInitialData();
  }

  void _loadInitialData() {
    final id = businessId;
    if (id.isEmpty) return;
    _foodController.fetchHomeData(businessId: id);
    _foodController.fetchDiscountFoodProducts(businessId: id);
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            Column(
              children: [
                _buildTopBar(),
                Obx(() {
                  final details =
                      _businessController.businessProfileDetails.value?.data;
                  return _buildProfileRow(details);
                }),
                Expanded(
                  child: Obx(() {
                    final isHomeLoading = _foodController
                            .foodHomeDataResponse.value.status ==
                        Status.INITIAL;
                    if (isHomeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: kBottomNavigationBarHeight + 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: SizeConfig.size10),
                            _buildTabsCard(),
                            SizedBox(height: SizeConfig.size12),
                            ..._buildTabContent(),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final id = businessId;
    if (id.isEmpty) return;
    _foodController.fetchHomeData(businessId: id);
    await _foodController.fetchDiscountFoodProducts(businessId: id);
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT — switches body by _selectedTab
  //   0 Order, 1 Overview, 2 Products, 3 Post, 4 Statistics
  // ─────────────────────────────────────────────
  List<Widget> _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return [_buildComingSoon(label: 'Orders coming soon')];
      case 1:
        return _buildOverviewSlivers();
      case 2:
        return _buildProductsTab();
      case 3:
        return _buildPostTab();
      case 4:
        return [
          MedicalStatisticsScreen(
            businessId: businessId.isNotEmpty ? businessId : userId,
          ),
        ];
      default:
        return [_buildComingSoon(label: AppStrings.comingSoon)];
    }
  }

  List<Widget> _buildOverviewSlivers() {
    return [
      _buildBannerSection(),
      SizedBox(height: SizeConfig.size12),
      _buildCreateOffersButton(),
      SizedBox(height: SizeConfig.size16),
      _buildPopularDishesSection(),
      _buildLivePhotosSection(),
      SizedBox(height: SizeConfig.size16),
      _buildGallerySection(),
      SizedBox(height: SizeConfig.size16),
      _buildContactSection(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // ─────────────────────────────────────────────
  // PRODUCTS TAB — food menu categories grid
  // ─────────────────────────────────────────────
  List<Widget> _buildProductsTab() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: CustomText(
                AppStrings.foodOurMenuLabel.tr,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => FoodCategoryMenuScreen()),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: CustomText(
                'Add More Product',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size8,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: SizeConfig.size10),
      _buildFoodMenuGrid(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  Widget _buildFoodMenuGrid() {
    return Obx(() {
      final List<GroceryNestedCategoryModel> menus =
          List<GroceryNestedCategoryModel>.from(
              _foodController.foodMenuNestedCategory);

      if (menus.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12,
            vertical: SizeConfig.size20,
          ),
          child: EmptyStateWidget(
            message: AppStrings.foodNoProductCreate.tr,
            actionText: 'Add Product',
            actionCallback: () => Get.to(() => FoodCategoryMenuScreen()),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            itemCount: menus.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: SizeConfig.size12,
              mainAxisSpacing: SizeConfig.size12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (_, i) => _foodMenuCategoryCard(menus[i]),
          );
        },
      );
    });
  }

  Widget _foodMenuCategoryCard(GroceryNestedCategoryModel item) {
    final hasImage = (item.image ?? '').isNotEmpty;
    final isNetwork = hasImage && isNetworkImage(item.image!);

    return InkWell(
      onTap: () => _openCategory(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: _categoryImage(
                    hasImage: hasImage,
                    isNetwork: isNetwork,
                    imagePath: item.image ?? '',
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10,
                  vertical: SizeConfig.size8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      item.name ?? '',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          CustomText(
                            'View Products',
                            fontSize: 11,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryImage({
    required bool hasImage,
    required bool isNetwork,
    required String imagePath,
  }) {
    const double size = 56;
    if (!hasImage) {
      return LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        height: size,
        width: size,
        boxFix: BoxFit.contain,
      );
    }
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox(
          width: size,
          height: size,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) =>
            Icon(Icons.broken_image, size: size, color: Colors.grey),
      );
    }
    return LocalAssets(
      imagePath: imagePath,
      height: size,
      width: size,
      boxFix: BoxFit.contain,
    );
  }

  Future<void> _openCategory(GroceryNestedCategoryModel item) async {
    if ((item.name ?? '').isEmpty) {
      commonSnackBar(message: 'Invalid category');
      return;
    }
    await Get.to(() => MyFoodProductScreen(foodMenu: item));
    if (_foodController.foodDataNeedsRefresh) {
      _foodController.foodDataNeedsRefresh = false;
      _foodController.fetchHomeData(businessId: businessId);
    }
  }

  // ─────────────────────────────────────────────
  // POST TAB — embeds FeedScreen filtered to current user's posts.
  // ─────────────────────────────────────────────
  List<Widget> _buildPostTab() {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: _createPostCta(),
      ),
      SizedBox(height: SizeConfig.size12),
      FeedScreen(
        key: const ValueKey('food_v2_my_posts'),
        postFilterType: PostType.myPosts,
        id: userId,
        isInParentScroll: true,
        horizontalPaddingChannel: SizeConfig.size12,
      ),
    ];
  }

  Widget _createPostCta() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: CustomText('Create Post',
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _showCreatePostDialog() async {
    final isBusiness = isBusinessUser();
    final entries = <_PostMenuEntry>[
      _PostMenuEntry(
        type: PostCreationMenu.message,
        label: AppStrings.lekha.tr,
        iconAsset: AppIconAssets.message_post,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.symbol,
        label: AppStrings.symbol.tr,
        iconAsset: 'assets/icons/add_symbol_color.png',
      ),
      _PostMenuEntry(
        type: PostCreationMenu.poll,
        label: AppStrings.poll.tr,
        iconAsset: AppIconAssets.qa_ask_questionOutlinedIcon,
      ),
      if (isBusiness)
        _PostMenuEntry(
          type: PostCreationMenu.jobPost,
          label: AppStrings.jobPost.tr,
          iconAsset: AppIconAssets.uilSuitcaseOutlinedIcon,
        ),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText('Create Post',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor),
              SizedBox(height: SizeConfig.size12),
              for (var i = 0; i < entries.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handlePostMenu(entries[i].type);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size10,
                        horizontal: SizeConfig.size4),
                    child: Row(
                      children: [
                        LocalAssets(
                            imagePath: entries[i].iconAsset,
                            height: 24,
                            width: 24),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(entries[i].label,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handlePostMenu(PostCreationMenu type) {
    switch (type) {
      case PostCreationMenu.message:
      case PostCreationMenu.poll:
        postVia(context, type);
        break;
      case PostCreationMenu.jobPost:
        Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(), arguments: {
          'isEditMode': false,
          'jobId': '',
          'createJobVia': 'business',
        });
        break;
      case PostCreationMenu.symbol:
        Get.to(() => AddChatSymbolScreen());
        break;
    }
  }

  // ─────────────────────────────────────────────
  // CREATE OFFERS BUTTON (overview tab)
  // ─────────────────────────────────────────────
  Widget _buildCreateOffersButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _onCreateOffer,
          icon: const Icon(Icons.local_offer_outlined,
              size: 18, color: Colors.white),
          label: CustomText('Create Your Offers',
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size8,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _onCreateOffer() {
    commonSnackBar(message: AppStrings.comingSoon);
  }

  Widget _buildComingSoon({required String label}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size40,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty,
                size: 48, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              label,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BACKGROUND
  // ─────────────────────────────────────────────
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        topInset + SizeConfig.size8,
        SizeConfig.size12,
        SizeConfig.size10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E88FF), Color(0xFF0040A0)],
        ),
      ),
      child: Row(
        children: [
          _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
          SizedBox(width: SizeConfig.size8),
          Builder(
            builder: (BuildContext context) {
              return InkWell(
                onTap: () {
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else if (isBusinessUser()) {
                    navigatePushTo(context, BusinessOwnProfileScreen());
                  }
                },
                child: Padding(
                    padding: EdgeInsets.only(left: SizeConfig.size15),
                    child: CachedAvatarWidget(
                        imageUrl: userProfileGlobal,
                        size: SizeConfig.size30,
                        borderRadius: SizeConfig.size15,
                        showProfileOnFullScreen: false)),
              );
            },
          ),
          SizedBox(width: SizeConfig.size8),
          if (!isBusinessUser()) _earnPill(),
          const Spacer(),
          _circleIconButton(
            icon: Icons.notifications_none,
            onTap: _openNotifications,
          ),
          SizedBox(width: SizeConfig.size8),
          _goLivePill(),
        ],
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: Get.width * 0.85,
          height: double.infinity,
          child: Drawer(child: ProfileMenuDrawer()),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: SizeConfig.size36,
        width: SizeConfig.size36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.mainTextColor),
      ),
    );
  }

  Widget _earnPill() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoinStackIcon(size: 20),
          SizedBox(width: SizeConfig.size6),
          CustomText('Earn',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
        ],
      ),
    );
  }

  Widget _goLivePill() {
    return GestureDetector(
      onTap: () => setState(() => _isGoLive = !_isGoLive),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText('Go live',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    _isGoLive ? AppColors.primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: _isGoLive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PROFILE ROW
  // ─────────────────────────────────────────────
  Widget _buildProfileRow(BusinessProfileDetails? profile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Obx(() {
                final logo = _businessController.imagePath?.value ??
                    profile?.logo ??
                    '';
                return Container(
                  height: SizeConfig.size40,
                  width: SizeConfig.size40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _logoFallback(),
                        )
                      : _logoFallback(),
                );
              }),
              Positioned(
                right: -10,
                top: 6,
                child: Container(
                  height: SizeConfig.size30,
                  width: SizeConfig.size30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade600,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: SizeConfig.size20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        profile?.businessName ?? '',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomText('+1',
                          fontSize: 11,
                          color: AppColors.secondaryTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                CustomText(
                  profile?.typeOfBusiness ?? '',
                  fontSize: 12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Obx(() => BusinessVerifyNowButton(
                details:
                    _businessController.businessProfileDetails.value?.data,
              )),
          SizedBox(width: SizeConfig.size10),
          IconButton(
            onPressed: _previewProfileAsVisitor,
            icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.restaurant_menu,
            size: 20, color: AppColors.secondaryTextColor),
      );

  // ─────────────────────────────────────────────
  // TABS CARD (single white card with pills)
  // ─────────────────────────────────────────────
  Widget _buildTabsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == _selectedTab;
              return Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: CustomText(
                      _tabs[i],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.mainTextColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BANNER (cover image)
  // ─────────────────────────────────────────────
  Widget _buildBannerSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Obx(() {
        final cover = _businessController.coverImage?.value ?? '';
        final hasBanner = cover.isNotEmpty;
        final profile =
            _businessController.businessProfileDetails.value?.data;

        return GestureDetector(
          onTap: () => _onEditCover(profile),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.hardEdge,
              child: hasBanner
                  ? _filledBannerContent(cover)
                  : _emptyBannerContent(),
            ),
          ),
        );
      }),
    );
  }

  Widget _emptyBannerContent() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            right: SizeConfig.size12,
            bottom: SizeConfig.size12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined,
                    size: 20, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size6),
                CustomText('Add Your Banner Here',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filledBannerContent(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade100),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
        ),
        Positioned(
          right: SizeConfig.size10,
          bottom: SizeConfig.size10,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                CustomText('Edit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onEditCover(BusinessProfileDetails? profile) async {
    try {
      final newPath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        AppStrings.editCoverPicture,
        cropAspectRatio: CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      final file = File(newPath);
      if (!await file.exists()) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }

      _businessController.coverImage?.value = newPath;
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      final dataImage =
          await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }
      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: profile?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  // ─────────────────────────────────────────────
  // POPULAR DISHES (discount foods, horizontal)
  // ─────────────────────────────────────────────
  Widget _buildPopularDishesSection() {
    return Obx(() {
      final isInitialLoading =
          _foodController.isDiscountProductsLoading.value &&
              _foodController.discountFoodItems.isEmpty;
      final hasItems = _foodController.discountFoodItems.isNotEmpty;
      if (!isInitialLoading && !hasItems) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.size16),
        child: _SectionCard(
          title: AppStrings.foodOfferDishDiscount.tr,
          trailingLabel: AppStrings.viewAll.tr,
          onTrailingTap: () => Get.to(
              () => DiscountFoodProductsScreen(businessId: businessId)),
          child: isInitialLoading
              ? const SizedBox(
                  height: 240,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _buildPopularDishesList(),
        ),
      );
    });
  }

  Widget _buildPopularDishesList() {
    final items = _foodController.discountFoodItems.length >
            _discountPreviewLimit
        ? _foodController.discountFoodItems
            .take(_discountPreviewLimit)
            .toList()
        : _foodController.discountFoodItems.toList();

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
        itemBuilder: (_, i) => _popularDishCard(items[i]),
      ),
    );
  }

  Widget _popularDishCard(CategoryFoodProductData item) {
    final hasVariants = item.variants != null && item.variants!.isNotEmpty;
    final variantCount = item.variants?.length ?? 0;
    final isMultiVariant = variantCount > 1;
    final sellingPrice = hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;
    final discountPercent =
        (mrp != null && sellingPrice != null && mrp > sellingPrice)
            ? (((mrp - sellingPrice) / mrp) * 100).round()
            : 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showFoodProductVariantSheet(context, product: item),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.images?.firstOrNull ?? '',
                    height: 130,
                    width: 170,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      width: 170,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFFFD7845), Color(0xFFFA5568)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: CustomText(
                          '$discountPercent% OFF',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FoodTypeIndicator(
                    isVegetarian:
                        item.dietaryType?.toLowerCase() == AppConstants.veg,
                    size: 8,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    item.name ?? '',
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBadge(rating: '4.5'),
                      const SizedBox(width: 4),
                      Flexible(
                        child: CustomText(
                          '1.2 K Reviews',
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          color: AppColors.secondaryTextColor,
                          fontSize: 11,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CustomText(
                        '${AppConstants.rupeeSymbol}${sellingPrice ?? 0}',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      if (mrp != null &&
                          sellingPrice != null &&
                          mrp >= sellingPrice) ...[
                        const SizedBox(width: 6),
                        CustomText(
                          '${AppConstants.rupeeSymbol}$mrp',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.secondaryTextColor,
                        ),
                      ],
                    ],
                  ),
                  if (variantCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          isMultiVariant
                              ? '+${variantCount - 1} more variant'
                              : '$variantCount variant',
                          fontSize: 10,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUSINESS LIVE PHOTOS (with floating edit FAB)
  // ─────────────────────────────────────────────
  Widget _buildLivePhotosSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SectionCard(
          title: 'Business Live Photos',
          child: GetBuilder<ViewBusinessDetailsController>(
            id: 'livePhotos',
            builder: (_) {
              final photos = _businessController
                      .businessProfileDetails.value?.data?.livePhotos ??
                  <String>[];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (_, index) {
                  final hasPhoto =
                      index < photos.length && photos[index].isNotEmpty;
                  return _LivePhotoSlot(
                    index: index,
                    photoUrl: hasPhoto ? photos[index] : null,
                    label: _slotLabel(index),
                    placeholderImage: _slotPlaceholder(index),
                    allPhotos: photos,
                    controller: _businessController,
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          top: SizeConfig.size60,
          child: Container(
            height: SizeConfig.size40,
            width: SizeConfig.size40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.edit_outlined,
                size: 18, color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }

  String _slotLabel(int index) {
    switch (index) {
      case 0:
        return 'Road Side Image';
      case 1:
        return 'Reception/Counter';
      case 2:
        return 'Interior 1';
      case 3:
      default:
        return 'Interior 2';
    }
  }

  String _slotPlaceholder(int index) {
    switch (index) {
      case 0:
        return AppImageAssets.storefrontExterior;
      case 1:
        return AppImageAssets.billingCounterReceptionArea;
      case 2:
        return AppImageAssets.interiorInsideShop;
      case 3:
      default:
        return AppImageAssets.productServiceDisplay;
    }
  }

  // ─────────────────────────────────────────────
  // GALLERY (food gallery WhatsApp-style preview)
  // ─────────────────────────────────────────────
  Widget _buildGallerySection() {
    return Obx(() {
      final data = _foodController.restaurantData.value;
      final all = <String>[];
      for (final entry in data?.gallery ?? const <FoodGallery>[]) {
        all.addAll(entry.imageUrls ?? const []);
      }
      return _SectionCard(
        title: 'Gallery',
        trailingLabel: 'Add Photo',
        onTrailingTap: () => Get.to(() => FoodServicePhotosPhotoScreen()),
        child: all.isEmpty ? _galleryEmptyGuide() : _galleryGrid(all),
      );
    });
  }

  Widget _galleryEmptyGuide() {
    return GestureDetector(
      onTap: () => Get.to(() => FoodServicePhotosPhotoScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.asset(
                  'assets/images/other_gallery.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 32),
                    SizedBox(height: SizeConfig.size6),
                    CustomText(AppStrings.foodAddPhotoLabel.tr,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _galleryGrid(List<String> images) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double gap = 4;

    void open(int i) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: i,
          ),
        );

    Widget tile(int i, {bool overlay = false}) => GestureDetector(
          onTap: () => open(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  display[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                if (overlay && extra > 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

    if (display.length == 1) {
      return AspectRatio(aspectRatio: 1, child: tile(0));
    }

    if (display.length == 2) {
      return AspectRatio(
        aspectRatio: 2,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(child: tile(1)),
        ]),
      );
    }

    if (display.length == 3) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: tile(1)),
              const SizedBox(height: gap),
              Expanded(child: tile(2)),
            ]),
          ),
        ]),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: tile(0)),
              const SizedBox(width: gap),
              Expanded(child: tile(1)),
            ]),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(children: [
              Expanded(child: tile(2)),
              const SizedBox(width: gap),
              Expanded(child: tile(3, overlay: extra > 0)),
            ]),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CONTACT US
  // ─────────────────────────────────────────────
  Widget _buildContactSection() {
    return Obx(() {
      final profile =
          _businessController.businessProfileDetails.value?.data;
      if (profile == null) return const SizedBox.shrink();

      final loc = profile.businessLocation;
      final lat = loc?.lat;
      final lon = loc?.lon;
      final phone = profile.businessNumber?.officeMobNo?.number;
      final owner = profile.ownerDetails?.firstOrNull;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText('Contact Us',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor),
            SizedBox(height: SizeConfig.size12),
            Container(
              padding: EdgeInsets.all(SizeConfig.size16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((profile.logo ?? '').isNotEmpty)
                    Container(
                      width: SizeConfig.size60,
                      height: SizeConfig.size60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                        image: DecorationImage(
                          image: NetworkImage(profile.logo!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: SizeConfig.size10),
                  CustomText(profile.businessName ?? '',
                      fontSize: 15, fontWeight: FontWeight.w700),
                  if ((profile.businessDescription ?? '').isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      profile.businessDescription!,
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  Divider(height: SizeConfig.size20),
                  if ((profile.websiteUrl ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.website_click,
                        profile.websiteUrl!, AppColors.primaryColor),
                  if ((owner?.name ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.principal, owner!.name!,
                        Colors.grey[700]!),
                  if ((owner?.email ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.email, owner!.email!,
                        AppColors.secondaryTextColor),
                  if ((phone ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.phone_outline, phone!,
                        AppColors.secondaryTextColor),
                  if ((profile.address ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.location_new,
                        profile.address!, Colors.grey[700]!),
                ],
              ),
            ),
            if (lat != null && lon != null) ...[
              SizedBox(height: SizeConfig.size12),
              BusinessLocationWidget(
                locationText: '',
                latitude: lat,
                longitude: lon,
                businessName: profile.businessName ?? '',
                padding: 0,
                isTitleShow: false,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalAssets(
              imagePath: icon, imgColor: iconColor, height: 16, width: 16),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(label,
                fontSize: 12,
                color: AppColors.mainTextColor,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Discover-style profile preview so the owner can preview their food
  /// profile the way customers discover it.
  void _previewProfileAsVisitor() {
    final profile =
        _businessController.businessProfileDetails.value?.data;
    final coverFromCtrl = _businessController.coverImage?.value ?? '';
    final logoFromCtrl = _businessController.imagePath?.value ?? '';

    final galleryPhotos = <String>[];
    final restaurantData = _foodController.restaurantData.value;
    for (final entry in restaurantData?.gallery ?? const <FoodGallery>[]) {
      galleryPhotos.addAll(entry.imageUrls ?? const []);
    }

    final service = ServiceData()
      ..id = profile?.id ?? businessId
      ..name = profile?.businessName
      ..profileImage = (coverFromCtrl.isNotEmpty
          ? coverFromCtrl
          : (logoFromCtrl.isNotEmpty
              ? logoFromCtrl
              : (profile?.logo ?? '')))
      ..bio = profile?.businessDescription
      ..address = profile?.address
      ..rating = profile?.avg_rating
      ..reviewCount = profile?.total_ratings?.toInt() ?? 0
      ..category = profile?.typeOfBusiness
      ..serviceMedia = ServiceMedia(photos: galleryPhotos);

    Get.to(() => SelfProfessionScreenPreview(
          service: service,
          timingMap: const {},
          priceDisplay: '',
          priceBadgeText: '',
          priceBadgeColor: AppColors.primaryColor,
          isSelfPreview: true,
        ));
  }
}

class _PostMenuEntry {
  final PostCreationMenu type;
  final String label;
  final String iconAsset;

  const _PostMenuEntry({
    required this.type,
    required this.label,
    required this.iconAsset,
  });
}

// ─────────────────────────────────────────────
// SHARED SECTION CARD WRAPPER
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: CustomText(title,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (trailingLabel != null)
                  GestureDetector(
                    onTap: onTrailingTap,
                    child: CustomText(trailingLabel!,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor),
                  ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            child,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LIVE PHOTO SLOT
// ─────────────────────────────────────────────
class _LivePhotoSlot extends StatefulWidget {
  final int index;
  final String? photoUrl;
  final String label;
  final String placeholderImage;
  final List<String> allPhotos;
  final ViewBusinessDetailsController controller;

  const _LivePhotoSlot({
    required this.index,
    required this.photoUrl,
    required this.label,
    required this.placeholderImage,
    required this.allPhotos,
    required this.controller,
  });

  @override
  State<_LivePhotoSlot> createState() => _LivePhotoSlotState();
}

class _LivePhotoSlotState extends State<_LivePhotoSlot> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl != null;

    return GestureDetector(
      onTap: _isLoading ? null : _onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: widget.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => _placeholderError(),
                    )
                  : _blurredPlaceholder(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: CustomText(
                widget.label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (!hasPhoto && !_isLoading)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: LocalAssets(
                    imagePath: AppIconAssets.profile_camera_pic,
                    height: 18,
                    width: 18,
                    imgColor: Colors.white,
                  ),
                ),
              ),
            ),
          if (hasPhoto && !_isLoading)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: _onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onTap() async {
    final hasPhoto = widget.photoUrl != null;
    if (hasPhoto) {
      navigatePushTo(
        context,
        ImageViewScreen(
          appBarTitle: AppStrings.imageViewer,
          subTitle: '',
          imageUrls: widget.allPhotos,
          initialIndex: widget.index,
        ),
      );
      return;
    }
    final imgStr = await SelectProfilePictureDialog.pickFromCamera(
      context,
      cropAspectRatio: CropAspectRatio(width: 1, height: 1),
    );
    if (imgStr == null || imgStr.isEmpty) return;
    if (!await File(imgStr).exists()) {
      commonSnackBar(message: AppStrings.imageProcessingFailed);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.controller.saveBusinessImages(imgStr, widget.controller);
      widget.controller.update(['livePhotos']);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDelete() async {
    if (widget.photoUrl == null) return;
    setState(() => _isLoading = true);
    try {
      final data = {ApiKeys.image_url: widget.photoUrl};
      await widget.controller.deleteLiveStoreImage(data);
      widget.controller.businessProfileDetails.value?.data?.livePhotos
          ?.removeAt(widget.index);
      widget.controller.update(['livePhotos']);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _blurredPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.placeholderImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

/// Stacked-coin glyph used by the "Earn" pill in the gradient header — three
/// overlapping golden discs with a ₹ on the front coin to match the header
/// reference image.
class _CoinStackIcon extends StatelessWidget {
  final double size;
  const _CoinStackIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    final coinDiameter = size * 0.78;
    return SizedBox(
      width: size + 4,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: _coin(coinDiameter, const Color(0xFFC9892B)),
          ),
          Positioned(
            left: 3,
            bottom: 4,
            child: _coin(coinDiameter, const Color(0xFFE0A53A)),
          ),
          Positioned(
            left: 6,
            bottom: 8,
            child: _coin(
              coinDiameter,
              const Color(0xFFF4C13B),
              child: const Text(
                '₹',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7A4A0A),
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coin(double diameter, Color color, {Widget? child}) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 0.5),
      ),
      child: child,
    );
  }
}
