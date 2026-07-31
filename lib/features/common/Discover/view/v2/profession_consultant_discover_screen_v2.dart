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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Tinted surface set for a consultant card. Mirrors the self-profession v2
/// cards so a result reads as the same family across both discover flows — a
/// soft coloured card body instead of flat white, with the inner "Services
/// offered" box tinted by a translucent wash of the same hue.
class _ConsultantCardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerLine;

  const _ConsultantCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerLine,
  });
}

/// Hero aspect ratio from the card design (assets/card_ui.png, 1568×800).
/// Kept in step with the same constant in
/// `self_profession_discover_screen_v2.dart` so both result cards match.
const double _heroAspectRatio = 1.96;

const _consultantCardPalettes = <_ConsultantCardPalette>[
  _ConsultantCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    tileBg: Color(0x1413DBF4),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _ConsultantCardPalette(
    cardBg: Color(0xFFF9EDFF),
    cardBorder: Color(0xFFE7CBF5),
    tileBg: Color(0x14BE26FF),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

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
                  child: Obx(() => GoogleMap(
                        initialCameraPosition:
                            CameraPosition(target: _mapTarget, zoom: 13),
                        markers: _backdropMarkers(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
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

  /// **Spec-Sheet Card** — hero photo (share + save / consultation-mode chip) →
  /// avatar + name + location → "Services offered" checklist box → price +
  /// Book Now footer. Same anatomy the self-profession v2 card uses so both
  /// discover flows read identically.
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
    // then the curated basic-details photo. Empty → neutral placeholder.
    final profileImage = (service.userDetails?.profileImage ?? '').trim();
    final heroImage = gallery.isNotEmpty
        ? gallery.first
        : (profileImage.isNotEmpty
            ? profileImage
            : (service.basicDetails?.profilePhotoUrl ?? '').trim());

    // Address line shown next to the distance — first non-empty of the
    // contact / user / basic-details address candidates.
    final address = <String?>[
      service.contact?.address,
      service.userDetails?.address,
      service.basicDetails?.location,
      service.userDetails?.location,
    ].firstWhere((a) => (a ?? '').trim().isNotEmpty, orElse: () => '')!.trim();

    final priceStr = amount == 0 ? '—' : '₹${formatIndianNumber(amount)}';
    final distStr = distanceKm == null
        ? null
        : '${distanceKm < 10 ? distanceKm.toStringAsFixed(1) : distanceKm.toStringAsFixed(0)} km away';
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.cardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero image + share/save + consultation-mode chip ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  // Ratio taken from the design (assets/card_ui.png, 1568×800)
                  // instead of a fixed 175 px, so the hero keeps the intended
                  // proportions on every screen width.
                  child: AspectRatio(
                    aspectRatio: _heroAspectRatio,
                    child: heroImage.isEmpty
                        ? Container(color: const Color(0xFFEDEFF4))
                        : CachedNetworkImage(
                            imageUrl: heroImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) =>
                                Container(color: const Color(0xFFEDEFF4)),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFEDEFF4),
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                  ),
                ),
                // Unconditional: the design always carries a rating pill in the
                // hero's top-left, so an unrated consultant shows "NA" instead
                // of leaving the slot empty.
                Positioned(
                  left: SizeConfig.size12,
                  top: SizeConfig.size12,
                  child: _buildRatingBadge(ratingValue),
                ),
                // Share + Save, stacked top-right — same affordances the
                // self-profession v2 card carries.
                Positioned(
                  right: SizeConfig.size12,
                  top: SizeConfig.size12,
                  child: Column(
                    children: [
                      _heroCircleButton(
                        assetPath: AppIconAssets.reelShare,
                        onTap: () => _shareConsultant(service),
                      ),
                      SizedBox(height: SizeConfig.size8),
                      // Local-only save (no backend yet) — fills the star and
                      // shows a "coming soon" note on first save.
                      Obx(() {
                        final saved = controller
                            .isProviderLocallySaved(service.userId);
                        return _heroCircleButton(
                          icon: saved
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          iconColor:
                              saved ? const Color(0xFFFFB400) : Colors.white,
                          onTap: () => _toggleSave(service),
                        );
                      }),
                    ],
                  ),
                ),
                // "Open | hh:mm-hh:mm" sits bottom-RIGHT per the design, the
                // same slot the self-profession card uses. The consultation
                // mode moves to bottom-left rather than being dropped — it's
                // the one thing a consultant card carries that a home-service
                // card doesn't.
                if (mode.isNotEmpty)
                  Positioned(
                    left: SizeConfig.size12,
                    bottom: SizeConfig.size12,
                    child: _buildModeBadge(mode),
                  ),
                if (hoursStr != null)
                  Positioned(
                    right: SizeConfig.size12,
                    bottom: SizeConfig.size12,
                    child: _buildOpenHoursChip(hoursStr),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(SizeConfig.size14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Avatar + name + location ─────────────────
                  // Avatar and name open the consultant's own profile (personal
                  // or business, per account type); the rest of the card still
                  // opens the service detail.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiscoverProfileTap(
                        accountType: service.userDetails?.accountType,
                        userId: service.userDetails?.id,
                        child: CachedAvatarWidget(
                          imageUrl: service.userDetails?.profileImage ?? '',
                          size: SizeConfig.size40,
                          borderColor: Colors.white,
                          borderRadius: SizeConfig.size20,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DiscoverProfileTap(
                              accountType: service.userDetails?.accountType,
                              userId: service.userDetails?.id,
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontFamily: AppConstants.OpenSans,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mainTextColor,
                                  letterSpacing: -0.2,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (distStr != null || address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: AppColors.primaryColor),
                                  const SizedBox(width: 2),
                                  if (distStr != null)
                                    CustomText(
                                      distStr,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryColor,
                                    ),
                                  if (distStr != null && address.isNotEmpty)
                                    CustomText(
                                      '  |  ',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                  if (address.isNotEmpty)
                                    Expanded(
                                      child: CustomText(
                                        address,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ─── "Services offered" box ───────────────────
                  if (visibleServices.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    Container(
                      padding: EdgeInsets.all(SizeConfig.size12),
                      decoration: BoxDecoration(
                        color: palette.tileBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.tileBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Services offered',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                          SizedBox(height: SizeConfig.size8),
                          Container(height: 1, color: palette.dividerLine),
                          SizedBox(height: SizeConfig.size10),
                          _servicesGrid(
                              visibleServices, extraServices, openDetail),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: SizeConfig.size14),

                  // ─── Footer: price + Book Now ─────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            'Starting From',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomText(
                                priceStr,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryColor,
                              ),
                              if (priceStr != '—' && priceType.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: CustomText(
                                    '/$priceType',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: openDetail,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.30),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        Icon(Icons.check_circle, size: 15, color: AppColors.green00),
        const SizedBox(width: 6),
        Expanded(
          child: CustomText(
            text,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor,
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
      ),
    );
  }

  // ─── Hero overlay actions (share + local save) ─────────────────
  /// Pass either [assetPath] (an SVG/PNG from AppIconAssets — the share glyph
  /// uses this) or [icon] for a Material glyph. [assetPath] wins when both are
  /// supplied.
  Widget _heroCircleButton({
    IconData? icon,
    String? assetPath,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: assetPath != null
              ? LocalAssets(
                  imagePath: assetPath,
                  height: 18,
                  width: 18,
                  imgColor: iconColor,
                )
              : Icon(icon, size: 18, color: iconColor),
        ),
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

  /// Floating "Open | hours" chip over the hero. Solid white fill so it stays
  /// readable on any photo.
  Widget _buildOpenHoursChip(String hours) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Green hairline, per the design — the chip is outlined, not just
        // white-on-photo.
        border: Border.all(
            color: AppColors.green00.withValues(alpha: 0.55), width: 1),
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
          Icon(Icons.access_time_rounded, size: 14, color: AppColors.green00),
          const SizedBox(width: 6),
          CustomText(
            'Open | $hours',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.green00,
          ),
        ],
      ),
    );
  }

  /// Star + score pill, top-left of the hero (assets/img.png): a translucent
  /// dark stadium with a white ring and white numerals — the same glassy
  /// treatment as the share/save circles. Identical to the self-profession v2
  /// badge so a rating reads the same across both discover flows.
  ///
  /// Always rendered so the hero's left slot is never empty. Shows the score
  /// when the consultant has one and "NA" when they don't — which is every
  /// consultant until the search endpoint starts returning a rating.
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
