import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/ongoing_ride_restorer.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/recent_shops_controller.dart';
import 'package:BlueEra/features/ride_booking/view/ride_home_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/nearest_stores_section.dart';
import 'package:BlueEra/features/common/Discover/widget/ongoing_booking_chip.dart';
import 'package:BlueEra/features/common/Discover/widget/recent_orders_section.dart';
import 'package:BlueEra/features/common/Discover/widget/recently_visited_stores_section.dart';
import 'package:BlueEra/features/common/Discover/widget/share_promo_sheet.dart';
import 'package:BlueEra/features/common/Discover/view/widget/automotive_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_home_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/education_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/financial_sectors.dart';
import 'package:BlueEra/features/common/Discover/view/widget/find_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/health_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/home_made_product_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/hotel_stay_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/job_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/professionals_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rental_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/shopping_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/transport_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_category_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/v2/home_service_discover_screen_v2.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/qr_code/view/emergency_qr_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_widget.dart';
import 'package:BlueEra/features/me/food/view/customer/restaurant_near_me_screen.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final controller = getOrPut(() => DiscoverController());

  final ScrollController _scrollController = ScrollController();
  late final EmergencyProfileController emergencyController;

  /// The share-profile promo dialog is shown once per app SESSION, the first
  /// time Discover mounts. Backed by the global [sharePromoShownThisSession] so
  /// it survives this screen being rebuilt / re-entered via the bottom nav, but
  /// is RESET on logout (unlike a private static, which used to stay true across
  /// logout→re-login and wrongly suppressed the promo for the next user).

  /// Active quick-access tab — see [discoverQuickAccessTabs]:
  /// 0=Quick Access, 1=Grocery & Food, 2=Travel & Booking,
  /// 3=Shopping & Sell, 4=Services & Professional, 5=Jobs & Other.
  ///
  /// Tab 0 (Quick Access) is the overview and shows every section; the rest
  /// filter down to the sections tagged with their index in [_sections].
  int _activeTabIndex = 0;

  /// Discover sections fetch against the user's lat/lng, so we hold the
  /// content behind the shimmer until the location attempt resolves —
  /// otherwise on first launch they'd fire with 0,0. Flips true once coords
  /// are available OR the fetch attempt finishes (even on denial), so we
  /// never block forever.
  bool _locationResolved = false;

  /// Every Discover section with the set of tab indices it belongs to, in the
  /// same top-to-bottom order as the redesign. Tab 0 (Quick Access / overview)
  /// shows everything, so it's not listed; the other tabs filter down to the
  /// sections tagged with their index.
  ///
  /// Every section renders as the same uniform circular-icon grid, but each
  /// keeps its original data source and tap routing untouched.
  List<({Widget widget, Set<int> tabs})> get _sections {
    return [
      // --- Tab 1 · Grocery & Food (ref: g1.jpeg) ---
      // "Near You" rail — sits above the grocery grid. ONE rail over the whole
      // nearby-discover response: grocery/food/product stores + service workers
      // + riders, distance-sorted, each routed to its own screen by card type.
      // Self-manages its own white card and collapses when nothing is nearby.
      (
        widget: NearestStoresSection(
          onViewAll: () =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
        ),
        tabs: {1}
      ),
      (
        widget: DiscoverCategorySection(
          title: AppStrings.groceryGeneralStore.tr,
          items: discoverGroceryCategories,
          columns: 5,
          onViewAll: () =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
          onItemTap: (_) =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
        ),
        tabs: {1}
      ),
      (
        widget: DiscoverCategorySection(
          title: AppStrings.restaurantFoodService.tr,
          items: discoverFoodCategories,
          columns: 5,
          onItemTap: (_) => Get.to(() => const RestaurantNearMeScreen()),
        ),
        tabs: {1}
      ),
      (
        widget: DiscoverCategorySection(
          title: AppStrings.homeMadeFood.tr,
          items: discoverHomeMadeFoodCategories,
          columns: 5,
          onItemTap: (_) => Get.to(() => const HmfCategoryDiscoverScreen()),
        ),
        tabs: {1}
      ),
      (
        widget: RecentlyVisitedStoresSection(
          onViewAll: () =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
        ),
        tabs: {1}
      ),

      // --- Tab 2 · Travel & Booking (ref: t1.jpeg) ---
      (widget: const TransportServiceWidget(), tabs: {2}),
      (widget: HotelStayServiceCard(), tabs: {2}),

      // --- Tab 3 · Shopping & Sell (ref: s1.jpeg) ---
      (widget: HomeMadeProductAndServiceWidget(), tabs: {3}),
      (widget: ShoppingCardWidget(), tabs: {3}),
      (widget: RentalCardWidget(), tabs: {3}),
      (widget: AutomotiveServiceCardWidget(), tabs: {3}),
      (
        widget: RecentlyVisitedStoresSection(
          onViewAll: () =>
              Get.toNamed(RouteHelper.getGroceryStoresScreenRoute()),
        ),
        tabs: {3}
      ),

      // --- Tab 4 · Services & Professional (ref: ss2.jpeg) ---
      // Pharmacy is a tile inside Healthcare (see `healthCareList`) rather than
      // its own section — tapping it opens `PharmacyStoresScreen`.
      (widget: HealthServiceCardWidget(), tabs: {4}),
      (widget: FindServiceCardWidget(), tabs: {4}),

      (widget: BookHomeServiceWidget(), tabs: {4}),
      (
        widget: DiscoverCategorySection(
          title: AppStrings.homeServices.tr,
          items: discoverHomeServicesCategories,
          columns: 5,
          onItemTap: (_) => Get.to(() => HomeServiceDiscoverScreenV2()),
        ),
        tabs: {4}
      ),
      (widget: ProfessionalsCardWidget(), tabs: {4}),
      (widget: FinancialSectors(), tabs: {4}),

      // --- Tab 5 · Jobs & Other (ref: j1.jpeg) ---
      (widget: JobServiceCardWidget(), tabs: {5}),
      (widget: EducationServiceCardWidget(), tabs: {5}),
    ];
  }

  @override
  void initState() {
    super.initState();
    emergencyController = getOrPut(() => EmergencyProfileController());

    _locationResolved = LocationService.hasUsableLocation;
    if (!_locationResolved) _ensureLocationThenBuild();

    // Put a ride that was running when the app was killed back on screen, so
    // the ongoing chip below the search bar is there on a cold start too. The
    // Connect tab does the same — the first tab to mount wins, the other call
    // returns immediately.
    OngoingRideRestorer.restoreIfNeeded();

    _maybeShowSharePromo();
  }

  /// How long the promo waits for the profile it renders from before giving up
  /// for this session. Comfortably covers a cold-start `/user/get`, while still
  /// being short enough that the sheet can't turn up long after the user has
  /// started doing something else.
  static const Duration _kPromoProfileTimeout = Duration(seconds: 8);

  /// Pops the share-profile promo at most once per calendar day (persisted
  /// across launches), the first time Discover mounts that day. Deferred to
  /// after the first frame so a valid context/overlay exists. The sheet itself
  /// — marketing clip + share card — lives in [SharePromoSheet].
  ///
  /// The sheet is held back until the profile behind the card is in memory —
  /// see [_awaitPromoProfile]. Nothing inside it ever shows a spinner: it
  /// either opens complete or doesn't open.
  Future<void> _maybeShowSharePromo() async {
    // Guests have no profile to share: no referral code, no poster, no clip —
    // the card would compose itself out of nothing. They also get the guest
    // scratch card from the nav shell (_maybeShowJoiningBonus), whose CTA is
    // "create a profile", and two sheets racing to open on the same landing is
    // worse than either. Returns BEFORE the session slot is claimed below, so
    // signing in still gets today's promo.
    if (isGuestUser()) return;
    // A fresh account was just created this session — Discover is mounting
    // behind the onboarding "update data" screen, so don't pop the promo over
    // it. See [suppressPromosAfterAccountCreation].
    if (suppressPromosAfterAccountCreation) return;
    if (sharePromoShownThisSession) return;
    final todayKey = _todayKey();
    final lastShown = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.sharePromoLastShownKey);
    // Already shown today → skip, and don't re-check for the rest of this
    // session.
    if (lastShown == todayKey) {
      sharePromoShownThisSession = true;
      return;
    }
    // Claim the session slot before the wait below, so re-entering Discover
    // through the bottom nav doesn't start a second wait racing this one.
    sharePromoShownThisSession = true;

    // Wait for the profile the card is composed from. The day key is written
    // only once we're actually going to show the sheet, so a promo skipped
    // here (profile never arrived / user navigated away) is still available on
    // the next launch today rather than silently burnt.
    if (!await _awaitPromoProfile()) return;

    if (!mounted) return;
    // The wait can span a navigation — don't pop the promo over whatever the
    // user opened in the meantime.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.sharePromoLastShownKey, todayKey);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Bottom sheet, not a dialog — it carries the marketing clip above the
      // share card, which needs the height a sheet gives it.
      SharePromoSheet.show(context);
    });
  }

  /// Resolves `true` once the profile the promo card renders from has loaded,
  /// `false` if it hasn't within [_kPromoProfileTimeout].
  ///
  /// The card — name, photo, referral code, poster, clip — is composed
  /// entirely from the signed-in profile, so opening the sheet before that
  /// profile is in memory shows a half-built card: an EMPTY sheet for a
  /// business account (the banner renders nothing without business details)
  /// and a "My Profile" / "------" placeholder for an individual, both of
  /// which then rewrite themselves under the user. Waiting here is what lets
  /// the sheet open already complete instead of loading in front of them.
  ///
  /// Business accounts read the business profile and everyone else the
  /// personal one — the same split [SharePromoSheet] uses to build the card.
  Future<bool> _awaitPromoProfile() async {
    if (_isPromoProfileReady) return true;

    final completer = Completer<bool>();
    StreamSubscription? sub;
    Timer? timer;

    void finish(bool ready) {
      if (completer.isCompleted) return;
      sub?.cancel();
      timer?.cancel();
      completer.complete(ready);
    }

    void onProfileChanged(_) {
      if (_isPromoProfileReady) finish(true);
    }

    if (isBusinessUser()) {
      // Nothing put this controller yet → nothing to wait on, and the banner
      // has no business profile to render. Skip today's promo.
      if (!Get.isRegistered<ViewBusinessDetailsController>()) return false;
      sub = Get.find<ViewBusinessDetailsController>()
          .businessProfileDetails
          .listen(onProfileChanged);
    } else {
      // getOrPut, not find: the sheet registers this controller itself, so we
      // listen to the very instance that will feed the card.
      sub = getOrPut(() => ViewPersonalDetailsController())
          .personalProfileDetails
          .listen(onProfileChanged);
    }

    // Re-check after subscribing — the profile can land in the gap between the
    // guard above and the listener being attached.
    if (_isPromoProfileReady) {
      finish(true);
    } else {
      timer = Timer(_kPromoProfileTimeout, () => finish(false));
    }
    return completer.future;
  }

  /// Whether the profile feeding the promo card is loaded **and** carries the
  /// backend-generated poster the card is built around. Guarded — the
  /// controllers aren't registered on every entry path.
  ///
  /// The poster is the promo: without it the sheet is a headline and three
  /// share buttons, and the share itself degrades to plain text (there's no
  /// image in the tree to capture). An account whose card hasn't been generated
  /// yet therefore gets no sheet at all rather than a hollow one — the wait in
  /// [_awaitPromoProfile] simply times out and today's promo is skipped, and
  /// since the day key is only written when the sheet actually opens, it comes
  /// back on its own once the backend has the card. The inline placements on
  /// the profile screens are unaffected; they still render posterless.
  bool get _isPromoProfileReady {
    try {
      final String? posterUrl;
      if (isBusinessUser()) {
        final data = Get.find<ViewBusinessDetailsController>()
            .businessProfileDetails
            .value
            ?.data;
        if (data == null) return false;
        posterUrl = data.marketingCard?.readyUrl;
      } else {
        final user = Get.find<ViewPersonalDetailsController>()
            .personalProfileDetails
            .value
            .user;
        if (user == null) return false;
        posterUrl = user.marketingCard?.readyUrl;
      }
      return posterUrl?.trim().isNotEmpty ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Local `yyyy-MM-dd` key used to bucket the promo to one show per day.
  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> _ensureLocationThenBuild() async {
    await LocationService.ensureUsableLocation();
    if (mounted) setState(() => _locationResolved = true);
  }

  /// Pull-to-refresh — force a fresh fetch of the location-based rails (bypasses
  /// the 24h TTL). Refreshes location first so a move is picked up, then hits
  /// the "Near You" (nearby-discover) and "Recently Visited" endpoints again.
  Future<void> _onRefresh() async {
    await LocationService.ensureUsableLocation();
    await Future.wait([
      getOrPut(() => NearbyStoresController()).fetch(),
      getOrPut(() => RecentShopsController()).fetch(),
    ]);
    if (mounted) setState(() => _locationResolved = true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// Light-blue header: location + wishlist, quick-access tabs,
              /// search bar. Covers the status bar area. The location row and
              /// quick-access tabs collapse away on scroll while the search bar
              /// stays pinned below the status bar.
              _buildHeaderSliver(context),

              /// "Your Ongoing Ride/Booking" chip — the re-entry point into a
              /// ride the customer minimised, plus the receipt/rating for one
              /// that finished while they were elsewhere in the app. Shown on
              /// every tab and collapses to nothing when there is no ride.
              const SliverToBoxAdapter(child: OngoingBookingChip()),

              SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size12)),

              /// "Orders in 12 Hrs." — the user's own recent orders, read from
              /// the Inquiry chat lane (ordering here means a chat with the
              /// shop). Sits directly under the ongoing ride because both
              /// answer the same question: what of mine is in flight right
              /// now. Collapses to nothing when no order is recent.
              const SliverToBoxAdapter(child: RecentOrdersSection()),

              /// Category content — gated behind the shimmer while location and
              /// the initial fetch are still in flight.
              _buildSectionsSliver(),

              /// Emergency QR + sticker options — only on the overview tab, as
              /// in the previous design.
              if (_activeTabIndex == 0) ...[
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (_) =>
                        EmergencyQrWidget(key: const ValueKey('emergency_qr')),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverToBoxAdapter(
                    child: Obx(() {
                      if (!emergencyController.hasEmergencyData.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          SizedBox(height: SizeConfig.size8),
                          QrDesignOptionsWidget(
                            userName: emergencyController.fullName.value,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ] else
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  /// Single sliver that swaps between shimmer and the real section column.
  ///
  /// Gated on the location attempt AND the AuthController's category-loading
  /// flag — the section widgets read the onboarding buckets in their own build
  /// methods, so we subscribe to them here to repaint on the silent refresh.
  Widget _buildSectionsSliver() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final auth = Get.find<AuthController>();
        auth.onboardingBucketsWatch;
        if (auth.isInitialCategoriesLoading.value || !_locationResolved) {
          return const _DiscoverSectionsShimmer();
        }
        return _buildSectionsColumn();
      }),
    );
  }

  Widget _buildSectionsColumn() {
    final visible = _sections
        .where((s) => _activeTabIndex == 0 || s.tabs.contains(_activeTabIndex))
        .toList();
    return Column(
      children: [
        for (final s in visible)
          // The recently-visited and nearest-stores rails are self-managing: each
          // carries its OWN white card + bottom spacing (matching the other
          // sections) when it has data, and collapses to zero when empty. Skip
          // the wrapper here so an EMPTY rail leaves no leftover white card.
          if (s.widget is RecentlyVisitedStoresSection ||
              s.widget is NearestStoresSection)
            s.widget
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: s.widget,
            ),
            SizedBox(height: SizeConfig.size12),
          ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  /// Header as a pinned [SliverAppBar]: the location row + quick-access tabs
  /// live in the collapsing [flexibleSpace] and scroll away, while the search
  /// bar sits in [bottom] so it stays pinned just below the status bar. Using a
  /// SliverAppBar (rather than a manual persistent header) lets Flutter handle
  /// the status-bar inset automatically as the header collapses.
  Widget _buildHeaderSliver(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // ONE continuous panel for the WHOLE header, so the location row, tabs and
    // search bar share a seamless background. As it collapses the tabs fade /
    // slide up while the search bar stays pinned at the bottom of the SAME
    // panel, so the tint is identical at every scroll position.
    return SliverPersistentHeader(
      pinned: true,
      delegate: _DiscoverHeaderDelegate(
        statusBarHeight: statusBarHeight,
        // Location row + tabs + top/bottom padding (the collapsing part).
        headerBlockHeight: 158,
        // Search row + its padding (always pinned at the bottom of the glass).
        searchAreaHeight: 78,
        locationRow: _locationRow(context),
        tabs: _quickAccessTabs(),
        searchRow: _searchRow(context),
      ),
    );
  }

  Widget _locationRow(BuildContext context) {
    return Row(
      // Space the pill and the wishlist button apart so the pill can hug its
      // address text (left) while the button stays at the far right.
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Loose flex: the pill is only as wide as its address text, but still
        // caps at the available width and ellipsizes a long address.
        Flexible(
          fit: FlexFit.loose,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: _kTopViewShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.primaryColor, size: 20),
                SizedBox(width: SizeConfig.size6),
                Flexible(
                  child: Obx(
                    () => CustomText(
                      [
                        LocationService.userCurrentAddress.value.subLocality,
                        LocationService.userCurrentAddress.value.city,
                      ].where((e) => e.isNotEmpty).join(', '),
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // The header's refresh button is gone — refreshing every rail from up
        // here was a blunt instrument. Each rail now owns its own refresh (see
        // NearestStoresSection); pull-to-refresh still reloads them all.
        _circleIconButton(
          boxShadow: _kTopViewShadow,
          child: const Icon(Icons.favorite_border,
              color: AppColors.primaryColor, size: 22),
          onTap: () {
            Navigator.pushNamed(context, RouteHelper.getYourCartScreenRoute());
          },
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required Widget child,
    required VoidCallback onTap,
    List<BoxShadow>? boxShadow,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }

  // Icon chip footprint: EdgeInsets.all(9)*2 + 30px icon.
  static const double _kTabChipSize = 48.0;

  Widget _quickAccessTabs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(discoverQuickAccessTabs.length, (index) {
        final item = discoverQuickAccessTabs[index];
        final isActive = _activeTabIndex == index;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_activeTabIndex == index) return;
              setState(() => _activeTabIndex = index);
            },
            child: Column(
              children: [
                // Light-blue tile when unselected → deep-blue gradient when
                // selected. AnimatedContainer cross-fades the two fills on tap;
                // the icon flips to white so it stays legible on the dark
                // active tile.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  width: _kTabChipSize,
                  height: _kTabChipSize,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    // Symmetric matched pair — same diagonal direction and a
                    // clear light→deep spread in both states, just shifted up
                    // the blue scale when selected.
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            // Bright blue → deep blue: a visible gradient, not
                            // one flat blue.
                            colors: [Color(0xFF33A6FF), Color(0xFF004E96)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            // Light-blue gradient — clearly blue but stays soft.
                            colors: [Color(0xFFDCEEFF), Color(0xFFBFDCFA)],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryColor
                          : const Color(0xFFCFE3FA),
                      width: isActive ? 1.6 : 1,
                    ),
                    boxShadow:
                        isActive ? _kTabChipActiveShadow : _kTabChipShadow,
                  ),
                  child: LocalAssets(
                    imagePath: item['icon']!,
                    width: 30,
                    height: 30,
                    boxFix: BoxFit.contain,
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  item['title']!,
                  fontSize: SizeConfig.small11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  // Label follows the same light→dark blue theme as the tile:
                  // deep blue + bold when selected, brand blue when not.
                  color: isActive ? AppColors.blue5CAF : AppColors.primaryColor,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _searchRow(BuildContext context) {
    return Row(
      children: [
        _circleIconButton(
          boxShadow: _kTopViewShadow,
          child: LocalAssets(
            imagePath: AppIconAssets.transport_bike,
            width: 24,
            height: 24,
          ),
          onTap: () => Get.to(() => const RideHomeScreen()),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(
              context,
              RouteHelper.getGlobalSearchScreenRoute(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: _kTopViewShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppColors.secondaryTextColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      AppStrings.searchAnything.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  LocalAssets(
                    imagePath: AppIconAssets.mic,
                    width: 20,
                    height: 20,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(width: 12),
                  LocalAssets(imagePath: AppIconAssets.camera_black),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One continuous Discover header. It fills the whole (pinned) header extent —
/// so location + tabs + search read as ONE background — while the location row
/// and tabs fade/slide up as the header collapses and the search bar stays
/// pinned at the bottom. The tint is identical at every scroll position (no
/// seam, and no colour change when the search sticks).
///
/// ## Why this is an opaque gradient and NOT a frosted-glass [BackdropFilter]
///
/// It used to be `BackdropFilter(blur 24)` over a translucent white tint. A
/// BackdropFilter forces a `saveLayer` and re-samples everything painted
/// beneath it on every frame — and here it sits in a PINNED sliver with the
/// whole feed scrolling underneath it. On a lot of Android GPU/driver combos
/// (and differently again on Impeller vs Skia) that sampled backdrop isn't
/// invalidated correctly, so stale text tiles get re-blitted: the section
/// labels smeared and repeated horizontally down the page.
///
/// An opaque background gives the same "one continuous header" read with
/// nothing to sample, so the artifact can't occur. If frosted glass is ever
/// reinstated here, it needs testing on low-end Android — this is a
/// device-dependent bug that will not reproduce on most dev hardware.
class _DiscoverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DiscoverHeaderDelegate({
    required this.statusBarHeight,
    required this.headerBlockHeight,
    required this.searchAreaHeight,
    required this.locationRow,
    required this.tabs,
    required this.searchRow,
  });

  final double statusBarHeight;
  final double headerBlockHeight;
  final double searchAreaHeight;
  final Widget locationRow;
  final Widget tabs;
  final Widget searchRow;

  @override
  double get maxExtent =>
      statusBarHeight + headerBlockHeight + searchAreaHeight;

  @override
  double get minExtent => statusBarHeight + searchAreaHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double range = maxExtent - minExtent;
    final double collapse = shrinkOffset.clamp(0.0, range);
    final double opacity =
        range == 0 ? 1.0 : (1 - collapse / range).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        // Opaque, so nothing behind it is sampled. The soft vertical gradient
        // keeps the light, airy read the frosted panel had.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3F7FD), Color(0xFFE8F0FA)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        // Replaces the depth the blur used to imply, so the header still
        // reads as floating above the feed.
        boxShadow: [
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Location + tabs — slide up & fade out as the header collapses.
            Positioned(
              top: statusBarHeight + 12 - collapse,
              left: 12,
              right: 12,
              // Skip the Opacity layer entirely at the extremes: fully
              // expanded and fully collapsed are the two states the header
              // rests in, and Opacity forces its own saveLayer.
              child: opacity >= 1.0
                  ? _collapsingBlock()
                  : opacity <= 0.0
                      ? const SizedBox.shrink()
                      : Opacity(opacity: opacity, child: _collapsingBlock()),
            ),
            // Search bar — always pinned to the bottom of the header.
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: searchRow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapsingBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        locationRow,
        const SizedBox(height: 16),
        tabs,
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _DiscoverHeaderDelegate oldDelegate) =>
      statusBarHeight != oldDelegate.statusBarHeight ||
      headerBlockHeight != oldDelegate.headerBlockHeight ||
      searchAreaHeight != oldDelegate.searchAreaHeight ||
      locationRow != oldDelegate.locationRow ||
      tabs != oldDelegate.tabs ||
      searchRow != oldDelegate.searchRow;
}

/// Shimmer skeleton shown in place of the Discover content while location and
/// the initial fetch are still resolving. Mirrors the card layout — a stack of
/// white cards each with a short title bar and a grid of round placeholders —
/// so the swap to real content reads as a content load, not a layout shift.
class _DiscoverSectionsShimmer extends StatelessWidget {
  const _DiscoverSectionsShimmer();

  static const int _cardCount = 3;
  static const int _columns = 5;
  static const int _tilesPerCard = 5;
  static const double _tileSpacing = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _cardCount; i++) ...[
          _shimmerCard(),
          SizedBox(height: SizeConfig.size12),
        ],
      ],
    );
  }

  Widget _shimmerCard() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLoadingShimmer(
            child: shimmerContainer(height: 22, width: 140),
          ),
          SizedBox(height: SizeConfig.size16),
          LayoutBuilder(builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - _tileSpacing * (_columns - 1)) /
                    _columns;
            return Wrap(
              spacing: _tileSpacing,
              runSpacing: _tileSpacing,
              children: List.generate(_tilesPerCard, (_) {
                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      buildLoadingShimmer(
                        child: shimmerContainer(
                          height: itemWidth * 0.9,
                          width: itemWidth * 0.9,
                          radius: itemWidth,
                        ),
                      ),
                      const SizedBox(height: 6),
                      buildLoadingShimmer(
                        child: shimmerContainer(height: 10, radius: 4),
                      ),
                    ],
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = AppColors.secondaryTextColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double dashHeight = 2;
    double dashSpace = 3;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Widget titleWidget(String title) {
  return CustomText(title,
      fontSize: SizeConfig.large18,
      color: AppColors.mainTextColor,
      fontWeight: FontWeight.w600);
}

/// Drop shadow for the floating white pills in the Discover header (location
/// bar, wishlist button, rider button, search bar), so they read as clearly
/// elevated over the frosted header. Two layers — a soft ambient spread plus a
/// tighter contact shadow — so the lift is visible even against the light glass.
const List<BoxShadow> _kTopViewShadow = [
  BoxShadow(
    color: Color(0x24101828),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x14101828),
    blurRadius: 4,
    offset: Offset(0, 1),
  ),
];

/// Resting shadow every quick-access tab tile floats on, so the row reads as a
/// set of lifted chips rather than flat outlined boxes. Two layers — a soft
/// ambient spread plus a tighter contact shadow — so even the unselected tiles
/// clearly lift off the frosted header.
const List<BoxShadow> _kTabChipShadow = [
  BoxShadow(
    color: Color(0x1F101828),
    blurRadius: 12,
    offset: Offset(0, 5),
  ),
  BoxShadow(
    color: Color(0x14101828),
    blurRadius: 3,
    offset: Offset(0, 1),
  ),
];

/// Brand-blue glow for the sliding selection highlight — lifts the active tab
/// and tints its shadow blue so the highlight reads as "lit up" as it slides.
const List<BoxShadow> _kTabChipActiveShadow = [
  BoxShadow(
    color: Color(0x2E0086FF),
    blurRadius: 14,
    offset: Offset(0, 6),
  ),
];
