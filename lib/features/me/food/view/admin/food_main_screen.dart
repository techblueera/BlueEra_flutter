import 'dart:ui';
import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
// import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/view/admin/food_category_menu_screen.dart';
import 'package:BlueEra/features/me/food/view/admin/tabs/food_overview_tab.dart';
// import 'package:BlueEra/features/me/food/view/admin/tabs/food_post_tab.dart';
import 'package:BlueEra/features/me/food/view/admin/tabs/food_products_tab.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/go_live_product_gate.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodMainScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const FoodMainScreen({super.key, this.fromBottomNavBar});

  @override
  State<FoodMainScreen> createState() => _FoodMainScreenState();
}

class _FoodMainScreenState extends State<FoodMainScreen>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  int _selectedTab = 0; // Products tab
  late final TabController _tabController;

  late final RestaurantController _foodController;
  late final ViewBusinessDetailsController _businessController;

  // Drives the orders list shown under the Order tab. Same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  // Post tab removed for business accounts — the merchant's own feed is no
  // longer surfaced here. Restore the label, the `FoodPostTab` view and the
  // matching `case` in both switches below together, or the indices desync.
  List<String> get _tabs => [
        AppStrings.productsTab.tr,
        AppStrings.overviewTab.tr,
        // AppStrings.postTabLabel.tr,
        AppStrings.statisticsTab.tr,
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
    _foodController = getOrPut(() => RestaurantController());
    _businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Skip when the user isn't on the Me tab â€” the screen can mount
      // transiently during initial bottom-nav routing (currentIndex
      // starts at 0 â†’ meScreens, then post-frame flips to the intended
      // tab like Discover), and we don't want the sheet popping there.
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      // The once-a-day "add your dishes" nudge. This tab (Products) is the one
      // it is about, so it belongs on the landing.
      //
      // No livePhotoGate any more: that existed to stop this stacking on top of
      // the live-photo sheet, which used to pop on this same landing. Live
      // photos now belong to Overview (see [_maybePromptLivePhotos]), so the
      // two can no longer collide and deferring this one would only delay it
      // for a business that has no photos yet.
      showAddProductPromptIfNeeded(
        context: context,
        spec: const AddProductPromptSpec(
          titleKey: AppStrings.addPromptTitleFood,
          ctaKey: AppStrings.addFood,
          icon: Icons.restaurant_menu_rounded,
        ),
        onAddProduct: _openAddFood,
      );
    });
  }

  /// One-shot per mount. The sheet helper only guards on "photos already exist"
  /// and "a sheet is already open", so without this it would re-pop on every
  /// swipe back to Overview until a photo is added.
  bool _livePhotoPromptShown = false;

  /// Live photos are part of the public profile the OVERVIEW tab edits and are
  /// shown there, so the upload sheet appears when the merchant opens Overview
  /// — not over the Products tab they land on, which is about stock.
  void _maybePromptLivePhotos() {
    if (_livePhotoPromptShown) return;
    _livePhotoPromptShown = true;
    // After the frame: the tab body is still building when the dispatcher runs,
    // and the helper reads ModalRoute to decide whether something is already on
    // top of this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _businessController,
      );
    });
  }

  /// Opens the add-dish flow — the SAME destination as the Products tab's "Add
  /// Food" masthead, so every "add dishes" affordance on this screen lands on
  /// one screen instead of dropping the merchant on a tab to find it again.
  ///
  /// Snaps to Products first: the gate can fire from Overview, and returning
  /// from a publish onto the tab that shows the new dish is the point.
  Future<void> _openAddFood() async {
    _tabController.animateTo(0);
    await Get.to(() => const FoodCategoryMenuScreen());
    if (!mounted) return;
    // Publishing sets this flag from [RestaurantController.markMenuChanged],
    // which has already dropped the saved snapshot and started the refetch —
    // so this is the GUARDED call: it either finds that work done or does it
    // once, instead of firing a duplicate pair of requests.
    if (_foodController.foodDataNeedsRefresh) {
      _foodController.foodDataNeedsRefresh = false;
      final id = businessId;
      if (id.isEmpty) return;
      _foodController.fetchHomeAndDiscountIfNeeded(businessId: id);
    }
  }

  /// Per-tab API dispatcher. Each tab owns a different data set, so we
  /// only fire the calls backing the visible tab when the user lands on
  /// it. Other tabs stay quiet until they're opened.
  void _fetchForTab(int tab) {
    switch (tab) {
      case 0:
        // Products — popular dishes (Offer Dish) + food menu.
        //
        // *IfNeeded* so returning to this tab reuses data that's already
        // loaded and still fresh. Every tab switch AND every swipe between
        // tabs lands here, so calling the unguarded fetches refired both
        // requests each time. Pull-to-refresh still forces a real reload, and
        // publishing a dish refetches explicitly. Mirrors grocery's
        // `fetchAllGroceryDataIfNeeded`.
        unawaited(_fetchProductsTab());
        break;
      case 1:
        // Overview â€” the joined-profile / contact / QR / share-banner
        // sections all read from [ViewBusinessDetailsController], which
        // is registered as a permanent singleton elsewhere on launch.
        // No food-specific API is needed for this tab.
        //
        // It IS where the live-photo nudge belongs: the photos are part of the
        // profile this tab shows and edits.
        _maybePromptLivePhotos();
        break;
      // Post was case 2; Statistics moved up with it removed.
      case 2:
        // Statistics â€” ProfileStatisticsScreen owns its own data.
        break;
    }
  }

  /// The Products tab's fetch, with the business id RESOLVED first.
  ///
  /// This used to be `final id = businessId; if (id.isEmpty) return;` inline,
  /// and that early return was silent and terminal: nothing re-runs the
  /// dispatcher, so [RestaurantController.foodHomeDataResponse] never left
  /// INITIAL, `menuResolved` in [FoodProductsTab] stayed false, and the tab sat
  /// on its loader for good — no error, no empty state, no retry.
  ///
  /// An empty [businessId] with a RESTORED `businessTypeGlobal` is a real
  /// state, not a can't-happen: they are two separate secure-storage keys read
  /// in the same boot batch, and `SharedPreferenceUtils.getSecureValue`
  /// deliberately swallows a keystore read failure into null. So the Me tab can
  /// route to Food (type restored) while the id it needs to fetch with is still
  /// empty.
  Future<void> _fetchProductsTab() async {
    final id = await _resolveBusinessId();
    if (!mounted) return;
    if (id.isEmpty) {
      // Out of ways to get an id. RESOLVE the tab's state anyway so it renders
      // its empty / "Add Food" surface instead of shimmering forever — a dead
      // end the merchant can see and act on beats one they cannot.
      logs('FOOD: businessId unresolved — Products tab has nothing to fetch');
      _foodController.foodHomeDataResponse.value = ApiResponse.error('error');
      return;
    }
    _foodController.fetchHomeAndDiscountIfNeeded(businessId: id);
  }

  /// [businessId] or the best attempt at recovering one.
  ///
  /// Three escalating recoveries, each a no-op once the global is set:
  ///
  /// 1. Re-read the stored key. It only ever ADOPTS a non-empty value, so a
  ///    second failed read cannot make things worse.
  /// 2. Fetch the business profile — request-coalesced, so a boot fetch already
  ///    in flight is joined rather than duplicated.
  /// 3. Read the id straight off THAT profile. Step 2 can leave the global
  ///    empty even on success, because it ends in a bulk secure-storage re-read
  ///    whose result it trusts over what it just wrote. That is fixed at the
  ///    source (see `getUserLoginData`), and this stays as the belt: the object
  ///    in memory is the one thing here that cannot be lost to a keystore hiccup.
  Future<String> _resolveBusinessId() async {
    if (businessId.isNotEmpty) return businessId;
    await getUserLoginBusinessId();
    if (businessId.isNotEmpty) return businessId;
    await _businessController.viewBusinessProfile();
    if (businessId.isNotEmpty) return businessId;
    final fromProfile =
        _businessController.businessProfileDetails.value?.data?.id?.trim() ?? '';
    if (fromProfile.isNotEmpty) {
      businessId = fromProfile;
      logs('FOOD: businessId recovered from the fetched profile');
    }
    return businessId;
  }

  /// Keep [_selectedTab] (the content source-of-truth for FAB/go-live state)
  /// in sync with the TabController and fire the new tab's lazy fetch when the
  /// user taps a tab or swipes between them.
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

  // BUILD
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
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
                _tabScroll(withQurekaPromoBelow(const FoodProductsTab())),
                _tabScroll(const FoodOverviewTab()),
                // _tabScroll(const FoodPostTab()),
                ProfileStatisticsScreen(
                  userId: businessId.isNotEmpty ? businessId : userId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh dispatcher â€” each tab owns a different data set,
  /// so the refresh action fires only the API(s) backing the currently
  /// visible tab. Avoids hammering unrelated endpoints on every pull.
  Future<void> _onRefreshCurrentTab() async {
    switch (_selectedTab) {
      case 0:
        final id = await _resolveBusinessId();
        if (id.isEmpty) return;
        _foodController.fetchHomeData(businessId: id);
        await _foodController.fetchDiscountFoodProducts(businessId: id);
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
          top: SizeConfig.size4,
          bottom: kBottomNavigationBarHeight + 30,
        ),
        child: tab,
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // TOP BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 4),
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
                  icon: Icons.notifications_none,
                  onTap: _openNotifications,
                ),
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
  /// An EMPTY menu is checked first, ahead of that payment gate — see
  /// [ensureCatalogueBeforeGoLive]. Only when going live; going offline is
  /// never blocked.
  Future<void> handleGoLiveTap() async {
    if (!_businessController.shopStatus.value.isOpenNow) {
      final ok = await ensureCatalogueBeforeGoLive(
        context: context,
        spec: const AddProductPromptSpec(
          titleKey: AppStrings.addPromptTitleFood,
          ctaKey: AppStrings.addFood,
          icon: Icons.restaurant_menu_rounded,
        ),
        ensureLoaded: () async {
          final id = businessId;
          if (id.isEmpty) return;
          await _foodController.fetchHomeAndDiscountIfNeeded(businessId: id);
        },
        hasItems: () =>
            _foodController.foodMenuNestedCategory.isNotEmpty ||
            _foodController.allFoodItems.isNotEmpty ||
            _foodController.restaurantSpecials.isNotEmpty,
        // The home fetch is what fills the menu; until it has completed the
        // menu being empty means "not loaded", not "no dishes".
        isLoaded: () =>
            _foodController.foodHomeDataResponse.value.status ==
            Status.COMPLETE,
        onAddItems: _openAddFood,
      );
      if (!ok) return;
    }
    await _businessController.toggleLiveNow();
  }

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _businessController.isLive.value,
        isUpdating: _businessController.isAvailabilityUpdating.value,
        onTap: handleGoLiveTap,
        onScheduleTap: _businessController.openScheduleControl,
        showShadow: false,
      ),
    );
  }
}
