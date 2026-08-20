import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
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
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Consultant card palette (assets/img.png) ───────────────────────────────
// Deliberately identical to the block at the top of
// `self_profession_discover_screen_v2.dart`: the two discover flows show the
// same card, and a value that drifts between them shows up as one list looking
// subtly wrong beside the other. Change one, change both.

/// Tinted surface set for one consultant card. Cards alternate between the two
/// entries in [_consultantCardPalettes] so a scrolling list reads as a rhythm
/// rather than a stack of identical blocks.
class _ConsultantCardPalette {
  final Color cardBg;
  final Color cardBorder;

  /// The services checklist panel — one step more saturated than [cardBg],
  /// which is what separates it from the body without needing a border.
  final Color panelBg;

  const _ConsultantCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.panelBg,
  });
}

const _consultantCardPalettes = <_ConsultantCardPalette>[
  _ConsultantCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    panelBg: Color(0xFFDBFAFD),
  ),
  _ConsultantCardPalette(
    cardBg: Color(0xFFF9EDFF),
    cardBorder: Color(0xFFE7CBF5),
    panelBg: Color(0xFFF4DDFF),
  ),
];

/// Profession pill behind the blue label. Shared by both palettes — the trade
/// chip and the CTA are the card's accent, and swapping them per card would
/// leave nothing constant to recognise.
const Color _chipBg = Color(0xFFD6F2FF);

/// Hairline on the white glyph plates. The design draws no stroke there at
/// all; this is the lightest cool hairline that still resolves as an edge, and
/// it earns its keep on the purple palette where white-on-white-ish has
/// nothing to sit against.
const Color _glyphPlateBorder = Color(0xFFDCEFF4);

/// Name and the two fact rows.
const Color _cardInk = Color(0xFF0D161F);

/// "Starting From", the price unit, and the overflow glyph.
const Color _cardInkSoft = Color(0xFF617077);

/// Checklist entries — lighter than [_cardInk]. The service names are
/// secondary to the consultant's name and read as a list, not as headlines.
const Color _serviceInk = Color(0xFF5C6873);

const double _cardRadius = 18;

/// The photo's width as a share of the card's inner width — the proportion the
/// design uses (216 of 632).
///
/// A share, not a fixed size, because the card has to hold on any screen. The
/// HEIGHT is not set here at all: the photo stretches to whatever the items
/// beside it need (see the `IntrinsicHeight` in the top band), so the two
/// columns finish level on a small phone, on a tablet, and at any system text
/// scale — none of which a hard-coded height survives.
const double _cardPhotoWidthRatio = 0.34;

/// Bounds for the above. Below the minimum a face is unreadable; above the
/// maximum the photo starts eating the space the name and the trade need. The
/// ceiling is raised on tablets, where the card is roughly twice as wide.
const double _cardPhotoMinWidth = 96;
double get _cardPhotoMaxWidth => SizeConfig.isTablet ? 220 : 148;

/// **Professionals & Consultants results — v2.**
///
/// The only consultant results screen — it replaced the v1
/// `ProfessionConsultantDiscoverScreen` (banner carousel + sticky category
/// header), which was deleted once this landed. Chromed to match its entry
/// screen ([ProfessionConsultantDiscoverEntryScreen]): a full-bleed map
/// backdrop with the consultant pins, a banner header (back + location pill +
/// expand), and the results themselves in a [DraggableScrollableSheet] the user
/// can pull up to near-full-screen or push down to reveal the map.
///
/// The backdrop map is decorative (gestures absorbed) — tapping anywhere on it,
/// or the expand button, opens the dedicated clustered full-screen map.
///
/// **Distances are computed client-side.** The consultant endpoint returns no
/// `distanceKm` (unlike self-work), so the origin is the location picked on the
/// entry screen when there is one, else the device fix. Everything is keyed on
/// the consultant id so pagination appends don't re-run the maths.
class ProfessionConsultantDiscoverScreenV2 extends StatefulWidget {
  final List<ProfessionTypeData> professionalConsultantCategories;
  final ProfessionTypeData? selectedProfessionConsultantData;

  const ProfessionConsultantDiscoverScreenV2({
    super.key,
    required this.professionalConsultantCategories,
    this.selectedProfessionConsultantData,
  });

  @override
  State<ProfessionConsultantDiscoverScreenV2> createState() =>
      _ProfessionConsultantDiscoverScreenV2State();
}

class _ProfessionConsultantDiscoverScreenV2State
    extends State<ProfessionConsultantDiscoverScreenV2> {
  final controller = getOrPut(() => DiscoverController());

  /// Custom pin for the backdrop map — rendered once, reused for every marker.
  BitmapDescriptor? _markerIcon;

  static const LatLng _fallbackCenter = LatLng(28.6139, 77.2090); // Delhi

  // ─── Client-side distance state ────────────────────────────────────────────
  // Keyed on consultant id so it survives pagination appends without
  // recomputing per row.
  double? _originLat;
  double? _originLng;
  final Map<String, double> _distances = {};
  bool _locationRequested = false;

  @override
  void initState() {
    super.initState();
    final selected = widget.selectedProfessionConsultantData;
    controller.selectedProfessionalConsultantData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    // Skip refetch on re-entry when the cached list is fresh for this
    // category; category taps on the entry screen force a fresh fetch.
    controller.fetchProfessionalConsultantServicesIfNeeded();
    _ensureOrigin();
    DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded).then((d) {
      if (mounted) setState(() => _markerIcon = d);
    });
  }

  /// Establishes the distance origin: the location picked on the entry screen
  /// wins, then the cached device fix, and only if neither is set do we ask the
  /// platform for GPS. Quiet failure when permission is denied — every distance
  /// falls back to `—` and the Nearest sort degrades to server order.
  Future<void> _ensureOrigin() async {
    if (_locationRequested) return;
    _locationRequested = true;

    final pickedLat = controller.earnDiscoverLat;
    final pickedLng = controller.earnDiscoverLng;
    if (pickedLat != null && pickedLng != null && !(pickedLat == 0 && pickedLng == 0)) {
      _originLat = pickedLat;
      _originLng = pickedLng;
      _recomputeDistances();
      if (mounted) setState(() {});
      return;
    }
    if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
      _originLat = LocationService.lat;
      _originLng = LocationService.lng;
      _recomputeDistances();
      if (mounted) setState(() {});
      return;
    }
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          return;
        }
      } else if (perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _originLat = pos.latitude;
      _originLng = pos.longitude;
      _recomputeDistances();
      if (mounted) setState(() {});
    } catch (_) {/* swallow — distance just stays unknown */}
  }

  /// Computes road-adjusted km for every loaded consultant that has usable
  /// coords. Idempotent — safe to call on every Obx rebuild.
  void _recomputeDistances() {
    if (_originLat == null || _originLng == null) return;
    for (final item in controller.professionalConsDataList) {
      final id = item.id ?? item.userId ?? '';
      if (id.isEmpty || _distances.containsKey(id)) continue;
      final lat = _toDouble(item.userDetails?.userLocation?.lat);
      final lng = _toDouble(item.userDetails?.userLocation?.lon);
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      final meters =
          Geolocator.distanceBetween(_originLat!, _originLng!, lat, lng);
      // 1.27× road factor mirrors the helper in
      // view_business_details_controller.dart so distances feel consistent
      // across the app.
      _distances[id] = (meters * 1.27) / 1000;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? _distanceFor(ProfessionalConsData item) =>
      _distances[item.id ?? item.userId ?? ''];

  // ─── Sorting / formatting helpers ──────────────────────────────────────────

  /// Returns a new list sorted by the active filter. Items missing the
  /// comparator key sort to the end.
  List<ProfessionalConsData> _applySort(
      List<ProfessionalConsData> items, CategoryFilter filter) {
    final sorted = List<ProfessionalConsData>.from(items);
    switch (filter) {
      case CategoryFilter.nearest:
        sorted.sort((a, b) {
          final da = _distanceFor(a) ?? double.infinity;
          final db = _distanceFor(b) ?? double.infinity;
          return da.compareTo(db);
        });
        break;
      case CategoryFilter.experienced:
        sorted.sort((a, b) {
          final aMonths = (a.about?.totalExperience?.years ?? 0) * 12 +
              (a.about?.totalExperience?.months ?? 0);
          final bMonths = (b.about?.totalExperience?.years ?? 0) * 12 +
              (b.about?.totalExperience?.months ?? 0);
          return bMonths.compareTo(aMonths); // descending
        });
        break;
      case CategoryFilter.priceLowToHigh:
        sorted.sort((a, b) {
          final ap = a.pricing?.amount ?? 0;
          final bp = b.pricing?.amount ?? 0;
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

  /// Converts an all-caps category name like "ADVOCATE" or "TAX_CONSULTANT"
  /// into a human-readable label ("Advocate" / "Tax Consultant"). Leaves
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

  /// Section title like "Advocates near you". Light pluralization: append "s"
  /// unless the label already ends with "s" or ")".
  String _nearYouTitle(String pretty) {
    if (pretty.isEmpty) return 'Consultants near you';
    final needsS = !pretty.toLowerCase().endsWith('s') && !pretty.endsWith(')');
    return '$pretty${needsS ? 's' : ''} near you';
  }

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

  /// Pins for the consultants already loaded in the list. The full
  /// (unpaginated, clustered) set lives on the dedicated map screen.
  /// Consultant coordinates for the static backdrop.
  ///
  /// Plain points rather than [Marker]s — the backdrop is a static image now,
  /// so there is nothing to attach a tap handler or an info window to. The
  /// clustered full-screen map behind the tap still builds real markers.
  List<({double lat, double lng})> _backdropPins() {
    final pins = <({double lat, double lng})>[];
    for (final c in controller.professionalConsDataList) {
      final lat = _toDouble(c.userDetails?.userLocation?.lat);
      final lng = _toDouble(c.userDetails?.userLocation?.lon);
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      pins.add((lat: lat, lng: lng));
    }
    return pins;
  }

  Set<Marker> _backdropMarkers() {
    final markers = <Marker>{};
    for (final c in controller.professionalConsDataList) {
      final lat = _toDouble(c.userDetails?.userLocation?.lat);
      final lng = _toDouble(c.userDetails?.userLocation?.lon);
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      markers.add(Marker(
        markerId: MarkerId(c.id ?? c.userId ?? '${c.userDetails?.name}_$lat,$lng'),
        position: LatLng(lat, lng),
        icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
      ));
    }
    return markers;
  }

  void _openFullMap() {
    Get.to(() => _ProfessionConsultantMapScreenV2(
          onMarkerTap: _showConsultantMapSheet,
        ));
  }

  /// Bottom sheet shown when a map marker is tapped — compact consultant
  /// summary (avatar, name, tagline, price, distance) with a "View Profile" CTA
  /// into [DiscoverProfessionalsViewScreen]. Takes the host [BuildContext] so
  /// the sheet renders over whichever screen the marker was tapped on.
  void _showConsultantMapSheet(
      BuildContext hostContext, ProfessionalConsData service) {
    final name = (service.basicDetails?.fullName?.trim().isNotEmpty ?? false)
        ? service.basicDetails!.fullName!
        : (service.userDetails?.name ?? AppStrings.unknownUser.tr);
    final amount = service.pricing?.amount ?? 0;
    final priceDisplay = amount == 0 ? '—' : '₹${formatIndianNumber(amount)}';
    final priceType = (service.pricing?.type ?? '').trim();
    final mode = (service.pricing?.consultationMode ?? '').trim();
    final distanceKm = _distanceFor(service);
    final distance = distanceKm == null
        ? null
        : '${distanceKm < 10 ? distanceKm.toStringAsFixed(1) : distanceKm.toStringAsFixed(0)} km';

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
                    CachedAvatarWidget(
                      imageUrl: service.userDetails?.profileImage ?? '',
                      size: SizeConfig.size60,
                      borderColor: Colors.white,
                      borderRadius: SizeConfig.size30,
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            name,
                            fontSize: SizeConfig.large18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((service.basicDetails?.professionalTitle ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 2),
                            CustomText(
                              service.basicDetails!.professionalTitle!,
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
                              if (distance != null) _buildDistanceBadge(distance),
                              if (mode.isNotEmpty) _buildModeBadge(mode),
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
                            if (priceType.isNotEmpty)
                              TextSpan(
                                text: ' / $priceType',
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
                          userId: service.userId ?? '',
                          source: ChatClickSource.searchResult,
                        );
                        openVisitProfile(
                              accountType: AppConstants.individual,
                              profileType: PROFESSIONAL,
                              userId: service.userId,
                              professionalData: service,
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
                              color:
                                  AppColors.primaryColor.withValues(alpha: 0.25),
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
      controller.fetchProfessionalConsultantServices(isLoadMore: true);
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
                  // interact with. The consultant pins survive as static
                  // markers.
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
                      final pretty = _prettyCategoryName(controller
                              .selectedProfessionalConsultantData.value?.name ??
                          '');
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
                if (controller.isProfConServiceLoading.value &&
                    controller.professionalConsDataList.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (controller.professionalConsDataList.isEmpty) {
                  final selectedName = controller
                          .selectedProfessionalConsultantData.value?.name ??
                      '';
                  // Server returns categories in upper-case (e.g. "ADVOCATE");
                  // flip to title-case so the message reads naturally.
                  final pretty = _prettyCategoryName(selectedName);
                  final message = pretty.isNotEmpty
                      ? AppStrings.noConsultantsFoundNearYou
                          .trParams({'category': pretty})
                      : AppStrings.noServicesFound.tr;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: EmptyStateWidget(message: message)),
                  );
                }
                // Recompute the distance cache cheaply for any new items
                // appended by the load-more sentinel, then sort.
                _recomputeDistances();
                final sorted = _applySort(
                  controller.professionalConsDataList,
                  controller.selectedFilter.value,
                );
                final showMoreSpinner =
                    controller.isProfConServiceLoadingMore.value;
                final rows = buildNativeAdRows(sorted.length);
                return SliverList.builder(
                  itemCount: rows.length + (showMoreSpinner ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    final row = rows[index];
                    if (row.isAd) {
                      return NativeAdSlot(
                        adOrdinal: row.adOrdinal,
                        keyPrefix: 'consultant_v2_native_ad',
                      );
                    }
                    // Palette alternates on the content index (not the row
                    // index) so injected ad rows don't break the rhythm.
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

  /// **Consultant card**, built to `assets/img.png` — the same anatomy the
  /// self-profession v2 card uses, so both discover flows read identically.
  ///
  /// Three bands: a square photo (rating pill inset top-left) beside name →
  /// trade chip → two glyph-and-label fact rows with an overflow "⋮"; then the
  /// services checklist on its own tinted panel; then price and "Book Now →".
  ///
  /// **Where the old card's parts went:** share and save moved off the photo
  /// into the "⋮" menu; the address line was dropped, the design carrying
  /// distance alone; the consultation-mode pill joined the trade chip on the
  /// chip row (it is the one thing a consultant card carries that a
  /// home-service card doesn't); and today's hours became the fallback for the
  /// experience row rather than a chip over the photo — see [_infoRows].
  Widget _buildSpecCard(ProfessionalConsData service, int index) {
    final palette =
        _consultantCardPalettes[index.abs() % _consultantCardPalettes.length];

    // ─── Data extraction with sensible fallbacks ──────────────────
    final name = (service.basicDetails?.fullName?.trim().isNotEmpty ?? false)
        ? service.basicDetails!.fullName!
        : (service.userDetails?.name ?? AppStrings.unknownUser.tr);
    final amount = service.pricing?.amount ?? 0;
    final priceType = (service.pricing?.type ?? '').trim();
    final mode = (service.pricing?.consultationMode ?? '').trim();
    final distanceKm = _distanceFor(service);
    final gallery = service.gallery?.signedUrls ?? const <String>[];

    // Hero image: prefer an uploaded gallery shot, then the profile photo,
    // then the curated basic-details photo.
    final profileImage = (service.userDetails?.profileImage ?? '').trim();
    final heroImage = gallery.isNotEmpty
        ? gallery.first
        : (profileImage.isNotEmpty
            ? profileImage
            : (service.basicDetails?.profilePhotoUrl ?? '').trim());

    // Trade label for the pill, best-first:
    //   1. the professional title they typed themselves;
    //   2. `userDetails.designation` — "HR Consultant", "Market Research
    //      Consultant". In practice this is the one that fires: live records
    //      carry an almost-empty `basicDetails` but always a designation, and
    //      it is far more specific than the bucket they were found under;
    //   3. the browsed category, as a last resort. It is a SLUG, so this path
    //      renders "Business Hr Consultant" — correct but graceless, which is
    //      why it sits last.
    final professionLabel = _prettyCategoryName([
      service.basicDetails?.professionalTitle,
      service.userDetails?.designation,
      controller.selectedProfessionalConsultantData.value?.name,
    ].firstWhere((t) => (t ?? '').trim().isNotEmpty, orElse: () => '')!.trim());

    final priceStr = amount == 0 ? '—' : '₹${formatIndianNumber(amount)}';
    final distStr = distanceKm == null
        ? null
        : '${distanceKm < 10 ? distanceKm.toStringAsFixed(1) : distanceKm.toStringAsFixed(0)} Km Away';
    final ratingValue = (service.rating != null && service.rating != 0)
        ? service.rating.toString()
        : null;
    final hoursStr = _todayHours(service);

    // "Services offered" checklist — certificate titles first (they read as
    // concrete offerings), falling back to portfolio project titles.
    var serviceTitles = (service.certificates ?? [])
        .map((c) => (c.title ?? '').trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (serviceTitles.isEmpty) {
      serviceTitles = (service.portfolio ?? [])
          .map((p) => (p.projectTitle ?? '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    final totalServices = serviceTitles.length;
    final showMoreServices = totalServices > 6;
    final visibleServices = showMoreServices
        ? serviceTitles.take(5).toList()
        : serviceTitles.take(6).toList();
    final extraServices = showMoreServices ? totalServices - 5 : 0;

    void openDetail() {
      ProfileClickTracker.track(
        userId: service.userId ?? '',
        source: ChatClickSource.searchResult,
      );
      openVisitProfile(
        accountType: AppConstants.individual,
        profileType: PROFESSIONAL,
        userId: service.userId,
        professionalData: service,
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
            // every device. The photo declares no height of its own, so the row
            // takes its height from the text column and then stretches the
            // photo to match. A fixed photo height only lines up on the one
            // screen it was measured against.
            LayoutBuilder(
              builder: (context, constraints) {
                final photoWidth =
                    (constraints.maxWidth * _cardPhotoWidthRatio)
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
                                  // The name still opens the consultant's own
                                  // profile; the rest of the card opens the
                                  // listing.
                                  child: DiscoverProfileTap(
                                    accountType:
                                        service.userDetails?.accountType,
                                    userId: service.userDetails?.id,
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
                            if (professionLabel.isNotEmpty || mode.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: SizeConfig.size6),
                                // A Wrap, not a Row: on a narrow screen a long
                                // title beside a mode pill has nowhere to go,
                                // and wrapping is free here because the photo
                                // stretches to whatever height this ends up.
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (professionLabel.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _chipBg,
                                          borderRadius:
                                              BorderRadius.circular(999),
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
                                    if (mode.isNotEmpty) _buildModeBadge(mode),
                                  ],
                                ),
                              ),
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
                // the block is, and a "Services offered" label above six items
                // the reader can already see is a row of height spent on
                // nothing.
                child: _servicesGrid(visibleServices, extraServices, openDetail),
              ),
            ],

            // ─── Band 3: price | Book Now ─────────────────
            SizedBox(height: SizeConfig.size12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Expanded, NOT a bare Column followed by a Spacer: the price
                // and the CTA together can exceed a narrow card's width, at
                // which point the Spacer collapses and the row overflows.
                // Giving the price the leftover space lets it ellipsize and
                // keeps the button — the thing that must never be clipped —
                // whole.
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
                          if (priceStr != '—' && priceType.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: CustomText(
                                '/$priceType',
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

  /// The square consultant photo, with the rating pill inset into its top-left
  /// corner exactly as the design places it.
  Widget _cardPhoto(
      ProfessionalConsData service, String heroImage, String? rating) {
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
                ? _professionHero()
                : CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    // A quarter of the old budget: this slot is a ~120dp
                    // thumbnail now, not a full-width letterbox.
                    memCacheWidth: 400,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFEDEFF4)),
                    errorWidget: (_, __, ___) => _professionHero(),
                  ),
          ),
        ),
        Positioned(left: 6, top: 6, child: _photoRatingBadge(rating)),
      ],
    );
  }

  /// Photo stand-in for a consultant with none — the tile of the CATEGORY the
  /// user is browsing, from `assets/discover/`.
  ///
  /// Keyed on the selected category rather than on anything per-consultant:
  /// this screen only ever shows one category at a time, so it is the right
  /// answer for every card, and the consultant payload carries no tag id of
  /// its own to look up.
  ///
  /// Falls back to a neutral plate when the category has no tile —
  /// [individualProfessionIcons] covers every current one, but it is data and a
  /// new category can arrive before its art does.
  Widget _professionHero() {
    final tile = _professionTile();
    if (tile == null) return Container(color: const Color(0xFFEDEFF4));
    return LocalAssets(imagePath: tile, boxFix: BoxFit.cover);
  }

  /// Asset path of the illustration for the browsed category, or null.
  ///
  /// The slug is tried first and the display name second, each normalised to
  /// the map's key shape (`Legal Govt Consultant` → `LEGAL_GOVT_CONSULTANT`) —
  /// the two have not always agreed on which one the selection carries.
  String? _professionTile() {
    String? lookup(String? raw) {
      if (raw == null) return null;
      final key = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
      return key.isEmpty ? null : individualProfessionIcons[key];
    }

    final selected = controller.selectedProfessionalConsultantData.value;
    return lookup(selected?.slugId) ?? lookup(selected?.name);
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

  /// The fact rows under the chip row — a white glyph plate, then a bold label.
  /// The design shows experience and distance.
  ///
  /// Experience is real data here, unlike on the self-profession card: the
  /// consultant payload carries `about.totalExperience` as years and months
  /// already worked out. When it is absent the slot takes today's opening
  /// hours — which is where the old card's floating "Open | hours" chip went —
  /// rather than leaving the row empty.
  List<Widget> _infoRows(
      ProfessionalConsData service, String? distStr, String? hoursStr) {
    final rows = <Widget>[];
    final experience = _experienceLabel(service);
    if (experience != null) {
      rows.add(
          _infoRow(icon: Icons.workspace_premium_outlined, label: experience));
    } else if (hoursStr != null) {
      rows.add(_infoRow(icon: Icons.access_time_rounded, label: 'Open $hoursStr'));
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

  /// "10 Years Experience", or null when the consultant has none recorded.
  ///
  /// Straight off `about.totalExperience`, the same figure the Experienced
  /// sort ranks on — so the card and the ordering cannot disagree. Under a
  /// year it reports months rather than giving up: someone eight months in has
  /// eight months of experience, and "0 Years" reads as an accusation.
  String? _experienceLabel(ProfessionalConsData service) {
    final total = service.about?.totalExperience;
    final years = total?.years ?? 0;
    final months = total?.months ?? 0;
    if (years >= 1) {
      return '$years ${years == 1 ? 'Year' : 'Years'} Experience';
    }
    if (months >= 1) {
      return '$months ${months == 1 ? 'Month' : 'Months'} Experience';
    }
    return null;
  }

  /// The "⋮" at the card's top-right.
  ///
  /// Share and save used to be two circles floating on the photo. The design
  /// has a single control in this corner, so they became its menu — a sheet
  /// rather than a popup so it needs no [BuildContext] from inside the list
  /// builder, and so both actions carry a label instead of a bare glyph.
  Widget _overflowMenu(ProfessionalConsData service) {
    return InkWell(
      onTap: () => _showConsultantMenu(service),
      borderRadius: BorderRadius.circular(999),
      child: const Padding(
        padding: EdgeInsets.only(left: 8, bottom: 6),
        child: Icon(Icons.more_vert, size: 20, color: _cardInkSoft),
      ),
    );
  }

  void _showConsultantMenu(ProfessionalConsData service) {
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
                  _shareConsultant(service);
                },
              ),
              Obx(() {
                final saved =
                    controller.isProviderLocallySaved(service.userId);
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

  /// Two-column checklist inside the "Services offered" box. [items] is already
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
            child: i + 1 < cells.length ? cells[i + 1] : const SizedBox.shrink(),
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

  // ─── Today's opening hours ─────────────────────────────────────
  /// Compact "10:00- 16:00" for TODAY, or null when the consultant has no
  /// schedule, is closed today, or the times are missing.
  ///
  /// The consultant payload carries a weekly `timings.schedule` with an
  /// `isOpen`/`openTime`/`closeTime` object per day — unlike self-work, which
  /// ships a flat timings list. So the day is picked from the device date
  /// rather than min/max-ing a range.
  String? _todayHours(ProfessionalConsData service) {
    final schedule = service.timings?.schedule;
    if (schedule == null) return null;

    // DateTime.weekday: 1 = Monday … 7 = Sunday.
    bool? isOpen;
    String? open;
    String? close;
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        isOpen = schedule.monday?.isOpen;
        open = schedule.monday?.openTime;
        close = schedule.monday?.closeTime;
        break;
      case DateTime.tuesday:
        isOpen = schedule.tuesday?.isOpen;
        open = schedule.tuesday?.openTime;
        close = schedule.tuesday?.closeTime;
        break;
      case DateTime.wednesday:
        isOpen = schedule.wednesday?.isOpen;
        open = schedule.wednesday?.openTime;
        close = schedule.wednesday?.closeTime;
        break;
      case DateTime.thursday:
        isOpen = schedule.thursday?.isOpen;
        open = schedule.thursday?.openTime;
        close = schedule.thursday?.closeTime;
        break;
      case DateTime.friday:
        isOpen = schedule.friday?.isOpen;
        open = schedule.friday?.openTime;
        close = schedule.friday?.closeTime;
        break;
      case DateTime.saturday:
        isOpen = schedule.saturday?.isOpen;
        open = schedule.saturday?.openTime;
        close = schedule.saturday?.closeTime;
        break;
      default:
        isOpen = schedule.sunday?.isOpen;
        open = schedule.sunday?.openTime;
        close = schedule.sunday?.closeTime;
    }

    if (isOpen == false) return null;
    final o = (open ?? '').trim();
    final c = (close ?? '').trim();
    if (o.isEmpty || c.isEmpty) return null;
    return '$o- $c';
  }

  void _shareConsultant(ProfessionalConsData service) {
    ShareService.instance.shareProfile(
      userId: service.userId ?? '',
      subject: service.basicDetails?.fullName ?? service.userDetails?.name,
    );
  }

  void _toggleSave(ProfessionalConsData service) {
    final wasSaved = controller.isProviderLocallySaved(service.userId);
    controller.toggleProviderLocalSave(service.userId);
    if (!wasSaved) {
      commonSnackBar(message: 'Saved — full favourites coming soon');
    }
  }

  // ─── Badges ────────────────────────────────────────────────────
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

  /// Consultation-mode pill (Online / In-person). Solid white fill because it
  /// overlays photos and maps, where a translucent pill would be unreadable.
  Widget _buildModeBadge(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Icon(
            mode.toLowerCase().contains('online')
                ? Icons.videocam_rounded
                : Icons.handshake_outlined,
            size: 14,
            color: AppColors.green00,
          ),
          const SizedBox(width: 6),
          CustomText(
            mode,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.green00,
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_PinnedFilterBar oldDelegate) => oldDelegate.child != child;
}

/// Full-screen map page reached by tapping the backdrop (or the expand button)
/// on [ProfessionConsultantDiscoverScreenV2]. Loads every consultant
/// (unpaginated) via [DiscoverController.fetchAllProfessionalConsForMap] and
/// renders them through `google_maps_flutter`'s built-in clustering so 100+ pins
/// stay smooth — nearby consultants collapse into a count badge that splits open
/// on zoom-in.
///
/// Initial zoom is `12` — roughly a 25–50 km frame around the user, matching
/// the "city-radius" feel of mainstream discover apps.
class _ProfessionConsultantMapScreenV2 extends StatefulWidget {
  final void Function(BuildContext context, ProfessionalConsData service)
      onMarkerTap;

  const _ProfessionConsultantMapScreenV2({required this.onMarkerTap});

  @override
  State<_ProfessionConsultantMapScreenV2> createState() =>
      _ProfessionConsultantMapScreenV2State();
}

class _ProfessionConsultantMapScreenV2State
    extends State<_ProfessionConsultantMapScreenV2> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _serviceIcon;

  final DiscoverController _ctrl = Get.find<DiscoverController>();
  static const ClusterManagerId _clusterManagerId =
      ClusterManagerId('profession_consultants_v2');

  @override
  void initState() {
    super.initState();
    _ctrl.fetchAllProfessionalConsForMap();
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

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Builds the marker set fed to [GoogleMap.markers]. Each marker is stamped
  /// with [_clusterManagerId] so the platform-side cluster manager can group
  /// nearby ones into a numbered badge automatically.
  Set<Marker> _buildMarkers(List<ProfessionalConsData> services) {
    final markers = <Marker>{};
    for (final s in services) {
      final lat = _toDouble(s.userDetails?.userLocation?.lat);
      final lng = _toDouble(s.userDetails?.userLocation?.lon);
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      final name = (s.basicDetails?.fullName?.trim().isNotEmpty ?? false)
          ? s.basicDetails!.fullName!
          : (s.userDetails?.name ?? AppStrings.unknownUser.tr);
      markers.add(
        Marker(
          markerId: MarkerId(s.id ?? s.userId ?? '${name}_$lat,$lng'),
          position: LatLng(lat, lng),
          clusterManagerId: _clusterManagerId,
          icon: _serviceIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: name,
            snippet: s.basicDetails?.professionalTitle ?? '',
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
            final markers = _buildMarkers(_ctrl.professionalConsMapList);
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
                _ctrl.professionalConsMapResponse.value.status == Status.INITIAL;
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
              final count = _ctrl.professionalConsMapList.where((s) {
                final lat = _toDouble(s.userDetails?.userLocation?.lat);
                final lng = _toDouble(s.userDetails?.userLocation?.lon);
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
