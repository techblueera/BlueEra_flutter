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
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_verify_now_button.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_screen_preview.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/view/all_top_selling_grocery_products_screen.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_statistics_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// Grocery Home screen (v2) — mirrors the medical home v2 layout so the
/// business owner sees a consistent, modern profile across me-section
/// services. Reuses [ViewBusinessDetailsController] for the profile data
/// and [GroceryController] for top-selling products & categories.
class GroceryHomeScreenV2 extends StatefulWidget {
  final String businessId;

  const GroceryHomeScreenV2({super.key, required this.businessId});

  @override
  State<GroceryHomeScreenV2> createState() => _GroceryHomeScreenV2State();
}

class _GroceryHomeScreenV2State extends State<GroceryHomeScreenV2> {
  bool _isGoLive = false;
  int _selectedTab = 1;

  late final GroceryController _groceryController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  static const _tabs = [
    'Order',
    'Overview',
    'Products',
    'Post',
    'Statics',
  ];

  @override
  void initState() {
    super.initState();
    _groceryController = getOrPut(() => GroceryController());
    _groceryController.fetchAllGroceryData(widget.businessId, otherStore: false);
  }

  Future<void> _refresh() async {
    await _groceryController.fetchAllGroceryData(widget.businessId,
        otherStore: false);
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
                _buildProfileRow(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB CONTENT — switches body by _selectedTab
  //   0 Order, 1 Overview, 2 Products, 3 Post, 4 Statics
  // ─────────────────────────────────────────────
  List<Widget> _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        return _buildOverviewSlivers();
      case 2:
        return _buildProductsTab();
      case 3:
        return _buildPostTab();
      case 0:
      case 4:
        return [MedicalStatisticsScreen(businessId: widget.businessId)];
      default:
        return [_buildComingSoon()];
    }
  }

  List<Widget> _buildOverviewSlivers() {
    return [
      _buildBannerSection(),
      SizedBox(height: SizeConfig.size12),
      _buildCreateOffersButton(),
      SizedBox(height: SizeConfig.size16),
      _buildTopSellingSection(),
      SizedBox(height: SizeConfig.size16),
      _buildLivePhotosSection(),
      SizedBox(height: SizeConfig.size16),
      _buildContactSection(),
      SizedBox(height: SizeConfig.size16),
      _buildQrCodeSection(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // ─────────────────────────────────────────────
  // QR CODE — share/download the business profile
  // ─────────────────────────────────────────────
  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: BusinessQrCodeWidget(data: details),
      );
    });
  }

  // ─────────────────────────────────────────────
  // PRODUCTS TAB — categories grid (with inventory)
  // ─────────────────────────────────────────────
  List<Widget> _buildProductsTab() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              AppStrings.groceryViewCategory.tr,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            ElevatedButton.icon(
              onPressed: _onAddMoreProducts,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: CustomText(
                AppStrings.addGrocery.tr,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: SizeConfig.size10),
      _buildCategoriesInline(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  Future<void> _onAddMoreProducts() async {
    await Get.toNamed(
      RouteHelper.getGrocerySuperCategoryScreenRoute(),
      arguments: {ApiKeys.argBulkUpload: true},
    );
    if (_groceryController.groceryDataNeedsRefresh) {
      _groceryController.groceryDataNeedsRefresh = false;
      _groceryController.fetchAllGroceryData(widget.businessId,
          otherStore: false);
    }
  }

  Widget _buildCategoriesInline() {
    return Obx(() {
      if (_groceryController.fetchMyGroceryCategoryResponse.value.status ==
          Status.INITIAL) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size30),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final list = List<GroceryCategoryWithInventoryModel>.from(
          _groceryController.groceryCategoryList);

      if (list.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
          child: Center(
            child: EmptyStateWidget(
              message: AppStrings.groceryViewNoProductsYetCreate.tr,
              actionText: AppStrings.addGrocery.tr,
              actionCallback: _onAddMoreProducts,
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: SizeConfig.size12,
          mainAxisSpacing: SizeConfig.size12,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (_, i) => _categoryCard(list[i], list),
      );
    });
  }

  Widget _categoryCard(
    GroceryCategoryWithInventoryModel item,
    List<GroceryCategoryWithInventoryModel> all,
  ) {
    final hasImage = item.image != null && item.image!.isNotEmpty;
    final isNetwork = hasImage && isNetworkImage(item.image!);
    final isSvg = hasImage && item.image!.toLowerCase().endsWith('.svg');

    return InkWell(
      onTap: () => Get.toNamed(
        RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
        arguments: {
          ApiKeys.userId: widget.businessId,
          ApiKeys.argGroceryCategoryWithInventory: all,
          ApiKeys.argArrGroceryCatKey: item.key,
          ApiKeys.argArrGroceryCatName: item.name,
        },
      ),
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
                    isSvg: isSvg,
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
                            AppStrings.groceryViewUpdateInventory.tr,
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
    required bool isSvg,
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
    if (isNetwork && isSvg) {
      return SvgPicture.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
        boxFix: BoxFit.contain);
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
        key: const ValueKey('grocery_v2_my_posts'),
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

  /// Dialog with the same post-creation entries as the global app bar:
  /// Lekha, Symbol, Poll, and Job (business only).
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
              CustomText(
                'Create Post',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
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
                horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _onCreateOffer() {
    commonSnackBar(message: AppStrings.comingSoon);
  }

  Widget _buildComingSoon() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty,
                size: 48, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size10),
            CustomText(AppStrings.comingSoon,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor),
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
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FB)),
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
          _nearbyRidersPill(),
          const Spacer(),
          _circleIconButton(
              icon: Icons.notifications_none, onTap: _openNotifications),
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

  Widget _circleIconButton(
      {required IconData icon, required VoidCallback onTap}) {
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

  /// Grocery-specific quick action — replaces medical's "Earn" pill so
  /// the merchant can hop straight to nearby riders for self-pickup
  /// or delivery dispatch.
  Widget _nearbyRidersPill() {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getNearByRidersScreenRoute()),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.riderIcon,
              imgColor: AppColors.mainTextColor,
              height: 18,
              width: 18,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText('Nearby Riders',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor),
          ],
        ),
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
                alignment:
                    _isGoLive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
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
  Widget _buildProfileRow() {
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
                final details =
                    _businessController.businessProfileDetails.value?.data;
                final logo = _businessController.imagePath?.value ??
                    details?.logo ??
                    '';
                return Container(
                  height: SizeConfig.size40,
                  width: SizeConfig.size40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
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
            child: Obx(() {
              final details =
                  _businessController.businessProfileDetails.value?.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(
                          details?.businessName ?? '',
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
                    details?.typeOfBusiness ?? '',
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),
          Obx(() => BusinessVerifyNowButton(
                details: _businessController.businessProfileDetails.value?.data,
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
        child: Icon(Icons.storefront,
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
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size16,
                        vertical: SizeConfig.size6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryColor : Colors.white,
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
                      color: selected ? Colors.white : AppColors.mainTextColor,
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

        return GestureDetector(
          onTap: _onEditCover,
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
                    color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
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

  Future<void> _onEditCover() async {
    try {
      final newPath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        AppStrings.editCoverPicture,
        cropAspectRatio: CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      _businessController.coverImage?.value = newPath;
      final file = File(newPath);
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
      final details = _businessController.businessProfileDetails.value?.data;
      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: details?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  // ─────────────────────────────────────────────
  // TOP-SELLING PRODUCTS (overview)
  // ─────────────────────────────────────────────
  Widget _buildTopSellingSection() {
    return Obx(() {
      final isLoading =
          _groceryController.fetchGroceryBusinessProductsResponse.value.status ==
              Status.INITIAL;
      final products = _groceryController.groceryBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      final cardWidth = MediaQuery.of(context).size.width * 0.55;
      return _SectionCard(
        title: AppStrings.groceryViewTopSellingProduct.tr,
        trailingLabel: AppStrings.groceryViewViewAll.tr,
        onTrailingTap: () => Get.to(() => AllTopSellingGroceryProductsScreen(
              userId: widget.businessId,
              otherStore: false,
            )),
        child: SizedBox(
          height: cardWidth * 1.40,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                  itemCount: products.length >
                          GroceryController.businessProductsPreviewLimit
                      ? GroceryController.businessProductsPreviewLimit
                      : products.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: SizeConfig.size10),
                  itemBuilder: (_, i) => _productCard(products[i], cardWidth),
                ),
        ),
      );
    });
  }

  Widget _productCard(BusinessProductData item, double width) {
    final productName =
        item.product?.name ?? item.productVariant?.variantName ?? '';
    final description = item.product?.description ?? '';
    final imageUrl = item.product?.images?.firstOrNull?.url;
    final mrp = item.minMrp ?? item.batches?.firstOrNull?.mrp;
    final sellingPrice =
        item.minSellingPrice ?? item.batches?.firstOrNull?.sellingPrice;
    final discount = item.avgDiscount;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_outlined,
                          color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child:
                        const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(productName,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (description.isNotEmpty)
                    CustomText(description,
                        fontSize: 10,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  SizedBox(height: SizeConfig.size6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (item.category?.name?.isNotEmpty ?? false)
                          _spec(item.category!.name!),
                        if (item.productVariant?.variantName?.isNotEmpty ??
                            false) ...[
                          SizedBox(width: SizeConfig.size4),
                          _spec(item.productVariant!.variantName!),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _priceCol('MRP', mrp),
                        SizedBox(width: SizeConfig.size8),
                        _priceCol('Selling', sellingPrice),
                        if (discount != null && discount > 0) ...[
                          SizedBox(width: SizeConfig.size6),
                          _discountChip(discount),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spec(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(text, fontSize: 9, color: AppColors.secondaryTextColor),
    );
  }

  Widget _priceCol(String label, num? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 9, color: AppColors.secondaryTextColor),
        CustomText('${AppConstants.rupeeSymbol}${value ?? '-'}',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
      ],
    );
  }

  Widget _discountChip(num discount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText('${discount.toStringAsFixed(0)}% OFF',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor),
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
                  [];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
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
        return 'Storefront / Road Side';
      case 1:
        return 'Billing Counter';
      case 2:
        return 'Aisles / Inside Shop';
      case 3:
      default:
        return 'Product Display';
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
  // CONTACT US
  // ─────────────────────────────────────────────
  Widget _buildContactSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();

      final loc = details.businessLocation;
      final mobile = details.businessNumber?.officeMobNo?.number;
      final phone = (mobile != null && mobile.isNotEmpty)
          ? '${details.businessNumber?.officeMobNo?.pre ?? ''} $mobile'.trim()
          : null;
      final owner = details.ownerDetails?.firstOrNull;

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
                  if (details.logo != null && details.logo!.isNotEmpty)
                    Container(
                      width: SizeConfig.size60,
                      height: SizeConfig.size60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                        image: DecorationImage(
                          image: NetworkImage(details.logo!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: SizeConfig.size10),
                  CustomText(details.businessName ?? '',
                      fontSize: 15, fontWeight: FontWeight.w700),
                  if (details.businessDescription?.isNotEmpty ?? false) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(details.businessDescription!,
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                  Divider(height: SizeConfig.size20),
                  if (details.websiteUrl?.isNotEmpty ?? false)
                    _contactItem(AppIconAssets.website_click,
                        details.websiteUrl!, AppColors.primaryColor),
                  if (owner?.name?.isNotEmpty ?? false)
                    _contactItem(AppIconAssets.principal, owner!.name!,
                        Colors.grey[700]!),
                  if (owner?.email?.isNotEmpty ?? false)
                    _contactItem(AppIconAssets.email, owner!.email!,
                        AppColors.secondaryTextColor),
                  if (phone != null)
                    _contactItem(AppIconAssets.phone_outline, phone,
                        AppColors.secondaryTextColor),
                  if (details.address?.isNotEmpty ?? false)
                    _contactItem(AppIconAssets.location_new, details.address!,
                        Colors.grey[700]!),
                ],
              ),
            ),
            if (loc?.lat != null && loc?.lon != null) ...[
              SizedBox(height: SizeConfig.size12),
              BusinessLocationWidget(
                locationText: "",
                latitude: loc!.lat!,
                longitude: loc.lon!,
                businessName: details.businessName ?? "",
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

  /// Opens the Discover-style profile preview so the owner can see the
  /// public profile the way other users discover it on the Discover screen.
  void _previewProfileAsVisitor() {
    final details = _businessController.businessProfileDetails.value?.data;
    final coverFromCtrl = _businessController.coverImage?.value ?? '';
    final logoFromCtrl = _businessController.imagePath?.value ?? '';

    final livePhotos = details?.livePhotos ?? const <String>[];

    final service = ServiceData()
      ..id = details?.id ?? widget.businessId
      ..name = details?.businessName
      ..profileImage = (coverFromCtrl.isNotEmpty
          ? coverFromCtrl
          : (logoFromCtrl.isNotEmpty ? logoFromCtrl : (details?.logo ?? '')))
      ..bio = details?.businessDescription
      ..address = details?.address
      ..category = details?.typeOfBusiness
      ..serviceMedia = ServiceMedia(photos: List<String>.from(livePhotos));

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
                CustomText(title,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor),
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
      onTap: _isLoading
          ? null
          : () async {
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
              } else {
                final imgStr = await SelectProfilePictureDialog.pickFromCamera(
                  context,
                  cropAspectRatio: CropAspectRatio(width: 1, height: 1),
                );
                if (imgStr != null) {
                  setState(() => _isLoading = true);
                  await widget.controller
                      .saveBusinessImages(imgStr, widget.controller);
                  widget.controller.update(['livePhotos']);
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                onTap: () async {
                  setState(() => _isLoading = true);
                  final data = {ApiKeys.image_url: widget.photoUrl};
                  await widget.controller.deleteLiveStoreImage(data);
                  widget
                      .controller.businessProfileDetails.value?.data?.livePhotos
                      ?.removeAt(widget.index);
                  widget.controller.update(['livePhotos']);
                  if (mounted) setState(() => _isLoading = false);
                },
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

