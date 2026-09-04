import 'dart:ui' as ui;

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/discover_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/ongoing_ride_restorer.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_sections_models.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_category_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/near_you_all_screen.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/view/v2/home_service_discover_screen_v2.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_group_sheet_v2.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_near_me_rail.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_qr_pair.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_quick_access_grid.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_recent_stores_card.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_v2_section_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/automotive_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/find_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/health_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/home_made_product_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/hotel_stay_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rental_card_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/ongoing_booking_chip.dart';
import 'package:BlueEra/features/common/Discover/widget/pending_order_chip.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/help_support/widget/help_support_avatar_button.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/me/food/view/customer/restaurant_near_me_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/products_store_discover_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/ride_booking/view/ride_home_screen.dart';
import 'package:BlueEra/widgets/app_home_background.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Discover **v2** — the layout in `assets/discover.png`.
///
/// A straight vertical list of near-white cards, in this fixed order:
///
///   1. header (location + profile banner) on one white panel
///   2. search field
///   3. **Quick Access** — ten launcher tiles, 5 x 2
///   4. **Shops Near Me** — nearby stores rail
///   5. **Services Near Me** — nearby workers rail
///   6. **Recent Visited Stores** — in-flight order rows
///   7. **Refer & Earn Now** — the referral banner
///   8. the QR pair — emergency QR + this account's profile QR
///
/// ## How this differs from [DiscoverScreen] (v1)
///
/// v1 is a catalogue: alternating chip ROWS and FOLDER tiles, fourteen
/// sections deep, every one of them a way to browse. v2 leads with what the
/// user already has around them — ten launchers, then the shops and people
/// actually nearby, then their own recent orders — and pushes the full
/// catalogue behind those ten tiles.
///
/// **Nothing here replaces v1.** [DiscoverScreen] is untouched and still what
/// the bottom nav mounts; this is a parallel page, so the two can be compared
/// on a device before either is retired. Every destination below is the SAME
/// call v1 makes — the same sheets, the same screens, the same category ids —
/// so switching between them changes the surface and never where a tap lands.
class DiscoverScreenV2 extends StatefulWidget {
  const DiscoverScreenV2({super.key});

  @override
  State<DiscoverScreenV2> createState() => _DiscoverScreenV2State();
}

/// Header panel drop shadow — `#151718` at 16% (`0x29` = 41/255), blur 10,
/// y+1. Spec'd separately from the cards' lift: the header is the one opaque
/// surface on the page and sits over everything, so it carries a heavier
/// shadow than the glass panels under it.
const List<BoxShadow> _kHeaderShadow = [
  BoxShadow(color: Color(0x29151718), blurRadius: 10, offset: Offset(0, 1)),
];

/// Search field drop shadow — `#151718` at 8% (`0x14` = 20/255), blur 10, y+1,
/// spread 0. Lighter than [_kHeaderShadow] because the field sits ON the page,
/// not over it.
const List<BoxShadow> _kSearchShadow = [
  BoxShadow(
    color: Color(0x14151718),
    blurRadius: 10,
    offset: Offset(0, 1),
    spreadRadius: 0,
  ),
];

/// Search field rim.
const Color _kSearchStroke = Color(0xFF86C5FF);
const double _kSearchRadius = 12;

/// Height of the field itself, and of the sliver that pins it.
///
/// Fixed rather than intrinsic: a [SliverPersistentHeader] must declare its
/// extent BEFORE laying out its child, so the field's height has to be a
/// number this file owns, not something measured from the text inside it.
const double _kSearchFieldHeight = 52;

class _DiscoverScreenV2State extends State<DiscoverScreenV2> {
  final ScrollController _scrollController = ScrollController();

  /// Page side padding — the left/right margin every card, the search field
  /// and the header content share.
  static const double _gap = 10.0;

  /// Vertical separation between every section, everywhere on the page —
  /// header to search, search to first card, card to card, and around the
  /// in-flight order chips.
  ///
  /// Deliberately the same number as [_gap]: the page is one column of cards,
  /// so an even margin on all four sides is what makes it read as a grid
  /// rather than as a list that happens to be inset.
  static const double _sectionGap = 10.0;

  /// Clearance under the last card for the floating bottom nav.
  static const double _bottomInset = 100;

  static const Color _headerFill = Color(0xFFFFFFFF);

  /// The rails fetch against the user's lat/lng, so content is held behind a
  /// shimmer until the location attempt resolves — otherwise the first fetch
  /// on a cold start goes out with 0,0. Flips true once coords are available
  /// OR the attempt finishes, so a denial never blocks the page.
  bool _locationResolved = false;

  final _nearby = getOrPut(() => NearbyStoresController());

  @override
  void initState() {
    super.initState();

    _locationResolved = LocationService.hasUsableLocation;
    if (_locationResolved) {
      // Coordinates already in hand — fetch straight away.
      _nearby.fetchIfNeeded();
    } else {
      // MUST wait for the location, and the fetch MUST be chained to it.
      //
      // `NearbyStoresController.fetch()` bails on `lat == 0 && lng == 0` — it
      // sets `loaded` and returns without touching the network, because a
      // nearby query against 0,0 is meaningless. Calling it here unconditionally
      // therefore burned the one and only attempt on a cold start: the request
      // was never made, nothing re-triggered it when the coordinates landed,
      // and `map-service/api/nearby/discover` never appeared in the logs at
      // all. v1 dodged this by mounting its rail INSIDE the location gate, so
      // the rail's own initState only ran once there was a location.
      _resolveLocation();
    }

    _ensureProfileBannerLoaded();
    // A ride that was running when the app was killed goes back on screen.
    OngoingRideRestorer.restoreIfNeeded();
    _loadBusinessChatList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    await LocationService.ensureUsableLocation();
    if (!mounted) return;
    setState(() => _locationResolved = true);
    // Only NOW are there coordinates to query with — see the note in
    // initState. Freshness-guarded, so a cached set still paints without a
    // request; the attempt is what has to happen after the location, not the
    // network call.
    _nearby.fetchIfNeeded();
  }

  Future<void> _onRefresh() async {
    await LocationService.ensureUsableLocation();
    await _nearby.fetch();
    if (mounted) setState(() => _locationResolved = true);
  }

  /// "Recent Visited Stores" renders off the business chat list, and Discover
  /// is a landing tab — without this the card stays empty until the user opens
  /// Connect's Inquiry tab, which fires the same emit.
  void _loadBusinessChatList() {
    if (isGuestUser() || !Get.isRegistered<ChatViewController>()) return;
    Get.find<ChatViewController>().emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  void _ensureProfileBannerLoaded() {
    if (!isLoggedIn() || isGuestUser()) return;
    getOrPut(() => ViewPersonalDetailsController()).viewPersonalProfile();
    if (isBusinessUser() && Get.isRegistered<ViewBusinessDetailsController>()) {
      Get.find<ViewBusinessDetailsController>().viewBusinessProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The status bar is covered by an opaque strip pinned OUTSIDE the scroll
    // view (below), and the scroll view is inset by the same amount. That is
    // what lets the pinned search bar stop directly under the status bar
    // instead of sliding beneath it — a `SliverPersistentHeader` pins to the
    // viewport's top edge, so the viewport has to start below the inset.
    final double statusBar = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Bare, NOT wrapped: AppHomeBackground is itself a Positioned.fill
            // and has to land directly in this Stack.
            const AppHomeBackground(),
            Padding(
              padding: EdgeInsets.only(top: statusBar),
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                // No stretch overscroll: Android 12+ stretches by moving the
                // scroll content into its own layer, and the glass panels'
                // BackdropFilter can only sample what is inside its enclosing
                // layer — so every panel went dark for the length of a drag.
                child: ScrollConfiguration(
                  behavior: const DiscoverGlassScrollBehavior(),
                  // Every card on the page reads its fill / stroke / blur from
                  // here — the section cards and the shimmer alike.
                  child: DiscoverSurfaceTheme(
                    fill: DiscoverV2Card.fill,
                    border: DiscoverV2Card.stroke,
                    blur: DiscoverV2Card.blur,
                    radius: DiscoverV2Card.radius,
                    strokeWidth: DiscoverV2Card.strokeWidth,
                    shadow: DiscoverV2Card.shadow,
                    child: Obx(() {
                      // Read here, above the scroll view, so the gate can pick
                      // between two different SLIVER trees. An Obx cannot sit
                      // in a `slivers:` list — it is a box widget, and the
                      // viewport would reject it at layout.
                      final auth = Get.find<AuthController>();
                      auth.onboardingBucketsWatch;
                      final loading = auth.isInitialCategoriesLoading.value ||
                          !_locationResolved;

                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _header(context)),
                          // Pins under the status bar once the header above has
                          // scrolled away, taking the header's place.
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _PinnedSearchBar(
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteHelper.getGlobalSearchScreenRoute(),
                              ),
                            ),
                          ),
                          // What the user already has in flight, above the
                          // catalogue: a ready order that expires unseen is
                          // the most common bad ending in production.
                          //
                          // `padding: zero` on both, with the spacing applied
                          // out here instead. Left to themselves the two chips
                          // bring their OWN insets — (12,12,12,0) and
                          // (12,4,12,4) — which is where the odd seam came
                          // from: an order chip sat 18px below the search bar
                          // and only 4px above Quick Access, while every other
                          // seam on the page is [_sectionGap]. They now obey
                          // the same one rule.
                          const SliverToBoxAdapter(
                            child: OngoingBookingChip(padding: _chipPadding),
                          ),
                          const SliverToBoxAdapter(
                            child: PendingOrderChip(padding: _chipPadding),
                          ),
                          if (loading)
                            const SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                  _gap, _gap, _gap, _bottomInset),
                              sliver: SliverToBoxAdapter(
                                  child: _DiscoverV2Shimmer()),
                            )
                          else
                            _bodySliver(context),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            // Opaque strip behind the status bar. White, so it is seamless with
            // the header at rest and with the pinned search bar once the header
            // is gone — without it, glass cards would blur through under the
            // clock.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: statusBar, color: _headerFill),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  /// Location row and the profile banner on ONE white panel with a rounded
  /// bottom, exactly as drawn. The app background starts below it, at the
  /// search field — that break is what separates "who and where you are" from
  /// everything the page offers.
  ///
  /// No `ClipRRect` around it: a clip crops its child, and [_kHeaderShadow]
  /// declared inside one would be cropped away with everything past the
  /// rounded edge. A rounded [BoxDecoration] gives the same corners and lets
  /// the shadow paint outside them.
  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _headerFill,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: _kHeaderShadow,
      ),
      padding: EdgeInsets.fromLTRB(
        _gap,
        SizeConfig.size8,
        _gap,
        SizeConfig.size12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _locationRow(),
          SizedBox(height: SizeConfig.size10),
          // The blue "Create your account / ₹100 Cashback" card in the
          // design: the account's backend-driven marketing carousel, which
          // already renders the guest CTA, the go-live slide and the
          // referral art. Unchanged from v1.
          const DiscoverProfileBanner(),
        ],
      ),
    );
  }

  /// Location pill on the left, support on the right.
  ///
  /// The design draws a HEART in the trailing slot. It stays
  /// [HelpSupportAvatarButton], as on v1 and for v1's reason: that heart used
  /// to route to the CART despite being drawn as a wishlist, and the design
  /// does not say what it should open now. Same position, same size — only the
  /// glyph differs from the mock, and it goes somewhere real.
  Widget _locationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location,
                  color: AppColors.primaryColor, size: 19),
              SizedBox(width: SizeConfig.size6),
              Flexible(
                child: Obx(
                  () => CustomText(
                    [
                      LocationService.userCurrentAddress.value.subLocality,
                      LocationService.userCurrentAddress.value.city,
                    ].where((e) => e.isNotEmpty).join(', '),
                    fontSize: SizeConfig.medium,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const HelpSupportAvatarButton(alwaysShow: true),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────

  /// The page body as a real [SliverList] — one child per section, separated
  /// by exactly [_sectionGap].
  ///
  /// **The gap belongs to the section, not to the list.** Three of these
  /// sections can render nothing — the two near-me rails when there is nobody
  /// nearby, Recent Visited Stores when nothing is in flight — and each
  /// decides that from its own observable, at its own build time. Padding them
  /// from out here meant an absent rail still contributed its gap, so a user
  /// with no shops AND no services nearby saw a triple-height space where two
  /// invisible cards used to be.
  ///
  /// So a section now returns either a [SizedBox.shrink] (exactly zero — no
  /// padding, because the padding is inside the branch that renders) or a card
  /// already carrying its own trailing gap. Absent sections cost nothing.
  ///
  /// The last section deliberately has no trailing gap: the sliver's own
  /// bottom inset clears the floating bottom nav.
  Widget _bodySliver(BuildContext context) {
    final sections = <Widget>[
      _gapped(DiscoverV2Card(
        title: 'Quick Access',
        child: DiscoverQuickAccessGrid(items: _quickAccessItems(context)),
      )),
      _shopsNearMe(),
      _servicesNearMe(),
      const DiscoverRecentStoresCard(bottomGap: _sectionGap),
      _gapped(_referAndEarn()),
      const DiscoverQrPair(),
    ];

    return SliverPadding(
      // No TOP inset: the pinned search bar above already carries
      // [_sectionGap] below its field, and adding it here again is what put a
      // double gap between the search and the first card.
      padding: const EdgeInsets.fromLTRB(_gap, 0, _gap, _bottomInset),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => sections[i],
          childCount: sections.length,
          // MUST be false, and this is not a performance tweak.
          //
          // The default wraps every child in a [RepaintBoundary], and a
          // `BackdropFilter` can only sample what is painted inside its OWN
          // layer. Behind a repaint boundary there is nothing behind it to
          // sample, so each card silently lost its blur and rendered as flat
          // 60% white over the page — which is why the sections came out a
          // different colour from the comp, and why the background's wave
          // pattern read through them crisply instead of frosted.
          //
          // The cost is real but small here: this list is six fixed sections,
          // not a long feed, so nothing repaints often enough to need its own
          // layer.
          addRepaintBoundaries: false,
        ),
      ),
    );
  }

  /// A section plus the one gap that follows it.
  static Widget _gapped(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: _sectionGap),
        child: child,
      );

  /// The inset an in-flight chip is given, so it lines up and spaces exactly
  /// like a body section.
  ///
  /// Handed to the chip via its own `padding` rather than wrapped around it
  /// from out here, and that is not a style choice: both chips apply their
  /// padding INSIDE the branch that renders and return a bare
  /// [SizedBox.shrink] when they have nothing to show. A [SliverPadding] or a
  /// [Padding] on the outside contributes its full height around a zero-height
  /// child, so wrapping would leave a 14px hole on every page with no order in
  /// flight — the same bug the body sections had.
  static const EdgeInsets _chipPadding =
      EdgeInsets.fromLTRB(_gap, 0, _gap, _sectionGap);

  /// "Shops Near Me" — the businesses in the endpoint's `shops_near_me`
  /// section, flattened out of their categories.
  Widget _shopsNearMe() {
    return Obx(() {
      final businesses = _nearby.shopBusinesses;
      if (businesses.isEmpty) return const SizedBox.shrink();
      return _gapped(DiscoverV2Card(
        title: _nearby.shopsTitle.value,
        trailingLabel: 'View All',
        onTrailingTap: () => Get.to(() => const NearYouAllScreen()),
        child: DiscoverNearMeRail(items: businesses, onTap: _openBusiness),
      ));
    });
  }

  /// "Services Near Me" — same shape, off `services_near_me`.
  Widget _servicesNearMe() {
    return Obx(() {
      final businesses = _nearby.serviceBusinesses;
      if (businesses.isEmpty) return const SizedBox.shrink();
      return _gapped(DiscoverV2Card(
        title: _nearby.servicesTitle.value,
        trailingLabel: 'View All',
        onTrailingTap: () => Get.to(() => const NearYouAllScreen()),
        child: DiscoverNearMeRail(items: businesses, onTap: _openBusiness),
      ));
    });
  }

  /// Open one nearby business's profile.
  ///
  /// This routes properly now. The rails previously landed every tap on the
  /// generic nearby list because the payload named a category but not its
  /// VERTICAL, and every store screen in the app is chosen by that vertical —
  /// so routing on the id alone would have sent a third of the tiles to the
  /// wrong screen.
  ///
  /// Each item now carries its own `type` (`Grocery` / `Service` / `Product` /
  /// …), its owner's `account_type`, and both ids. [openVisitProfile] takes it
  /// from there, exactly as v1's `openNearbyEntry` does for a store card, so
  /// the two rails cannot disagree about where the same shop opens.
  void _openBusiness(NearbySectionItem item) {
    if (item.id.isEmpty && item.userId.isEmpty) return;
    openVisitProfile(
      // The OWNER's account type, which is what decides business-vs-individual
      // routing. Defaults to BUSINESS: every row in these two sections is a
      // business by construction, and an empty string would route nowhere.
      accountType:
          item.accountType.isNotEmpty ? item.accountType : AppConstants.business,
      typeOfBusiness: item.type.isEmpty ? null : item.type,
      categoryOfBusiness: item.categoryName.isEmpty ? null : item.categoryName,
      businessId: item.id.isEmpty ? null : item.id,
      userId: item.userId.isEmpty ? null : item.userId,
    );
  }

  Widget _referAndEarn() {
    return DiscoverV2Card(
      title: 'Refer & Earn Now',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The whole banner is the button — it says "Invite Friends", so the
        // tap does the inviting. It shares THIS artwork, not the account's
        // marketing card: the offer is in these pixels.
        onTap: () => shareDiscoverReferral(
          posterAsset: AppImageAssets.referEarnBanner,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1176 / 603,
            child: Image.asset(
              AppImageAssets.referEarnBanner,
              fit: BoxFit.cover,
              // A missing asset collapses the slot rather than leaving
              // Flutter's grey broken-image box mid-page.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick Access destinations ───────────────────────────────────────────

  /// The ten tiles, in the order the design draws them.
  ///
  /// Every destination is the SAME call v1's equivalent section makes — the
  /// same group sheets with the same sub-sections, the same folder sheets, the
  /// same screens. The launcher replaces how you REACH a section, never what
  /// the section is.
  List<QuickAccessItem> _quickAccessItems(BuildContext context) {
    return [
      QuickAccessItem(
        label: 'Ride',
        icon: DiscoverIcons.quickRide,
        onTap: () => Get.to(() => const RideHomeScreen()),
      ),
      QuickAccessItem(
        label: 'Grocery & Food',
        icon: DiscoverIcons.quickGroceryFood,
        onTap: () => _openGroceryAndFood(context),
      ),
      QuickAccessItem(
        label: 'Shopping',
        icon: DiscoverIcons.quickShopping,
        onTap: () => _openShopping(context),
      ),
      QuickAccessItem(
        label: 'Health Care',
        icon: DiscoverIcons.quickHealthCare,
        onTap: () => _openSection(
          context,
          AppStrings.healthcareServices.tr,
          const HealthServiceCardWidget(),
        ),
      ),
      QuickAccessItem(
        label: 'Properties',
        icon: DiscoverIcons.quickProperties,
        onTap: () => _openSection(
          context,
          AppStrings.rentAndProperties.tr,
          const RentalCardWidget(),
        ),
      ),
      QuickAccessItem(
        label: 'Services',
        icon: DiscoverIcons.quickServices,
        onTap: () => _openFindServices(context),
      ),
      QuickAccessItem(
        label: 'Automotive',
        icon: DiscoverIcons.quickAutomotive,
        onTap: () => _openSection(
          context,
          AppStrings.discoverAutomotiveAndServices.tr,
          const AutomotiveServiceCardWidget(),
        ),
      ),
      QuickAccessItem(
        label: 'Hotel/Stay',
        icon: DiscoverIcons.quickHotelStay,
        onTap: () => _openSection(
          context,
          AppStrings.bookYourStay.tr,
          const HotelStayServiceCard(),
        ),
      ),
      QuickAccessItem(
        label: 'Finance',
        icon: DiscoverIcons.quickFinance,
        onTap: () => Get.to(
          () => FinanceListingScreen(selectedCategory: financeCategories.first),
        ),
      ),
      QuickAccessItem(
        label: 'Career',
        icon: DiscoverIcons.quickCareer,
        onTap: () =>
            Get.to(() => isGuestUser() ? GuestDashBoardScreen() : JobsScreen()),
      ),
    ];
  }

  /// Open ONE section in the folder sheet, the way v1's single-section folders
  /// do. [DiscoverFolderScope] is what puts the section into sheet mode, where
  /// it renders every category instead of the handful its landing card caps at.
  void _openSection(BuildContext context, String title, Widget section) {
    DiscoverFolderSheet.show(
      context,
      title,
      (_) => DiscoverFolderScope(enabled: true, child: section),
    );
  }

  /// **Grocery & Food** — Grocery + Restaurants & Food + Home Made Food, the
  /// same three sub-sections v1's folder holds.
  void _openGroceryAndFood(BuildContext context) {
    final auth = Get.find<AuthController>();
    final groceries = auth.businessOnboardingGroceriesCategories;
    final foods = auth.businessOnboardingFoodsCategories;

    DiscoverGroupSheetV2.show(
      context,
      AppStrings.discoverGroceryAndFood.tr,
      [
        DiscoverGroupSubSection(
          title: AppStrings.groceryGeneralStore.tr,
          section: DiscoverGridSection(
            title: AppStrings.groceryGeneralStore.tr,
            items: groceries,
            getName: (item) => (item.name ?? '').tr,
            getIcon: (item) => item.imageUrl ?? '',
            onItemTap: (item) => Get.toNamed(
              RouteHelper.getGroceryStoresScreenRoute(),
              arguments: item.tagId,
            ),
          ),
        ),
        DiscoverGroupSubSection(
          title: AppStrings.restaurantFoodService.tr,
          section: DiscoverGridSection(
            title: AppStrings.restaurantFoodService.tr,
            items: foods,
            getName: (item) => (item.name ?? '').tr,
            getIcon: (item) => item.imageUrl ?? '',
            // Carries the tapped category through, so the restaurant screen
            // opens on that tab instead of on "All Food".
            onItemTap: (item) => Get.to(
              () => RestaurantNearMeScreen(initialCategoryTagId: item.tagId),
            ),
          ),
        ),
        DiscoverGroupSubSection(
          title: AppStrings.homeMadeFood.tr,
          section: DiscoverCategorySection(
            title: AppStrings.homeMadeFood.tr,
            items: discoverHomeMadeFoodCategories,
            onItemTap: (item) => Get.to(
              () => HmfCategoryDiscoverScreen(initialCategoryName: item.name),
            ),
          ),
        ),
      ],
    );
  }

  /// **Shopping** — Home Made Product + Shopping, as v1's folder holds them.
  void _openShopping(BuildContext context) {
    final products =
        Get.find<AuthController>().businessOnboardingProductsCategories;

    DiscoverGroupSheetV2.show(
      context,
      AppStrings.discoverShopping.tr,
      [
        DiscoverGroupSubSection(
          title: AppStrings.shoppingSales.tr,
          section: DiscoverGridSection(
            title: AppStrings.shoppingSales.tr,
            items: products,
            getName: (item) => item.name ?? '',
            getIcon: (item) => item.imageUrl ?? '',
            onItemTap: (item) => Get.to(
              () => ProductsStoreDiscoverScreen(
                productCategoryName: item.name,
                productCategory: item.tagId,
              ),
            ),
          ),
        ),
        DiscoverGroupSubSection(
          title: AppStrings.homeMadeProducts.tr,
          section: const HomeMadeProductAndServiceWidget(),
        ),
      ],
    );
  }

  /// **Services** — Home Services + Business Services, as v1's folder holds
  /// them.
  void _openFindServices(BuildContext context) {
    DiscoverGroupSheetV2.show(
      context,
      AppStrings.findServices.tr,
      [
        DiscoverGroupSubSection(
          title: AppStrings.homeServices.tr,
          section: DiscoverCategorySection(
            title: AppStrings.homeServices.tr,
            items: discoverHomeServicesCategories,
            onItemTap: (item) => Get.to(
              () => HomeServiceDiscoverScreenV2(initialCategoryName: item.name),
            ),
          ),
        ),
        DiscoverGroupSubSection(
          title: AppStrings.discoverBusinessServices.tr,
          section: const FindServiceCardWidget(),
        ),
      ],
    );
  }
}

/// Placeholder while location and the first category load resolve — the same
/// stack of cards the real page draws, so nothing jumps when content lands.
class _DiscoverV2Shimmer extends StatelessWidget {
  const _DiscoverV2Shimmer();

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: DiscoverV2Card.fill,
            borderRadius: BorderRadius.circular(DiscoverV2Card.radius),
            border: Border.all(color: DiscoverV2Card.stroke),
            boxShadow: DiscoverV2Card.shadow,
          ),
        );

    return Column(
      children: [
        // Quick Access: two rows of tiles plus the heading.
        block(210),
        // The two near-me rails.
        block(140),
        block(140),
        // Recent visited stores.
        block(180),
      ],
    );
  }
}

/// The search field, pinned.
///
/// At rest it is a field sitting on the page background, directly under the
/// header. Once the header has scrolled away it stops under the status bar and
/// TAKES THE HEADER'S PLACE — so on pin it grows an opaque white ground and the
/// header's own shadow, and the page scrolls beneath it.
///
/// `overlapsContent` is what drives that switch. For a pinned header whose min
/// and max extents are equal, `shrinkOffset` never moves, so it cannot be used
/// to detect the pin; `overlapsContent` is true exactly when content is
/// scrolling underneath, which is the same moment.
class _PinnedSearchBar extends SliverPersistentHeaderDelegate {
  const _PinnedSearchBar({required this.onTap});

  final VoidCallback onTap;

  /// Gap above and below the field at rest, so it clears the header and the
  /// first card by the page's own section gap.
  static const double _pad = _DiscoverScreenV2State._sectionGap;

  /// How much of the top gap is given up as the bar pins.
  ///
  /// This is what makes the pin DETECTABLE. `overlapsContent` is not the
  /// signal it looks like — it reports whether a sliver is overlapped by a
  /// PRECEDING sliver (the NestedScrollView case), and a pinned header never
  /// sets it for itself, so it is false the whole way down. And `shrinkOffset`
  /// is pinned at 0 whenever `minExtent == maxExtent`, because it is defined as
  /// `min(scrollOffset, maxExtent - minExtent)`.
  ///
  /// Giving the bar a real collapse range fixes both: `shrinkOffset` now runs
  /// 0 → [_collapse] exactly as the bar reaches the top, which drives the
  /// ground in and the top gap out together.
  static const double _collapse = _pad;

  static const double _maxExtent = _kSearchFieldHeight + (_pad * 2);
  static const double _minExtent = _maxExtent - _collapse;

  @override
  double get minExtent => _minExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 0 at rest, 1 once fully pinned.
    final double t = (shrinkOffset / _collapse).clamp(0.0, 1.0);

    final Widget bar = Padding(
      padding: EdgeInsets.fromLTRB(
        _DiscoverScreenV2State._gap,
        // The top gap is what collapses; the bottom one stays, so the field
        // keeps its clearance from the content sliding under it.
        _pad - (_collapse * t),
        _DiscoverScreenV2State._gap,
        _pad,
      ),
      child: _field(context),
    );

    // Nothing behind the bar but the page background yet — no ground needed,
    // and skipping the BackdropFilter entirely while it would be invisible
    // avoids a `saveLayer` on every frame of an ordinary scroll.
    if (t == 0) return bar;

    // Pinned. The ground is GLASS, not the opaque white the header uses: the
    // page is scrolling underneath and the whole point of the effect is that
    // you can see it go. Fill comes from [DiscoverSurfaceTheme] so the bar can
    // never drift from the panels sliding under it.
    //
    // ClipRect, not ClipRRect: the pinned bar spans the full width and is
    // square-cornered. The clip is not optional — a BackdropFilter with no clip
    // blurs the entire layer beneath it, not just its own bounds.
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          // The section surface's own sigma, scaled in with the collapse, so
          // the pinned bar frosts to exactly the depth the cards do.
          sigmaX: DiscoverSurfaceTheme.blurOf(context) * t,
          sigmaY: DiscoverSurfaceTheme.blurOf(context) * t,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Faded in with the collapse so the bar does not pop a ground on
            // the first pixel of scroll.
            color: DiscoverSurfaceTheme.fillOf(context)
                .withValues(alpha: DiscoverSurfaceTheme.fillOf(context).a * t),
            boxShadow: t == 1 ? _kHeaderShadow : null,
          ),
          child: bar,
        ),
      ),
    );
  }

  Widget _field(BuildContext context) {
    return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: _kSearchFieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kSearchRadius),
              border: Border.all(color: _kSearchStroke),
              boxShadow: _kSearchShadow,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  // The bar is built from constants and one callback, so a rebuild can never
  // change what it renders.
  @override
  bool shouldRebuild(_PinnedSearchBar oldDelegate) => false;
}
