import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_detail_screen.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card surface mirrors `_HospitalCard` so lab tiles read as siblings of the
/// hospital directory when both are reached from [HealthCareListingScreen].
const Color _kCardBorder = Color(0xFFE9EBF0);

/// Lab listing used from the Healthcare discover flow. Renders labs 2-up in
/// the same grid the hospital directory uses (`docs/labnew.png`): hero image
/// with share + Open Now pills, name, ★ rating | lab type, distance | address,
/// then the Tests / Facilities counters.
///
/// Uses the same [NearestPharmaciesController] as [LabProfilesListScreen] but
/// under a separate tag so the two screens don't share reactive state.
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
          return _loadingGrid();
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
          // Two tiles per row. Built as a ListView of paired rows rather than
          // a GridView so each row can size to its own tallest tile — a fixed
          // childAspectRatio would clip the longer names/addresses.
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
              vertical: SizeConfig.size8,
            ),
            itemCount: (controller.pharmacies.length + 1) ~/ 2,
            itemBuilder: (context, rowIndex) {
              final leftIndex = rowIndex * 2;
              final rightIndex = leftIndex + 1;
              final left = controller.pharmacies[leftIndex];
              final right = rightIndex < controller.pharmacies.length
                  ? controller.pharmacies[rightIndex]
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                // IntrinsicHeight so mismatched name/address lengths don't
                // leave one tile shorter than the other.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _LabCard(item: left, onTap: _open)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: right != null
                            ? _LabCard(item: right, onTap: _open)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _open(PharmacyItem item) =>
      Get.to(() => LabDetailScreen(businessId: item.id));

  /// One shimmer controller for the whole grid — per-tile shimmers saturate
  /// Android's BLASTBufferQueue on mid-range devices.
  Widget _loadingGrid() {
    return buildLoadingShimmer(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size8,
        ),
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _LabCardSkeletonBody()),
                SizedBox(width: 10),
                Expanded(child: _LabCardSkeletonBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact lab tile — the `docs/labnew.png` layout: hero (AspectRatio 1.2 +
/// share stack + Open pill) → name → ★ rating | lab type → distance | address
/// → tests / facilities counters.
class _LabCard extends StatelessWidget {
  final PharmacyItem item;
  final void Function(PharmacyItem item) onTap;

  const _LabCard({required this.item, required this.onTap});

  // ── Data helpers ──────────────────────────────────────────────

  /// Cover banner: `coverPicture` (see `viewBusinessProfileModel.dart` —
  /// `coverimage` deserialises from `coverPicture`), falling back to the first
  /// live photo, then the logo, so the hero never collapses to a bare icon
  /// when only the profile photo is available.
  String get _cover {
    final cover = item.raw['coverPicture']?.toString() ?? '';
    if (cover.isNotEmpty) return cover;
    final photos = item.raw['live_photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first?.toString() ?? '';
      if (first.isNotEmpty) return first;
    }
    return item.logo.trim();
  }

  String get _location {
    final csp = item.raw['city_state_pincode']?.toString() ?? '';
    if (csp.isNotEmpty) return csp;
    if (item.address.isNotEmpty) return item.address;
    return item.pincode;
  }

  /// The line under the name. Prefers the business sub-category ("Pathology
  /// Lab"), falling back to the top-level category so a lab with only a
  /// category set still gets a label — same rule the hospital tile uses.
  String get _labType {
    final sub = item.raw['sub_category_details'];
    if (sub is Map) {
      final name = sub['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    final cat = item.raw['category_details'];
    if (cat is Map) {
      return cat['name']?.toString().trim() ?? '';
    }
    return '';
  }

  /// `liveState.isLive` — true only when the current clock is inside today's
  /// window (see `lib/docs/BUSINESS_FILTER_TIMING.md`). The pill is hidden
  /// outside it rather than showing a "Closed" state, matching the design.
  bool get _isOpenNow {
    final live = item.raw['liveState'];
    return live is Map && live['isLive'] == true;
  }

  /// Distance from the device, formatted with the same three-tier scale the
  /// finance card uses (m / one-decimal KM / whole KM). Reads the list-item
  /// payload's `business_location: {lat, lon}` and returns '' when coordinates
  /// are missing or zeroed so the location line collapses to just the address.
  String get _distance {
    final loc = item.raw['business_location'];
    if (loc is! Map) return '';
    final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (loc['lon'] as num?)?.toDouble() ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m away';
    if (km < 10) return '${km.toStringAsFixed(1)}km away';
    return '${km.toStringAsFixed(0)}km away';
  }

  /// Test-category names, kept only as the fallback count source. Backend
  /// sends `testCategories` as a list of strings (or `{name}` objects); both
  /// shapes are coerced and empties dropped.
  List<String> get _testCategories {
    final raw = item.raw['testCategories'];
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is String) return e;
          if (e is Map) return (e['name'] ?? e['title'] ?? '').toString();
          return e?.toString() ?? '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Counter shown on the card. Prefers a real test count when the payload
  /// carries one and falls back to the category count, which is what
  /// `business/filter` sends today.
  int get _testCount {
    for (final key in const ['testCount', 'availableTestCount', 'testCategoryCount']) {
      final value = item.raw[key];
      if (value is num) return value.toInt();
    }
    return _testCategories.length;
  }

  /// `facility_count` / `facilities` on the `business/filter` record — the
  /// same two fields the hospital adapter reads.
  int get _facilityCount {
    final count = item.raw['facility_count'];
    if (count is num) return count.toInt();
    final list = item.raw['facilities'];
    if (list is List) return list.length;
    return 0;
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
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F001120),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoverSection(),
            Padding(
              padding: EdgeInsets.only(
                right: SizeConfig.size10,
                left: SizeConfig.size10,
                top: SizeConfig.size10,
                bottom: SizeConfig.size4,
              ),
              child: _buildInfoBlock(),
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size8),
              child: _buildTestsFacilities(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  Widget _buildCoverSection() {
    final cover = _cover;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cover.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    placeholder: (_, __) => Container(color: AppColors.greyE5),
                    errorWidget: (_, __, ___) => _imageFallback(),
                  )
                : _imageFallback(),
            Positioned(
              top: SizeConfig.size6,
              right: SizeConfig.size6,
              child: GestureDetector(
                onTap: _share,
                child: _circleIcon(AppIconAssets.share_bold),
              ),
            ),
            if (_isOpenNow)
              Positioned(
                bottom: SizeConfig.size6,
                right: SizeConfig.size6,
                child: _openPill(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.greyE5,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
      );

  Widget _circleIcon(String icon) {
    return Container(
      width: SizeConfig.size26,
      height: SizeConfig.size26,
      decoration: const BoxDecoration(
        color: AppColors.black25,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size6),
        child: LocalAssets(
          imagePath: icon,
          imgColor: AppColors.white,
        ),
      ),
    );
  }

  Widget _openPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size6,
        vertical: SizeConfig.size3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF2FFF2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.green00, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time,
              size: SizeConfig.size12, color: AppColors.green00),
          SizedBox(width: SizeConfig.size3),
          CustomText(
            AppStrings.labCardOpenNow.tr,
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.green00,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // ─── INFO BLOCK ──────────────────────────────────────────────────
  Widget _buildInfoBlock() {
    final name = item.name.trim().isEmpty ? AppStrings.unknown.tr : item.name;
    final rating = item.rating > 0 ? item.rating.toStringAsFixed(1) : '';
    final labType = _labType;
    final distance = _distance;
    final address = _location.trim() == 'N/A' ? '' : _location.trim();
    final showMeta = rating.isNotEmpty || labType.isNotEmpty;
    final showLocation = distance.isNotEmpty || address.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          name,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w800,
          color: AppColors.black22,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showMeta) ...[
          SizedBox(height: SizeConfig.size4),
          _buildMetaRow(rating, labType),
        ],
        if (showLocation) ...[
          SizedBox(height: SizeConfig.size4),
          _buildLocationRow(distance, address),
        ],
      ],
    );
  }

  /// ★ 4.8 | Pathology Lab. The separator only appears when both halves are
  /// present, so an unrated lab still renders a clean type line.
  Widget _buildMetaRow(String rating, String labType) {
    return Row(
      children: [
        if (rating.isNotEmpty) ...[
          LocalAssets(
            imagePath: AppIconAssets.fill_star,
            width: SizeConfig.size12,
            height: SizeConfig.size12,
            imgColor: AppColors.yellow,
          ),
          SizedBox(width: SizeConfig.size3),
          CustomText(
            rating,
            fontSize: SizeConfig.extraSmall8,
            fontWeight: FontWeight.w500,
            color: AppColors.grey7E,
          ),
        ],
        if (labType.isNotEmpty)
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  if (rating.isNotEmpty)
                    TextSpan(
                      text: '  |  ',
                      style: TextStyle(
                        color: AppColors.grey7E,
                        fontSize: SizeConfig.extraSmall,
                      ),
                    ),
                  TextSpan(
                    text: labType,
                    style: TextStyle(
                      color: AppColors.grey7E,
                      fontSize: SizeConfig.extraSmall8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// pin + distance (primary) | address (secondary).
  Widget _buildLocationRow(String distanceText, String address) {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.location_outline,
          imgColor: AppColors.primaryColor,
          height: SizeConfig.size10,
          width: SizeConfig.size10,
        ),
        SizedBox(width: SizeConfig.size4),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (distanceText.isNotEmpty)
                  TextSpan(
                    text: distanceText,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.extraSmall8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (distanceText.isNotEmpty && address.isNotEmpty)
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall8,
                    ),
                  ),
                if (address.isNotEmpty)
                  TextSpan(
                    text: address,
                    style: TextStyle(
                      color: AppColors.grey7E,
                      fontSize: SizeConfig.extraSmall8,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── FOOTER (tests / facilities) ──────────────────────────────────
  /// The hospital tile's Departments / Facilities slot, with Tests standing in
  /// for Departments. Each row collapses when its count is zero so a sparse
  /// lab doesn't leave an empty pill behind.
  Widget _buildTestsFacilities() {
    final showTests = _testCount > 0;
    final showFacilities = _facilityCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTests)
          _footerRow(AppIconAssets.laboratoryIcon, _testCount,
              AppStrings.labTestsLabel.tr),
        if (showTests && showFacilities) SizedBox(height: SizeConfig.size6),
        if (showFacilities)
          _footerRow('assets/svg/hands_brain.svg', _facilityCount,
              AppStrings.labFacilitiesLabel.tr),
      ],
    );
  }

  /// Light grey pill, dark icon + count in bold with a bullet before the
  /// label — identical to the hospital tile's footer row.
  Widget _footerRow(String icon, int count, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF6F7F9),
        borderRadius: BorderRadius.circular(SizeConfig.size10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: icon,
            height: SizeConfig.size16,
            width: SizeConfig.size16,
            imgColor: AppColors.black22,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: SizeConfig.small,
                  color: AppColors.black22,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: '$count'),
                  const TextSpan(text: '  •  '),
                  TextSpan(text: label),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder tile. Wrapped by a single [buildLoadingShimmer] at the list
/// level so every tile shares one animation controller.
class _LabCardSkeletonBody extends StatelessWidget {
  const _LabCardSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: shimmerContainer(width: double.infinity, radius: 0),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerContainer(height: 12, width: double.infinity),
                SizedBox(height: SizeConfig.size4),
                shimmerContainer(height: 10, width: 120),
                SizedBox(height: SizeConfig.size4),
                shimmerContainer(height: 10, width: double.infinity),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerContainer(height: 30, width: double.infinity, radius: 10),
                SizedBox(height: SizeConfig.size6),
                shimmerContainer(height: 30, width: double.infinity, radius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
