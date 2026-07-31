import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_navigation.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key, required this.serviceType});
  final String serviceType;
  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  late final HospitalServiceAiController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalServiceAiController());
    controller.fetchInitial(widget.serviceType);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    // Paginate via scroll notifications instead of an explicit controller so
    // the inner ListView uses the NestedScrollView's PrimaryScrollController
    // when embedded (e.g. HealthCareListingScreen) — that keeps the banner /
    // sticky-category header and the list scrolling as one smooth motion.
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
          controller.fetchMore(widget.serviceType);
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          if (controller.isLoading.value && controller.profiles.isEmpty) {
            // One Shimmer drives all skeleton cards. Per-card shimmers flooded
            // BLASTBufferQueue with redraws (visible as the "Already acquired
            // max frames" spam in logcat).
            return buildLoadingShimmer(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                itemCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, __) => const _HospitalCardSkeletonBody(),
              ),
            );
          }
          if (controller.error.value.isNotEmpty &&
              controller.profiles.isEmpty) {
            return Center(
              child: CustomText(
                "Failed to load data",
                fontSize: SizeConfig.medium,
                color: AppColors.red,
              ),
            );
          }
          if (controller.profiles.isEmpty) {
            return Center(
              child: CustomText(
                "No hospitals found",
                fontSize: SizeConfig.medium,
                color: AppColors.grey9B,
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              await controller.fetchInitial(widget.serviceType);
            },
            child: Builder(
              builder: (context) {
                final rows = buildNativeAdRows(controller.profiles.length);
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                  itemCount:
                      rows.length + (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == rows.length) {
                      // Load-more footer: wrap a single body in one shimmer.
                      return buildLoadingShimmer(
                        child: const _HospitalCardSkeletonBody(),
                      );
                    }
                    final row = rows[index];
                    if (row.isAd) {
                      return NativeAdSlot(
                        adOrdinal: row.adOrdinal,
                        keyPrefix: 'hospital_native_ad',
                      );
                    }
                    final item = controller.profiles[row.contentIndex];
                    return _HospitalCard(item: item);
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalFullData item;

  const _HospitalCard({required this.item});

  bool _isEmpty(String? s) => s == null || s.trim().isEmpty;

  String _valueOr(String? s, {String fallback = "Not available"}) =>
      _isEmpty(s) ? fallback : s!.trim();

  List<String> _collectGalleryPhotos() {
    final photos = <String>[];
    if (item.gallery != null) {
      for (final g in item.gallery!) {
        if (g.uploadPhoto != null && g.uploadPhoto!.isNotEmpty) {
          photos.add(g.uploadPhoto!);
        }
        if (g.images != null) {
          photos.addAll(g.images!.where((u) => u.trim().isNotEmpty));
        }
      }
    }
    return photos;
  }

  /// Cover priority: gallery → cover → logo. Returns null when none exists.
  String? _coverImage() {
    final gallery = _collectGalleryPhotos();
    if (gallery.isNotEmpty) return gallery.first;
    if (!_isEmpty(item.coverUrl)) return item.coverUrl;
    if (!_isEmpty(item.logoUrl)) return item.logoUrl;
    return null;
  }

  List<String> _departmentNames() => (item.departments ?? [])
      .map((d) => d.name ?? '')
      .where((s) => s.trim().isNotEmpty)
      .toList();

  List<String> _buildFacilities() {
    // The `business/filter` listing supplies facility names directly. Prefer
    // those; fall back to deriving them from the emergency-care / other-
    // facility booleans (populated only on the full-details path).
    final apiNames = item.facilityNames;
    if (apiNames != null && apiNames.isNotEmpty) {
      return apiNames.where((s) => s.trim().isNotEmpty).toList();
    }
    final list = <String>[];
    final ec = item.emergencyCare;
    final of = item.otherFacilities;
    if (ec?.emergencyCasualty ?? false) list.add("Emergency");
    if (ec?.traumaCare ?? false) list.add("Trauma Care");
    if (ec?.icu ?? false) list.add("ICU");
    if (ec?.ccu ?? false) list.add("CCU");
    if (ec?.nicu ?? false) list.add("NICU");
    if (ec?.picu ?? false) list.add("PICU");
    if (of?.ambulance ?? false) list.add("Ambulance");
    if (of?.bloodBank ?? false) list.add("Blood Bank");
    if (of?.diagnosticDepartments ?? false) list.add("Diagnostics");
    if (of?.medicalStore ?? false) list.add("Medical Store");
    if (of?.pmSwasthyaBimaYojana ?? false) list.add("PM Yojana");
    return list;
  }

  double _destLat() {
    final coords = item.location?.coordinates;
    // GeoJSON stores [lng, lat].
    if (coords != null && coords.length >= 2) return coords[1];
    return 0.0;
  }

  double _destLng() {
    final coords = item.location?.coordinates;
    if (coords != null && coords.length >= 2) return coords[0];
    return 0.0;
  }

  /// "x.x km away" / "xxx m away" — null when either endpoint is unknown so
  /// the location row falls back to just the address.
  String? _distanceLabel() {
    final dLat = _destLat();
    final dLng = _destLng();
    if (dLat == 0.0 && dLng == 0.0) return null;
    final uLat = LocationService.lat;
    final uLng = LocationService.lng;
    if (uLat == 0.0 && uLng == 0.0) return null;
    final km = calculateDistanceKm(uLat, uLng, dLat, dLng);
    if (km.isNaN || km.isInfinite) return null;
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away';
  }

  /// Routed through [openVisitProfile] so the type→screen mapping stays in one
  /// place. The fetched list item goes with it, so the hospital screen seeds
  /// its controller with the real record rather than an id-only stub.
  void _openDetail() {
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: BusinessType.Healthcare.name,
      categoryOfBusiness: 'HOSPITALS',
      businessId: item.id,
      userId: item.userId,
      hospitalData: item,
    );
  }

  void _openChat() {
    final userId = item.userId ?? '';
    if (userId.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = item.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
        userId: bId,
        source: ChatClickSource.searchResult,
      );
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      name: item.name,
      profile: item.logoUrl,
      route: AppConstants.route_discover,
    );
  }

  void _share() {
    final name = item.name ?? 'Hospital';

    final shareLink = hospitalDeepLink(
      hospitalId: item.userId,
    );
    ShareService.instance.openShareSheet(
      text: 'Check out ${item.name} on BlueEra\n$shareLink',
      subject: name,
    );
  }

  void _openMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
        context: context,
        destinationName: item.name ?? 'Hospital',
        destinationAddress: item.location?.name ?? '',
        destinationLat: _destLat(),
        destinationLng: _destLng(),
        visitCallback: _openDetail);
  }

  void _openImageViewer(BuildContext context) {
    final gallery = _collectGalleryPhotos();
    final images = gallery.isNotEmpty
        ? gallery
        : [if (_coverImage() != null) _coverImage()!];
    if (images.isEmpty) return;
    navigatePushTo(
      context,
      ImageViewScreen(
        subTitle: item.name ?? 'Hospital',
        appBarTitle: AppStrings.imageViewer,
        imageUrls: images,
        initialIndex: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openDetail,
        child: CommonCardWidget(
          cardMargin: 0,
          padding: 0,
          borderRadius: 16,
          shadowColor: AppColors.shadowColor.withValues(alpha: 0.10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover banner with floating action buttons.
              _coverHeader(context),
              SizedBox(
                height: 10,
              ),
              // Body content pulled up so the logo straddles the cover edge.
              // The translate leaves ~28px of breathing room at the card
              // bottom, which doubles as the bottom padding.
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: _coverBody(context),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ─── Cover banner ───────────────────────────────────────────────────────

  Widget _coverHeader(BuildContext context) {
    final cover = _coverImage();
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: cover == null
                ? Container(
                    color: AppColors.liteWhite,
                    child: LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    placeholder: (_, __) => Container(
                      color: AppColors.liteWhite,
                      child: LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.liteWhite,
                      child: LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
                    ),
                  ),
          ),
        ),
        // Tap the banner to open the full-screen gallery.
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              onTap: () => _openImageViewer(context),
            ),
          ),
        ),
        // Floating share control. Rating badge + rate CTA are intentionally
        // omitted on the listing card — the hospital `business/filter`
        // payload does not include the be_user_service `businesses._id`
        // (see lib/docs/rating-ui-integration.md §1) and rating without
        // it 404s. Rate/reviews live on the detail screen instead, where
        // VisitBusinessHero resolves the correct id from the profile fetch.
        Positioned(
          top: 10,
          right: 10,
          child: _circleAction(AppIconAssets.share_bold, _share),
        ),
      ],
    );
  }

  Widget _circleAction(String icon, VoidCallback onTap) {
    return Material(
      color: AppColors.black25,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.black25,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: LocalAssets(
            imagePath: icon,
            height: 20,
            width: 20,
            imgColor: AppColors.white,
          ),
        ),
      ),
    );
  }

  // ─── Body ───────────────────────────────────────────────────────────────

  Widget _coverBody(BuildContext context) {
    final deptNames = _departmentNames();
    final facilities = _buildFacilities();
    // Prefer the server's explicit counts; fall back to the rendered list
    // length so the badge stays correct on the full-details path.
    final deptCount = item.departmentCount ?? deptNames.length;
    final facilityCount = item.facilityCount ?? facilities.length;
    final distance = _distanceLabel();
    final address = item.location?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo (straddling the cover) + name + location.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / name open the hospital's business profile; the
            // rest of the card keeps opening the hospital detail page.
            DiscoverProfileTap(
              accountType: AppConstants.business,
              businessId: item.id,
              userId: item.userId,
              child: _logo(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DiscoverProfileTap(
                      accountType: AppConstants.business,
                      businessId: item.id,
                      userId: item.userId,
                      child: CustomText(
                        _valueOr(item.name, fallback: "Unknown Hospital"),
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black22,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openMapBottomSheet(context),
                      child: Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.location_outline,
                            imgColor: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 3),
                          // Distance highlighted in the primary color, kept
                          // separate from the (secondary) address.
                          if (distance != null) ...[
                            CustomText(
                              distance,
                              fontSize: SizeConfig.small,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w400,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!_isEmpty(address))
                              CustomText(
                                '  |  ',
                                fontSize: SizeConfig.small,
                                color: Color(0xff66727E),
                                fontWeight: FontWeight.w500,
                              ),
                          ],
                          Expanded(
                            child: CustomText(
                              _isEmpty(address)
                                  ? (distance == null
                                      ? 'Address not available'
                                      : '')
                                  : address!.trim(),
                              fontSize: SizeConfig.small,
                              color: Color(0xff66727E),
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Departments summary.
        Container(
          padding: EdgeInsets.all(0),
          decoration: BoxDecoration(
            border: Border.all(
              width: 0.5,
              color: AppColors.greyE6,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _serviceRow(
                  icon: "assets/svg/department.svg",
                  title: 'Departments',
                  items: deptNames,
                  count: deptCount,
                  emptyLabel: 'No departments listed',
                  // color: AppColors.primaryColor.withValues(alpha: 0.10)
                ),
              ),
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColors.greyE6,
              ),
              // Facilities summary.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _serviceRow(
                  icon: "assets/svg/hands_brain.svg",
                  title: 'Facilities',
                  items: facilities,
                  count: facilityCount,
                  emptyLabel: 'No facilities listed',
                  // color: AppColors.green0B.withValues(alpha: 0.10)),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 16),
        // Chat + Book Now actions.
        Row(
          children: [
            Expanded(flex: 1, child: _chatButton(context)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _bookNowButton(),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _logo() {
    final hasLogo = !_isEmpty(item.logoUrl);
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: hasLogo
            ? CachedNetworkImage(
                imageUrl: item.logoUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 200,
                placeholder: (_, __) => Container(color: AppColors.liteWhite),
                errorWidget: (_, __, ___) => LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                ),
              )
            : Container(
                color: AppColors.liteWhite,
                child: LocalAssets(imagePath: AppIconAssets.place_holder_image),
              ),
      ),
    );
  }

  /// One summary row: a rounded icon tile on the left, then `Title • N` with a
  /// single-line, comma-joined preview of the [items] beneath it, and an
  /// `N More` link on the right. Summary always renders on first frame — the
  /// `More` badge is opt-in and its visibility is decided by a lightweight
  /// `LayoutBuilder` overflow check that runs *after* the summary is already
  // /// laid out, so a stale first-frame measurement can never hide the items.
  // Widget _serviceRow({
  //   required String icon,
  //   required String title,
  //   required List<String> items,
  //   required int count,
  //   required String emptyLabel,
  //   required Color color,
  // }) {
  //   final accent = AppColors.primaryColor;
  //   final facilityAccent = const Color(0xff00B87A1A);
  //   // Anchor on the larger of the server count / names length so the badge
  //   // never under-reports. Guards against server sending count=0 while items
  //   // are present (which would otherwise hide the badge entirely).
  //   final total = count > items.length ? count : items.length;
  //   final summary = items.isEmpty ? emptyLabel : items.join(', ');
  //   final serverHasMore = count > items.length;
  //   const preview = 4;
  //   // Fall-back count for the "More" link when the summary overflows: server
  //   // extras + everything past the preview cap. Never negative.
  //   final previewHidden =
  //       (items.length > preview ? items.length - preview : 0) +
  //           (serverHasMore ? count - items.length : 0);
  //
  //   final summaryText = CustomText(
  //     summary,
  //     fontSize: SizeConfig.extraSmall,
  //     color: items.isEmpty ? AppColors.grey9B : const Color(0xff66727E),
  //     fontWeight: FontWeight.w600,
  //     maxLines: 1,
  //     overflow: TextOverflow.ellipsis,
  //   );
  //
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.center,
  //     children: [
  //       Container(
  //         width: 38,
  //         height: 38,
  //         alignment: Alignment.center,
  //         decoration: BoxDecoration(
  //           color: color,
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //         child: LocalAssets(
  //           imagePath: icon,
  //           height: 20,
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 CustomText(
  //                   title,
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppColors.black22,
  //                 ),
  //                 if (total > 0) ...[
  //                   const SizedBox(width: 5),
  //                   CustomText(
  //                     '• $total',
  //                     fontSize: SizeConfig.small,
  //                     fontWeight: FontWeight.w600,
  //                     color: AppColors.black22,
  //                   ),
  //                 ],
  //               ],
  //             ),
  //             const SizedBox(height: 3),
  //             // Summary sits in Expanded so the row always paints even before
  //             // LayoutBuilder resolves. LayoutBuilder only decides whether the
  //             // "More" badge slot on the right is populated — items are never
  //             // hidden waiting on a measurement.
  //             LayoutBuilder(
  //               builder: (context, constraints) {
  //                 if (constraints.maxWidth <= 0 ||
  //                     !constraints.maxWidth.isFinite) {
  //                   return summaryText;
  //                 }
  //
  //                 final summaryStyle = TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: items.isEmpty
  //                       ? AppColors.grey9B
  //                       : const Color(0xff66727E),
  //                 );
  //                 final fullPainter = TextPainter(
  //                   text: TextSpan(text: summary, style: summaryStyle),
  //                   maxLines: 1,
  //                   textDirection: TextDirection.ltr,
  //                 )..layout(maxWidth: constraints.maxWidth);
  //                 final overflows = fullPainter.didExceedMaxLines;
  //
  //                 if (!overflows && !serverHasMore) return summaryText;
  //                 if (previewHidden <= 0 && !overflows) return summaryText;
  //
  //                 final badgeCount =
  //                     previewHidden > 0 ? previewHidden : items.length;
  //                 return Row(
  //                   children: [
  //                     Expanded(child: summaryText),
  //                     const SizedBox(width: 8),
  //                     GestureDetector(
  //                       behavior: HitTestBehavior.opaque,
  //                       onTap: _openDetail,
  //                       child: CustomText(
  //                         '$badgeCount More',
  //                         fontSize: SizeConfig.small,
  //                         fontWeight: FontWeight.w600,
  //                         color: accent,
  //                       ),
  //                     ),
  //                   ],
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _serviceRow({
    required String icon,
    required String title,
    required List<String> items,
    required int count,
    required String emptyLabel,
  }) {
    final accent = AppColors.primaryColor;
    const preview = 4;
    final shown = items.length < preview ? items.length : preview;
    // Anchor on the larger of the server count / names length so the link
    // never under-reports the remaining items.
    final total = count > items.length ? count : items.length;
    final hidden = total - shown;
    final summary = items.isEmpty ? emptyLabel : items.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: LocalAssets(imagePath: icon),
          // child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomText(
                    title,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(width: 5),
                  CustomText(
                    '• $count',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              CustomText(
                summary,
                fontSize: SizeConfig.small,
                color: items.isEmpty
                    ? AppColors.grey9B
                    : AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (hidden > 0) ...[
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openDetail,
            child: CustomText(
              '$hidden More',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _chatButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _openMapBottomSheet(context);
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
              color: Color(0xffF2F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xffCFE8FF))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalAssets(
                  imagePath: AppIconAssets.directionIcon,
                  imgColor: AppColors.primaryColor),
              const SizedBox(width: 6),
              CustomText(
                AppStrings.directions,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookNowButton() {
    final accent = AppColors.primaryColor;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _openDetail,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(10),
            // boxShadow: [
            //   BoxShadow(
            //     color: accent.withValues(alpha: 0.30),
            //     blurRadius: 8,
            //     offset: const Offset(0, 3),
            //   ),
            // ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                AppStrings.inquiry,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholders only — wrap in a single [buildLoadingShimmer] at the list
/// level so all cards share one animation controller. Rendering N shimmers
/// at once saturates Android's BLASTBufferQueue ("Already acquired max
/// frames") on mid-range devices.
class _HospitalCardSkeletonBody extends StatelessWidget {
  const _HospitalCardSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      child: CommonCardWidget(
        cardMargin: 0,
        padding: 0,
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover banner.
            shimmerContainer(height: 150, radius: 16),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerContainer(width: 62, height: 62, radius: 31),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                shimmerContainer(height: SizeConfig.size16),
                                SizedBox(height: SizeConfig.size8),
                                shimmerContainer(
                                    height: SizeConfig.size12, width: 180),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size14),
                    shimmerContainer(height: SizeConfig.size12, width: 240),
                    SizedBox(height: SizeConfig.size6),
                    shimmerContainer(height: SizeConfig.size12),
                    SizedBox(height: SizeConfig.size12),
                    shimmerContainer(height: SizeConfig.size12, width: 240),
                    SizedBox(height: SizeConfig.size6),
                    shimmerContainer(height: SizeConfig.size12),
                    SizedBox(height: SizeConfig.size16),
                    Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: shimmerContainer(height: 46, radius: 12)),
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 2,
                            child: shimmerContainer(height: 46, radius: 12)),
                      ],
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
}
