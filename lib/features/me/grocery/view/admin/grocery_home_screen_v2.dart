import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/controller/profile_statistics_controller.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/view/all_top_selling_grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_shop_availability_screen.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_order_tab.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/gradient_add_button.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Grocery Home screen (v2) â€” mirrors the medical home v2 layout so the
/// business owner sees a consistent, modern profile across me-section
/// services. Reuses [ViewBusinessDetailsController] for the profile data
/// and [GroceryController] for top-selling products & categories.
class GroceryHomeScreenV2 extends StatefulWidget {
  final String businessId;

  const GroceryHomeScreenV2({super.key, required this.businessId});

  @override
  State<GroceryHomeScreenV2> createState() => _GroceryHomeScreenV2State();
}

class _GroceryHomeScreenV2State extends State<GroceryHomeScreenV2>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  /// Local live state backing the Go-Live toggle/pill.
  bool isShopGoLive = false;

  int _selectedTab = 0;
  late final TabController _tabController;

  late final GroceryController _groceryController;
  final _businessController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  // Chat controller drives the Orders list shown under the Order tab.
  // Mirrors `ConnectMainPage._emitChatListForTab(2)` â€” same controller,
  // same event, so the data is shared with the Connect screen and
  // receives socket-driven updates while the user is on this screen.
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  List<String> get _tabs => [
        AppStrings.orderTab.tr,
        AppStrings.overviewTab.tr,
        AppStrings.productsTab.tr,
        AppStrings.postTabLabel.tr,
        AppStrings.staticsTab.tr,
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: _selectedTab,
      vsync: this,
    )..addListener(_handleTabChange);
    registerMeTabBackHandler(_tabController);
    _groceryController = getOrPut(() => GroceryController());
    // Hydrate the order chat list so the Order tab's incoming-orders
    // list has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Order tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // Fire the API(s) backing the tab the screen lands on (Overview by
    // default). Switching tabs later will fire other tabs' APIs lazily
    // via [_onTabTapped] â€” mirrors product_screen's per-tab discipline.
    _fetchForTab(_selectedTab);
  }

  /// Per-tab API dispatcher. Each tab owns a different data set, so we
  /// only fire the calls backing the visible tab when the user lands on
  /// it. Other tabs stay quiet until they're opened.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        // Order â€” order chat list is hydrated in initState; the
        // ContributionController binds lazily when its slot renders
        // and fires its own /recharge/plans + /recharge/current.
        break;
      case 1:
        // Overview â€” the joined-profile / contact / QR / share-banner
        // sections all read from the permanent
        // [ViewBusinessDetailsController]; no grocery API needed.
        break;
      case 2:
        // Products â€” top-selling products + category-with-inventory.
        _groceryController.fetchAllGroceryData(
          widget.businessId,
          otherStore: false,
        );
        break;
      case 3:
        // Post â€” FeedScreen owns its own controller fetch on mount.
        break;
      case 4:
        // Statics â€” ProfileStatisticsScreen self-fetches on first build.
        // It's kept alive (AutomaticKeepAliveClientMixin), so its initState
        // won't re-run on later taps; trigger a refresh here so the analytics
        // reload every time the user opens the Statics tab. On the very first
        // tap the controller isn't registered yet (the screen builds this
        // frame and fires its own init), so we skip to avoid a double fetch.
        if (Get.isRegistered<ProfileStatisticsController>()) {
          Get.find<ProfileStatisticsController>().refresh();
        }
        break;
    }
  }

  /// Keep [_selectedTab] in sync with the TabController and fire the new tab's
  /// lazy fetch when the user taps a tab or swipes between them.
  void _handleTabChange() {
    if (_selectedTab != _tabController.index) {
      setState(() => _selectedTab = _tabController.index);
      _fetchForTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Pull-to-refresh dispatcher â€” each tab owns a different data set,
  /// so the refresh action fires only the API(s) backing the currently
  /// visible tab. Avoids hammering unrelated endpoints on every pull.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        _chatViewController.emitEvent(
          ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.business_Chat_Type},
        );
        if (Get.isRegistered<ContributionController>()) {
          await Get.find<ContributionController>().fetchCurrent();
        }
        break;
      case 1:
        await _businessController.viewBusinessProfile();
        break;
      case 2:
        await _groceryController.fetchAllGroceryData(
          widget.businessId,
          otherStore: false,
        );
        break;
      case 3:
        if (Get.isRegistered<FeedController>()) {
          await Get.find<FeedController>().getFeed(refresh: true);
        }
        break;
      case 4:
        // ProfileStatisticsScreen manages its own state and doesn't
        // expose an external refresh hook â€” no-op for now.
        break;
    }
  }

  // the tab content scrolling underneath it. Mirrors the reference
  // mock at assets/img1.png: the chrome stays put while content moves.
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // Approximate top-bar height; the sticky tabs overlay engages
    // once the user has scrolled past the original (in-flow) tabs.
    final topBarHeight = topInset + 56;
    return Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: (){
      //   Get.to(() => const GroceryShopAvailabilityScreen());
      // }),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: topBarHeight,
              tabViews: [
                _tabScroll([
                  GroceryOrderTab(
                    businessId: widget.businessId,
                    onAddProduct: () => _tabController.animateTo(2),
                  ),
                ]),
                _tabScroll(_buildOverviewSlivers()),
                _tabScroll(_buildProductsTab()),
                _tabScroll(_buildPostTab()),
                ProfileStatisticsScreen(userId: widget.businessId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps a tab's content list in a refreshable, scrollable body for the
  /// [TabBarView]. The per-tab builders return bounded box widgets, so
  /// SingleChildScrollView + Column reproduces the previous layout.
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


  List<Widget> _buildOverviewSlivers() {
    return [
      BusinessJoinedProfileCard(businessController: _businessController),
      SizedBox(height: SizeConfig.size2),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: CommonBusinessLivePhoto(
          controller: _businessController,
        ),
      ),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: const BusinessDescriptionCard(),
      ),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Obx(() {
          final details = _businessController.businessProfileDetails.value?.data;
          return BusinessContactMapCard(
            businessProfileDetails: details,
          );
        }),
      ),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Obx(() {
          final details = _businessController.businessProfileDetails.value?.data;
          return WebsiteOverviewCard(
            websiteUrl: details?.websiteUrl,
            onSave: (url) => _businessController
                .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
          );
        }),
      ),
      SizedBox(height: SizeConfig.size12),
      _buildQrCodeSection(),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: const BusinessShareBanner(),
      ),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PROFILE CARDS â€” three INDEPENDENT containers with 12-px gaps:
  //   Card 1. Joined-date pill   â†’ small left-aligned pill with calendar
  //                                 icon + "Joined - DD/MM/YYYY"
  //   Card 2. Identity + rating  â†’ bigger logo, name, sub-cat pill, rating
  //   Card 3. Cover photo banner â†’ editable 16:9 cover with "Edit" chip
  // Card 1 uses a different visual treatment (self-sized pill) than
  // cards 2 and 3 (full-width white cards) per assets/img_1.png.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // QR CODE â€” share/download the business profile
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: BusinessQrCodeWidget(
          data: details,
          // Grocery-specific deep link so the QR opens the store directly
          // (`/app/business/grocery/<id>` → VisitGroceryStoreScreen) instead
          // of routing through the generic profile share-preview.
          deepLinkOverride: groceryProfileDeepLink(userId: details.userId),
        ),
      );
    });
  }

  // PRODUCTS TAB â€” top-level "Add Grocery" CTA, then the same
  // top-selling and category-with-inventory cards as Overview.
  // The category section keeps its inline "Update Inventory" link;
  // this top button is the dedicated bulk-upload entry point.
  List<Widget> _buildProductsTab() {
    return [
      GradientAddButton(
        label: AppStrings.addGrocery.tr,
        onTap: _onAddMoreProducts,
        margin: EdgeInsets.only(
            top: SizeConfig.size10, right: SizeConfig.size12),
      ),
      SizedBox(height: SizeConfig.size16),
      _buildTopSellingSection(),
      SizedBox(height: SizeConfig.size16),
      _buildCategoryWithInventorySection(),
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
      _groceryController.fetchAllGroceryData(widget.businessId, otherStore: false);
    }
  }

  // POST TAB â€” embeds FeedScreen filtered to current user's posts.
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
        label: CustomText(AppStrings.createPost.tr,
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      _PostMenuEntry(
        type: PostCreationMenu.reel,
        label: 'Reel',
        iconAsset: AppIconAssets.video_outline,
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
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.createPost.tr,
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
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size10, horizontal: SizeConfig.size4),
                    child: Row(
                      children: [
                        LocalAssets(imagePath: entries[i].iconAsset, height: 24, width: 24),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(entries[i].label,
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1) Divider(height: 1, color: Colors.grey.shade200),
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
      case PostCreationMenu.reel:
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

  // TOP BAR
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
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
                // Pills wrapped in Flexible so their inner text can ellipsize
                // instead of pushing the row past its width.
                Flexible(child: _nearbyRidersPill()),
                SizedBox(width: SizeConfig.size6),
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(icon: Icons.notifications_none, onTap: _openNotifications),
                SizedBox(width: SizeConfig.size6),
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

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
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
      ),
    );
  }

  /// Grocery-specific quick action â€” replaces medical's "Earn" pill so
  /// the merchant can hop straight to nearby riders for self-pickup
  /// or delivery dispatch.
  Widget _nearbyRidersPill() {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getNearByRidersScreenRoute()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
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
                    child: CustomText(AppStrings.nearbyRiders.tr,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Drive the Go-Live toggle. Turning ON opens the shop-availability form
  /// directly — no dialog and no device permission gate. The form persists
  /// the hours and goes live via the backend, popping back `true` on success.
  Future<void> handleGoLiveTap() async {
    if (isShopGoLive) {
      setState(() => isShopGoLive = false);
      return;
    }

    final result = await Get.to(() => const GroceryShopAvailabilityScreen());
    if (result == true && mounted) {
      setState(() => isShopGoLive = true);
    }
  }

  Widget _goLivePill() {
    return GoLivePill(
      value: isShopGoLive,
      onTap: handleGoLiveTap,
    );
  }

  // TOP-SELLING PRODUCTS â€” editorial-style horizontal scroller. Each
  // tile is a ranked chart entry with a brand-tinted image hero, a
  // small "#01" rank pill, the green-gradient discount sticker, a
  // bold name, and a prominent price. A 3-px brand-blue gradient
  // ribbon caps the bottom edge so the section reads as one curated
  // shelf. Header uses the page's vertical-bar pattern + chip CTA.
  Widget _buildTopSellingSection() {
    return Obx(() {
      final isLoading =
          _groceryController.fetchGroceryBusinessProductsResponse.value.status == Status.INITIAL;
      final products = _groceryController.groceryBusinessProductsList;
      if (!isLoading && products.isEmpty) return const SizedBox.shrink();

      // The business-products list can carry one row per variant (so the same
      // product repeats). Group by product → one card per product; tapping a
      // card opens a sheet listing that product's variants.
      final grouped = groupBusinessProductsByProduct(products.toList());
      final previewGroups = grouped.length > GroceryController.businessProductsPreviewLimit
          ? grouped.take(GroceryController.businessProductsPreviewLimit).toList()
          : grouped;

      return Container(
        // White-bordered shell wrapping the whole top-selling section
        // (header + cards rail) with a uniform 10-px inner padding.
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
            _topSellingSectionHeader(),
            SizedBox(height: SizeConfig.size12),
            SizedBox(
              height: 225,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : ListView.builder(
                      itemCount: previewGroups.length,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final group = previewGroups[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          // Align stops the horizontal ListView's tight cross-axis
                          // (height) constraint from stretching the card — it sizes
                          // to its content instead of filling the rail height.
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: 160,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => showGroceryVariantsSheet(
                                  context: context,
                                  productName: group.product.product?.name ?? '',
                                  productImageUrl: group.product.productImageUrlOnly,
                                  variants: group.variants,
                                ),
                                child: GroceryTopSellingProductCard(
                                  product: group.product,
                                  variants: group.variants,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }


  Widget _topSellingSectionHeader() {
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
                AppStrings.groceryViewTopSellingProduct.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.handPickedBestSellers.tr,
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
        _viewAllCta(),
      ],
    );
  }

  // "View All" chip â€” label on the left, solid primary circular
  // arrow badge on the right. Mirrors the chip language used by the
  // category section's CTA on the opposite end.
  Widget _viewAllCta() {
    return GestureDetector(
      onTap: () => Get.to(() => AllTopSellingGroceryProductsScreen(
            userId: widget.businessId,
            otherStore: false,
          )),
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
              AppStrings.groceryViewViewAll.tr,
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
              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Editorial "ranked tile" for the top-selling shelf. Image hero is
  // padded inside a brand-tinted gradient backdrop so product shots
  // never crop awkwardly. A small "#NN" pill in the top-right marks
  // the chart position; the green discount sticker sits opposite. The
  // info zone uses a clear three-row hierarchy (chips â†’ name â†’ price)
  // and the card is finished with a brand-blue gradient ribbon at
  // the bottom edge to anchor the silhouette.

  // CATEGORIES WITH INVENTORY â€” header strip + two-tone storefront
  // card grid. Same design language used in food's products tab:
  // a vertical brand-accent bar with title + helper, a refined chip
  // CTA on the right, and full-bleed photo cards below with a tinted
  // hero zone and a crisp footer carrying the name + a brand chevron.
  Widget _buildCategoryWithInventorySection() {
    return Obx(() {
      final groceryCategoryList =
          List<GroceryCategoryWithInventoryModel>.from(_groceryController.groceryCategoryList);

      return Container(
        // White-bordered shell wrapping the whole category section
        // (header + inventory grid) with a uniform 10-px inner padding —
        // mirrors the top-selling section's container.
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
            _categorySectionHeader(),
            SizedBox(height: SizeConfig.size16),
            if (groceryCategoryList.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size20,
                ),
                child: EmptyStateWidget(
                  message: AppStrings.noProductYetCreateOne.tr,
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: SizeConfig.size4),
                    itemCount: groceryCategoryList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: SizeConfig.size12,
                      mainAxisSpacing: SizeConfig.size12,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (_, i) => _groceryCategoryCard(
                      groceryCategoryList[i],
                      groceryCategoryList,
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _categorySectionHeader() {
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
                AppStrings.groceryViewCategory.tr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                AppStrings.tapCategoryToManageInventory.tr,
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
        _addGroceryCta(),
      ],
    );
  }

  // Refined CTA chip â€” solid primary circular `+` badge anchors a
  // brand-outlined chip. Same shadow + border treatment as other
  // section chips so the rhythm reads as a single design language.
  Widget _addGroceryCta() {
    return GestureDetector(
      onTap: _onAddMoreProducts,
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
              AppStrings.addGrocery.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Two-tone storefront card. Tinted hero zone with the full image
  // (BoxFit.contain so nothing crops), crisp white footer with the
  // name + a small filled brand-blue chevron. Single tap target â€”
  // no separate "View Products" CTA â€” for a clean silhouette.
  Widget _groceryCategoryCard(
    GroceryCategoryWithInventoryModel item,
    List<GroceryCategoryWithInventoryModel> all,
  ) {
    final image = item.image ?? '';
    final hasImage = image.isNotEmpty;
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
          // boxShadow: const [
          //   BoxShadow(
          //     color: Color(0x42001120),
          //     blurRadius: 10,
          //     offset: Offset(0, 2),
          //   ),
          // ],
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
                                  placeholder: (_, __) => const SizedBox.shrink(),
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
