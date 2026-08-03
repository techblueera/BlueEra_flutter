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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

/// Tinted surface set for a provider card. Mirrors the grocery/product store
/// cards so a result card reads as the same family across the app — a soft
/// coloured card body instead of flat white, with the inner "Expertise" box
/// tinted by a translucent wash of the same hue.
class _ProviderCardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerLine;

  const _ProviderCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerLine,
  });
}

const _providerCardPalettes = <_ProviderCardPalette>[
  _ProviderCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    // CSS #13DBF414 (RGBA) → Flutter ARGB 0x1413DBF4 — translucent
    // teal wash so the inner tiles tint with the card's identity.
    tileBg: Color(0x1413DBF4),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _ProviderCardPalette(
    // Deliberately stronger than the grocery card's #FCF5FF: that value is
    // only ~10/255 off white on its strongest channel, so next to the teal
    // card (~18 off) the body read as plain white and only the inner tile
    // looked pink. This carries the tint across the whole card instead.
    cardBg: Color(0xFFF9EDFF),
    cardBorder: Color(0xFFE7CBF5),
    tileBg: Color(0x14BE26FF),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

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

/// Hero aspect ratio from the card design (assets/card_ui.png, 1568×800).
/// Shared by both discover v2 result cards so they stay identical.
const double _heroAspectRatio = 1.96;

class _SelfProfessionDiscoverScreenV2State
    extends State<SelfProfessionDiscoverScreenV2> {
  final controller = getOrPut(() => DiscoverController());
  final String serviceSubType = 'selfWork';
  final String earnServiceType = AppConstants.service;

  /// Custom pin for the backdrop map — rendered once, reused for every marker.
  static final Widget _markerIcon =
      DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded);

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
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
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
  List<BlueMapMarker> _backdropMarkers() {
    final markers = <BlueMapMarker>[];
    for (final s in controller.earnServiceList) {
      final lat = s.userLocation?.lat?.toDouble();
      final lng = s.userLocation?.lon?.toDouble();
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      markers.add(BlueMapMarker(
        id: s.id ?? '${s.name}_$lat,$lng',
        position: LatLng(lat, lng),
        child: _markerIcon,
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
    final priceUnit =
        (priceData?.unitLabel.isNotEmpty ?? false) ? priceData!.unitLabel : 'Hour';
    final ratingValue =
        service.rating != null && service.rating != 0 ? service.rating.toString() : '0';
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
                                border: Border.all(color: Colors.white, width: 2),
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
                            horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withValues(alpha: 0.25),
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
        notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      controller.fetchEarnServices(
          earnServiceType: earnServiceType, subType: serviceSubType, isLoadMore: true);
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
                  child: Obx(() => BlueMap(
                        initialCenter: _mapTarget,
                        initialZoom: 13,
                        markers: _backdropMarkers(),
                        myLocationEnabled: true,
                        interactive: false,
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
              builder: (context, scrollController) => _buildSheet(scrollController),
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
                  padding: EdgeInsets.fromLTRB(
                      SizeConfig.size12, SizeConfig.size10, SizeConfig.size12, SizeConfig.size10),
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
                      ? AppStrings.noProvidersFoundNearYou.trParams({'category': pretty})
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
                final showMoreSpinner = controller.isEarnServiceLoadingMore.value;
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
                        keyPrefix: 'self_profession_v2_native_ad',
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

  /// **Spec-Sheet Card** — hero photo (rating badge / share + save / "Open |
  /// hours" chip) → avatar + name + location → "Expertise" checklist box →
  /// price + Book Now footer. Same card the v1 list used, so switching chrome
  /// doesn't change how a provider reads.
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

    final address = (service.address?.trim().isNotEmpty ?? false)
        ? service.address!.trim()
        : (service.location ?? '').trim();
    final ratingValue =
        (service.rating != null && service.rating != 0) ? service.rating.toString() : null;

    // Prefer the provider's explicit `expertise` list (the design labels this
    // box "Expertise"), else fall back to serviceOffered + typesOfWork.
    final expertiseList = (service.service?.expertise ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final services =
        expertiseList.isNotEmpty ? expertiseList : _combinedServices(service);
    final totalServices = services.length;
    final showMoreServices = totalServices > 6;
    final visibleServices =
        showMoreServices ? services.take(5).toList() : services.take(6).toList();
    final extraServices = showMoreServices ? totalServices - 5 : 0;

    final priceStr = priceMin == 0
        ? '—'
        : (isRange
            ? '₹${formatIndianNumber(priceMin)}-${formatIndianNumber(priceMax)}'
            : '₹${formatIndianNumber(priceMin)}');
    final distStr = distance == 0
        ? null
        : '${distance < 10 ? distance.toStringAsFixed(1) : distance.toStringAsFixed(0)} km away';
    // Compact hours: "9:00 AM - 6:00 PM" → "9AM-6PM" for the floating chip.
    String compactTime(String t) {
      final m = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false).firstMatch(t.trim());
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
            // ─── Hero image + rating badge + "Open | hours" chip ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  // Ratio taken from the design (assets/card_ui.png, 1568×800)
                  // instead of a fixed 175 px, so the hero keeps the intended
                  // proportions on every screen width rather than growing
                  // letterboxed on wide phones and cramped on small ones.
                  child: AspectRatio(
                    aspectRatio: _heroAspectRatio,
                    child: heroImage.isEmpty
                        ? Container(color: const Color(0xFFEDEFF4))
                        : CachedNetworkImage(
                            imageUrl: heroImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) => Container(color: const Color(0xFFEDEFF4)),
                            errorWidget: (_, __, ___) => LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.fill,
                            ),
                          ),
                  ),
                ),
                // Unconditional: the design always carries a rating pill in the
                // hero's top-left, so an unrated provider shows "NA" instead
                // of leaving the slot empty.
                Positioned(
                  left: SizeConfig.size12,
                  top: SizeConfig.size12,
                  child: _buildRatingBadge(ratingValue),
                ),
                // Share + Save, stacked top-right. Availability is conveyed by
                // the "Open | hours" chip, so no standalone live badge here.
                Positioned(
                  right: SizeConfig.size12,
                  top: SizeConfig.size12,
                  child: Column(
                    children: [
                      _heroCircleButton(
                        assetPath: AppIconAssets.reelShare,
                        onTap: () => _shareProvider(service),
                      ),
                      SizedBox(height: SizeConfig.size8),
                      // Local-only save (no backend yet) — fills the star and
                      // shows a "coming soon" note on first save.
                      Obx(() {
                        final saved = controller.isProviderLocallySaved(service.id);
                        return _heroCircleButton(
                          icon: saved ? Icons.star_rounded : Icons.star_border_rounded,
                          iconColor: saved ? const Color(0xFFFFB400) : Colors.white,
                          onTap: () => _toggleSave(service),
                        );
                      }),
                    ],
                  ),
                ),
                if (hoursStr != null)
                  Positioned(
                    right: SizeConfig.size12,
                    bottom: SizeConfig.size12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        // Green hairline, per the design — the chip is outlined,
                        // not just white-on-photo.
                        border: Border.all(
                            color: AppColors.green00.withValues(alpha: 0.55),
                            width: 1),
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
                            'Open | $hoursStr',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green00,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(SizeConfig.size14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Avatar + name + location ─────────────────
                  // Avatar and name open the poster's profile (personal or
                  // business, per account type); the rest of the card still
                  // opens the service detail.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiscoverProfileTap(
                        accountType: service.accountType,
                        userId: service.id,
                        child: CachedAvatarWidget(
                          imageUrl: profileImage,
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
                              accountType: service.accountType,
                              userId: service.id,
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

                  // ─── "Expertise" box ──────────────────────────
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
                            'Expertise',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                          SizedBox(height: SizeConfig.size8),
                          Container(height: 1, color: palette.dividerLine),
                          SizedBox(height: SizeConfig.size10),
                          _servicesGrid(visibleServices, extraServices, openDetail),
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
                              if (priceStr != '—' && priceUnit.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: CustomText(
                                    '/$priceUnit',
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
                                color: AppColors.primaryColor.withValues(alpha: 0.30),
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
          Icon(Icons.location_on_outlined, size: 12, color: AppColors.secondaryTextColor),
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
    final Color fg = isLive ? Colors.green.shade700 : AppColors.secondaryTextColor;
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
    if (timingsList == null || timingsList.isEmpty) return {"start": "--", "end": "--"};
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_PinnedFilterBar oldDelegate) => oldDelegate.child != child;
}

/// Full-screen map page reached by tapping the backdrop (or the expand button)
/// on [SelfProfessionDiscoverScreenV2]. Loads every provider (unpaginated) via
/// [DiscoverController.fetchAllEarnServicesForMap] and renders them through
/// BlueMap's client-side clustering so 100+ pins stay smooth —
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
  State<_SelfProfessionMapScreenV2> createState() => _SelfProfessionMapScreenV2State();
}

class _SelfProfessionMapScreenV2State extends State<_SelfProfessionMapScreenV2> {
  BlueMapController? _mapController;
  /// Category pin, as a widget: correct on the first frame, and stable by
  /// identity so BlueMap does not redraw every pin on every rebuild.
  static final Widget _serviceIcon =
      DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded);

  final DiscoverController _ctrl = Get.find<DiscoverController>();
  @override
  void initState() {
    super.initState();
    _ctrl.fetchAllEarnServicesForMap(
      earnServiceType: widget.earnServiceType,
      subType: widget.subType,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Builds the marker set fed to [GoogleMap.markers]. Each marker is stamped
  /// with [_clusterManagerId] so the platform-side cluster manager can group
  /// nearby ones into a numbered badge automatically.
  /// Services on the map, keyed by marker id, so a tap resolves back to the
  /// service it represents.
  final Map<String, ServiceData> _servicesByMarkerId = {};

  List<BlueMapMarker> _buildMarkers(List<ServiceData> services) {
    _servicesByMarkerId.clear();
    final markers = <BlueMapMarker>[];
    for (final s in services) {
      final lat = s.userLocation?.lat?.toDouble();
      final lng = s.userLocation?.lon?.toDouble();
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      final id = s.id ?? '${s.name}_$lat,$lng';
      _servicesByMarkerId[id] = s;
      markers.add(
        BlueMapMarker(
          id: id,
          position: LatLng(lat, lng),
          child: _serviceIcon,
        ),
      );
    }
    return markers;
  }

  void _onMarkerTap(String markerId) {
    final service = _servicesByMarkerId[markerId];
    if (service != null) widget.onMarkerTap(context, service);
  }

  @override
  Widget build(BuildContext context) {
    // Frame on the picked earn-discover location when set, else the device fix.
    final initialLat =
        _ctrl.earnDiscoverLat ?? (LocationService.lat != 0.0 ? LocationService.lat : 28.6139);
    final initialLng =
        _ctrl.earnDiscoverLng ?? (LocationService.lng != 0.0 ? LocationService.lng : 77.2090);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final markers = _buildMarkers(_ctrl.earnServiceMapList);
            return BlueMap(
              initialCenter: LatLng(initialLat, initialLng),
              initialZoom: 12,
              markers: markers,
              // Replaces Google's platform-side ClusterManager.
              clusterMarkers: true,
              myLocationEnabled: true,
              onMarkerTap: _onMarkerTap,
              onMapCreated: (c) => _mapController = c,
            );
          }),
          // Loading overlay while the unpaginated fetch is in flight.
          Obx(() {
            final isLoading = _ctrl.earnServiceMapResponse.value.status == Status.INITIAL;
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
                    _mapController?.moveTo(
                      LatLng(initialLat, initialLng),
                      zoom: 13,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 18, color: AppColors.primaryColor),
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
