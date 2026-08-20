import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/common/Discover/widget/filter_capsule.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/widgets/static_map_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Provider card palette (assets/img.png) ─────────────────────────────────
// Every value below was DECODED out of the design PNG rather than matched by
// eye: the file was inflated and the pixels read directly, taking the modal
// colour of each flat region and the darkest pixel of each text run. Where a
// sample landed on an existing token it is written as that token instead
// (the CTA's #0085FE is [AppColors.primaryColor]) so the card follows the
// theme rather than pinning a duplicate literal beside it.

/// Tinted surface set for one provider card. Cards alternate between the two
/// entries in [_providerCardPalettes] so a scrolling list reads as a rhythm
/// rather than a stack of identical blocks — the same two-tone treatment the
/// grocery and product store cards use elsewhere in the app.
///
/// The teal entry is the design (`assets/img.png`) as sampled; the purple one
/// is its counterpart, carried over from the card this replaced.
class _ProviderCardPalette {
  final Color cardBg;
  final Color cardBorder;

  /// The services checklist panel — one step more saturated than [cardBg],
  /// which is what separates it from the body without needing a border.
  final Color panelBg;

  const _ProviderCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.panelBg,
  });
}

const _providerCardPalettes = <_ProviderCardPalette>[
  _ProviderCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    panelBg: Color(0xFFDBFAFD),
  ),
  _ProviderCardPalette(
    cardBg: Color(0xFFF9EDFF),
    cardBorder: Color(0xFFE7CBF5),
    // The purple twin of the sampled panel: the old card tinted this box with
    // an ~8% #BE26FF wash over its body, which resolves to this.
    panelBg: Color(0xFFF4DDFF),
  ),
];

/// Profession pill behind the blue label ("Electrician"). Shared by both
/// palettes — the trade chip and the CTA are the card's accent, and swapping
/// them per card would leave nothing constant to recognise.
const Color _chipBg = Color(0xFFD6F2FF);

/// Hairline on the white glyph plates.
///
/// The design has no stroke at all there — decoding it, the plate edge goes
/// from the card body straight to #FFFFFF across two pixels of antialiasing.
/// This is the lightest cool hairline that still resolves as an edge, so the
/// plates keep a defined shape on both palettes without gaining weight.
const Color _glyphPlateBorder = Color(0xFFDCEFF4);

/// Name and the two info rows.
const Color _cardInk = Color(0xFF0D161F);

/// "Starting From", and the price unit.
const Color _cardInkSoft = Color(0xFF617077);

/// Checklist entries — deliberately lighter than [_cardInk]. In the design the
/// service names are secondary to the provider's name and read as a list, not
/// as headlines.
const Color _serviceInk = Color(0xFF5C6873);

const double _cardRadius = 18;

/// The photo's width as a share of the card's inner width — the proportion the
/// design uses (216 of 632).
///
/// A share, not a fixed size, because the card has to hold on any screen. The
/// HEIGHT is not set here at all: the photo stretches to whatever the four
/// items beside it need (see the `IntrinsicHeight` in the top band), so the
/// two columns finish level on a small phone, on a tablet, and at any system
/// text scale — none of which a hard-coded height survives. At default
/// settings that lands within a few points of square, as drawn.
const double _cardPhotoWidthRatio = 0.34;

/// Bounds for the above. Below the minimum a face is unreadable; above the
/// maximum the photo starts eating the space the name and the trade need.
///
/// The ceiling is raised on tablets, where the card is roughly twice as wide:
/// a phone-sized cap there would hold the photo at a fifth of the card instead
/// of the third the design draws, and the row would read as a thumbnail with a
/// paragraph next to it.
const double _cardPhotoMinWidth = 96;
double get _cardPhotoMaxWidth => SizeConfig.isTablet ? 220 : 148;

/// **Self-profession (Book Home Services) results — v2.**
///
/// Same data as [SelfProfessionDiscoverScreen], re-chromed to match the entry
/// screen ([SelfProfessionDiscoverEntryScreen]): a full-bleed map backdrop with
/// the provider pins, a banner header (back + location pill + expand), and the
/// results themselves in a [DraggableScrollableSheet] the user can pull up to
/// near-full-screen or push down to reveal the map.
///
/// The backdrop map is decorative (gestures absorbed) — tapping anywhere on it,
/// or the expand button, opens the dedicated clustered full-screen map, exactly
/// like the inline preview did in v1.
class SelfProfessionDiscoverScreenV2 extends StatefulWidget {
  final List<ProfessionTypeData> selfEmployedCategories;
  final ProfessionTypeData? selectedSelfProfessionData;

  const SelfProfessionDiscoverScreenV2({
    super.key,
    required this.selfEmployedCategories,
    this.selectedSelfProfessionData,
  });

  @override
  State<SelfProfessionDiscoverScreenV2> createState() =>
      _SelfProfessionDiscoverScreenV2State();
}

class _SelfProfessionDiscoverScreenV2State
    extends State<SelfProfessionDiscoverScreenV2> {
  final controller = getOrPut(() => DiscoverController());
  final String serviceSubType = 'selfWork';
  final String earnServiceType = AppConstants.service;

  /// Custom pin for the backdrop map — rendered once, reused for every marker.
  BitmapDescriptor? _markerIcon;

  static const LatLng _fallbackCenter = LatLng(28.6139, 77.2090); // Delhi

  @override
  void initState() {
    super.initState();
    final selected = widget.selectedSelfProfessionData;
    controller.selectedEarnServiceData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    // Skip refetch on re-entry when the cached list is fresh for this
    // category; category taps on the entry screen force a fresh fetch.
    controller.fetchEarnServicesIfNeeded(
        earnServiceType: earnServiceType, subType: serviceSubType);
    DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded).then((d) {
      if (mounted) setState(() => _markerIcon = d);
    });
  }

  // ─── Sorting / formatting helpers ──────────────────────────────────────────

  /// Returns a new list sorted by the active filter. Items missing the
  /// comparator key sort to the end.
  ///
  /// `ServiceData` already carries a server-computed `distance` so we don't
  /// have to read GPS here. There's no explicit experience field on this model
  /// — we use `rating` (descending) as a stand-in for the "Experienced" filter,
  /// which generally tracks tenure.
  List<ServiceData> _applySort(List<ServiceData> items, CategoryFilter filter) {
    final sorted = List<ServiceData>.from(items);
    switch (filter) {
      case CategoryFilter.nearest:
        sorted.sort((a, b) {
          final da = (a.distance ?? double.infinity).toDouble();
          final db = (b.distance ?? double.infinity).toDouble();
          return da.compareTo(db);
        });
        break;
      case CategoryFilter.experienced:
        sorted.sort((a, b) {
          final ar = (a.rating ?? 0).toDouble();
          final br = (b.rating ?? 0).toDouble();
          return br.compareTo(ar); // descending
        });
        break;
      case CategoryFilter.priceLowToHigh:
        sorted.sort((a, b) {
          final ap = _priceFor(a);
          final bp = _priceFor(b);
          // Treat 0 as "unpriced" → push to end.
          if (ap == 0 && bp == 0) return 0;
          if (ap == 0) return 1;
          if (bp == 0) return -1;
          return ap.compareTo(bp);
        });
        break;
    }
    return sorted;
  }

  /// Converts an all-caps category name like "ELECTRICIAN" or "HOME_TUTOR"
  /// into a human-readable label ("Electrician" / "Home Tutor"). Leaves
  /// already mixed-case names untouched.
  String _prettyCategoryName(String raw) {
    if (raw.isEmpty) return raw;
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned != cleaned.toUpperCase()) return cleaned;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Section title like "Electricians near you". Light pluralization: append
  /// "s" unless the label already ends with "s" or ")" (e.g. "Maid (Female)").
  String _nearYouTitle(String pretty) {
    if (pretty.isEmpty) return 'Providers near you';
    final needsS = !pretty.toLowerCase().endsWith('s') && !pretty.endsWith(')');
    return '$pretty${needsS ? 's' : ''} near you';
  }

  /// Effective price used for the Price (Low–High) sort — the range/single
  /// minimum (handles both legacy `singlePrice` and the newer `priceRange`).
  num _priceFor(ServiceData s) => s.priceData?.effectiveMin ?? 0;

  // ─── Map backdrop ──────────────────────────────────────────────────────────

  LatLng get _mapTarget {
    final lat = controller.earnDiscoverLat;
    final lng = controller.earnDiscoverLng;
    if (lat != null && lng != null && !(lat == 0 && lng == 0)) {
      return LatLng(lat, lng);
    }
    if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
      return LatLng(LocationService.lat, LocationService.lng);
    }
    return _fallbackCenter;
  }

  /// Pins for the providers already loaded in the list. The full (unpaginated,
  /// clustered) set lives on the dedicated map screen.
  /// Provider coordinates for the static backdrop.
  ///
  /// Plain points rather than [Marker]s — the backdrop is a static image now,
  /// so there is nothing to attach a tap handler or an info window to. The
  /// clustered full-screen map behind the tap still builds real markers.
  List<({double lat, double lng})> _backdropPins() {
    final pins = <({double lat, double lng})>[];
    for (final s in controller.earnServiceList) {
      final lat = s.userLocation?.lat?.toDouble();
      final lng = s.userLocation?.lon?.toDouble();
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      pins.add((lat: lat, lng: lng));
    }
    return pins;
  }

  Set<Marker> _backdropMarkers() {
    final markers = <Marker>{};
    for (final s in controller.earnServiceList) {
      final lat = s.userLocation?.lat?.toDouble();
      final lng = s.userLocation?.lon?.toDouble();
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      markers.add(Marker(
        markerId: MarkerId(s.id ?? '${s.name}_$lat,$lng'),
        position: LatLng(lat, lng),
        icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
      ));
    }
    return markers;
  }

  void _openFullMap() {
    Get.to(() => _SelfProfessionMapScreenV2(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
          onMarkerTap: _showServiceMapSheet,
        ));
  }

  /// Bottom sheet shown when a map marker is tapped — compact provider summary
  /// (avatar, name, rating, distance, price) with a "View Profile" CTA into
  /// [SelfEmployeeViewDiscoverScreen]. Takes the host [BuildContext] so the
  /// sheet renders over whichever screen the marker was tapped on.
  void _showServiceMapSheet(BuildContext hostContext, ServiceData service) {
    final priceData = service.priceData;
    final isRange = priceData?.effectiveIsRange ?? false;
    final priceDisplay = isRange
        ? "₹${formatIndianNumber(priceData?.effectiveMin ?? 0)}-${formatIndianNumber(priceData?.effectiveMax ?? 0)}"
        : "₹${formatIndianNumber(priceData?.effectiveMin ?? 0)}";
    final priceUnit = (priceData?.unitLabel.isNotEmpty ?? false)
        ? priceData!.unitLabel
        : 'Hour';
    final ratingValue = service.rating != null && service.rating != 0
        ? service.rating.toString()
        : '0';
    final distance = '${service.distance ?? 0} km';

    showModalBottomSheet<void>(
      context: hostContext,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
              SizeConfig.size16, SizeConfig.size16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _grabHandle()),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CachedAvatarWidget(
                          imageUrl: service.profileImage ?? '',
                          size: SizeConfig.size60,
                          borderColor: Colors.white,
                          borderRadius: SizeConfig.size30,
                        ),
                        // Presence dot — only when the provider really is live.
                        if (service.isLive == true)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            service.name ?? AppStrings.unknownUser.tr,
                            fontSize: SizeConfig.large18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((service.profession ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            CustomText(
                              service.profession!,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                          SizedBox(height: SizeConfig.size6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildRatingBadge(ratingValue),
                              _buildDistanceBadge(distance),
                              if (service.isLive != null)
                                _buildLiveBadge(service.isLive!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size16),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            TextSpan(text: priceDisplay),
                            TextSpan(
                              text: ' / $priceUnit',
                              style: TextStyle(
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        ProfileClickTracker.track(
                          userId: service.id ?? '',
                          source: ChatClickSource.searchResult,
                        );
                        openVisitProfile(
                          accountType: AppConstants.individual,
                          profileType: SELF_EMPLOYED,
                          userId: service.id,
                          serviceData: service,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                            vertical: SizeConfig.size8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomText(
                          AppStrings.viewProfile,
                          color: Colors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.fetchEarnServices(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
          isLoadMore: true);
    }
    return false;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status-bar icons — they sit over the light map backdrop.
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Decorative map backdrop — the sheet owns the gestures, so a tap
            // anywhere here jumps to the full clustered map instead of panning.
            Positioned.fill(
              child: GestureDetector(
                onTap: _openFullMap,
                child: AbsorbPointer(
                  // A picture, not a live GoogleMap. Gestures are absorbed and
                  // a tap opens the real clustered map, so this was paying a
                  // Dynamic Maps load per build to render something nobody can
                  // interact with. The provider pins survive as static markers.
                  child: Obx(() => StaticMapPreview(
                        latitude: _mapTarget.latitude,
                        longitude: _mapTarget.longitude,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        zoom: 13,
                        showMarker: false,
                        pins: _backdropPins(),
                      )),
                ),
              ),
            ),
            // Header: back + location pill + expand-to-full-map.
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
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: Obx(() {
                      final label = controller.earnDiscoverLocationLabel.value;
                      return bannerMapLocationPill(
                          label: label.isNotEmpty ? label : null);
                    }),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  bannerMapCircleIconButton(
                    icon: Icons.fullscreen_rounded,
                    onTap: _openFullMap,
                  ),
                ],
              ),
            ),
            // Results sheet.
            DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.32,
              maxChildSize: 0.94,
              snap: true,
              snapSizes: const [0.32, 0.62, 0.94],
              builder: (context, scrollController) =>
                  _buildSheet(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(ScrollController scrollController) {
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
      clipBehavior: Clip.antiAlias,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        // A CustomScrollView (not a plain ListView) so the sort chips can pin
        // to the top of the sheet while the cards scroll beneath them — and so
        // the whole thing still drives the drag-to-resize gesture.
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _grabHandle()),
                    // Title: "{Category}s near you" — the category chosen on the
                    // entry screen. Reactive so it follows the selection.
                    Obx(() {
                      final pretty = _prettyCategoryName(
                          controller.selectedEarnServiceData.value?.name ?? '');
                      return CustomText(
                        _nearYouTitle(pretty),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Sort chips — tapping mutates `selectedFilter`; the Obx below
            // re-sorts the loaded list client-side, no refetch needed.
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedFilterBar(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(SizeConfig.size12,
                      SizeConfig.size10, SizeConfig.size12, SizeConfig.size10),
                  child: Obx(() => FilterCapsule(
                        filters: controller.filters,
                        selected: controller.selectedFilter.value,
                        onChanged: (f) {
                          if (controller.selectedFilter.value == f) return;
                          controller.selectedFilter.value = f;
                        },
                      )),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              sliver: Obx(() {
                if (controller.isEarnServiceLoading.value &&
                    controller.earnServiceList.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (controller.earnServiceList.isEmpty) {
                  final selectedName =
                      controller.selectedEarnServiceData.value?.name ?? '';
                  // Server returns categories in upper-case (e.g. "ELECTRICIAN");
                  // flip to title-case so the message reads naturally.
                  final pretty = _prettyCategoryName(selectedName);
                  final message = pretty.isNotEmpty
                      ? AppStrings.noProvidersFoundNearYou
                          .trParams({'category': pretty})
                      : AppStrings.noServicesFound.tr;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: EmptyStateWidget(message: message)),
                  );
                }
                final sorted = _applySort(
                  controller.earnServiceList,
                  controller.selectedFilter.value,
                );
                final showMoreSpinner =
                    controller.isEarnServiceLoadingMore.value;
                final rows = buildNativeAdRows(sorted.length);
                return SliverList.builder(
                  itemCount: rows.length + (showMoreSpinner ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)));
                    }
                    final row = rows[index];
                    if (row.isAd) {
                      return NativeAdSlot(
                        adOrdinal: row.adOrdinal,
                        keyPrefix: 'self_profession_v2_native_ad',
                      );
                    }
                    // Palette alternates on the CONTENT index, not the row
                    // index, so injected ad rows don't break the rhythm.
                    return _buildSpecCard(
                        sorted[row.contentIndex], row.contentIndex);
                  },
                );
              }),
            ),
            SliverToBoxAdapter(child: SizedBox(height: SizeConfig.paddingL)),
          ],
        ),
      ),
    );
  }

  Widget _grabHandle() {
    return Container(
      width: 44,
      height: 4,
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// **Provider card**, built to `assets/img.png`.
  ///
  /// Three bands, top to bottom:
  ///  1. a SQUARE photo on the left (rating pill inset into its top-left) beside
  ///     name → profession chip → two glyph-and-label info rows, with an
  ///     overflow "⋮" at the far right;
  ///  2. the services checklist on its own pale-cyan panel — two columns of
  ///     green ticks, no heading and no divider;
  ///  3. "Starting From" + price on the left, a solid blue "Book Now →" on the
  ///     right.
  ///
  /// This replaced a full-bleed letterbox hero. The design puts the photo
  /// beside the details rather than above them, which is what lets a card show
  /// the provider, their trade, their experience and their whole service list
  /// in roughly the height the hero alone used to take.
  ///
  /// **Where the old card's parts went:** share and save moved off the photo
  /// into the "⋮" menu (the design has one control there, not two floating
  /// circles); the address line was dropped, the design carrying distance
  /// alone; and opening hours became the fallback for the experience row
  /// rather than a chip over the photo — see [_infoRows].
  Widget _buildSpecCard(ServiceData service, int index) {
    final palette =
        _providerCardPalettes[index.abs() % _providerCardPalettes.length];

    // ─── Data extraction with sensible fallbacks ──────────────────
    final name = (service.name?.trim().isNotEmpty ?? false)
        ? service.name!
        : AppStrings.unknownUser.tr;

    final priceData = service.priceData;
    final isRange = priceData?.effectiveIsRange ?? false;
    final priceMin = priceData?.effectiveMin ?? 0;
    final priceMax = priceData?.effectiveMax ?? 0;
    final priceUnit =
        (priceData?.unitLabel.isNotEmpty ?? false) ? priceData!.unitLabel : '';
    final distance = (service.distance ?? 0).toDouble();
    final timingMap = getMinMaxTimings(service.service?.effectiveTimings);
    final timingStart = timingMap['start'] ?? '--';
    final timingEnd = timingMap['end'] ?? '--';

    final livePhotos = (service.serviceMedia?.photos ?? const <String>[])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final profileImage = service.profileImage ?? '';
    // Hero image: a service photo if one exists, else the profile photo.
    final heroImage = livePhotos.isNotEmpty ? livePhotos.first : profileImage;

    final ratingValue = (service.rating != null && service.rating != 0)
        ? service.rating.toString()
        : null;

    // Trade label for the pill. The provider's own profession when they carry
    // one, else the category the user picked to get here — the screen is
    // scoped to a single trade, so that is never a guess.
    final professionLabel = _prettyCategoryName(
        (service.profession?.trim().isNotEmpty ?? false)
            ? service.profession!.trim()
            : (controller.selectedEarnServiceData.value?.name ?? ''));

    // Prefer the provider's explicit `expertise` list (the design labels this
    // box "Expertise"), else fall back to serviceOffered + typesOfWork.
    final expertiseList = (service.service?.expertise ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final services =
        expertiseList.isNotEmpty ? expertiseList : _combinedServices(service);
    final totalServices = services.length;
    final showMoreServices = totalServices > 6;
    final visibleServices = showMoreServices
        ? services.take(5).toList()
        : services.take(6).toList();
    final extraServices = showMoreServices ? totalServices - 5 : 0;

    // "₹1000 – ₹1,000": the design repeats the ₹ on both ends of a range and
    // spaces the dash, so the two figures read as two prices rather than as one
    // hyphenated token.
    final priceStr = priceMin == 0
        ? '—'
        : (isRange
            ? '₹${formatIndianNumber(priceMin)} – ₹${formatIndianNumber(priceMax)}'
            : '₹${formatIndianNumber(priceMin)}');
    final distStr = distance == 0
        ? null
        : '${distance < 10 ? distance.toStringAsFixed(1) : distance.toStringAsFixed(0)} Km Away';
    // Compact hours: "9:00 AM - 6:00 PM" → "9AM-6PM" for the floating chip.
    String compactTime(String t) {
      final m = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false)
          .firstMatch(t.trim());
      if (m == null) return t;
      final hh = m.group(1)!;
      final mm = m.group(2)!;
      final pm = m.group(3)!.toUpperCase();
      return mm == '00' ? '$hh$pm' : '$hh:$mm$pm';
    }

    final hoursStr = (timingStart == '--' && timingEnd == '--')
        ? null
        : '${compactTime(timingStart)}-${compactTime(timingEnd)}';

    void openDetail() {
      ProfileClickTracker.track(
        userId: service.id ?? '',
        source: ChatClickSource.searchResult,
      );
      openVisitProfile(
        accountType: AppConstants.individual,
        profileType: SELF_EMPLOYED,
        userId: service.id,
        serviceData: service,
      );
    }

    return InkWell(
      onTap: openDetail,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: palette.cardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Band 1: photo | name + trade + facts ─────
            //
            // IntrinsicHeight + stretch is what keeps the two columns level on
            // every device. The photo declares no height of its own, so the
            // row takes its height from the text column — longer trade names,
            // a bigger system font, a narrow screen that wraps something — and
            // then stretches the photo to match. A fixed photo height only
            // lines up on the one screen it was measured against.
            LayoutBuilder(
              builder: (context, constraints) {
                final photoWidth = (constraints.maxWidth * _cardPhotoWidthRatio)
                    .clamp(_cardPhotoMinWidth, _cardPhotoMaxWidth);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: photoWidth,
                        child: _cardPhoto(service, heroImage, ratingValue),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  // The name still opens the poster's own profile;
                                  // everywhere else on the card opens the service.
                                  child: DiscoverProfileTap(
                                    accountType: service.accountType,
                                    userId: service.id,
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: AppConstants.OpenSans,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: _cardInk,
                                        letterSpacing: -0.2,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                _overflowMenu(service),
                              ],
                            ),
                            if (professionLabel.isNotEmpty) ...[
                              SizedBox(height: SizeConfig.size6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _chipBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: CustomText(
                                  professionLabel,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            ..._infoRows(service, distStr, hoursStr),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ─── Band 2: the services checklist ───────────
            if (visibleServices.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(SizeConfig.size12),
                decoration: BoxDecoration(
                  color: palette.panelBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                // No heading and no divider: the design lets the ticks say what
                // the block is, and an "Expertise" label above six items the
                // reader can already see is a row of height spent on nothing.
                child:
                    _servicesGrid(visibleServices, extraServices, openDetail),
              ),
            ],

            // ─── Band 3: price | Book Now ─────────────────
            SizedBox(height: SizeConfig.size12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Expanded, NOT a bare Column followed by a Spacer. A price
                // range is the widest thing on this row ("₹10,000 – ₹1,00,000"
                // is ~130dp at 19px) and the CTA is another ~136dp; on a 320dp
                // phone the card's inner width is ~266dp, so the two together
                // overrun it, the Spacer collapses to nothing and the row
                // overflows. Giving the price the leftover space instead lets
                // it ellipsize and keeps the button whole — the button is the
                // thing that must never be clipped.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        'Starting From',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _cardInkSoft,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: CustomText(
                              priceStr,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (priceStr != '—' && priceUnit.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: CustomText(
                                '/$priceUnit',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _cardInkSoft,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                InkWell(
                  onTap: openDetail,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 46,
                    // 18, not 22: the CTA is the one fixed-width thing on the
                    // row, so every point it gives back is a point the price
                    // keeps on a narrow screen.
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          'Book Now',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The square provider photo, with the rating pill inset into its top-left
  /// corner exactly as the design places it.
  Widget _cardPhoto(ServiceData service, String heroImage, String? rating) {
    // No width or height of its own — the caller sets the width from the card's
    // measurements and the row's stretch sets the height. `StackFit.expand` is
    // what passes that down: without it a Stack whose children are all
    // positioned collapses, and the photo would vanish.
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ClipRRect(
            // Tighter than the card's own corner, per the design — the photo
            // reads as a framed portrait, not as a pill.
            borderRadius: BorderRadius.circular(10),
            child: heroImage.isEmpty
                ? _professionHero(service)
                : CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    // A quarter of the old budget: this slot is a ~120dp
                    // thumbnail now, not a full-width letterbox.
                    memCacheWidth: 400,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFEDEFF4)),
                    errorWidget: (_, __, ___) => _professionHero(service),
                  ),
          ),
        ),
        Positioned(left: 6, top: 6, child: _photoRatingBadge(rating)),
      ],
    );
  }

  /// Star + score, inset into the photo.
  ///
  /// A near-opaque black plate with a soft 10px radius, which is what the
  /// design draws — not the translucent stadium with a white ring that the map
  /// sheet uses ([_buildRatingBadge]). On a dark portrait, which is most of
  /// them, a see-through pill has nothing to sit against.
  Widget _photoRatingBadge(String? rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(
            rating ?? 'NA',
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  /// The fact rows under the trade chip — a white glyph plate, then a bold
  /// label. The design shows experience and distance.
  ///
  /// Experience comes from `experienceStartDate` (see [_experienceLabel]), and
  /// plenty of providers have not set one. Rather than leave the slot empty it
  /// falls back to opening hours — which is where the old card's floating
  /// "Open | hours" chip went. A card with one lonely row reads as broken; a
  /// card with hours reads as a provider you can call today.
  List<Widget> _infoRows(
      ServiceData service, String? distStr, String? hoursStr) {
    final rows = <Widget>[];
    final experience = _experienceLabel(service);
    if (experience != null) {
      rows.add(
          _infoRow(icon: Icons.workspace_premium_outlined, label: experience));
    } else if (hoursStr != null) {
      rows.add(
          _infoRow(icon: Icons.access_time_rounded, label: 'Open $hoursStr'));
    }
    if (distStr != null) {
      // The app's own pin rather than a Material glyph — it is the same mark
      // the rest of the app points to a place with.
      rows.add(
          _infoRow(assetPath: AppIconAssets.location_outline, label: distStr));
    }
    return [
      for (final row in rows) ...[SizedBox(height: SizeConfig.size8), row],
    ];
  }

  /// One fact row. Pass [assetPath] for an app SVG or [icon] for a Material
  /// glyph — the distance row uses the former, so the two are not
  /// interchangeable at the call site.
  ///
  /// The white plate keeps a [_glyphPlateBorder] hairline so its shape stays
  /// defined on the purple palette as well as the teal one, where white on
  /// white-ish would otherwise have nothing to sit against.
  Widget _infoRow({IconData? icon, String? assetPath, required String label}) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _glyphPlateBorder, width: 1),
          ),
          child: assetPath != null
              ? LocalAssets(
                  imagePath: assetPath,
                  height: 15,
                  width: 15,
                  imgColor: AppColors.primaryColor,
                )
              : Icon(icon, size: 16, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: CustomText(
            label,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _cardInk,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// "10 Years Experience", or null when there is nothing to say.
  ///
  /// Two sources, in order:
  ///  1. an `experience` total the backend already worked out — if the server
  ///     has done the arithmetic, re-deriving it here is just a second answer
  ///     that can disagree with the provider's own profile;
  ///  2. otherwise the JOINING DATE (`experienceStartDate`), run through the
  ///     shared [calculateExperience] so the card says exactly what the
  ///     provider's own service screen says.
  ///
  /// Never from `experiences` — that field is a free-text list of past roles,
  /// not a duration.
  ///
  /// Under a year it reports months rather than giving up: a provider who
  /// started eight months ago has eight months of experience, and "0 Years"
  /// would read as an accusation.
  String? _experienceLabel(ServiceData service) {
    final explicit = _explicitExperienceLabel(service.experience);
    if (explicit != null) return explicit;

    final raw = service.experienceStartDate?.trim();
    if (raw == null || raw.isEmpty) return null;
    // Guard the parse ourselves: calculateExperience swallows a bad date into
    // {0, 0}, which is indistinguishable from "joined this month" and would
    // print a row saying nothing.
    if (DateTime.tryParse(raw) == null) return null;

    final exp = calculateExperience(raw);
    final years = exp['years'] ?? 0;
    final months = exp['months'] ?? 0;
    if (years >= 1) {
      return '$years ${years == 1 ? 'Year' : 'Years'} Experience';
    }
    if (months >= 1) {
      return '$months ${months == 1 ? 'Month' : 'Months'} Experience';
    }
    return null;
  }

  /// Renders a backend-supplied experience total.
  ///
  /// Accepts either a bare count (`10`, `"10"`) or a phrase the server already
  /// worded (`"10 years"`), and only appends "Experience" when it is missing —
  /// so a server that starts sending a full label does not produce
  /// "10 Years Experience Experience".
  String? _explicitExperienceLabel(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final years = num.tryParse(value);
    if (years != null) {
      if (years <= 0) return null;
      final n = years == years.roundToDouble() ? years.toInt() : years;
      return '$n ${years == 1 ? 'Year' : 'Years'} Experience';
    }
    if (value.toLowerCase().contains('experience')) return value;
    return '$value Experience';
  }

  /// The "⋮" at the card's top-right.
  ///
  /// Share and save used to be two circles floating on the photo. The design
  /// has a single control in this corner, so they became its menu — a sheet
  /// rather than a popup so it needs no [BuildContext] from inside the list
  /// builder, and so both actions carry a label instead of a bare glyph.
  Widget _overflowMenu(ServiceData service) {
    return InkWell(
      onTap: () => _showProviderMenu(service),
      borderRadius: BorderRadius.circular(999),
      child: const Padding(
        padding: EdgeInsets.only(left: 8, bottom: 6),
        child: Icon(Icons.more_vert, size: 20, color: _cardInkSoft),
      ),
    );
  }

  void _showProviderMenu(ServiceData service) {
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: SizeConfig.size8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabHandle(),
              _menuAction(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  Get.back<void>();
                  _shareProvider(service);
                },
              ),
              Obx(() {
                final saved = controller.isProviderLocallySaved(service.id);
                return _menuAction(
                  icon: saved ? Icons.star_rounded : Icons.star_border_rounded,
                  iconColor: saved ? const Color(0xFFFFB400) : _cardInk,
                  label: saved ? 'Saved' : 'Save',
                  onTap: () {
                    Get.back<void>();
                    _toggleSave(service);
                  },
                );
              }),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _menuAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = _cardInk,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20, vertical: SizeConfig.size14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            SizedBox(width: SizeConfig.size14),
            CustomText(
              label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _cardInk,
            ),
          ],
        ),
      ),
    );
  }

  /// Photo stand-in for a provider who has none — their PROFESSION's tile from
  /// `assets/discover/`, the same art the category that led here was drawn
  /// with.
  ///
  /// Fills the slot rather than being letterboxed inside it: the tiles are
  /// 160×160 squares and the photo slot is a square too, so `cover` scales
  /// without cropping anything and the tile's own rounded wash becomes the
  /// photo's face. That only works because the design's photo is square —
  /// the old full-width hero had to inset the tile to keep the subject.
  ///
  /// Falls back to a neutral plate when the profession has no tile:
  /// [individualProfessionIcons] covers every current category, but it is data
  /// and a new profession can arrive before its art does.
  Widget _professionHero(ServiceData service) {
    final tile = _professionTile(service);
    if (tile == null) return Container(color: const Color(0xFFEDEFF4));
    return LocalAssets(imagePath: tile, boxFix: BoxFit.cover);
  }

  /// Asset path of the profession illustration for [service], or null.
  ///
  /// Three sources, cheapest first: the provider's own `profession`, then the
  /// category the user picked to get here (its slug, then its display name).
  /// The screen is scoped to ONE profession, so the selection is a reliable
  /// answer even when a provider record carries nothing — which is the case
  /// that matters, since a provider with no photo often has a thin record all
  /// round.
  ///
  /// Every candidate is normalised to the map's key shape (`Home Tutor` →
  /// `HOME_TUTOR`): the API has sent both the tag id and the display label in
  /// this field, and keying on only one of them would blank the hero for half
  /// the categories.
  String? _professionTile(ServiceData service) {
    String? lookup(String? raw) {
      if (raw == null) return null;
      final key = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
      return key.isEmpty ? null : individualProfessionIcons[key];
    }

    final selected = controller.selectedEarnServiceData.value;
    return lookup(service.profession) ??
        lookup(selected?.slugId) ??
        lookup(selected?.name);
  }

  /// Merges the provider's `serviceOffered` + `typesOfWork` into a single
  /// deduped (case-insensitive) list, preserving first-seen order.
  List<String> _combinedServices(ServiceData service) {
    final out = <String>[];
    final seen = <String>{};
    final raw = <String>[
      ...?service.service?.serviceOffered,
      ...?service.service?.typesOfWork,
    ];
    for (final item in raw) {
      final t = item.trim();
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }
    return out;
  }

  /// Two-column checklist inside the "Expertise" box. [items] is already
  /// capped; when [extra] > 0 a trailing "+N more services" link (→ [onMore])
  /// fills the final cell.
  Widget _servicesGrid(List<String> items, int extra, VoidCallback onMore) {
    final cells = <Widget>[
      ...items.map(_serviceCheckItem),
      if (extra > 0) _moreServicesLink(extra, onMore),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cells[i]),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child:
                i + 1 < cells.length ? cells[i + 1] : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < cells.length) {
        rows.add(SizedBox(height: SizeConfig.size8));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _serviceCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Outlined tick, per the design — the filled disc read as a status
        // indicator ("done") rather than as a list bullet.
        Icon(Icons.check_circle_outline_rounded,
            size: 16, color: AppColors.green00),
        const SizedBox(width: 6),
        Expanded(
          child: CustomText(
            text,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _serviceInk,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _moreServicesLink(int extra, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CustomText(
        '+$extra more services',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
        // Matches the tick rows either side of it. Without a cap this wraps to
        // two lines in a narrow cell and the last grid row grows taller than
        // the ones above it.
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ─── Card actions (share + local save), reached from the "⋮" menu ──────────
  void _shareProvider(ServiceData service) {
    ShareService.instance.shareProfile(
      userId: service.id ?? '',
      subject: service.name,
    );
  }

  void _toggleSave(ServiceData service) {
    final wasSaved = controller.isProviderLocallySaved(service.id);
    controller.toggleProviderLocalSave(service.id);
    if (!wasSaved) {
      commonSnackBar(message: 'Saved — full favourites coming soon');
    }
  }

  // ─── Badges ────────────────────────────────────────────────────
  /// Star + score pill, top-left of the hero (assets/img.png): a translucent
  /// dark stadium with a white ring and white numerals — the same glassy
  /// treatment as the share/save circles, so the hero's overlays read as one
  /// set and stay legible on any photo.
  ///
  /// Always rendered so the hero's left slot is never empty. Shows the score
  /// when the provider has one and "NA" when they don't — never a fabricated
  /// number or a misleading 0.
  Widget _buildRatingBadge(String? rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.38),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 14, width: 14),
          const SizedBox(width: 6),
          CustomText(
            rating ?? 'NA',
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.greyE5.withValues(alpha: 0.4),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined,
              size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 3),
          CustomText(
            text,
            fontSize: 11,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  /// Availability pill driven by the response's `isLive`. Solid white fill (not
  /// a translucent tint) because it overlays photos/maps, where a see-through
  /// pill would be unreadable.
  Widget _buildLiveBadge(bool isLive) {
    final Color fg =
        isLive ? Colors.green.shade700 : AppColors.secondaryTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F001120),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isLive ? Colors.green : AppColors.grey9B,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          CustomText(
            isLive ? AppStrings.online.tr : AppStrings.offline.tr,
            fontSize: 11,
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  // ─── Timing helpers ───
  DateTime _parse12HourTime(String timeStr) {
    final format = RegExp(r'(\d+):(\d+)\s*(AM|PM)');
    final match = format.firstMatch(timeStr.trim());
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);
      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;
      return DateTime(0, 1, 1, hour, minute);
    }
    return DateTime(0);
  }

  Map<String, String> getMinMaxTimings(List<Timings>? timingsList) {
    if (timingsList == null || timingsList.isEmpty)
      return {"start": "--", "end": "--"};
    Timings? earliest = timingsList.first;
    Timings? latest = timingsList.first;
    for (final t in timingsList) {
      if (_parse12HourTime(t.start ?? "00:00 AM")
          .isBefore(_parse12HourTime(earliest?.start ?? "00:00 AM"))) {
        earliest = t;
      }
      if (_parse12HourTime(t.end ?? "00:00 AM")
          .isAfter(_parse12HourTime(latest?.end ?? "00:00 AM"))) {
        latest = t;
      }
    }
    return {"start": earliest?.start ?? "--", "end": latest?.end ?? "--"};
  }
}

/// Pins the sort-chip row to the top of the sheet. Fixed extent (chips are a
/// constant 32 px tall plus padding) so it neither collapses nor floats.
class _PinnedFilterBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _PinnedFilterBar({required this.child});

  static const double _extent = 52;

  @override
  double get minExtent => _extent;
  @override
  double get maxExtent => _extent;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_PinnedFilterBar oldDelegate) =>
      oldDelegate.child != child;
}

/// Full-screen map page reached by tapping the backdrop (or the expand button)
/// on [SelfProfessionDiscoverScreenV2]. Loads every provider (unpaginated) via
/// [DiscoverController.fetchAllEarnServicesForMap] and renders them through
/// `google_maps_flutter`'s built-in clustering so 100+ pins stay smooth —
/// nearby providers collapse into a count badge that splits open on zoom-in.
///
/// Initial zoom is `12` — roughly a 25–50 km frame around the user, matching
/// the "city-radius" feel of mainstream discover apps.
class _SelfProfessionMapScreenV2 extends StatefulWidget {
  final String earnServiceType;
  final String subType;
  final void Function(BuildContext context, ServiceData service) onMarkerTap;

  const _SelfProfessionMapScreenV2({
    required this.earnServiceType,
    required this.subType,
    required this.onMarkerTap,
  });

  @override
  State<_SelfProfessionMapScreenV2> createState() =>
      _SelfProfessionMapScreenV2State();
}

class _SelfProfessionMapScreenV2State
    extends State<_SelfProfessionMapScreenV2> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _serviceIcon;

  final DiscoverController _ctrl = Get.find<DiscoverController>();
  static const ClusterManagerId _clusterManagerId =
      ClusterManagerId('self_profession_services_v2');

  @override
  void initState() {
    super.initState();
    _ctrl.fetchAllEarnServicesForMap(
      earnServiceType: widget.earnServiceType,
      subType: widget.subType,
    );
    // Pre-render the custom marker icon once; cluster taps pop the unclustered
    // marker so this is what the user actually sees.
    DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded).then((d) {
      if (mounted) setState(() => _serviceIcon = d);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Builds the marker set fed to [GoogleMap.markers]. Each marker is stamped
  /// with [_clusterManagerId] so the platform-side cluster manager can group
  /// nearby ones into a numbered badge automatically.
  Set<Marker> _buildMarkers(List<ServiceData> services) {
    final markers = <Marker>{};
    for (final s in services) {
      final lat = s.userLocation?.lat?.toDouble();
      final lng = s.userLocation?.lon?.toDouble();
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      markers.add(
        Marker(
          markerId: MarkerId(s.id ?? '${s.name}_$lat,$lng'),
          position: LatLng(lat, lng),
          clusterManagerId: _clusterManagerId,
          icon: _serviceIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: s.name ?? AppStrings.unknownUser.tr,
            snippet: s.profession ?? '',
            onTap: () => widget.onMarkerTap(context, s),
          ),
          onTap: () => widget.onMarkerTap(context, s),
        ),
      );
    }
    return markers;
  }

  /// Frames the camera around every position inside the tapped cluster so the
  /// cluster expands cleanly into individual pins.
  Future<void> _zoomToCluster(Cluster cluster) async {
    if (_mapController == null) return;
    final markers = cluster.markerIds;
    if (markers.length <= 1) {
      _mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(cluster.position, 15));
      return;
    }
    _mapController!
        .animateCamera(CameraUpdate.newLatLngBounds(cluster.bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    // Frame on the picked earn-discover location when set, else the device fix.
    final initialLat = _ctrl.earnDiscoverLat ??
        (LocationService.lat != 0.0 ? LocationService.lat : 28.6139);
    final initialLng = _ctrl.earnDiscoverLng ??
        (LocationService.lng != 0.0 ? LocationService.lng : 77.2090);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final markers = _buildMarkers(_ctrl.earnServiceMapList);
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(initialLat, initialLng),
                zoom: 12,
              ),
              markers: markers,
              clusterManagers: {
                ClusterManager(
                  clusterManagerId: _clusterManagerId,
                  onClusterTap: _zoomToCluster,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (c) => _mapController = c,
            );
          }),
          // Loading overlay while the unpaginated fetch is in flight.
          Obx(() {
            final isLoading =
                _ctrl.earnServiceMapResponse.value.status == Status.INITIAL;
            if (!isLoading) return const SizedBox.shrink();
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }),
          // Banner-style header.
          Positioned(
            top: statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: bannerMapLocationPill(
                    label: _ctrl.earnDiscoverLocationLabel.value.isNotEmpty
                        ? _ctrl.earnDiscoverLocationLabel.value
                        : null,
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                bannerMapCircleIconButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                          LatLng(initialLat, initialLng), 13),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final count = _ctrl.earnServiceMapList.where((s) {
                final lat = s.userLocation?.lat?.toDouble();
                final lng = s.userLocation?.lon?.toDouble();
                return lat != null && lng != null && !(lat == 0 && lng == 0);
              }).length;
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          '$count ${count == 1 ? AppStrings.serviceProviderOnMapSuffix.tr : AppStrings.serviceProvidersOnMapSuffix.tr}',
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
