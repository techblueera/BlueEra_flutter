import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/discover_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/map/view/searchLocationScreen.dart';
import 'package:BlueEra/features/common/rental/view/property_discover_screen.dart';
import 'package:BlueEra/features/common/rental/view/rental_services_dashboard_screen_v2.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/static_map_preview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Rent & Properties — entry.**
///
/// Location-first landing for the rental flow: a map of the place being
/// searched, the field that changes it, and the category grid. It answers "where
/// do you want to look?" before "what are you looking for?", because for
/// property the answer to the second question is worthless without the first —
/// a 2BHK in the wrong city is not a result.
///
/// It replaces what the rental card used to open, which was
/// `RentalServicesDashboardScreenV2` — the seller's OWN listings, with an "Add
/// Listing" button. That is the right screen for someone letting a flat and the
/// wrong one for everybody else, and it was the destination for both.
///
/// Picking a category stamps the chosen place onto [PropertyDiscoverScreen],
/// which scopes its search to it and carries it into its map preview and its
/// full-screen map. The global [LocationService] is never touched — see
/// [PropertyDiscoverController.setSearchLocation] for why.
///
/// Deliberately the same shape as [SelfProfessionDiscoverEntryScreen] (Book
/// Home Services): static map backdrop, draggable sheet, location field,
/// category grid. Two location-first pickers in one app should not be two
/// different objects.
class RentalDiscoverEntryScreen extends StatefulWidget {
  /// Show only sale, only rental, or every category.
  ///
  /// The rental card's own "For Sale" / "For Rent" chips arrive here with this
  /// set, so tapping the chip a user meant still means something — otherwise
  /// both chips and the card body would all open the identical screen and the
  /// choice they just made would be discarded.
  final bool? isSale;

  /// Index into [propertyDiscoverTiles] of the category the user already tapped
  /// on the way in (the Discover "Rent & Properties" tiles), or null when they
  /// arrived without picking one.
  ///
  /// Only marks the tile — it does not skip this screen. The location is the
  /// thing being collected here, and a pre-picked category that jumped straight
  /// through would defeat the point of the screen existing; showing it marked is
  /// what keeps the trip from feeling like a step backwards.
  final int? highlightCategoryIndex;

  const RentalDiscoverEntryScreen({
    super.key,
    this.isSale,
    this.highlightCategoryIndex,
  });

  @override
  State<RentalDiscoverEntryScreen> createState() =>
      _RentalDiscoverEntryScreenState();
}

class _RentalDiscoverEntryScreenState extends State<RentalDiscoverEntryScreen> {
  /// The place the search will scope to. Seeded from the device fix, replaced by
  /// whatever the user picks. Null means "we have no location" — the search then
  /// falls back to the device fix downstream, which may also be nothing.
  double? _lat;
  double? _lng;
  String _locationLabel = '';

  /// Drives the sheet, and is read by the floating action button so it can sit
  /// on the sheet's top edge at any height — see [_listYourPropertyFab].
  final _sheetController = DraggableScrollableController();

  /// Sheet heights, as a share of the screen. Named because the FAB's resting
  /// position is derived from [_kSheetInitialExtent] before the controller has
  /// attached.
  static const double _kSheetInitialExtent = 0.58;
  static const double _kSheetMinExtent = 0.44;
  static const double _kSheetMaxExtent = 0.92;

  /// Sheet height at which the floating button starts fading out: past this
  /// there is no map left for it to float on. See [_listYourPropertyFab].
  static const double _kFabFadeFrom = 0.78;

  /// Categories on offer, in the order [propertyDiscoverTiles] declares them.
  ///
  /// Index matters: [PropertyDiscoverScreen] identifies a category by its
  /// position in that same list, so the tiles carry their ORIGINAL index rather
  /// than their position in this (possibly filtered) grid.
  late final List<({PropertyTileData tile, int index})> _categories;

  @override
  void initState() {
    super.initState();
    if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
      _lat = LocationService.lat;
      _lng = LocationService.lng;
    }
    _locationLabel = _deviceAddressLabel();
    _categories = [
      for (var i = 0; i < propertyDiscoverTiles.length; i++)
        if (widget.isSale == null || propertyDiscoverTiles[i].isSale == widget.isSale)
          (tile: propertyDiscoverTiles[i], index: i),
    ];
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Short label for the device address ("SubLocality, City"), or empty when the
  /// fix hasn't resolved to an address yet.
  String _deviceAddressLabel() {
    final a = LocationService.userCurrentAddress.value;
    return [a.subLocality, a.city]
        .where((p) => p.trim().isNotEmpty)
        .join(', ');
  }

  bool get _hasLocation => _lat != null && _lng != null && !(_lat == 0 && _lng == 0);

  /// Delhi as the backdrop's last resort. The map is decoration here — it is
  /// never what the search is scoped to, so a fallback centre cannot send anyone
  /// to the wrong results; it only avoids a grey rectangle.
  double get _mapLat => _hasLocation ? _lat! : 28.6139;

  double get _mapLng => _hasLocation ? _lng! : 77.2090;

  // ── Location ──────────────────────────────────────────────────────────────
  /// The app's standard full-screen picker: autofocused field, "Use Current
  /// Location", and recent searches. A bottom sheet would fight the keyboard for
  /// the same space and would still need all three of those.
  Future<void> _openLocationPicker() async {
    double? pickedLat;
    double? pickedLng;
    String? pickedAddress;
    await Get.to(() => SearchLocationScreen(
          fromScreen: '',
          onPlaceSelected: (lat, lng, address) {
            pickedLat = lat;
            pickedLng = lng;
            pickedAddress = address;
          },
        ));
    if (!mounted || pickedLat == null || pickedLng == null) return;
    setState(() {
      _lat = pickedLat;
      _lng = pickedLng;
      _locationLabel = (pickedAddress ?? '').trim();
    });
  }

  // ── Category → results ────────────────────────────────────────────────────
  void _openCategory(int originalIndex) {
    Get.to(() => PropertyDiscoverScreen(
          initialCategoryIndex: originalIndex,
          searchLat: _lat,
          searchLng: _lng,
          searchLabel: _locationLabel,
        ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map backdrop. A picture, not a live GoogleMap: the sheet above owns
          // every gesture, so there is nothing here to pan — and a GoogleMap
          // bills a Dynamic Maps load on every build where the Static API is a
          // cheaper SKU that CachedNetworkImage keeps on disk. Same call the
          // Book Home Services entry makes.
          Positioned.fill(
            child: AbsorbPointer(
              child: StaticMapPreview(
                latitude: _mapLat,
                longitude: _mapLng,
                width: size.width,
                height: size.height,
                zoom: 13,
                showMarker: _hasLocation,
              ),
            ),
          ),
          Positioned(
            top: topInset + SizeConfig.size8,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(child: _titlePill()),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _kSheetInitialExtent,
            minChildSize: _kSheetMinExtent,
            maxChildSize: _kSheetMaxExtent,
            builder: (context, scrollController) => _sheet(scrollController),
          ),
          // Last in the Stack: it floats above both the map and the sheet.
          _listYourPropertyFab(size.height),
        ],
      ),
    );
  }

  Widget _titlePill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F001120),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CustomText(
        AppStrings.rentAndProperties.tr,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.mainTextColor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _sheet(ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22001120),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: SizeConfig.size12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            // Keeps the sheet's own controller, so dragging the grid still
            // resizes the sheet.
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              children: [
                CustomText(
                  AppStrings.searchLocation.tr,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size12),
                _locationField(),
                SizedBox(height: SizeConfig.size20),
                CustomText(
                  AppStrings.selectCategory.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size12),
                _categoryGrid(),
                // Room to scroll the last row clear of the floating button,
                // which overlaps the sheet's top edge rather than its bottom —
                // so this is ordinary breathing room, not clearance.
                SizedBox(height: SizeConfig.size16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The owner's way in — "List Your Property" → their own listings, where the
  /// Add Listing sheet lives.
  ///
  /// ## It floats on the seam, and rides the sheet
  ///
  /// This screen is two layers: a decorative map plate, and the white sheet that
  /// holds everything you can actually do. The button belongs to neither — so it
  /// sits on the boundary between them, anchored just above the sheet's top-right
  /// corner, and MOVES with the sheet as it is dragged.
  ///
  /// That placement is the whole design. A `Scaffold.floatingActionButton` is
  /// pinned to the bottom-right of the screen, which on this layout means on top
  /// of the sheet and over the category grid — and this action has already been
  /// tried inside the sheet twice (last item in the list, then a pinned floor
  /// bar) and covered or displaced the grid both times. Riding the seam, it
  /// covers nothing at any sheet height, and watching it glide is what tells you
  /// the sheet is a layer you can move.
  ///
  /// EXTENDED, not a bare `+`. Letting a property is a once-in-a-while act for
  /// the few users it applies to at all; a naked plus on a search screen is a
  /// guess. The label is the affordance.
  ///
  /// Solid brand blue with white content: the map plate is a muted grey-blue, so
  /// this is the one saturated thing on that layer and needs nothing else to be
  /// found — no chevron, no badge, one shadow.
  Widget _listYourPropertyFab(double screenHeight) {
    return AnimatedBuilder(
      // Rebuilds on every drag frame, which is what keeps the button on the
      // sheet's edge instead of at a fixed offset.
      animation: _sheetController,
      builder: (context, _) {
        // `size` throws before the sheet has attached its controller, and the
        // first frame is built before that happens.
        final extent = _sheetController.isAttached
            ? _sheetController.size
            : _kSheetInitialExtent;

        // Past [_kFabFadeFrom] there is no seam left to sit on: keep rising and
        // the button would climb into the back button and the title. So it fades
        // out over the last of the sheet's travel and comes back on the way
        // down. Dragging the sheet to full height is someone concentrating on the
        // grid — the right moment for this to step aside, not to be relocated on
        // top of what they just opened.
        final fade = ((_kSheetMaxExtent - extent) /
                (_kSheetMaxExtent - _kFabFadeFrom))
            .clamp(0.0, 1.0);

        return Positioned(
          right: SizeConfig.size16,
          bottom: (extent * screenHeight) + SizeConfig.size12,
          child: IgnorePointer(
            // Not tappable once it is more transparent than it is visible.
            ignoring: fade < 0.5,
            child: Opacity(
              opacity: fade,
              child: Material(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(28),
                elevation: 6,
                shadowColor: AppColors.primaryColor.withValues(alpha: 0.45),
                child: InkWell(
                  onTap: () =>
                      Get.to(() => const RentalServicesDashboardScreenV2()),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_home_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          AppStrings.listYourProperty.tr,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The one control on this screen that changes what the results will be, so it
  /// reads as a field rather than a label: the place in the app's blue, with the
  /// pin and an edit affordance either side of it.
  Widget _locationField() {
    final resolved = _locationLabel.trim();
    final hasPlace = resolved.isNotEmpty;
    return InkWell(
      onTap: _openLocationPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              hasPlace ? Icons.location_on_rounded : Icons.my_location_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(
                // No place resolved yet — the field says what tapping it does
                // rather than sitting empty.
                hasPlace ? resolved : AppStrings.searchLocation.tr,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: hasPlace
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 18, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across, not four: these labels carry a listing type as well as a
        // category ("For Rent · Houses & Apartments"), and at four columns they
        // ellipsised down to the half that both tiles in a pair share.
        const columns = 3;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: SizeConfig.size16,
          children: [
            for (final c in _categories)
              SizedBox(
                width: itemWidth,
                child: _RentalCategoryTile(
                  tile: c.tile,
                  width: itemWidth,
                  highlighted: c.index == widget.highlightCategoryIndex,
                  onTap: () => _openCategory(c.index),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One category in the grid: the artwork, then the listing type, then the
/// category name.
class _RentalCategoryTile extends StatelessWidget {
  const _RentalCategoryTile({
    required this.tile,
    required this.width,
    required this.onTap,
    this.highlighted = false,
  });

  final PropertyTileData tile;
  final double width;
  final VoidCallback onTap;

  /// The category the user tapped to get here — marked, not selected. There is
  /// no selection state on this screen: every tile is a one-tap route into the
  /// results, and this one just says "this is the one you came for".
  final bool highlighted;

  /// Sale and rental read as two different things at a glance, which is the
  /// whole reason the pair is split: blue for buying, green for renting — the
  /// same two accents the rental card's own chips use.
  Color get _accent =>
      tile.isSale ? const Color(0xFF0086FF) : const Color(0xFF00B87A);

  /// Artwork box height, as a share of the tile's width.
  ///
  /// Slightly wider than tall rather than square: at 1:1 three rows of these did
  /// not fit the sheet, so the grid opened showing two and a sliver of a third.
  /// The illustrations are centred with their own margin, so `cover` trimming a
  /// little off the top and bottom costs nothing.
  static const double _kArtHeightRatio = 0.84;

  @override
  Widget build(BuildContext context) {
    final artHeight = width * _kArtHeightRatio;
    final radius = BorderRadius.circular(14);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Three layers, and the order matters:
          //
          //  1. the shadow, BEHIND everything;
          //  2. the artwork, clipped to the tile's shape;
          //  3. the rim, painted OVER the artwork as a foreground decoration.
          //
          // The rim used to be a `border` on the Container holding the art, and
          // a Container with a border insets its child by the border's width
          // (`BoxDecoration.padding` comes from the border's dimensions). So the
          // illustration was drawn 1-2px inside the clip and the tile's own pale
          // fill showed through as a ring around it — the gap in the screenshot,
          // widest on the marked tile because its rim is 2px.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: radius,
                // The rim carries the mark: the accent at full strength and two
                // pixels wide on the tile they came for, a hairline on the rest.
                border: Border.all(
                  color: _accent.withValues(alpha: highlighted ? 1 : 0.18),
                  width: highlighted ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  width: width,
                  height: artHeight,
                  // Base fill for cut-out art with a transparent background;
                  // self-contained art covers it completely.
                  child: ColoredBox(
                    color: const Color(0xFFF3F5FA),
                    child: _artwork(),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          // The listing type leads and is the coloured half — it is what
          // distinguishes the three categories that appear twice in this grid,
          // and putting it second let it be the part that ellipsised away.
          CustomText(
            (tile.isSale ? AppStrings.forSale : AppStrings.forRent).tr,
            textAlign: TextAlign.center,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _accent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          CustomText(
            _categoryLabel,
            textAlign: TextAlign.center,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// The category's translated name, keyed off `propertyType` — `label` on
  /// [PropertyTileData] is raw English and also travels to the controller as
  /// data. Same mapping as the Discover "Rent & Properties" tiles.
  String get _categoryLabel {
    switch (tile.propertyType) {
      case 'HouseAndApartment':
        return AppStrings.propertyCategoryHousesApartments.tr;
      case 'NewProjectsAndProperties':
        return AppStrings.propertyCategoryNewProjectsProperties.tr;
      case 'LandAndPlots':
        return AppStrings.propertyCategoryLandsPlots.tr;
      case 'ShopAndOffices':
        return AppStrings.propertyCategoryShopsOffices.tr;
      case 'PGAndGuestHouse':
        return AppStrings.propertyCategoryPGGuestHouse.tr;
    }
    return tile.label;
  }

  Widget _artwork() {
    final path = tile.image;
    if (path.isEmpty) return const SizedBox.shrink();
    // [DiscoverIcons] art ships on its own tinted square and fills the tile;
    // anything else is a transparent cut-out that needs room to breathe. Same
    // rule as DiscoverSheetTile.
    if (DiscoverIcons.isSelfContained(path)) {
      return LocalAssets(imagePath: path, boxFix: BoxFit.cover);
    }
    return Padding(
      // Proportional to the SHORT side now that the box is wider than it is
      // tall — 16% of the width was a third of the height once both edges were
      // counted, which squeezed a cut-out into the middle band of the tile.
      padding: EdgeInsets.all(width * _kArtHeightRatio * 0.14),
      child: LocalAssets(imagePath: path, boxFix: BoxFit.contain),
    );
  }
}
