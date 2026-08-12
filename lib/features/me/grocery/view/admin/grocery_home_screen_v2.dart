import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
// import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/controller/profile_statistics_controller.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/view/admin/tabs/grocery_overview_tab.dart';
// import 'package:BlueEra/features/me/grocery/view/admin/tabs/grocery_post_tab.dart';
import 'package:BlueEra/features/me/grocery/view/admin/tabs/grocery_products_tab.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
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
  int _selectedTab = 0;
  late final TabController _tabController;

  late final GroceryController _groceryController;
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  // Chat controller drives the Orders list shown under the Order tab.
  // Mirrors `ConnectMainPage._emitChatListForTab(2)` â€” same controller,
  // same event, so the data is shared with the Connect screen and
  // receives socket-driven updates while the user is on this screen.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Post tab removed for business accounts — the merchant's own feed is no
  // longer surfaced here. Restore the label, the `GroceryPostTab` view and the
  // matching `case` in both switches below together, or the indices desync.
  List<String> get _tabs => [
        AppStrings.productsTab.tr,
        AppStrings.overviewTab.tr,
        // AppStrings.postTabLabel.tr,
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
    // Fire the API(s) backing the tab the screen lands on (Products by
    // default). Switching tabs later will fire other tabs' APIs lazily
    // via [_onTabTapped] â€” mirrors product_screen's per-tab discipline.
    _fetchForTab(_selectedTab);
    // The once-a-day "add your grocery items" nudge. Lives here rather than in
    // GroceryScreen because the CTA needs this screen's TabController.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Skip when the user isn't on the Me tab â€” same transient-mount guard
      // GroceryScreen uses for the live-photo sheet.
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      showAddProductPromptIfNeeded(
        context: context,
        spec: const AddProductPromptSpec(
          titleKey: AppStrings.addPromptTitleGrocery,
          ctaKey: AppStrings.addProduct,
          icon: Icons.local_grocery_store_outlined,
        ),
        onAddProduct: () => _tabController.animateTo(0),
        // GroceryScreen pops the live-photo sheet on this same landing.
        livePhotoGate: _businessController,
      );
    });
  }

  /// Per-tab API dispatcher. Each tab owns a different data set, so we
  /// only fire the calls backing the visible tab when the user lands on
  /// it. Other tabs stay quiet until they're opened.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        // Products â€” top-selling products + category-with-inventory.
        // *IfNeeded* so returning to this tab reuses data that's already
        // loaded and still fresh. Every tab switch (and every swipe between
        // tabs) lands here, so calling the unguarded fetch refired both
        // requests each time. Pull-to-refresh still forces a real reload.
        _groceryController.fetchAllGroceryDataIfNeeded(
          widget.businessId,
          otherStore: false,
        );
        break;
      case 1:
        // Overview â€” the joined-profile / contact / QR / share-banner
        // sections all read from the permanent
        // [ViewBusinessDetailsController]; no grocery API needed.
        //
        // The live-photo request belongs here, not on the landing. The photos
        // are part of this profile and are shown on this tab, so asking for
        // them the moment the store opens (on PRODUCTS) put the request over a
        // screen about stock. It fires on each visit while the store still has
        // none: the helper no-ops once any photo exists, and will not stack on
        // a sheet that is already open.
        //
        // Post-frame because this runs from the TabController's listener, mid
        // tab-change; pushing a route from inside that lands the sheet on a
        // half-settled navigator.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showBusinessLivePhotoBottomSheetIfNeeded(
            context: context,
            controller: _businessController,
          );
        });
        break;
      // Post was case 2; Statics moved up with it removed.
      case 2:
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
        await _groceryController.fetchAllGroceryData(
          widget.businessId,
          otherStore: false,
        );
        break;
      case 1:
        await _businessController.viewBusinessProfile();
        break;
      // Post was case 2; Statistics moved up with it removed.
      case 2:
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
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: topBarHeight,
              // One class per tab, each in `admin/tabs/` — this screen owns the
              // chrome (top bar, tab controller, per-tab fetch/refresh) and
              // nothing else. Statistics already is its own screen.
              tabViews: [
                _tabScroll(GroceryProductsTab(businessId: widget.businessId)),
                _tabScroll(const GroceryOverviewTab()),
                // _tabScroll(const GroceryPostTab()),
                ProfileStatisticsScreen(userId: widget.businessId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps a tab in the refreshable, scrollable body they all share. The tab
  /// classes are content-only (each returns a bounded Column), and this is the
  /// only place the `left: 20 / nothing on the right` padding contract they
  /// build against is set.
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
                Flexible(child: const ReferEarnPill()),
                const Spacer(),
                _circleIconButton(
                    icon: Icons.notifications_none, onTap: _openNotifications),
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
          child: Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ProfileMenuDrawer()),
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

  /// Drive the Go-Live toggle — a plain on/off switch. With weekly hours saved
  /// it flips today's open/closed state straight from the pill; with no hours
  /// yet it shows the "Set visiting hours" prompt, since there is nothing to
  /// switch on until a schedule exists. Hours are set and edited from the clock
  /// button beside the pill. The security-deposit gate lives in toggleLiveNow().
  Future<void> handleGoLiveTap() async {
    await _businessController.toggleLiveNow();
  }

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        isUpdating: _businessController.isAvailabilityUpdating.value,
        onTap: handleGoLiveTap,
        onScheduleTap: _businessController.openScheduleControl,
      ),
    );
  }
}
