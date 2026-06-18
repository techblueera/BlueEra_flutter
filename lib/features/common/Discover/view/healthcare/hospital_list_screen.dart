import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
        if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
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

  void _openDetail() {
    try {
      final controller = Get.find<HospitalServiceAiController>();
      controller.hospitalDataResModel?.value =
          HospitalFullDetailsResModel(success: true, data: item);
      Get.to(() => DiscoverHospitalHomeScreen());
    } on Exception catch (e) {
      logs("ERROR $e");
    }
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
    final addr = item.location?.name ?? '';
    ShareService.instance.openShareSheet(
      text: 'Check out $name on BlueEra'
          '${addr.trim().isNotEmpty ? '\n📍 ${addr.trim()}' : ''}',
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
        visitCallback: () => Get.to(() => DiscoverHospitalHomeScreen()));
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover banner with floating action buttons.
              _coverHeader(context),
              // Body content pulled up so the logo straddles the cover edge.
              // The translate leaves ~28px of breathing room at the card
              // bottom, which doubles as the bottom padding.
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: _coverBody(context),
                ),
              ),
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
            height: 150,
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
        // Floating share + directions controls.
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              _circleAction(Icons.share_outlined, _share),
              const SizedBox(width: 8),
              _circleAction(
                  Icons.directions_outlined, () => _openMapBottomSheet(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.black25,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: AppColors.primaryColor),
        ),
      ),
    );
  }

  // ─── Body ───────────────────────────────────────────────────────────────

  Widget _coverBody(BuildContext context) {
    final deptNames = _departmentNames();
    final facilities = _buildFacilities();
    final distance = _distanceLabel();
    final address = item.location?.name;
    final locationText = [
      if (distance != null) distance,
      if (!_isEmpty(address)) address!.trim(),
    ].join('  |  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo (straddling the cover) + name + location.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logo(),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      _valueOr(item.name, fallback: "Unknown Hospital"),
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openMapBottomSheet(context),
                      child: Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: AppColors.primaryColor),
                          const SizedBox(width: 3),
                          Expanded(
                            child: CustomText(
                              locationText.trim().isEmpty
                                  ? 'Address not available'
                                  : locationText,
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
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
        _serviceRow(
          icon: Icons.local_hospital_outlined,
          title: 'Departments',
          items: deptNames,
          emptyLabel: 'No departments listed',
        ),
        const SizedBox(height: 12),
        // Facilities summary.
        _serviceRow(
          icon: Icons.medical_services_outlined,
          title: 'Facilities',
          items: facilities,
          emptyLabel: 'No facilities listed',
        ),
        const SizedBox(height: 16),
        // Chat + Book Now actions.
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _chatButton(),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _bookNowButton(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _logo() {
    final hasLogo = !_isEmpty(item.logoUrl);
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.black25,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                child:
                    LocalAssets(imagePath: AppIconAssets.place_holder_image),
              ),
      ),
    );
  }

  /// One summary line: `[icon] Title • N  ........  View All`, with a muted
  /// secondary line listing the items underneath.
  Widget _serviceRow({
    required IconData icon,
    required String title,
    required List<String> items,
    required String emptyLabel,
  }) {
    final accent = AppColors.primaryColor;
    final count = items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 15, color: accent),
            ),
            const SizedBox(width: 8),
            CustomText(
              title,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(width: 6),
            CustomText(
              '• $count',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
            const Spacer(),
            if (count > 0)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openDetail,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      'View All',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: accent),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: CustomText(
            count == 0 ? emptyLabel : items.join(', '),
            fontSize: SizeConfig.small,
            color: count == 0 ? AppColors.grey9B : AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chatButton() {
    final accent = AppColors.primaryColor;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openChat,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalAssets(
                imagePath: AppIconAssets.chat,
                height: 18,
                width: 18,
                imgColor: accent,
              ),
              const SizedBox(width: 8),
              CustomText(
                'Chat',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: accent,
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openDetail,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                'Book Now',
                fontSize: SizeConfig.medium,
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
                        shimmerContainer(
                            width: 62, height: 62, radius: 31),
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
