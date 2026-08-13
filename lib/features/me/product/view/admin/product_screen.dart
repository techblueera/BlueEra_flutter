import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
// import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/product_home_screen.dart';
// import 'package:BlueEra/features/me/product/view/admin/tabs/product_post_tab.dart';
import 'package:BlueEra/features/me/product/view/admin/tabs/products_tab.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/go_live_product_gate.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductScreen extends StatefulWidget {

  const ProductScreen({
    super.key,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  TabController? _tabController;
  int _selectedTab = 0; // land on the first tab (Products) on open
  bool _isLoading = true;

  late final List<String> _tabs;

  final inventoryController = getOrPut(() => InventoryController());
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Fire the API backing the tab the screen lands on. [_onTabChanged] only
    // runs when the index CHANGES, so without this the landing tab (Products)
    // never fetched: its skeletons sat at Status.INITIAL forever until the
    // merchant switched to another tab and came back.
    _fetchForTab(_selectedTab);
    // Hydrate the order chat list so the Order tab's incoming-orders
    // list has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Order tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    // The once-a-day "add your products" nudge. No livePhotoGate here: this
    // screen lands on Order (tab 0) and its live-photo sheet is fired by
    // ProductHomeScreen, which TabBarView doesn't build until the merchant
    // opens Overview â€” so the two can't collide on this landing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAddProductPromptIfNeeded(
        context: context,
        spec: const AddProductPromptSpec(
          titleKey: AppStrings.addPromptTitleProduct,
          ctaKey: AppStrings.addProduct,
          icon: Icons.inventory_2_outlined,
        ),
        onAddProduct: () => _tabController?.animateTo(0),
      );
    });
  }

  void _initializeData() {
    // Tabs mirror the grocery v2 home screen exactly so the merchant
    // sees a consistent layout across me-section services.
    // Post tab removed for business accounts — the merchant's own feed is no
    // longer surfaced here. Restore the label, the `ProductPostTab` view and
    // the matching `case` in the refresh switch together, or indices desync.
    _tabs = [
      AppStrings.productsTab.tr,
      AppStrings.overviewTab.tr,
      // AppStrings.postTabLabel.tr,
      AppStrings.staticsTab.tr,
    ];

    _tabController = TabController(
      length: _tabs.length,
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
      _fetchForTab(c.index);
    }
  }

  /// Per-tab API dispatcher. Only Products has data this screen owns — Overview
  /// reads the permanent business controller, Post and Statistics own their own
  /// fetches — so the other tabs are deliberately no-ops.
  ///
  /// *IfNeeded* so re-opening the tab reuses what's already loaded and still
  /// fresh; the unguarded call refetched catalog + categories on every single
  /// switch. Pull-to-refresh and post-publish still force a real reload.
  void _fetchForTab(int tab) {
    if (tab == 0) {
      inventoryController.fetchAllProductDataIfNeeded();
    }
  }

  /// Pull-to-refresh dispatcher â€” each tab owns a different data set,
  /// so the refresh action fires only the API(s) backing the currently
  /// visible tab. Avoids hammering unrelated endpoints on every pull.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        // Products: re-pull catalog + categories.
        inventoryController.fetchAllProductData();
        break;
      case 1:
        // Overview: re-pull the business profile (drives joined date,
        // identity card, cover banner, contact-map, QR, share banner).
        await viewBusinessDetailsController.viewBusinessProfile();
        break;
      // Post was case 2; Statics moved up with it removed.
      case 2:
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
              // One class per tab, each in `admin/tabs/` — this screen owns the
              // chrome (top bar, tab controller, per-tab fetch/refresh) and
              // nothing else. Overview (ProductHomeScreen) and Statistics
              // already are their own screens.
              tabViews: [
                _tabScroll(ProductsTab(onAddProduct: _onAddProduct)),
                _tabScroll(const ProductHomeScreen()),
                // _tabScroll(const ProductPostTab()),
                ProfileStatisticsScreen(userId: userId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TAB CONTENT â€” rebuilt per tab. Each branch returns the body
  // widgets the inner scroll content should host. Mirrors grocery's
  // _buildTabContent pattern so the outer CustomScrollView controls
  // the scroll for every tab.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Wraps a tab in the refreshable, scrollable body they all share. The tab
  /// classes are content-only (each returns a bounded Column), and this is the
  /// only place the `left: 20 / nothing on the right` padding contract they
  /// build against is set. Statistics is passed directly (owns its scroll).
  Widget _tabScroll(Widget tab) {
    return RefreshIndicator(
      onRefresh: _onRefreshCurrentTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20,
          top: SizeConfig.size10,
          bottom: kBottomNavigationBarHeight + 30,
        ),
        child: tab,
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

  /// Same flow that was previously triggered by the top-bar "Add Product"
  /// pill â€” now reused by the "Add Product" tab pill.
  Future<void> _onAddProduct() async {
    if (businessId.isEmpty) return;
    await Get.toNamed(
      RouteHelper.getProductSuperCategoryScreenRoute(),
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
      _tabController?.animateTo(0);
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

  /// Drive the Go-Live toggle — a plain on/off switch. With weekly hours saved
  /// it flips today's open/closed state straight from the pill; with no hours
  /// yet it shows the "Set visiting hours" prompt. Hours are set and edited
  /// from the clock button beside the pill. The security-deposit gate lives in
  /// toggleLiveNow().
  ///
  /// An EMPTY catalogue is checked first, ahead of that payment gate — see
  /// [ensureCatalogueBeforeGoLive]. Only when going live; going offline is
  /// never blocked.
  Future<void> handleGoLiveTap() async {
    if (!viewBusinessDetailsController.shopStatus.value.isOpenNow) {
      final ok = await ensureCatalogueBeforeGoLive(
        context: context,
        spec: const AddProductPromptSpec(
          titleKey: AppStrings.addPromptTitleProduct,
          ctaKey: AppStrings.addProduct,
          icon: Icons.inventory_2_outlined,
        ),
        ensureLoaded: () => inventoryController.fetchAllProductDataIfNeeded(),
        hasItems: () =>
            inventoryController.allProducts.isNotEmpty ||
            inventoryController.productNestedCategoryList.isNotEmpty,
        isLoaded: () =>
            inventoryController.fetchProductCategoryResponse.value.status ==
            Status.COMPLETE,
        onAddItems: _onAddProduct,
      );
      if (!ok) return;
    }
    await viewBusinessDetailsController.toggleLiveNow();
  }

  /// Go-live toggle pill. Off-state: white track + grey thumb.
  /// On-state: brand-blue track + white thumb. Same chip language
  /// the grocery v2 top bar uses.
  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: viewBusinessDetailsController.isLive.value,
        isUpdating:
            viewBusinessDetailsController.isAvailabilityUpdating.value,
        onTap: handleGoLiveTap,
        onScheduleTap: viewBusinessDetailsController.openScheduleControl,
        showShadow: false,
      ),
    );
  }

  // PROFILE ROW

  // TABS â€” solid white card with high-contrast labels and an animated
  // underline that glides under the selected tab. Mirrors the grocery
  // v2 home design so styling stays consistent across me-section.
}
