import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/profe_cons_res_model.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/filter_capsule.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../chat/auth/controller/chat_view_controller.dart';

class ProfessionConsultantDiscoverScreen extends StatefulWidget {
  final List<ProfessionTypeData> professionalConsultantCategories;
  final ProfessionTypeData? selectedProfessionConsultantData;

  const ProfessionConsultantDiscoverScreen(
      {super.key, required this.professionalConsultantCategories, this.selectedProfessionConsultantData});

  @override
  State<ProfessionConsultantDiscoverScreen> createState() => _ProfessionConsultantDiscoverScreenState();
}

class _ProfessionConsultantDiscoverScreenState extends State<ProfessionConsultantDiscoverScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<ProfessionTypeData> _professionalConsultantCategories;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/business-people-casual-meeting_53876-101882.jpg?w=1380",
    "https://img.freepik.com/free-photo/group-diverse-people-having-business-meeting_53876-25060.jpg?w=1380",
    "https://img.freepik.com/free-photo/side-view-woman-working-as-lawyer_23-2151202449.jpg?w=1380",
  ];

  // ─── Client-side sort state ──────────────────────────────────────
  // The backend doesn't sort, so we fetch current position once and
  // compute distance / experience / price comparators in memory. The
  // distance map is keyed on service.id so it survives pagination
  // appends without re-running geolocator per row.
  double? _myLat;
  double? _myLng;
  final Map<String, double> _distances = {};
  bool _locationRequested = false;

  @override
  initState() {
    super.initState();
    _professionalConsultantCategories = widget.professionalConsultantCategories;
    final selected = widget.selectedProfessionConsultantData;
    controller.selectedProfessionalConsultantData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    // Skip refetch on re-entry when the cached list is fresh for this
    // category; category taps below still force a fresh fetch.
    controller.fetchProfessionalConsultantServicesIfNeeded();
    _ensureLocation();
  }

  /// Fetches current GPS once, then refreshes the distance cache so
  /// the Nearest sort and the spec-strip `NEAR` column light up. Quiet
  /// failure when permission is denied — every distance falls back to
  /// `—` and the Nearest sort degrades to server order.
  Future<void> _ensureLocation() async {
    if (_locationRequested) return;
    _locationRequested = true;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) return;
      } else if (perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _myLat = pos.latitude;
      _myLng = pos.longitude;
      _recomputeDistances();
      if (mounted) setState(() {});
    } catch (_) {/* swallow — distance just stays unknown */}
  }

  /// Computes road-adjusted km for every loaded service that has
  /// usable coords. Idempotent — safe to call on every Obx rebuild.
  void _recomputeDistances() {
    if (_myLat == null || _myLng == null) return;
    for (final item in controller.professionalConsDataList) {
      final id = item.id ?? item.userId ?? '';
      if (id.isEmpty || _distances.containsKey(id)) continue;
      final lat = _toDouble(item.userDetails?.userLocation?.lat);
      final lng = _toDouble(item.userDetails?.userLocation?.lon);
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      final meters = Geolocator.distanceBetween(_myLat!, _myLng!, lat, lng);
      // 1.27× road factor mirrors the existing helper in
      // view_business_details_controller.dart so distances feel
      // consistent across the app.
      _distances[id] = (meters * 1.27) / 1000;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? _distanceFor(ProfessionalConsData item) => _distances[item.id ?? item.userId ?? ''];

  /// Converts an all-caps category name like "ADVOCATE" or
  /// "TAX_CONSULTANT" into a human-readable label like "Advocate" /
  /// "Tax Consultant" for the empty-state message. Leaves already
  /// mixed-case names untouched.
  String _prettyCategoryName(String raw) {
    if (raw.isEmpty) return raw;
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned != cleaned.toUpperCase()) return cleaned;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Returns a new list sorted by the active filter. Items missing
  /// the comparator key sort to the end so they don't crowd the top
  /// of a sorted list with stale rows.
  List<ProfessionalConsData> _applySort(List<ProfessionalConsData> items, CategoryFilter filter) {
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
          final aMonths =
              (a.about?.totalExperience?.years ?? 0) * 12 + (a.about?.totalExperience?.months ?? 0);
          final bMonths =
              (b.about?.totalExperience?.years ?? 0) * 12 + (b.about?.totalExperience?.months ?? 0);
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

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      controller.fetchProfessionalConsultantServices(isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      // StickyCategory(
      //     id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._professionalConsultantCategories.map((c) => StickyCategory(
            id: c.tagId ?? '',
            name: c.name ?? '',
            imageUrl: getIndividualProfessionIcon(c.tagId).isNotEmpty
                ? getIndividualProfessionIcon(c.tagId)
                : c.imageUrl ?? '',
          )),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                    categories: stickyCategories,
                    selectedId:
                        controller.selectedProfessionalConsultantData.value?.slugId ?? ADVERTISING_CONSULTANT,
                    // selectedId: controller
                    //         .selectedProfessionalConsultantData.value?.slugId ??
                    //     'ALL_OPTION',
                    onCategoryTap: (item) {
                      // if (item.id == 'ALL_OPTION') {
                      //   controller.selectedProfessionalConsultantData.value =
                      //       null;
                      // } else {
                      controller.selectedProfessionalConsultantData.value = OnboardingCategoryModel(
                        name: item.name,
                        slugId: item.id,
                        accountType: AppConstants.individual,
                      );
                      // }
                      controller.fetchProfessionalConsultantServices();
                      setState(() {});
                    },
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
              ],
              body: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size8),
          // Compact sort chips (Nearest / Experienced / Price Low→High) — the
          // shared [FilterCapsule], same control the self-profession Discover
          // list uses. Tapping just mutates `selectedFilter`; the Obx below
          // re-sorts the loaded list client-side. No refetch needed.
          Obx(() => FilterCapsule(
                filters: controller.filters,
                selected: controller.selectedFilter.value,
                onChanged: (f) {
                  if (controller.selectedFilter.value == f) return;
                  controller.selectedFilter.value = f;
                },
              )),
          SizedBox(height: SizeConfig.size10),
          Expanded(
            child: Obx(() {
              if (controller.isProfConServiceLoading.value && controller.professionalConsDataList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.professionalConsDataList.isEmpty) {
                final selectedName = controller.selectedProfessionalConsultantData.value?.name ?? '';
                // Server returns categories in upper-case (e.g.
                // "ADVOCATE"); flip to title-case for the message so
                // it reads naturally ("No Advocate consultants…").
                final pretty = _prettyCategoryName(selectedName);
                final message = pretty.isNotEmpty
                    ? AppStrings.noConsultantsFoundNearYou.trParams({'category': pretty})
                    : AppStrings.noServicesFound.tr;
                return Center(child: EmptyStateWidget(message: message));
              }
              // Recompute distance cache cheaply for any new items
              // appended by the load-more sentinel, then sort by the
              // active filter.
              _recomputeDistances();
              final sorted = _applySort(
                controller.professionalConsDataList,
                controller.selectedFilter.value,
              );
              final showMoreSpinner = controller.isProfConServiceLoadingMore.value;
              final rows = buildNativeAdRows(sorted.length);
              return ListView.builder(
                itemCount: rows.length + (showMoreSpinner ? 1 : 0),
                padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                itemBuilder: (context, index) {
                  if (index == rows.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final row = rows[index];
                  if (row.isAd) {
                    return NativeAdSlot(
                      adOrdinal: row.adOrdinal,
                      keyPrefix: 'consultant_native_ad',
                    );
                  }
                  return _buildSpecCard(sorted[row.contentIndex]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// **Spec-Sheet Card** — editorial directory entry.
  /// Eyebrow (designation) + oversized name + tagline → hairline →
  /// 4-column spec strip (EXP / PRICE / NEAR / MODE) → optional 16:9
  /// gallery hero → hairline → ghost View + filled Enquire footer.
  Widget _buildSpecCard(ProfessionalConsData service) {
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
    final heroImage = gallery.isNotEmpty
        ? gallery.first
        : ((service.userDetails?.profileImage?.trim().isNotEmpty ?? false)
            ? service.userDetails!.profileImage!.trim()
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

    // "Services offered" checklist — certificate titles first (they read as
    // concrete offerings), falling back to portfolio project titles.
    var serviceTitles =
        (service.certificates ?? []).map((c) => (c.title ?? '').trim()).where((t) => t.isNotEmpty).toList();
    if (serviceTitles.isEmpty) {
      serviceTitles = (service.portfolio ?? [])
          .map((p) => (p.projectTitle ?? '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    final totalServices = serviceTitles.length;
    final showMoreServices = totalServices > 6;
    final visibleServices =
        showMoreServices ? serviceTitles.take(5).toList() : serviceTitles.take(6).toList();
    final extraServices = showMoreServices ? totalServices - 5 : 0;

    void openDetail() {
      ProfileClickTracker.track(
        userId: service.userId ?? '',
        source: ChatClickSource.searchResult,
      );
      Get.to(() => DiscoverProfessionalsViewScreen(
            professionalConsData: service,
          ));
    }

    return InkWell(
      onTap: openDetail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyE5, width: 1),
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
            // ─── Hero image + floating consultation-mode chip ─────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 175,
                    width: double.infinity,
                    child: heroImage.isEmpty
                        ? Container(color: const Color(0xFFEDEFF4))
                        : CachedNetworkImage(
                            imageUrl: heroImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) => Container(color: const Color(0xFFEDEFF4)),
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
                if (mode.isNotEmpty)
                  Positioned(
                    right: SizeConfig.size12,
                    bottom: SizeConfig.size12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedAvatarWidget(
                        imageUrl: service.userDetails?.profileImage ?? '',
                        size: SizeConfig.size40,
                        borderColor: Colors.white,
                        borderRadius: SizeConfig.size20,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                            if (distStr != null || address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppColors.primaryColor,
                                  ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEDEFF4),
                          width: 1,
                        ),
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
                          Container(height: 1, color: const Color(0xFFEDEFF4)),
                          SizedBox(height: SizeConfig.size10),
                          _servicesGrid(
                            visibleServices,
                            extraServices,
                            openDetail,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: SizeConfig.size14),

                  // ─── Footer: price + chat + Book Now ──────────
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
                              if (priceType.isNotEmpty)
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
                      // Chat / enquire icon button
                      // InkWell(
                      //   onTap: () =>
                      //       ProfessionEnquirySheet.open(context, service),
                      //   borderRadius: BorderRadius.circular(12),
                      //   child: Container(
                      //     height: 44,
                      //     width: 44,
                      //     decoration: BoxDecoration(
                      //       color: AppColors.primaryColor
                      //           .withValues(alpha: 0.10),
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     child: Center(
                      //       child: LocalAssets(
                      //         imagePath: AppIconAssets.chat,
                      //         height: 20,
                      //         width: 20,
                      //         imgColor: AppColors.primaryColor,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(width: SizeConfig.size10),
                      // Book Now (filled)
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
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
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

  /// Two-column checklist inside the "Services offered" box. [items] is
  /// already capped; when [extra] > 0 a trailing "+N more services" link
  /// (→ [onMore]) fills the final cell.
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

  // Legacy `selfProfessionCard` was retired — the ListView now calls
  // [_buildSpecCard]. Keeping this breadcrumb so anyone diffing the
  // file knows where the old card body lived.
  // ignore: unused_element
  Widget _legacySelfProfessionCardStub(ProfessionalConsData service) {
    // Legacy body retained but no longer invoked; the file's
    // ListView now calls [_buildSpecCard]. Keeping the symbol live
    // so any external callers still compile until they migrate.
    return InkWell(
      onTap: () => Get.to(() => DiscoverProfessionalsViewScreen(professionalConsData: service)),
      child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedAvatarWidget(
                    imageUrl: service.userDetails?.profileImage ?? '',
                    size: SizeConfig.size40,
                    borderColor: Colors.white,
                    borderRadius: SizeConfig.size20,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.userDetails?.name ?? AppStrings.unknownUser.tr,
                          color: AppColors.mainTextColor, fontWeight: FontWeight.w600),
                      CustomText(
                        service.basicDetails?.shortTagline ?? 'N/A',
                        fontSize: SizeConfig.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.mainTextColor,
                      ),
                    ],
                  )),
                ],
              ),

              /*  (service.certificates != null &&
                      (service.certificates?.isNotEmpty ?? false))
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          SizedBox(height: SizeConfig.size6),
                          ...List.generate(
                            service.certificates?.take(2).length ?? 0,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 6.0, right: 8.0),
                                    width: 4.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryTextColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: CustomText(
                                      service.certificates?[index].title,
                                      fontSize: SizeConfig.small,
                                      color: AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: SizeConfig.size6),
                        ])
                  : SizedBox(),*/

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    CustomText(
                      "${service.pricing?.consultationMode ?? "N/A"}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.green00,
                    ),
                    // CustomText(
                    //   timingMap["start"]!,
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   overflow: TextOverflow.ellipsis,
                    //   color: AppColors.secondaryTextColor,
                    //   maxLines: 1,
                    // ),
                    // CustomText(
                    //   ' | ',
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   color: AppColors.secondaryTextColor,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    // CustomText(
                    //   "${AppStrings.close.tr}: ",
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   overflow: TextOverflow.ellipsis,
                    //   color: AppColors.redB4,
                    //   maxLines: 1,
                    // ),
                    // CustomText(
                    //   timingMap["end"]!,
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   color: AppColors.grayText,
                    //   overflow: TextOverflow.ellipsis,
                    //   maxLines: 1,
                    // ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Legacy stub — locals (priceDisplay/badgeColor/badgeText)
                  // were removed when this card was retired. Keeping a
                  // shell here so the method still compiles; nothing
                  // calls it anymore.
                  CustomText(
                    '₹${formatIndianNumber(service.pricing?.amount ?? 0)}',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: AppColors.primaryColor,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size4,
                      vertical: SizeConfig.size2,
                    ),
                    child: CustomText(
                      service.pricing?.type ?? '',
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      final targetUserId = service.userId ?? '';
                      if (targetUserId.isEmpty) return;
                      final chatViewController = getOrPut(() => ChatViewController());

                      chatViewController.checkChatConnectionAndOpenChat(
                          userId: service.userId ?? "", route: AppConstants.route_discover);
                      // Get.to(() => PersonalChatScreen(
                      //       conversationId: '',
                      //       userId: targetUserId,
                      //       profileImage:
                      //           service.userDetails?.profileImage ?? '',
                      //       name: service.userDetails?.name ?? '',
                      //       type: AppConstants.personal_Chat_Type,
                      //       isInitialMessage: true,
                      //     ));
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_outlined, size: 14, color: AppColors.white),
                          const SizedBox(width: 4),
                          CustomText(
                            'Enquire',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }

  void showFullProfessionDetails(
    ProfessionalConsData service, {
    // required Map<String, String> timingMap,
    required String priceDisplay,
    required String priceBadgeText,
    required Color priceBadgeColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: kToolbarHeight,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),

                _header(context),

                const SizedBox(height: 4),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigate to details
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
                              child: CachedNetworkImage(
                                imageUrl: service.basicDetails?.profilePhotoUrl ?? '',
                                width: SizeConfig.screenWidth,
                                height: SizeConfig.size150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.size150,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.person, size: SizeConfig.size150 / 2),
                              ),
                            ),
                            Positioned(
                                left: 20,
                                bottom: -(SizeConfig.size34),
                                child: Container(
                                  padding: EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                                  child: CachedAvatarWidget(
                                    imageUrl: service.basicDetails?.profilePhotoUrl ?? '',
                                    size: SizeConfig.size65,
                                    borderColor: Colors.white,
                                    borderRadius: SizeConfig.size40,
                                  ),
                                ))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size60,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomText(service.basicDetails?.fullName ?? ' User',
                                  fontSize: SizeConfig.large,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              width: SizeConfig.size8,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size3,
                                horizontal: SizeConfig.size10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: AppColors.secondaryTextColor, width: 0.5),
                              ),
                              child: CustomText(service.basicDetails?.professionalTitle,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: ExpandableText(
                          text: "${service.basicDetails?.shortTagline ?? ''}",
                          trimLines: 3,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.mainTextColor,
                            fontFamily: AppConstants.OpenSans,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Price
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        '${AppStrings.price.tr}: ',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      CustomText(
                        priceDisplay,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: priceBadgeColor,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size4,
                          vertical: SizeConfig.size2,
                        ),
                        child: CustomText(
                          priceBadgeText,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      )
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                /* // Timing
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.timingLabel,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            CustomText(
                              "${AppStrings.open.tr}: ",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.green00,
                            ),
                            CustomText(
                              timingMap["start"]!,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                            ),
                            CustomText(
                              ' | ',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                            CustomText(
                              "${AppStrings.close.tr}: ",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.redB4,
                              maxLines: 1,
                            ),
                            CustomText(
                              timingMap["end"]!,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grayText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),*/

                SizedBox(height: SizeConfig.size15),

                // Service Description
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.serviceDescription,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.certificates != null && (service.certificates?.isNotEmpty ?? false))
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(height: SizeConfig.size6),
                              ...List.generate(
                                service.certificates?.take(2).length ?? 0,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6.0, right: 8.0),
                                        width: 4.0,
                                        height: 4.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryTextColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          service.certificates?[index].title,
                                          fontSize: SizeConfig.small,
                                          color: AppColors.secondaryTextColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: SizeConfig.size6),
                            ])
                          : SizedBox(),
                      /* (service.service != null &&
                              service.service!.facilities != null &&
                              service.service!.facilities!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                service.service!.facilities!.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 6.0, right: 8.0),
                                        width: 4.0,
                                        height: 4.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryTextColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          service.service!.facilities![index],
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CustomText(
                              'No Description available',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),*/
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Work Experience
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.workExperience,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.about?.totalExperience?.years != null &&
                              service.about?.totalExperience?.years != 0)
                          ? CustomText(
                              "${service.about?.totalExperience?.years ?? 0} ${AppStrings.yearsExp.tr}",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            )
                          : CustomText(
                              AppStrings.noExperienceLabel,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Expertise
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.portfolioLabel,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.portfolio != null && service.portfolio!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                service.portfolio!.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 6.0, right: 8.0),
                                            width: 4.0,
                                            height: 4.0,
                                            decoration: BoxDecoration(
                                              color: AppColors.secondaryTextColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomText(
                                              service.portfolio?[index].projectTitle,
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mainTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      CustomText(
                                        service.portfolio?[index].description,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CustomText(
                              AppStrings.noDataLabel,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size15),

                // Gallery
                Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.gallery,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(
                        color: AppColors.greyE5,
                        height: 0.5,
                        width: SizeConfig.screenWidth,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      (service.gallery != null &&
                              service.gallery?.signedUrls != null &&
                              (service.gallery?.signedUrls?.isNotEmpty ?? false))
                          ? Builder(builder: (context) {
                              // Split into rows of 4
                              final rows = <String>[];
                              rows.addAll(service.gallery?.signedUrls ?? []);
                              // for (int i = 0;
                              //     i < (service.gallery?.signedUrls?.length??0);
                              //     i += crossAxisCount) {
                              //   rows.add(
                              //     service.gallery?.signedUrls?.sublist(
                              //       i,
                              //       (i + crossAxisCount).clamp(0,
                              //           service.serviceMedia!.photos!.length),
                              //     ),
                              //   );
                              // }
                              return Wrap(
                                children: List.generate(rows.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                      child: CachedNetworkImage(
                                        imageUrl: rows[index],
                                        width: SizeConfig.size80,
                                        height: SizeConfig.size80,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: SizeConfig.size80,
                                          height: SizeConfig.size80,
                                          color: Colors.grey[300],
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.person, size: SizeConfig.size80 / 2),
                                      ),
                                    ),
                                  );
                                }),
                              );
                              /*  return Column(
                                children:
                                    List.generate(rows.length, (rowIndex) {
                                  final rowItems = rows[rowIndex];
                                  logs("rowItems=== ${rowItems}");

                                  final isLastRow = rowIndex == rows.length - 1;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom:
                                            isLastRow ? 0 : mainAxisSpacing),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: List.generate(
                                          crossAxisCount * 2 - 1, (i) {
                                        if (i.isEven) {
                                          final itemIndex = i ~/ 2;

                                          if (itemIndex < rowItems.length) {
                                            final photos = rowItems[itemIndex];

                                            return Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            10.0)),
                                                child: CachedNetworkImage(
                                                  imageUrl: photos,
                                                  width: SizeConfig.size80,
                                                  height: SizeConfig.size80,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    width: SizeConfig.size80,
                                                    height: SizeConfig.size80,
                                                    color: Colors.grey[300],
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.person,
                                                              size: SizeConfig
                                                                      .size80 /
                                                                  2),
                                                ),
                                              ),
                                            );
                                          } else {
                                            return const Expanded(
                                                child: SizedBox.shrink());
                                          }
                                        } else {
                                          return SizedBox(
                                              width: SizeConfig.size8);
                                        }
                                      }),
                                    ),
                                  );
                                }),
                              );*/
                            })
                          : CustomText(
                              AppStrings.noPhotosAvailableMsg,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingL),

                CustomBtn(
                  onTap: () {},
                  isValidate: true,
                  radius: SizeConfig.size10,
                  title: AppStrings.requestBooking.tr,
                  // isLoading: authController.isAddBusinessUserLoading.value
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 50,
          height: 5,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          const Expanded(
            child: CustomText(
              AppStrings.allVariants,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      );
}

// Segmented capsule filter UI moved to
// `lib/features/common/Discover/widget/filter_capsule.dart` so the
// self-profession screen can share the same control.
