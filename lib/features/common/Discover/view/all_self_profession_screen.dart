import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/filter_capsule.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_screen.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── AllSelfProfessionScreen ───
class AllSelfProfessionScreen extends StatefulWidget {
  final List<ProfessionTypeData> selfEmployedCategories;
  final ProfessionTypeData? selectedSelfProfessionData;

  const AllSelfProfessionScreen({
    super.key,
    required this.selfEmployedCategories,
    this.selectedSelfProfessionData,
  });

  @override
  State<AllSelfProfessionScreen> createState() =>
      _AllSelfProfessionScreenState();
}

class _AllSelfProfessionScreenState extends State<AllSelfProfessionScreen> {
  final controller = getOrPut(() => DiscoverController());
  late List<ProfessionTypeData> _selfEmployedCategories;
  final String serviceSubType = 'selfWork';
  final String earnServiceType = AppConstants.service;

  @override
  void initState() {
    super.initState();
    _selfEmployedCategories = widget.selfEmployedCategories;
    final selected = widget.selectedSelfProfessionData;
    controller.selectedEarnServiceData.value = selected != null
        ? OnboardingCategoryModel(
            name: selected.name ?? '',
            slugId: selected.tagId ?? '',
            accountType: AppConstants.individual,
          )
        : null;
    controller.fetchEarnServices(
        earnServiceType: earnServiceType, subType: serviceSubType);
  }

  /// Returns a new list sorted by the active filter. Mirrors the
  /// professional-consultant screen so both Discover lists feel
  /// identical. Items missing the comparator key sort to the end.
  ///
  /// `ServiceData` already carries a server-computed `distance` so we
  /// don't have to read GPS here. There's no explicit experience
  /// field on this model — we use `rating` (descending) as a stand-in
  /// for the "Experienced" filter, which generally tracks tenure.
  List<ServiceData> _applySort(
      List<ServiceData> items, CategoryFilter filter) {
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

  /// Converts an all-caps category name like "ELECTRICIAN" or
  /// "HOME_TUTOR" into a human-readable label like "Electrician" /
  /// "Home Tutor" for the empty-state message. Leaves already
  /// mixed-case names untouched.
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

  /// Effective price used for the Price (Low–High) sort — the range/single
  /// minimum (handles both legacy `singlePrice` and the newer `priceRange`).
  num _priceFor(ServiceData s) => s.priceData?.effectiveMin ?? 0;

  Widget _buildServicesMap(double statusBarHeight) {
    return DiscoverMapPreview(
      statusBarHeight: statusBarHeight,
      onTap: _openFullMap,
    );
  }

  void _openFullMap() {
    Get.to(() => _SelfProfessionMapScreen(
          earnServiceType: earnServiceType,
          subType: serviceSubType,
          onMarkerTap: _showServiceMapSheet,
        ));
  }

  /// Bottom sheet shown when a map marker is tapped — compact provider
  /// summary (avatar, name, rating, distance, price) with a "View Profile"
  /// CTA into [SelfEmployeeViewScreen]. Takes the host [BuildContext]
  /// so the sheet can render over either this screen or the dedicated
  /// [_SelfProfessionMapScreen] depending on where the marker was tapped.
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
                              _buildOnlineBadge(),
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
                        Get.to(() => SelfEmployeeViewScreen(
                              service: service,
                              timingMap:
                                  getMinMaxTimings(service.service?.effectiveTimings),
                              priceDisplay: priceDisplay,
                              priceBadgeText: (priceData?.feeType ??
                                          priceData?.priceType ??
                                          '')
                                      .capitalizeFirst ??
                                  '',
                              priceBadgeColor: isRange
                                  ? AppColors.green1A
                                  : AppColors.primaryColor,
                            ));
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

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stickyCategories = [
      // StickyCategory(id: 'ALL_OPTION', name: 'All', imageUrl: AppImageAssets.all),
      ..._selfEmployedCategories.map((c) => StickyCategory(
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
        backgroundColor: AppColors.appBackgroundColor,
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildServicesMap(statusBarHeight),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: stickyCategories,
                    singleLineLabel: true,
                    selectedId: controller.selectedEarnServiceData.value?.slugId ?? ELECTRICIAN,
                    // selectedId: controller.selectedEarnServiceData.value?.slugId ?? 'ALL_OPTION',
                    onCategoryTap: (item) {
                      // controller.selectedEarnServiceData.value =
                      //     item.id == 'ALL_OPTION' ? null : OnboardingCategoryModel(
                      //       name: item.name,
                      //       slugId: item.id,
                      //       accountType: AppConstants.individual,
                      //     );
                      controller.selectedEarnServiceData.value = OnboardingCategoryModel(
                        name: item.name,
                        slugId: item.id,
                        accountType: AppConstants.individual,
                      );
                      controller.fetchEarnServices(
                          earnServiceType: earnServiceType, subType: serviceSubType);
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
          // Segmented capsule — same widget the professional-consultant
          // screen uses, so the Discover lists feel uniform. Tapping
          // mutates `selectedFilter`; the Obx below re-sorts the
          // loaded list client-side, no refetch needed.
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
              if (controller.isEarnServiceLoading.value &&
                  controller.earnServiceList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.earnServiceList.isEmpty) {
                final selectedName =
                    controller.selectedEarnServiceData.value?.name ?? '';
                // Server returns categories in upper-case (e.g.
                // "ELECTRICIAN"); flip to title-case for the message
                // so it reads naturally ("No Electrician providers…").
                final pretty = _prettyCategoryName(selectedName);
                final message = pretty.isNotEmpty
                    ? AppStrings.noProvidersFoundNearYou.trParams({'category': pretty})
                    : AppStrings.noServicesFound.tr;
                return Center(
                    child: EmptyStateWidget(message: message));
              }
              final sorted = _applySort(
                controller.earnServiceList,
                controller.selectedFilter.value,
              );
              final showMoreSpinner =
                  controller.isEarnServiceLoadingMore.value;
              return ListView.builder(
                itemCount: sorted.length + (showMoreSpinner ? 1 : 0),
                padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                itemBuilder: (context, index) {
                  if (index == sorted.length) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child:
                                CircularProgressIndicator(strokeWidth: 2)));
                  }
                  return _buildSpecCard(sorted[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// **Spec-Sheet Card** — mirrors the consultant directory entry.
  /// Eyebrow (designation/profession) + oversized name + tagline →
  /// hairline → 4-column spec strip (RATING / PRICE / NEAR / HOURS) →
  /// optional 200px gallery hero → hairline → ghost View + filled
  /// Enquire footer. Visual structure identical to
  /// [AllProfessionConsultantScreen] so the two Discover lists feel
  /// uniform; only the data extraction differs because the underlying
  /// model is [ServiceData].
  Widget _buildSpecCard(ServiceData service) {
    // ─── Data extraction with sensible fallbacks ──────────────────
    final designation = (service.designation?.trim().isNotEmpty ?? false)
        ? service.designation!.trim()
        : (service.profession ?? '').trim();
    final name = (service.name?.trim().isNotEmpty ?? false)
        ? service.name!
        : AppStrings.unknownUser.tr;
    final taglineRaw =
        (service.bio ?? '').split('\n').firstWhere((s) => s.trim().isNotEmpty,
            orElse: () => '');

    final rating = service.rating ?? 0;
    final priceData = service.priceData;
    final isRange = priceData?.effectiveIsRange ?? false;
    final priceMin = priceData?.effectiveMin ?? 0;
    final priceMax = priceData?.effectiveMax ?? 0;
    final distance = (service.distance ?? 0).toDouble();
    final timingMap = getMinMaxTimings(service.service?.effectiveTimings);
    final timingStart = timingMap['start'] ?? '--';
    final timingEnd = timingMap['end'] ?? '--';

    final livePhotos = (service.serviceMedia?.photos ?? const <String>[])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final profileImage = service.profileImage ?? '';

    // ─── Spec-strip value formatters ──────────────────────────────
    final ratingStr =
        rating == 0 ? '—' : rating.toDouble().toStringAsFixed(1);
    final priceStr = priceMin == 0
        ? '—'
        : (isRange
            ? '₹${formatIndianNumber(priceMin)}-${formatIndianNumber(priceMax)}'
            : '₹${formatIndianNumber(priceMin)}');
    final distStr = distance == 0
        ? '—'
        : '${distance < 10 ? distance.toStringAsFixed(1) : distance.toStringAsFixed(0)} km';
    // Compact hours: "9:00 AM - 6:00 PM" → "9AM-6PM" so the narrow
    // spec column doesn't FittedBox down to an unreadable size.
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
        ? '—'
        : '${compactTime(timingStart)}-${compactTime(timingEnd)}';

    // For the price badge inside SelfEmployeeViewScreen — kept
    // identical to the legacy card so the detail page reads the same.
    final priceDisplay = isRange
        ? "₹${formatIndianNumber(priceMin)}-${formatIndianNumber(priceMax)}"
        : "₹${formatIndianNumber(priceMin)}";
    final badgeColor = isRange ? AppColors.green1A : AppColors.primaryColor;
    final badgeText =
        (priceData?.feeType ?? priceData?.priceType ?? '').capitalizeFirst ?? '';

    void openDetail() {
      ProfileClickTracker.track(
        userId: service.id ?? '',
        source: ChatClickSource.searchResult,
      );
      Get.to(() => SelfEmployeeViewScreen(
            service: service,
            timingMap: timingMap,
            priceDisplay: priceDisplay,
            priceBadgeText: badgeText,
            priceBadgeColor: badgeColor,
          ));
    }

    return InkWell(
      onTap: openDetail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Eyebrow: bullet + DESIGNATION ────────────────────
            if (designation.isNotEmpty)
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Flexible(
                    child: Text(
                      designation.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                        letterSpacing: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            SizedBox(height: SizeConfig.size8),

            // ─── Name + small avatar ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                CachedAvatarWidget(
                  imageUrl: profileImage,
                  size: SizeConfig.size40,
                  borderColor: Colors.white,
                  borderRadius: SizeConfig.size20,
                ),
              ],
            ),

            if (taglineRaw.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size6),
              Text(
                taglineRaw,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            SizedBox(height: SizeConfig.size12),
            Container(height: 1, color: const Color(0xFFEDEFF4)),
            SizedBox(height: SizeConfig.size12),

            // ─── 4-column spec strip ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _specColumn(AppStrings.specLabelRating.tr, ratingStr)),
                Expanded(child: _specColumn(AppStrings.specLabelPrice.tr, priceStr)),
                Expanded(child: _specColumn(AppStrings.specLabelNear.tr, distStr)),
                Expanded(child: _specColumn(AppStrings.specLabelHours.tr, hoursStr)),
              ],
            ),

            // ─── Live-photo carousel OR profile-image fallback ────
            // Mirrors the consultant card so the gallery experience
            // stays consistent across both Discover lists. The 200px
            // height holds the card silhouette steady even when a
            // provider hasn't uploaded service photos yet.
            if (livePhotos.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoreLivePhotoWidget(
                  livePhotos: livePhotos,
                  natureOfBusiness: service.profession ?? 'Service',
                  height: 200,
                  onViewFullScreen: ({
                    required int index,
                    required List<String> storeImage,
                    required String natureOfBusiness,
                  }) {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: natureOfBusiness,
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: storeImage,
                        initialIndex: index,
                      ),
                    );
                  },
                ),
              ),
            ] else if (profileImage.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => navigatePushTo(
                    context,
                    ImageViewScreen(
                      subTitle: service.profession ?? 'Service',
                      appBarTitle: AppStrings.imageViewer,
                      imageUrls: [profileImage],
                      initialIndex: 0,
                    ),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: profileImage,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      memCacheHeight: 600,
                      placeholder: (_, __) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                      ),
                      errorWidget: (_, __, ___) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: SizeConfig.size12),
            Container(height: 1, color: const Color(0xFFEDEFF4)),
            SizedBox(height: SizeConfig.size10),

            // ─── Footer: View (ghost) + Enquire (filled) ──────────
            Row(
              children: [
                Expanded(
                  child: _ghostButton(
                    label: 'view'.tr,
                    icon: Icons.arrow_outward_rounded,
                    onTap: openDetail,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: _filledButton(
                    label: AppStrings.enquire.tr,
                    icon: Icons.chat_outlined,
                    onTap: () {
                      final targetUserId = service.id ?? '';
                      if (targetUserId.isEmpty) return;
                      final chatViewController =
                          getOrPut(() => ChatViewController());
                      chatViewController.checkChatConnectionAndOpenChat(
                          userId: targetUserId,
                          route: AppConstants.route_discover);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Single column of the 4-column spec strip — label on top in
  /// uppercase eyebrow style, value below in body weight with tabular
  /// figures so digit columns align across rows.
  Widget _specColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              letterSpacing: 0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ghostButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Badges (still used by the map-marker bottom sheet) ─────────
  Widget _buildRatingBadge(String rating) {
    const goldFg = Color(0xFFB8860B);
    const goldBg = Color(0xFFFFF3D1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, goldBg],
        ),
        border: Border.all(
          color: goldFg.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: goldFg.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(
            rating,
            fontSize: 11,
            color: AppColors.mainTextColor,
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

  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.green.withValues(alpha: 0.10),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          CustomText(
            AppStrings.online.tr,
            fontSize: 11,
            color: Colors.green.shade700,
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
          .isBefore(_parse12HourTime(earliest?.start ?? "00:00 AM")))
        earliest = t;
      if (_parse12HourTime(t.end ?? "00:00 AM")
          .isAfter(_parse12HourTime(latest?.end ?? "00:00 AM"))) latest = t;
    }
    return {"start": earliest?.start ?? "--", "end": latest?.end ?? "--"};
  }
}

/// Full-screen map page reached by tapping the inline preview on
/// [AllSelfProfessionScreen]. Loads every provider (unpaginated) via
/// [DiscoverController.fetchAllEarnServicesForMap] and renders them
/// through `google_maps_flutter`'s built-in clustering so 100+ pins
/// stay smooth — nearby providers collapse into a count badge that
/// splits open as the user zooms in.
///
/// Initial zoom is `12` — that frames roughly a 25–50 km area around
/// the user, matching the "city-radius" feel of mainstream discover apps.
class _SelfProfessionMapScreen extends StatefulWidget {
  final String earnServiceType;
  final String subType;
  final void Function(BuildContext context, ServiceData service) onMarkerTap;

  const _SelfProfessionMapScreen({
    required this.earnServiceType,
    required this.subType,
    required this.onMarkerTap,
  });

  @override
  State<_SelfProfessionMapScreen> createState() =>
      _SelfProfessionMapScreenState();
}

class _SelfProfessionMapScreenState extends State<_SelfProfessionMapScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _serviceIcon;

  final DiscoverController _ctrl = Get.find<DiscoverController>();
  static const ClusterManagerId _clusterManagerId =
      ClusterManagerId('self_profession_services');

  @override
  void initState() {
    super.initState();
    _ctrl.fetchAllEarnServicesForMap(
      earnServiceType: widget.earnServiceType,
      subType: widget.subType,
    );
    // Pre-render the custom marker icon once; cluster taps pop the
    // unclustered marker so this is what the user actually sees.
    DiscoverMarkerIcons.circle(icon: Icons.work_outline_rounded).then((d) {
      if (mounted) setState(() => _serviceIcon = d);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Builds the marker set fed to [GoogleMap.markers]. Each marker is
  /// stamped with [_clusterManagerId] so the platform-side cluster
  /// manager can group nearby ones into a numbered badge automatically.
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

  /// Frames the camera around every position inside the tapped cluster
  /// so the cluster expands cleanly into individual pins.
  Future<void> _zoomToCluster(Cluster cluster) async {
    if (_mapController == null) return;
    final markers = cluster.markerIds;
    if (markers.length <= 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.position, 15),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(cluster.bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLat =
        LocationService.lat != 0.0 ? LocationService.lat : 28.6139;
    final initialLng =
        LocationService.lng != 0.0 ? LocationService.lng : 77.2090;
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
            final isLoading = _ctrl.earnServiceMapResponse.value.status ==
                Status.INITIAL;
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
                Expanded(child: bannerMapLocationPill()),
                SizedBox(width: SizeConfig.size8),
                bannerMapCircleIconButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(initialLat, initialLng),
                        13,
                      ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
