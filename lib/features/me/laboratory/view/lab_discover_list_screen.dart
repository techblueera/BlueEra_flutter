import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_detail_screen.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lab listing used from the Healthcare discover flow. Renders each lab as
/// a vertical "discover" card matching the img.png mock: hero image with
/// rating + share pills, business identity row, an "Available Tests"
/// summary block, and a footer with price + Inquiry CTA.
///
/// Uses the same [NearestPharmaciesController] as [LabProfilesListScreen]
/// but under a separate tag so the two screens don't share reactive state.
class LabDiscoverListScreen extends StatefulWidget {
  final String category;
  final String? subCategory;

  const LabDiscoverListScreen({
    super.key,
    required this.category,
    this.subCategory,
  });

  @override
  State<LabDiscoverListScreen> createState() => _LabDiscoverListScreenState();
}

class _LabDiscoverListScreenState extends State<LabDiscoverListScreen> {
  late final NearestPharmaciesController controller;

  @override
  void initState() {
    super.initState();
    controller =
        getOrPut(() => NearestPharmaciesController(), tag: 'lab_discover');
    controller.fetchNearest(
      category: widget.category,
      subCategory: widget.subCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: Colors.transparent,
      child: Obx(() {
        if (controller.isLoading.value && controller.pharmacies.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (controller.error.value.isNotEmpty &&
            controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.failedToLoadData.tr,
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noLaboratoriesFound.tr,
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () => controller.fetchNearest(
            category: widget.category,
            subCategory: widget.subCategory,
          ),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size12,
              horizontal: SizeConfig.size12,
            ),
            itemCount: controller.pharmacies.length,
            separatorBuilder: (_, __) => const SizedBox.shrink(),
            itemBuilder: (context, index) {
              final item = controller.pharmacies[index];
              return _LabDiscoverCard(
                item: item,
                onTap: () => Get.to(
                  () => LabDetailScreen(businessId: item.id),
                ),
                onInquiry: () => Get.to(
                  () => LabDetailScreen(businessId: item.id),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _LabDiscoverCard extends StatelessWidget {
  final PharmacyItem item;
  final VoidCallback onTap;
  final VoidCallback onInquiry;

  const _LabDiscoverCard({
    required this.item,
    required this.onTap,
    required this.onInquiry,
  });

  // ── Data helpers ──────────────────────────────────────────────
  String get _image {
    final photos = item.raw['live_photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first?.toString() ?? '';
      if (first.isNotEmpty) return first;
    }
    return item.logo;
  }

  String get _location {
    final csp = item.raw['city_state_pincode']?.toString() ?? '';
    if (csp.isNotEmpty) return csp;
    if (item.address.isNotEmpty) return item.address;
    return item.pincode;
  }

  /// Today's opening hours block from the new `timing` payload
  /// (see `lib/docs/BUSINESS_FILTER_TIMING.md`). Returns `null` when the
  /// business has never set its hours — callers must render a "Timing not
  /// set" state rather than falling back to a default.
  Map? get _todayTiming {
    final timing = item.raw['timing'];
    if (timing is! Map) return null;
    final today = timing['today'];
    return today is Map ? today : null;
  }

  /// `liveState.isLive` — true only when the current clock is inside today's
  /// window. Used to distinguish "Open now" from "Open today".
  bool get _isLiveNow {
    final live = item.raw['liveState'];
    return live is Map && live['isLive'] == true;
  }

  /// Distance from the device to the lab, formatted with the same three-tier
  /// scale the finance card uses (m / one-decimal KM / whole KM). Reads the
  /// list-item payload's `business_location: {lat, lon}` — the same shape the
  /// pharmacies list already consumes — and returns 'N/A' when coordinates
  /// are missing or zeroed.
  String get _distance {
    final loc = item.raw['business_location'];
    if (loc is! Map) return 'N/A';
    final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (loc['lon'] as num?)?.toDouble() ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return 'N/A';
    final km = calculateDistance(lat, lng);
    if (km == null) return 'N/A';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m Away';
    if (km < 10) return '${km.toStringAsFixed(1)}KM Away';
    return '${km.toStringAsFixed(0)}KM Away';
  }

  /// Test category names for the "Available Tests" preview line. Backend sends
  /// `testCategories` as a list of strings (or `{name}` objects); we coerce
  /// both shapes and drop empties.
  List<String> get _testCategories {
    final raw = item.raw['testCategories'];
    if (raw is List) {
      return raw
          .map((e) {
            if (e is String) return e;
            if (e is Map) {
              return (e['name'] ?? e['title'] ?? '').toString();
            }
            return e?.toString() ?? '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Total test count for the badge. Prefers the server-provided
  /// `availableTestCount`; falls back to the length of [_testCategories]
  /// when the field is missing.
  int get _availableTestCount {
    final count = item.raw['testCategoryCount'];
    if (count is num) return count.toInt();
    return _testCategories.length;
  }

  /// Consultation & test cost range from `costRange`. Supports either an
  /// `{min, max}` object or a pre-formatted string; returns '' when the
  /// server hasn't populated it yet.
  String get _priceRange {
    final range = item.raw['costRange'];
    if (range is Map) {
      final min = range['min'];
      final max = range['max'];
      if (min is num && max is num && (min > 0 || max > 0)) {
        if (min == max) return '₹${min.toStringAsFixed(0)}';
        return '₹${min.toStringAsFixed(0)} - ₹${max.toStringAsFixed(0)}';
      }
      if (min is num && min > 0) return '₹${min.toStringAsFixed(0)}';
      if (max is num && max > 0) return '₹${max.toStringAsFixed(0)}';
    }
    if (range is String && range.isNotEmpty) return range;
    return '';
  }

  void _share() {
    ShareService.instance.openShareSheet(
      text: 'Check out ${item.name} on BlueEra',
      subject: item.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: SizeConfig.size10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  child: _identityRow(),
                ),
                SizedBox(height: SizeConfig.size12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  child: _availableTestsBlock(),
                ),
                SizedBox(height: SizeConfig.size12),
                _footer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero image + overlays ────────────────────────────────────
  Widget _hero() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.greyE5),
                    errorWidget: (_, __, ___) => _imageFallback(),
                  )
                : _imageFallback(),
            Positioned(
              top: 10,
              left: 10,
              child: _ratingPill(),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  _circleIcon(AppIconAssets.share_bold, onTap: () => _share),
                  const SizedBox(height: 8),
                  _circleIcon(AppIconAssets.star_rounded, onTap: () => () {}),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: _timingPill(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.greyE5,
        alignment: Alignment.center,
        child: Icon(
          Icons.local_hospital_outlined,
          color: Colors.grey.shade400,
          size: 40,
        ),
      );

  Widget _ratingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black25,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.yellow),
          const SizedBox(width: 4),
          CustomText(
            item.rating > 0 ? item.rating.toStringAsFixed(1) : 'N/A',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(String icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.black25,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
            height: 14,
            width: 8,
          ),
        ),
      ),
    );
  }

  /// Bottom-right hero pill driven by the new `timing` payload. Three states:
  /// - `timing == null` → "Timing not set" (neutral chip)
  /// - `today.isOpen == false` → "Closed today" (red chip)
  /// - `today.isOpen == true` → "Open · HH:MM - HH:MM" (green); prefixed with
  ///   "Open now" when `liveState.isLive` confirms the current clock is inside
  ///   today's window, otherwise "Open today" — `today.isOpen` alone only
  ///   means "open sometime today".
  Widget _timingPill() {
    final today = _todayTiming;

    if (today == null) {
      return _timingChip(
        label: 'Timing not set',
        background: const Color(0xffF5F5F5),
        foreground: AppColors.grey7E,
      );
    }

    final bool isOpen = today['isOpen'] == true;
    final String open = today['shopOpenTime']?.toString() ?? '';
    final String close = today['shopCloseTime']?.toString() ?? '';

    if (!isOpen || (open.isEmpty && close.isEmpty)) {
      return _timingChip(
        label: 'Closed today',
        background: const Color(0xffFFF2F2),
        foreground: AppColors.red,
      );
    }

    final String range = (open.isNotEmpty && close.isNotEmpty)
        ? '$open - $close'
        : (open.isNotEmpty ? open : close);
    final String label =
        _isLiveNow ? 'Open now · $range' : 'Open today · $range';

    return _timingChip(
      label: label,
      background: const Color(0xffF2FFF2),
      foreground: AppColors.greenShade,
    );
  }

  Widget _timingChip({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: foreground, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: CustomText(
                label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Identity row: logo + name + location ─────────────────────
  Widget _identityRow() {
    // Same "meaningful" guard the finance card uses — treat 'N/A' as absent
    // so an unknown distance doesn't get concatenated with the address.
    bool isMeaningful(String s) => s.isNotEmpty && s != 'N/A';
    final distance = _distance;
    final address = _location;
    final bool showDistance = isMeaningful(distance);
    final bool showAddress = isMeaningful(address);
    final bool hasLocation = showDistance || showAddress;
    // final location = [
    //   if (isMeaningful(distance)) distance,
    //   if (isMeaningful(address)) address,
    // ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: SizeConfig.size50,
            height: SizeConfig.size50,
            child: item.logo.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.logo,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.greyE5),
                    errorWidget: (_, __, ___) => _logoFallback(),
                  )
                : _logoFallback(),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                item.name.isNotEmpty ? item.name : AppStrings.unknown.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size2),
              if (hasLocation) ...[
                SizedBox(height: SizeConfig.size2),
                Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.location_outline,
                      imgColor: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            if (showDistance)
                              TextSpan(
                                text: distance,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            if (showDistance && showAddress)
                              TextSpan(
                                text: "  |  ",
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            if (showAddress)
                              TextSpan(
                                text: address,
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoFallback() => Container(
        color: AppColors.greyE5,
        alignment: Alignment.center,
        child: Icon(
          Icons.local_hospital_outlined,
          size: 22,
          color: Colors.grey.shade500,
        ),
      );

  // ── Available Tests block ────────────────────────────────────
  Widget _availableTestsBlock() {
    final categories = _testCategories;
    final count = _availableTestCount;
    const inlineLimit = 2;
    final inline = categories.take(inlineLimit).join(', ');
    final more = categories.length - inlineLimit;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffDDE2EE), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: LocalAssets(
                imagePath: AppIconAssets.laboratoryIcon,
                imgColor: AppColors.primaryColor,
                height: 20,
                width: 20),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CustomText(
                      'Available Test',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black22,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.grey7E,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    CustomText(
                      '$count',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black22,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        inline.isNotEmpty ? inline : 'No tests listed yet',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey7E,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (more > 0) ...[
                      SizedBox(width: SizeConfig.size6),
                      GestureDetector(
                        onTap: onTap,
                        child: CustomText(
                          '$more More',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer: cost + Inquiry Now CTA ───────────────────────────
  // Mirrors school's `_buildFeeRow`: bordered container, label + value on
  // the left, primary Inquiry button on the right.
  Widget _footer() {
    final price = _priceRange;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Consultation & Test Cost',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  price.isNotEmpty ? price : 'N/A',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onInquiry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    'Inquiry Now',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
