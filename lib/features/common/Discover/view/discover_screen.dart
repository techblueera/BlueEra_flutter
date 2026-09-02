import 'dart:ui' as ui;

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/ongoing_ride_restorer.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_category_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/near_you_all_screen.dart';
import 'package:BlueEra/features/common/Discover/view/profession_consultant_discover_entry_screen.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_discover_entry_screen.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/view/v2/home_service_discover_screen_v2.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_banner_row_v2.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_group_sheet_v2.dart';
import 'package:BlueEra/features/common/Discover/view/widget/automotive_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/education_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/find_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/health_service_card_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/home_made_product_service_widget.dart';
import 'package:BlueEra/features/common/Discover/view/widget/hotel_stay_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rental_card_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/features/common/Discover/widget/nearest_stores_section.dart';
import 'package:BlueEra/features/common/Discover/widget/ongoing_booking_chip.dart';
import 'package:BlueEra/features/common/Discover/widget/pending_order_chip.dart';
import 'package:BlueEra/features/common/Discover/widget/recent_orders_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/help_support/widget/help_support_avatar_button.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'package:BlueEra/features/loan/view/quick_loan_apply_screen.dart';
import 'package:BlueEra/features/common/qr_code/view/emergency_qr_screen.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_widget.dart';
import 'package:BlueEra/features/me/food/view/customer/restaurant_near_me_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/products_store_discover_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/features/ride_booking/view/ride_home_screen.dart';
import 'package:BlueEra/widgets/app_home_background.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Discover — the layout in `assets/Discover.png`.
///
/// The page is a fixed alternation: a full-width CHIP ROW, then a pair of
/// FOLDER TILES, repeated. Every tile and chip mounts the same section widget
/// the page it replaced did, so every category id, every piece of artwork and
/// every destination is unchanged. What differs is which sections are browsed
/// by name and which by picture, and that three pairs of related sections
/// share one folder instead of holding four separate ones:
///
///   * **Grocery & Food** — Grocery, Restaurants & Food, Home Made Food
///   * **Shopping** — Home Made Product, Shopping
///   * **Find Services** — Home Services, Business Services
///
/// This is the ONLY Discover — the page it was built alongside has been
/// deleted and the bottom nav mounts this one. It was called `DiscoverScreenV2`
/// while both existed; the suffix is gone now that there is nothing to
/// distinguish it from.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final EmergencyProfileController _emergencyController;

  /// Owned by the page rather than left implicit so the scroll position is
  /// available to anything on it that needs one.
  final ScrollController _scrollController = ScrollController();

  /// Gap between folders, across a row and between rows — and the page's own
  /// side padding, so a folder edge lines up with the chip row above it.
  static const double _gap = 12.0;

  /// The section-container surface: white at 60% behind a solid white rim.
  ///
  /// **Alpha comes FIRST in a Dart colour literal.** The spec is written the
  /// CSS way — a colour plus a separate opacity — so `#ffffff` at 60% is
  /// `0x99FFFFFF`, not `0xFFFFFF99`. Getting this backwards is what produced a
  /// near-transparent blue-grey on an earlier pass at this screen.
  ///
  /// A white wash rather than the dark ink in [kDiscoverGlassFill]: that ink
  /// sits a step darker than the pale-blue page so a panel gains an edge, and
  /// it is still what every OTHER Discover page paints. This page is specified
  /// the other way round — lighter than the background, with the rim doing the
  /// separating — which is why these values are handed down as a scope instead
  /// of being written into `discover_glass.dart`. [DiscoverFolderTile] is
  /// shared, so changing the constants there would repaint pages this spec
  /// does not cover.
  ///
  /// Every section container on this page reads all five from
  /// [DiscoverSurfaceTheme], so they move the banner rows and the folder tiles
  /// together.
  static const Color _cardFill = Color(0x99FFFFFF); // #ffffff @ 60%
  static const Color _cardStroke = Color(0xFFFFFFFF); // #ffffff @ 100%
  static const double _cardStrokeWidth = 1.5;
  static const double _cardBlur = 5;
  static const double _cardRadius = 20;

  /// Drop shadow: y+1, blur 10, `#194557` at 10% (`0x1A` = 26/255).
  ///
  /// One shadow, not the two in [kDiscoverGlassShadow] — the spec gives a
  /// single soft lift, and stacking the shared pair under it would double the
  /// darkness at the panel's edge.
  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x1A194557),
      blurRadius: 10,
      offset: Offset(0, 1),
    ),
  ];

  /// The header panel: solid white, blurred 4.
  static const Color _headerFill = Color(0xFFFFFFFF);
  static const double _headerBlur = 4;

  /// Rim for the search field. Grey, not [_cardStroke]: the field is the one
  /// bordered thing on this page sitting on the WHITE header rather than on the
  /// page background, so the section cards' white stroke would be invisible on
  /// it.
  static const Color _searchFieldStroke = Color(0xFFDDE2EE);

  /// The sections fetch against the user's lat/lng, so the content is held
  /// behind a shimmer until the location attempt resolves — otherwise the
  /// first fetch on a cold start goes out with 0,0. Flips true once coords are
  /// available OR the attempt finishes, so a denial never blocks the page.
  bool _locationResolved = false;

  @override
  void initState() {
    super.initState();
    _emergencyController = getOrPut(() => EmergencyProfileController());

    _locationResolved = LocationService.hasUsableLocation;
    if (!_locationResolved) _resolveLocation();

    _ensureProfileBannerLoaded();
    // A ride that was running when the app was killed goes back on screen — the
    // ongoing chip below the search bar is there on a cold start too.
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
    if (mounted) setState(() => _locationResolved = true);
  }

  Future<void> _onRefresh() async {
    await LocationService.ensureUsableLocation();
    await getOrPut(() => NearbyStoresController()).fetch();
    if (mounted) setState(() => _locationResolved = true);
  }

  /// "Orders in 12 Hrs." renders off the business chat list, and Discover is a
  /// landing tab — without this the rail stays empty until the user opens
  /// Connect's Inquiry tab, which fires the same emit. Same event and payload,
  /// so the two cannot drift.
  void _loadBusinessChatList() {
    if (isGuestUser() || !Get.isRegistered<ChatViewController>()) return;
    Get.find<ChatViewController>().emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  /// The header banner is the account's backend-generated marketing card, so
  /// the profile has to be in memory. Both fetches are cheap to repeat —
  /// personal is cache-first, business coalesces concurrent callers — which is
  /// why this can run on every mount.
  void _ensureProfileBannerLoaded() {
    if (!isLoggedIn() || isGuestUser()) return;
    getOrPut(() => ViewPersonalDetailsController()).viewPersonalProfile();
    if (isBusinessUser() && Get.isRegistered<ViewBusinessDetailsController>()) {
      Get.find<ViewBusinessDetailsController>().viewBusinessProfile();
    }
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
        // Transparent so the app background shows through every gap between
        // the glass panels.
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Bare, NOT wrapped: AppHomeBackground is itself a Positioned.fill
            // and has to land directly in this Stack.
            const AppHomeBackground(),
            RefreshIndicator(
              onRefresh: _onRefresh,
              // No stretch overscroll: Android 12+ stretches by moving the
              // scroll content into its own layer, and the glass panels'
              // BackdropFilter can only sample what is inside its enclosing
              // layer — so every panel went dark for the length of a drag.
              child: ScrollConfiguration(
                behavior: const DiscoverGlassScrollBehavior(),
                // Every card on the page reads its fill / stroke / blur from
                // here, folder tiles included.
                child: DiscoverSurfaceTheme(
                  fill: _cardFill,
                  border: _cardStroke,
                  blur: _cardBlur,
                  radius: _cardRadius,
                  strokeWidth: _cardStrokeWidth,
                  shadow: _cardShadow,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _header(context)),
                      // The promo used to sit HERE, directly under the search
                      // bar, as a full-width card — the first thing on the page,
                      // ahead of the user's own in-flight rides and orders. It
                      // now runs as two slim strips BETWEEN the catalogue
                      // sections instead (see [_promoStrip]), so what the user
                      // came for leads the page and the promo reads as a break
                      // between sections rather than as the headline.
                      const SliverToBoxAdapter(child: OngoingBookingChip()),
                      // Orders waiting on the customer, with their clocks.
                      // Directly under the ride chip because they answer the
                      // same question — "what of mine is in flight" — and a
                      // ready order that expires unseen is the single most
                      // common bad ending in production (guide §12).
                      const SliverToBoxAdapter(child: PendingOrderChip()),
                      SliverToBoxAdapter(
                          child: SizedBox(height: SizeConfig.size12)),
                      const SliverToBoxAdapter(child: RecentOrdersSection()),
                      _sectionsSliver(),
                      _footerSliver(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — location row, profile banner, search bar
  // ---------------------------------------------------------------------------

  /// Location row, banner and search bar on ONE white panel — the design keeps
  /// the whole header on a solid ground and starts the app background at the
  /// first chip row, which is what separates "who and where you are" from the
  /// catalogue below it.
  Widget _header(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: _headerBlur, sigmaY: _headerBlur),
        child: Container(
          color: _headerFill,
          padding: EdgeInsets.fromLTRB(
            _gap,
            MediaQuery.of(context).padding.top + SizeConfig.size8,
            _gap,
            SizeConfig.size12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _locationRow(),
              SizedBox(height: SizeConfig.size10),
              const DiscoverProfileBanner(),
              SizedBox(height: SizeConfig.size10),
              _searchBar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Location pill on the left, support on the right.
  ///
  /// The design draws a heart here. It stays [HelpSupportAvatarButton], as in
  /// v1: that heart used to route to the CART despite being drawn as a
  /// wishlist, and help is what a stuck user looks for at the top of a page.
  /// The button hides itself when support has nothing to offer, so the row
  /// simply loses its trailing chip in that case.
  Widget _locationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          fit: FlexFit.loose,
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
        // alwaysShow: the button hides itself until the server-tailored
        // question list arrives, which is why the header could look as though
        // it had lost its support entry point entirely. It stays put now and
        // fetches on tap.
        const HelpSupportAvatarButton(alwaysShow: true),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pushNamed(
        context,
        RouteHelper.getGlobalSearchScreenRoute(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          // NOT [_cardStroke]: the section cards below are stroked pure white
          // because they sit on the page background, but this field sits on the
          // white HEADER panel, where a white rim leaves it with no edge at
          // all. Its own grey, deliberately — the two are on different grounds
          // and cannot share a stroke.
          border: Border.all(color: _searchFieldStroke),
          boxShadow: _cardShadow,
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
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  /// Held behind a shimmer until BOTH the location attempt and the first
  /// category load have resolved — the sections read the onboarding buckets in
  /// their own build methods, so this subscribes to them here to repaint when
  /// the silent refresh lands.
  Widget _sectionsSliver() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final auth = Get.find<AuthController>();
        auth.onboardingBucketsWatch;
        if (auth.isInitialCategoriesLoading.value || !_locationResolved) {
          return const _DiscoverShimmer();
        }
        return _sectionsColumn(context);
      }),
    );
  }

  /// The page body, in the design's exact order.
  Widget _sectionsColumn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _gap),
      child: Column(
        children: [
          // "Near You" — self-managing: it carries its own card and spacing
          // when it has data and collapses to nothing when it doesn't.
          NearestStoresSection(
            onViewAll: () => Get.to(() => const NearYouAllScreen()),
          ),
          _bannerRow(_transportRow()),
          _folderRow(_groceryAndFoodFolder(context), _shoppingFolder(context)),
          _bannerRow(_homeServicesRow()),
          _folderRow(_findServicesFolder(context), _healthcareFolder()),
          // First promo strip — a third of the way down, after the page has
          // already given the user four sections.
          _promoStrip(0),
          _bannerRow(_professionalRow()),
          _folderRow(_stayFolder(), _rentFolder()),
          _bannerRow(_financialRow()),
          // Second strip, two thirds down. Spacing them this far apart is the
          // point: two strips a section apart would read as one banner block.
          _promoStrip(1),
          _folderRow(_automotiveFolder(), _educationFolder()),
          _bannerRow(_jobsRow()),
        ],
      ),
    );
  }

  Widget _bannerRow(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: _gap),
        child: child,
      );

  /// A promo ad between two sections — the slim 320x50 `banner_strip`, the same
  /// shape the "Me" tabs carry, not the full-width `home_hero` card this page
  /// used to open with.
  ///
  /// The strip is a different PLACEMENT, not the card scaled down: its artwork
  /// is drawn at 6.4:1 and served under its own key, so it stays legible at a
  /// height a card cropped this thin could never hold its message at. That is
  /// also what makes it sit right here — at strip height it reads as a divider
  /// between sections rather than as a section of its own.
  ///
  /// [index] picks the creative, so the page's two strips are never the same
  /// image and neither reshuffles as the list repaints. Collapses to nothing
  /// when the ad bundle has no strip creative, leaving no gap in the column.
  Widget _promoStrip(int index) => QurekaPromoBanner(
        strip: true,
        creativeIndex: index,
        margin: const EdgeInsets.only(bottom: _gap),
      );

  /// Two folders side by side. A folder sizes itself, so a row whose second
  /// slot is empty keeps its half-width rather than stretching.
  Widget _folderRow(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: _gap),
          Expanded(child: right),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chip rows
  // ---------------------------------------------------------------------------

  Widget _transportRow() {
    return DiscoverBannerRowV2(
      title: AppStrings.bookYourTransport.tr,
      leadingIcon: AppImageAssets.gpsDiscover,
      // Every transport type opens the same ride screen — the type is picked
      // there, on the map, next to the fare. Same as v1's folder tap.
      chips: [
        for (final item in transportItemsCategories)
          DiscoverBannerChip(
            label: item.name,
            icon: item.icon ?? '',
            onTap: _openRide,
          ),
      ],
      onTap: _openRide,
      // ONE line, as drawn: the transport types are five short words and the
      // design keeps the whole row to a single box. Anything past the line
      // collapses into "More", which opens the same ride screen the chips do.
      maxLines: 1,
    );
  }

  void _openRide() => Get.to(() => const RideHomeScreen());

  Widget _homeServicesRow() {
    final categories =
        Get.find<AuthController>().individualOnboardingSkillWorkList;
    // The flow is location-first: every chip enters the same entry screen (map
    // + "Where you Want?" + profession grid), where the user picks the place
    // and the trade. Mirrors BookHomeServiceWidget.
    void open() => Get.to(() => SelfProfessionDiscoverEntryScreen(
          selfEmployedCategories: categories,
        ));
    return DiscoverBannerRowV2(
      title: AppStrings.bookHomeServices.tr,
      leadingIcon: AppImageAssets.servicesDiscover,
      chips: [
        for (final item in categories)
          DiscoverBannerChip(
            label: _trimHomePrefix(item.name ?? ''),
            icon: item.imageUrl ?? '',
            onTap: open,
          ),
      ],
      onTap: open,
      // Two lines, then More — the trades are many and their names are long.
      maxLines: 2,
    );
  }

  /// "Home Electrician" reads as "Electrician" on a chip — the row is already
  /// titled "Book Your Home Services", so the prefix is said twice.
  String _trimHomePrefix(String raw) {
    if (raw.toLowerCase().startsWith('home ')) return raw.substring(5).trim();
    return raw;
  }

  Widget _professionalRow() {
    final categories =
        Get.find<AuthController>().individualOnboardingConsultationList;
    void open() => Get.to(() => ProfessionConsultantDiscoverEntryScreen(
          professionalConsultantCategories: categories,
        ));
    return DiscoverBannerRowV2(
      title: AppStrings.professionalsConsultant.tr,
      leadingIcon: AppImageAssets.professionalsDiscover,
      chips: [
        for (final item in categories)
          DiscoverBannerChip(
            label: item.name ?? '',
            icon: item.imageUrl ?? '',
            onTap: open,
          ),
      ],
      onTap: open,
      // Two lines, then More.
      maxLines: 2,
    );
  }

  Widget _financialRow() {
    final api = Get.find<AuthController>();
    return Obx(() {
      // Read the RxList in the builder body — `getIcon`-style callbacks run
      // outside Obx's reactive scope and would register no dependency.
      final apiCategories =
          api.businessOnboardingFinancialSectorsCategories.toList();
      return DiscoverBannerRowV2(
        title: AppStrings.financialBanksAndLoans.tr,
        leadingIcon: AppImageAssets.financialDiscover,
        chips: [
          for (final item in financeCategories)
            DiscoverBannerChip(
              label: item.name,
              icon: apiCategoryIcon(apiCategories, item.slugId) ??
                  (item.icon ?? ''),
              onTap: () =>
                  Get.to(() => FinanceListingScreen(selectedCategory: item)),
            ),
        ],
        onTap: () => Get.to(
          () => FinanceListingScreen(selectedCategory: financeCategories.first),
        ),
        // One line, then More — the CTA under it needs the room.
        maxLines: 1,
        ctaHint: AppStrings.needMoney.tr,
        ctaLabel: AppStrings.quickApplyForLoan.tr,
        // The CTA now does what it says: it opens the loan APPLICATION form
        // rather than a list of lenders to go and read. The chips above and
        // the row itself still browse the finance listings, so nothing lost
        // the way into them.
        onCta: openQuickLoanApply,
      );
    });
  }

  Widget _jobsRow() {
    void openJobs() =>
        Get.to(() => isGuestUser() ? GuestDashBoardScreen() : JobsScreen());
    return DiscoverBannerRowV2(
      title: AppStrings.jobNearMe.tr,
      leadingIcon: AppImageAssets.jobsDiscover,
      chips: [
        for (final item in jobCategories)
          DiscoverBannerChip(
            label: item.name,
            icon: item.icon ?? '',
            onTap: openJobs,
          ),
      ],
      onTap: openJobs,
      // One line, then More — the CTA under it needs the room.
      maxLines: 1,
      ctaLabel: AppStrings.createResume.tr,
      onCta: openJobs,
    );
  }

  // ---------------------------------------------------------------------------
  // Folders
  // ---------------------------------------------------------------------------

  /// A folder whose sheet holds ONE section — the tile and the sheet both come
  /// from the section widget itself, exactly as on v1.
  ///
  /// [title] renames only the TILE, for the two sections whose full names run
  /// past a half-width caption and ellipsise. The sheet still opens under the
  /// section's own name.
  Widget _singleFolder(Widget section, {String? title}) => DiscoverFolderScope(
        enabled: true,
        child: DiscoverFolderHost(section: section, title: title),
      );

  Widget _healthcareFolder() => _singleFolder(const HealthServiceCardWidget());

  Widget _stayFolder() => _singleFolder(const HotelStayServiceCard());

  Widget _rentFolder() => _singleFolder(const RentalCardWidget());

  Widget _automotiveFolder() => _singleFolder(
        const AutomotiveServiceCardWidget(),
        title: AppStrings.discoverAutomotiveAndServices.tr,
      );

  Widget _educationFolder() => _singleFolder(
        const EducationServiceCardWidget(),
        title: AppStrings.discoverEducationAndTraining.tr,
      );

  /// **Grocery & Food** — Grocery + Restaurants & Food + Home Made Food behind
  /// one folder, per `assets/img_3.png`.
  ///
  /// The preview is four icons, one per idea the folder holds, rather than the
  /// first four of the merged list: taking the head of the list would preview
  /// four kinds of grocery store and say nothing about the restaurants or the
  /// tiffin services also inside.
  Widget _groceryAndFoodFolder(BuildContext context) {
    final auth = Get.find<AuthController>();
    final groceries = auth.businessOnboardingGroceriesCategories;
    final foods = auth.businessOnboardingFoodsCategories;

    return DiscoverFolderTile(
      title: AppStrings.discoverGroceryAndFood.tr,
      iconPaths: [
        if (groceries.isNotEmpty) groceries.first.imageUrl ?? '',
        if (foods.isNotEmpty) foods.first.imageUrl ?? '',
        discoverHomeMadeFoodCategories.first.icon ?? '',
        if (foods.length > 1) foods[1].imageUrl ?? '',
      ],
      onTap: () => DiscoverGroupSheetV2.show(
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
      ),
    );
  }

  /// **Shopping** — Home Made Product + Shopping in one folder.
  Widget _shoppingFolder(BuildContext context) {
    final products =
        Get.find<AuthController>().businessOnboardingProductsCategories;

    return DiscoverFolderTile(
      title: AppStrings.discoverShopping.tr,
      // More than four, deliberately: the last slot becomes a mini 2x2 — the
      // "there is more inside" cue the design draws on this tile.
      iconPaths: [
        for (final item in products.take(3)) item.imageUrl ?? '',
        for (final item in discoverHomeMadeProductCategories.take(4))
          item.icon ?? '',
      ],
      onTap: () => DiscoverGroupSheetV2.show(
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
      ),
    );
  }

  /// **Find Services** — Home Services + Business Services in one folder.
  Widget _findServicesFolder(BuildContext context) {
    final services =
        Get.find<AuthController>().businessOnboardingServicesCategories;

    return DiscoverFolderTile(
      title: AppStrings.findServices.tr,
      iconPaths: [
        for (final item in discoverHomeServicesCategories.take(3))
          item.icon ?? '',
        for (final item in services.take(4)) item.imageUrl ?? '',
      ],
      onTap: () => DiscoverGroupSheetV2.show(
        context,
        AppStrings.findServices.tr,
        [
          DiscoverGroupSubSection(
            title: AppStrings.homeServices.tr,
            section: DiscoverCategorySection(
              title: AppStrings.homeServices.tr,
              items: discoverHomeServicesCategories,
              onItemTap: (item) => Get.to(
                () =>
                    HomeServiceDiscoverScreenV2(initialCategoryName: item.name),
              ),
            ),
          ),
          DiscoverGroupSubSection(
            title: AppStrings.discoverBusinessServices.tr,
            // The existing section, unchanged: in sheet scope it renders every
            // category (not the eight its landing card caps at) and each tile
            // carries its own tagId into the listing.
            section: const FindServiceCardWidget(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer — the banner again, then the QR cards
  // ---------------------------------------------------------------------------

  Widget _footerSliver() {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            // Refer & Earn — a plain static banner, NOT the header's
            Padding(
              padding: const EdgeInsets.fromLTRB(_gap, 0, _gap, _gap),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // The whole banner is the button — it says "Invite Friends", so
                // the tap does the inviting. It shares THIS artwork, not the
                // account's profile card: the offer ("Earn up to ₹1000") is in
                // these pixels, and attaching a profile poster instead would
                // send a picture the user never saw. The referral code and
                // links ride in the message text regardless.
                onTap: () => shareDiscoverReferral(
                  posterAsset: AppImageAssets.referEarnBanner,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
            ),
            // The QR is deliberately PLAIN: no scroll-linked scale, no width
            // override — exactly the card the rest of the app renders. Growing
            // it towards the middle of the screen and stretching it to the page
            // width were both tried and dropped.
            EmergencyQrWidget(key: const ValueKey('emergency_qr_v2')),
            Obx(() {
              if (!_emergencyController.hasEmergencyData.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  SizedBox(height: SizeConfig.size8),
                  QrDesignOptionsWidget(
                    userName: _emergencyController.fullName.value,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Placeholder while location and the first category load resolve — the same
/// alternation the real page uses, so nothing jumps when the content lands.
class _DiscoverShimmer extends StatelessWidget {
  const _DiscoverShimmer();

  @override
  Widget build(BuildContext context) {
    // The page's own surface, read from the scope rather than the constants:
    // the placeholder has to be the same colour and radius as the cards that
    // replace it, or the page changes shade the moment the content lands.
    final fill = DiscoverSurfaceTheme.fillOf(context);
    final border = DiscoverSurfaceTheme.borderOf(context);
    final strokeWidth = DiscoverSurfaceTheme.strokeWidthOf(context);
    final radius = DiscoverSurfaceTheme.radiusOf(context);
    final shadow = DiscoverSurfaceTheme.shadowOf(context);

    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: strokeWidth),
            boxShadow: shadow,
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A folder row is two squares plus the gap between them.
          final folderRow = (constraints.maxWidth - 14) / 2 + 26;
          return Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                block(96),
                block(folderRow),
              ],
            ],
          );
        },
      ),
    );
  }
}
