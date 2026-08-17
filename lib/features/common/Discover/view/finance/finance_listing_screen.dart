import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FinanceListingScreen extends StatefulWidget {
  final OnboardingCategoryModel? selectedCategory;

  const FinanceListingScreen({super.key, this.selectedCategory});

  @override
  State<FinanceListingScreen> createState() => _FinanceListingScreenState();
}

class _FinanceListingScreenState extends State<FinanceListingScreen> {
  final _controller = getOrPut(() => FinanceDiscoverController());

  /// The one scroll position on this screen — see [buildFinanceListSlivers] for
  /// why there is only one.
  final _scrollController = ScrollController();

  /// A plain field, not an `Rx`. The screen already calls `setState` when the
  /// category changes, and the value was being read outside any `Obx` — so the
  /// reactivity was doing nothing except making it look as though a rebuild were
  /// handled somewhere else.
  OnboardingCategoryModel? _selectedCategory;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/business-finance-employment-female-successful-entrepreneurs-concept_1258-93733.jpg?w=1380",
    "https://img.freepik.com/free-photo/financial-concept-with-wooden-cubes-calculator-coins_176474-8187.jpg?w=1380",
    "https://img.freepik.com/free-photo/arrangement-finance-elements-diagram_23-2148793749.jpg?w=1380",
  ];

  String get _slugId => _selectedCategory?.slugId ?? '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory ?? financeCategories.first;
    // The fetch moved up here with the scroll view. It used to live in the list
    // widget's initState, which is also what made a category switch refetch —
    // that still happens, explicitly, in [_onCategoryTap].
    _controller.fetchInitial(_slugId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Load-more, read off the only scroll position on the screen.
  ///
  /// Previously a `NotificationListener` under a `NestedScrollView`, which
  /// received the header's notifications as well as the list's and could not
  /// tell them apart. `fetchMore` still guards on its own loaders, so a burst of
  /// scroll events cannot stack requests.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _controller.fetchMore();
    }
  }

  void _onCategoryTap(StickyCategory item) {
    if (item.id == _selectedCategory?.slugId) return;
    setState(() {
      _selectedCategory =
          financeCategories.firstWhere((c) => c.slugId == item.id);
    });
    // A different category is a different result set, so the viewport goes back
    // to the top with it — staying at the old offset would drop the user into
    // the middle of a list they have not seen, or past the end of a shorter one.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _controller.fetchInitial(_slugId);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = financeCategories
        .map((c) => StickyCategory(
              id: c.slugId,
              name: c.name,
              imageUrl: c.icon,
            ))
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // ## The whole page is ONE scroll view with THREE slivers
        //
        // Banner, pinned category header, list. That count never changes: the
        // list is a single `SliverList.builder` and a page landing only grows its
        // `itemCount` — see [financeListSliver].
        //
        // No `RefreshIndicator`. It fires on a leading-edge overscroll, which is
        // also what a scroll correction looks like, and its `onRefresh` reloaded
        // page 1 — so an accidental trigger put the reader back at the top with
        // the first ten results. Re-tapping the category in the header is the
        // deliberate way to reload, and it is the only path that clears the list.
        body: Obx(() {
          // Touched explicitly so this rebuilds on any of them, whichever branch
          // [financeListSliver] takes — an Obx only subscribes to what its LAST
          // build actually read.
          _controller.profiles.length;
          _controller.isLoading.value;
          _controller.isLoadingMore.value;
          _controller.error.value;

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
                    statusBarHeight: statusBarHeight,
                    backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
                    bottomBorderSide: const BorderSide(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    // The header paints a search bar; this is what it opens —
                    // the shared store search, scoped to this vertical by its
                    // StoreSearchConfig. Tapping a result opens that profile.
                    onSearchTap: () => Get.to(() =>
                        StoreSearchScreen(config: StoreSearchConfig.finance())),
                    categories: stickyCategories,
                    selectedId: _selectedCategory?.slugId,
                    onCategoryTap: _onCategoryTap,
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              financeListSliver(_controller),
            ],
          );
        }),
      ),
    );
  }
}

/// Card surface for the finance tile — matches the two-up school listing
/// (`AllEducationServiceScreen.selfProfessionCard`) and the service tile
/// (`ServiceBusinessCard`). Plain white with a hairline border so cover
/// imagery reads cleanly when two tiles sit side by side.
const Color _kCardBorder = Color(0xFFE9EBF0);
const Color _kCardDivider = Color(0xFFEDEFF3);

/// Ad cadence: one full-width slot after every 10 cards, and never after the
/// last row. Matches the grid cadence the shared inserter uses.
const int _kAdAfterEveryCards = 10;

/// The finance directory as **exactly one sliver**, for the single
/// [CustomScrollView] on [FinanceListingScreen].
///
/// ## Why one sliver, and why that is the whole point
///
/// Three structures were tried here before this one, and each broke the scroll
/// position in its own way:
///
///  1. A `CustomScrollView` inside a `NestedScrollView` body — two coordinated
///     positions, and the inner one re-created whenever its `Scrollable` was
///     rebuilt, which reset it to zero.
///  2. One `CustomScrollView`, but with the cards split into `SliverMasonryGrid`
///     chunks and full-width ad slivers interleaved between them. That makes the
///     SLIVER LIST ITSELF grow in the middle as pages land: `CustomScrollView`
///     reconciles its slivers positionally, so later slivers were re-homed, and
///     a re-created lazily-measured grid re-estimates its own scroll extent —
///     moving the ground above the reader.
///  3. The same, with keys and a collapsing bottom-loader sliver. Better, still
///     a variable number of slivers.
///
/// So: **the sliver count is now fixed at one, and pagination changes nothing
/// but `itemCount` on a single `SliverList.builder`.** Growing a builder
/// delegate's item count is the one list mutation Flutter is built around — it
/// is how every paginated list works, and it cannot disturb what is already laid
/// out above. This is the structure `PropertyDiscoverScreen` uses, which is the
/// paginated list in this app that does not have this bug.
///
/// The cost is the masonry packing: cards are laid out as fixed pairs, so a row
/// is as tall as its taller card. That is worth paying — a tidy grid that holds
/// its position beats a tightly packed one that does not.
///
/// Called from inside that screen's `Obx`, so every `.value` read here is what
/// subscribes it to the controller.
Widget financeListSliver(FinanceDiscoverController controller) {
  if (controller.isLoading.value && controller.profiles.isEmpty) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );
  }
  if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: CustomText(
          "Failed to load data",
          fontSize: SizeConfig.medium,
          color: AppColors.red,
        ),
      ),
    );
  }
  if (controller.profiles.isEmpty) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: CustomText(
          "No services found",
          fontSize: SizeConfig.medium,
          color: AppColors.grey9B,
        ),
      ),
    );
  }

  final items = controller.profiles;
  final rows = _financeRows(items.length);
  // The load-more spinner is an extra ITEM, not another sliver — that is what
  // keeps the sliver count fixed while it comes and goes.
  final showLoader = controller.isLoadingMore.value;

  return SliverPadding(
    padding: EdgeInsets.only(
      left: SizeConfig.size12,
      right: SizeConfig.size12,
      top: SizeConfig.size6,
      bottom: SizeConfig.size24,
    ),
    sliver: SliverList.builder(
      itemCount: rows.length + (showLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }
        final row = rows[index];
        if (row.isAd) {
          return Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size10),
            child: NativeAdSlot(
              adOrdinal: row.adOrdinal,
              keyPrefix: 'finance_native_ad',
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: SizeConfig.size10),
          child: Row(
            // NOT `stretch`. A list item is laid out with an UNBOUNDED height,
            // and a Row's cross axis is that height — so stretch has nothing to
            // stretch to and hands its children `maxHeight: infinity`, which
            // throws in layout. The paint that follows a failed layout then dies
            // on a null sliver geometry, which is what the
            // "Null check operator used on a null value" in
            // `RenderViewportBase._paintContents` was.
            //
            // `start` costs a ragged bottom edge when a pair's cards differ in
            // height (one has the Min Balance / Savings footer, the other does
            // not) — the honest trade for having given up masonry packing.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FinanceCard(
                  item: items[row.first],
                  index: row.first,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                // Odd tail: the last card keeps its column instead of
                // stretching across the row.
                child: row.second == null
                    ? const SizedBox.shrink()
                    : _FinanceCard(
                        item: items[row.second!],
                        index: row.second!,
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// One row of the list: a pair of cards, or a full-width ad slot.
class _FinanceRow {
  const _FinanceRow.cards(this.first, this.second)
      : adOrdinal = -1;
  const _FinanceRow.ad(this.adOrdinal)
      : first = -1,
        second = null;

  /// Index of the left card, and of the right one when the row is full.
  final int first;
  final int? second;

  /// -1 on a card row.
  final int adOrdinal;

  bool get isAd => adOrdinal >= 0;
}

/// Pairs [itemCount] cards into rows, dropping an ad row in after every
/// [_kAdAfterEveryCards] cards.
///
/// Derived purely from the count, so the rows for the first N cards are
/// identical before and after a page lands — the existing rows keep their
/// builder indices and only new ones are appended.
List<_FinanceRow> _financeRows(int itemCount) {
  final rows = <_FinanceRow>[];
  var adOrdinal = 0;
  var i = 0;
  while (i < itemCount) {
    final hasSecond = i + 1 < itemCount;
    rows.add(_FinanceRow.cards(i, hasSecond ? i + 1 : null));
    i += hasSecond ? 2 : 1;
    // Never after the final row — an ad below the last card reads as the list
    // having more to show when it does not.
    if (i < itemCount && i % _kAdAfterEveryCards == 0) {
      rows.add(_FinanceRow.ad(adOrdinal++));
    }
  }
  return rows;
}

/// Compact 2-up finance tile: hero (share icon + Open pill) → business
/// name → ★ rating + RBI Registered → location row → hairline → Min
/// Balance + Savings P.A. footer. Missing values collapse gracefully.
class _FinanceCard extends StatelessWidget {
  final FinanceBusinessItem item;

  /// Card position — kept for API compatibility with the previous
  /// palette-driven implementation, unused now that the tile is a flat
  /// white surface.
  final int index;

  const _FinanceCard({required this.item, required this.index});

  // ─── DERIVED VALUES ──────────────────────────────────────────────
  String get _heroImage {
    final logoUrl = item.logoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty) return logoUrl;
    final cover = item.coverUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    if (item.gallery != null) {
      for (final g in item.gallery!) {
        final urls = g.imageUrls;
        if (urls == null) continue;
        for (final u in urls) {
          if (u.trim().isNotEmpty) return u.trim();
        }
      }
    }
    return item.logoUrl?.trim() ?? '';
  }

  String get _displayName {
    final n = item.profileName?.trim() ?? '';
    return n.isNotEmpty ? n : 'Unknown';
  }

  /// `4.8` for a rated profile, `0 Ratings` for one nobody has rated yet.
  ///
  /// Never empty, so the meta row is never dropped — see the class doc for why
  /// every row on this card is unconditional.
  ///
  /// Prefers `avg_rating` (the server-computed display average) and falls back to
  /// `rating`, which is all the search-list rows carry.
  String get _ratingText {
    final r = item.avgRating ?? item.rating;
    if (r != null && r > 0) return r.toStringAsFixed(1);
    return '0 ${AppStrings.ratings.tr}';
  }

  bool get _hasRbiFlag => item.rbiRegistered == true;

  String get _distanceText {
    // Match the header (visit_business_common_header.dart:297): show
    // `X.X km away` when we have coords, empty otherwise. Coords come
    // from the GeoJSON `[lng, lat]` array on the finance model.
    final coords = item.contactUs?.firstOrNull?.branch?.location?.coordinates ??
        item.location?.coordinates;
    if (coords == null || coords.length < 2) return '';
    final lng = coords[0];
    final lat = coords[1];
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m away';
    if (km < 10) return '${km.toStringAsFixed(1)}km away';
    return '${km.toStringAsFixed(0)}km away';
  }

  String get _addressText {
    final candidates = <String?>[
      item.location?.address,
      item.location?.name,
    ];
    for (final c in candidates) {
      final t = c?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  /// Today's "Open | HH:MM - HH:MM" label with fallback to the legacy
  /// `businessHours` block. Returns null when the source only produces
  /// "Open | N/A" — the hero pill collapses in that case.
  String? get _openLabel {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    if (today != null && today.hasHours) {
      return 'Open | ${today.openTime} - ${today.closeTime}';
    }
    final bh = item.businessHours;
    if (bh?.hasHours == true) {
      return 'Open | ${bh!.openTime} - ${bh.closeTime}';
    }
    return null;
  }

  /// Stands in for any value the listing does not carry. An em-dash reads as
  /// "not stated", where a blank cell reads as a rendering fault.
  static const String _kNoValue = '—';

  /// "₹500" style thousands separator for the min-balance cell.
  String get _minBalanceText {
    final mb = item.financeDetails?.minBalance;
    if (mb == null || mb <= 0) return _kNoValue;
    return '₹${_fmt(mb)}';
  }

  /// "3.0%" for the savings-rate cell — one decimal keeps the visual
  /// weight of the two footer values matched.
  String get _savingsRateText {
    final s = item.financeDetails?.savingRatePA;
    if (s == null || s <= 0) return _kNoValue;
    return '${s.toStringAsFixed(1)}%';
  }

  String _fmt(num n) {
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && (fromEnd - 1) % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  /// ## Every row is unconditional, and that is what makes the cards equal
  ///
  /// The card used to drop its meta row, its location row and its whole footer
  /// when the values behind them were missing, so no two cards were the same
  /// height and a two-up row came out ragged.
  ///
  /// Nothing is dropped now: an absent rating reads `0 Ratings`, an absent
  /// address reads `—`, and both footer cells always render. Every card is
  /// therefore cover (a fixed aspect ratio of an equal width) + four
  /// single-line rows — identical in height on any screen width, with no fixed
  /// pixel height to go stale and no `IntrinsicHeight` pass per row.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openStore,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F001120),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoverSection(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size10,
                SizeConfig.size10,
                SizeConfig.size10,
                SizeConfig.size10,
              ),
              child: _buildInfoBlock(),
            ),
            // Always drawn, both cells filled — see the build doc.
            Container(height: 1, color: _kCardDivider),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: _buildFinanceRow(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  /// Hero uses an [AspectRatio] so the cover scales with tile width —
  /// same pattern as the school and service tiles.
  Widget _buildCoverSection() {
    final heroImage = _heroImage;
    final openLabel = _openLabel;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            heroImage.isNotEmpty
                ? GestureDetector(
                    onTap: () => Get.to(() => ImageViewScreen(
                          subTitle: item.type ?? 'Finance',
                          appBarTitle: AppStrings.imageViewer,
                          imageUrls: [heroImage],
                          initialIndex: 0,
                        )),
                    child: CachedNetworkImage(
                      imageUrl: heroImage,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      placeholder: (_, __) =>
                          Container(color: AppColors.greyE5),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.greyE5,
                        child: LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.liteWhite,
                    child: LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  ),
            Positioned(
              top: SizeConfig.size6,
              right: SizeConfig.size6,
              child: GestureDetector(
                onTap: _shareFinance,
                child: _circleIcon(AppIconAssets.share_bold),
              ),
            ),
            if (openLabel != null)
              Positioned(
                bottom: SizeConfig.size6,
                right: SizeConfig.size6,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size6,
                    vertical: SizeConfig.size3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF2FFF2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.greenShade, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: SizeConfig.size12, color: AppColors.greenShade),
                      SizedBox(width: SizeConfig.size3),
                      Flexible(
                        child: CustomText(
                          openLabel,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenShade,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _circleIcon(String icon) {
    return Container(
      width: SizeConfig.size26,
      height: SizeConfig.size26,
      decoration: const BoxDecoration(
        color: AppColors.black25,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size6),
        child: LocalAssets(
          imagePath: icon,
          imgColor: AppColors.white,
        ),
      ),
    );
  }

  // ─── INFO BLOCK ──────────────────────────────────────────────────
  /// Name, then the meta row, then the location row — all three always, so the
  /// block is the same height on every card.
  Widget _buildInfoBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          _displayName,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w800,
          color: AppColors.black22,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size4),
        _buildMetaRow(_ratingText),
        SizedBox(height: SizeConfig.size4),
        _buildLocationRow(_distanceText, _addressText),
      ],
    );
  }

  /// ★ 4.8  [verified] RBI Registered — RBI status is rendered in the
  /// brand green next to the rating per the design (img_1.png).
  ///
  /// The star and [rating] are unconditional: an unrated profile reads
  /// `★ 0 Ratings` rather than losing the row and shortening the card.
  Widget _buildMetaRow(String rating) {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.fill_star,
          width: SizeConfig.size12,
          height: SizeConfig.size12,
          imgColor: AppColors.yellow,
        ),
        SizedBox(width: SizeConfig.size3),
        CustomText(
          rating,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.black22,
        ),
        SizedBox(width: SizeConfig.size8),
        if (_hasRbiFlag)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: SizeConfig.size12,
                  color: AppColors.greenShade,
                ),
                SizedBox(width: SizeConfig.size3),
                Flexible(
                  child: CustomText(
                    'RBI Registered',
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenShade,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Inline pin + distance + " | " + address — matches the service /
  /// school tile so all discover directories share the same location
  /// styling.
  ///
  /// Drawn even when the listing carries neither — a lone pin beside an em-dash
  /// keeps the card its full height, and says "no address on file" rather than
  /// leaving a gap that looks like a bug.
  Widget _buildLocationRow(String distanceText, String address) {
    final hasNeither = distanceText.isEmpty && address.isEmpty;
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.location_outline,
          imgColor: AppColors.primaryColor,
          height: SizeConfig.size10,
          width: SizeConfig.size10,
        ),
        SizedBox(width: SizeConfig.size4),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (hasNeither)
                  TextSpan(
                    text: _kNoValue,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
                    ),
                  ),
                if (distanceText.isNotEmpty)
                  TextSpan(
                    text: distanceText,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (distanceText.isNotEmpty && address.isNotEmpty)
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
                    ),
                  ),
                if (address.isNotEmpty)
                  TextSpan(
                    text: address,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Two-cell footer: Min Balance | Savings P.A.
  ///
  /// Both cells always render, each falling back to an em-dash. They used to
  /// collapse independently, which left the two columns landing in different
  /// places from card to card and made the footer — and so the card — a
  /// different height depending on what the listing happened to carry.
  Widget _buildFinanceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _statCell(label: 'Min Balance', value: _minBalanceText),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: _statCell(label: 'Savings P.A.', value: _savingsRateText),
        ),
      ],
    );
  }

  Widget _statCell({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          fontWeight: FontWeight.w500,
          color: AppColors.grey7E,
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          value,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Routed through openVisitProfile so the type→screen mapping stays in
  /// one place. The lightweight list item goes with it and seeds
  /// `selectedDetail`, so the detail screen renders at once and upgrades
  /// itself to the full record.
  void _openStore() {
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: BusinessType.Finance.name,
      businessId: item.businessProfileId ?? item.id,
      userId: item.userId,
      financeData: item,
    );
  }

  Future<void> _shareFinance() async {
    final shareLink = financialDeepLink(
      businessId: item.userId,
    );

    await ShareService.instance.openShareSheet(
      text:
          "Check out ${item.profileName ?? 'this profile'} on BlueEra:\n$shareLink",
      subject: item.profileName,
    );
  }
}
