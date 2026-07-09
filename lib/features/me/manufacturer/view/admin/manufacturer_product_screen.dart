import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_admin_all_top_selling_products_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_product_home_screen.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_admin_product_card.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_orders_tab_body.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/gradient_add_button.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_shop_availability_screen.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/contribution/view/contribution_screen_v2.dart';
import 'package:get/get.dart';

class ManufacturerProductScreen extends StatefulWidget {

  const ManufacturerProductScreen({
    super.key,
  });

  @override
  State<ManufacturerProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ManufacturerProductScreen>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  TabController? _tabController;
  int _selectedTab = 0; // land on the first tab (Order) on open
  bool _isLoading = true;
  bool _isGoLive = false;

  late final List<String> _tabs;
  late final List<Widget> _tabViews;

  final inventoryController = getOrPut(() => ManufacturerInventoryController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Hydrate the order chat list so the Order tab's incoming-orders
    // list has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Order tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  void _initializeData() {
    // Tabs mirror the grocery v2 home screen exactly so the merchant
    // sees a consistent layout across me-section services.
    _tabs = const ['Order', 'Overview', 'Products', 'Post', 'Statics'];

    _tabViews = [
      ManufacturerOrdersTabBody(
          onAddProducts: () => _tabController?.animateTo(2)),
      const ManufacturerProductHomeScreen(),
      _ProductsTabBody(onAddProduct: _onAddProduct),
      _PostTabBody(),
      ProfileStatisticsScreen(userId: userId),
    ];

    _tabController = TabController(
      length: _tabViews.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_onTabChanged);
    registerMeTabBackHandler(_tabController!);
    setState(() => _isLoading = false);
  }

  void _onTabChanged() {
    final c = _tabController;
    if (c == null) return;
    // No `indexIsChanging` guard here: on tap, `animateTo` notifies
    // listeners synchronously with `indexIsChanging == true`, and we
    // need to react at the START of the animation (not the end) so
    // the lazy product fetch fires for tap-driven changes too.
    if (_selectedTab != c.index) {
      setState(() => _selectedTab = c.index);
      // Fetch product data lazily â€” only when the merchant actually
      // opens the Products tab, not on every Me-tab landing.
      if (c.index == 2) {
        inventoryController.fetchAllProductData();
      }
    }
  }

  /// Pull-to-refresh dispatcher â€” each tab owns a different data set,
  /// so the refresh action fires only the API(s) backing the currently
  /// visible tab. Avoids hammering unrelated endpoints on every pull.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        // Orders: re-pull the order chat list + recharge status.
        _chatViewController.emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.business_Chat_Type},
        );
        if (Get.isRegistered<ContributionController>()) {
          await Get.find<ContributionController>().fetchCurrent();
        }
        break;
      case 1:
        // Overview: re-pull the business profile (drives joined date,
        // identity card, cover banner, contact-map, QR, share banner).
        await viewBusinessDetailsController.viewBusinessProfile();
        break;
      case 2:
        // Products: re-pull catalog + categories.
        inventoryController.fetchAllProductData();
        break;
      case 3:
        // Post: re-pull the merchant's own posts feed.
        if (Get.isRegistered<FeedController>()) {
          await Get.find<FeedController>().getFeed(refresh: true);
        }
        break;
      case 4:
        // Statics: ProfileStatisticsScreen manages its own state and
        // doesn't expose an external refresh hook â€” no-op for now.
        break;
    }
  }

  @override
  void dispose() {
    if (_tabController != null) {
      _tabController!.removeListener(_onTabChanged);
    }
    _tabController?.dispose();
    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController!,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: topBarHeight,
              tabViews: [
                _tabScroll([
                  ManufacturerOrdersTabBody(
                      onAddProducts: () => _tabController?.animateTo(2)),
                ]),
                _tabScroll(const [ManufacturerProductHomeScreen()]),
                _tabScroll([_ProductsTabBody(onAddProduct: _onAddProduct)]),
                _tabScroll([_PostTabBody()]),
                ProfileStatisticsScreen(userId: userId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB CONTENT â€” rebuilt per tab. Each branch returns the body
  // widgets the inner scroll content should host. Mirrors grocery's
  // _buildTabContent pattern so the outer CustomScrollView controls
  // the scroll for every tab.
  /// Wraps a tab's content list in a refreshable, scrollable body for the
  /// [TabBarView]. The per-tab bodies are content-only (designed for a parent
  /// scroll), so SingleChildScrollView + Column reproduces the previous
  /// CustomScrollView layout. Statistics is passed directly (owns its scroll).
  Widget _tabScroll(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _onRefreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20,
          top: SizeConfig.size10,
          bottom: kBottomNavigationBarHeight + 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // TOP BAR â€” glass-morphic chrome mirroring the grocery v2 home:
  // backdrop blur (50), translucent white fill (#FFFFFF33), white
  // border, and a soft outer #00112042 / blur-16 shadow that paints
  // outside the ClipRect via BlurStyle.outer so the glass interior
  // stays clean.
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    final isGuest = isGuestUser();

    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              topInset + SizeConfig.size8,
              SizeConfig.size12,
              SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              border: Border.all(
                color: Colors.white,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
                SizedBox(width: SizeConfig.size6),
                // Pills wrapped in Flexible so their inner text can
                // ellipsize instead of pushing the row past its width.
                Flexible(child: _nearbyRidersPill()),
                SizedBox(width: SizeConfig.size6),
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                if (!isGuest) ...[
                  _circleIconButton(
                    icon: Icons.notifications_none,
                    onTap: _openNotifications,
                  ),
                  SizedBox(width: SizeConfig.size6),
                ],
                _goLivePill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  /// Same flow that was previously triggered by the top-bar "Add ManufacturerProduct"
  /// pill â€” now reused by the "Add ManufacturerProduct" tab pill.
  Future<void> _onAddProduct() async {
    if (businessId.isEmpty) return;
    await Get.toNamed(
      RouteHelper.getManufacturerAddProductViaAiStep1Route(),
      arguments: {
        ApiKeys.id: businessId,
        ApiKeys.providerType: ProviderType.business,
      },
    );
    if (inventoryController.productDataNeedsRefresh) {
      inventoryController.productDataNeedsRefresh = false;
      // After a publish the merchant wants to see the new item in the
      // catalog, not whatever tab they launched the add flow from. Jump
      // to the Products tab before kicking off the refresh.
      _tabController?.animateTo(2);
      inventoryController.fetchAllProductData();
    }
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: CircleBorder()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: SizeConfig.size36,
            width: SizeConfig.size36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFC9CDD5),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
          ),
        ),
      ),
    );
  }

  /// Quick-action pill â€” jumps to the nearby-riders screen so the
  /// merchant can dispatch self-pickup or delivery. Glass white
  /// surface + #C9CDD5 outline matching the grocery v2 pill.
  Widget _nearbyRidersPill() {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getNearByRidersScreenRoute()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFC9CDD5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.riderIcon,
                  imgColor: AppColors.secondaryTextColor,
                  height: 18,
                  width: 18,
                ),
                SizedBox(width: SizeConfig.size6),
                Flexible(
                  child: CustomText(
                    'Nearby Riders',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Drive the Go-Live toggle. Turning ON opens the shop-availability
  /// (open-timer) form directly — same as the grocery v2 home. The form
  /// persists the hours and goes live via the backend, popping back `true`
  /// on success. Turning OFF just flips the local toggle.
  Future<void> handleGoLiveTap() async {
    if (_isGoLive) {
      setState(() => _isGoLive = false);
      return;
    }

    // Security-deposit go-live gate — sourced from the business profile's
    // `securityDeposit` (GET business profile). Block only when the backend
    // explicitly reports `required && !paid`; fail-open otherwise. See
    // docs/backend/BUSINESS_GO_LIVE_BACKEND_INTEGRATION.md.
    if (!viewBusinessDetailsController.canGoLive) {
      // Tell the merchant why go-live is blocked, then route them to the
      // security-deposit flow to complete payment — go-live stays blocked
      // until it's paid.
      commonSnackBar(
        message:
            'Your payment is incomplete. Please complete the security deposit to go live and receive service enquiries.',
      );
      Get.to(() => const ContributionScreenV2());
      return;
    }

    final result = await Get.to(() => const GroceryShopAvailabilityScreen());
    if (result == true && mounted) {
      setState(() => _isGoLive = true);
    }
  }

  /// Go-live toggle pill. Off-state: white track + grey thumb.
  /// On-state: brand-blue track + white thumb. Same chip language
  /// the grocery v2 top bar uses.
  Widget _goLivePill() {
    return GoLivePill(
      value: _isGoLive,
      onTap: handleGoLiveTap,
      showShadow: false,
    );
  }

}

// POST TAB â€” embeds FeedScreen filtered to the current user's posts.
class _PostTabBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return FeedScreen(
      key: const ValueKey('inventory_v2_my_posts'),
      postFilterType: PostType.myPosts,
      id: userId,
      isInParentScroll: true,
      horizontalPaddingChannel: SizeConfig.size12,
    );
  }
}

// PRODUCTS TAB â€” surfaces the merchant's top-selling preview and the
// category-with-inventory grid. The Overview tab no longer carries
// these sections; this dedicated lane makes catalog management the
// primary action of the Products tab.
class _ProductsTabBody extends StatefulWidget {
  final VoidCallback onAddProduct;

  const _ProductsTabBody({required this.onAddProduct});

  @override
  State<_ProductsTabBody> createState() => _ProductsTabBodyState();
}

class _ProductsTabBodyState extends State<_ProductsTabBody> {
  final controller = getOrPut(() => ManufacturerInventoryController());

  @override
  Widget build(BuildContext context) {
    // Content-only â€” outer CustomScrollView in InventoryScreen owns
    // the scroll + RefreshIndicator. This widget just lays out its
    // sections in a Column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientAddButton(
          label: AppStrings.addProduct.tr,
          onTap: widget.onAddProduct,
          margin: EdgeInsets.only(
              top: SizeConfig.size10, right: SizeConfig.size12),
        ),
        SizedBox(height: SizeConfig.size12),
        // --- Top Selling Products ---
        Obx(() {
          if (controller.ownDraftAndPublicProductResponse.value.status ==
              Status.INITIAL) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: buildHorizontalListSkeleton(),
            );
          }
          return controller.allProducts.isNotEmpty
              ? _topSellingProduct()
              : const SizedBox.shrink();
        }),

        SizedBox(height: SizeConfig.size12),

        // --- Section header + category cards wrapped in one white
        // shell — mirrors the grocery v2 home's category container.
        Container(
          margin: EdgeInsets.only(right: SizeConfig.size12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section header — vertical brand-bar + 2-line title +
              // refined "Add ManufacturerProduct" chip CTA.
              _productsSectionHeader(),
              SizedBox(height: SizeConfig.size16),

              // --- Category — two-tone storefront cards.
              Obx(() {
                if (controller.fetchProductCategoryResponse.value.status ==
                    Status.INITIAL) {
                  return buildCategoryGridSkeleton();
                }
                return _categoryWithInventoryGrid();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productsSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Our Products',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                'Tap a category to manage inventory',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _addProductCta(),
      ],
    );
  }

  // Refined CTA chip â€” solid primary circular `+` badge anchors the
  // outlined chip. Same chip language used in food's products tab.
  Widget _addProductCta() {
    return GestureDetector(
      onTap: widget.onAddProduct,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          // boxShadow: const [
          //   BoxShadow(
          //     color: Color(0x42001120),
          //     blurRadius: 10,
          //     offset: Offset(0, 2),
          //   ),
          // ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              AppStrings.addProduct.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Editorial "best-seller chart" shelf â€” vertical-bar header + chip
  // CTA up top, horizontal scroller of ranked tiles below. Card uses
  // a brand-tinted hero, orangeâ†’pink discount sticker, "#NN" rank
  // pill, three-row info hierarchy, and a brand-blue gradient ribbon
  // at the bottom edge so the entire shelf reads as one curated row.
  Widget _topSellingProduct() {
    return Container(
      // White-bordered shell wrapping the whole top-selling section
      // (header + cards rail) with a uniform 10-px inner padding —
      // mirrors the grocery v2 home's top-selling container.
      margin: EdgeInsets.only(top: 8, right: SizeConfig.size12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topSellingHeader(),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            height: ManufacturerAdminProductCard.gridCardHeight,
            child: Builder(builder: (context) {
              final previewCount = controller.allProducts.length >
                      ManufacturerInventoryController.ownProductsPreviewLimit
                  ? ManufacturerInventoryController.ownProductsPreviewLimit
                  : controller.allProducts.length;
              return ListView.builder(
                itemCount: previewCount,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size12),
                  child: SizedBox(
                    width: 168,
                    child: ManufacturerAdminProductCard(
                      product: controller.allProducts[index],
                      deleteProductApi: () {},
                      width: 168,
                      isGridShow: true,
                      showAttributes: false,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _topSellingHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Top Selling',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                "Customers' favorites this month",
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _topSellingViewAllChip(),
      ],
    );
  }

  // "View All" chip â€” label on the left, solid primary circular
  // arrow badge on the right. Mirrors the other chip CTAs on the page.
  Widget _topSellingViewAllChip() {
    return GestureDetector(
      onTap: () => Get.to(() => const ManufacturerAdminAllTopSellingProductsScreen()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          // boxShadow: const [
          //   BoxShadow(
          //     color: Color(0x42001120),
          //     blurRadius: 10,
          //     offset: Offset(0, 2),
          //   ),
          // ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'View All',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }


  Widget _categoryWithInventoryGrid() {
    final List<ProductCategoryWithInventoryModel> categoryList =
        controller.productNestedCategoryList;
    if (categoryList.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size20,
        ),
        child: EmptyStateWidget(
          message: "You don't have product yet, Want to create one?",
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: SizeConfig.size4),
          itemCount: categoryList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: SizeConfig.size12,
            mainAxisSpacing: SizeConfig.size12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) =>
              _inventoryCategoryCard(categoryList[i], categoryList),
        );
      },
    );
  }

  // Two-tone storefront card â€” tinted hero zone with the full image
  // (BoxFit.contain so nothing crops), crisp white footer with the
  // name + a small filled brand-blue chevron. Single tap target â€”
  // no separate "View Products" CTA â€” for a clean silhouette.
  Widget _inventoryCategoryCard(
    ProductCategoryWithInventoryModel item,
    List<ProductCategoryWithInventoryModel> categoryList,
  ) {
    final image = (item.image ?? '').toString();
    final hasImage = image.isNotEmpty;
    return InkWell(
      onTap: () => Get.toNamed(
        RouteHelper.getManufacturerNestedCategoryWithInventoryScreenRoute(),
        arguments: {
          ApiKeys.userId: businessId,
          ApiKeys.argProductCategoryWithInventory: categoryList.toList(),
          ApiKeys.argProductCatKey: item.key ?? '',
          ApiKeys.argProductCatName: item.name ?? '',
        },
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.10),
                        AppColors.primaryColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox.expand(
                      child: !hasImage
                          ? LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.contain,
                            )
                          : isNetworkImage(image)
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                )
                              : LocalAssets(
                                  imagePath: image,
                                  boxFix: BoxFit.contain,
                                ),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEF1F4), width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size10,
                  vertical: SizeConfig.size10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomText(
                        item.name ?? '',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

