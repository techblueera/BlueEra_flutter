import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card surface mirrors [ServiceBusinessCard] so hospital tiles read as
/// siblings of the Services-Near-Me directory when placed 2-up.
const Color _kCardBorder = Color(0xFFE9EBF0);
const Color _kCardDivider = Color(0xFFEDEFF3);

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
    // Paginate via scroll notifications so the outer NestedScrollView drives
    // scrolling as a single motion (see HealthCareListingScreen).
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
                        Expanded(child: _HospitalCardSkeletonBody()),
                        SizedBox(width: 10),
                        Expanded(child: _HospitalCardSkeletonBody()),
                      ],
                    ),
                  ),
                ),
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
                // Two content tiles per row; ad rows stay full-width so
                // NativeAdSlot renders unchanged.
                final grid = _pairForGrid(rows);
                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10,
                    vertical: SizeConfig.size8,
                  ),
                  itemCount:
                      grid.length + (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == grid.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _HospitalCardSkeletonBody()),
                              SizedBox(width: 10),
                              Expanded(child: _HospitalCardSkeletonBody()),
                            ],
                          ),
                        ),
                      );
                    }
                    final lr = grid[index];
                    if (lr.isAd) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NativeAdSlot(
                          adOrdinal: lr.adOrdinal!,
                          keyPrefix: 'hospital_native_ad',
                        ),
                      );
                    }
                    final left = controller.profiles[lr.leftIndex!];
                    final right = lr.rightIndex != null
                        ? controller.profiles[lr.rightIndex!]
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      // IntrinsicHeight so mismatched name/address lengths
                      // don't leave one tile shorter than the other.
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _HospitalCard(
                                item: left,
                                serviceType: widget.serviceType,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: right != null
                                  ? _HospitalCard(
                                      item: right,
                                      serviceType: widget.serviceType,
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }

  List<_GridLayoutRow> _pairForGrid(List<NativeAdRow> rows) {
    final result = <_GridLayoutRow>[];
    var i = 0;
    while (i < rows.length) {
      final r = rows[i];
      if (r.isAd) {
        result.add(_GridLayoutRow.ad(r.adOrdinal));
        i++;
        continue;
      }
      if (i + 1 < rows.length && !rows[i + 1].isAd) {
        result
            .add(_GridLayoutRow.pair(r.contentIndex, rows[i + 1].contentIndex));
        i += 2;
      } else {
        result.add(_GridLayoutRow.pair(r.contentIndex, null));
        i++;
      }
    }
    return result;
  }
}

class _GridLayoutRow {
  final int? leftIndex;
  final int? rightIndex;
  final int? adOrdinal;
  final bool isAd;
  _GridLayoutRow.pair(this.leftIndex, this.rightIndex)
      : adOrdinal = null,
        isAd = false;
  _GridLayoutRow.ad(this.adOrdinal)
      : leftIndex = null,
        rightIndex = null,
        isAd = true;
}

/// Compact hospital tile. Palette, metrics and sub-widget shapes are aligned
/// with [ServiceBusinessCard] so both directories feel like siblings:
///   hero (AspectRatio 1.2 + share stack + Open pill) → name → ★ rating +
///   specialty → distance | address → hairline → departments / facilities.
class _HospitalCard extends StatelessWidget {
  final HospitalFullData item;
  final String serviceType;

  const _HospitalCard({required this.item, required this.serviceType});

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
    // those; fall back to the boolean flags on the full-details path.
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

  /// "x.xkm away" / "xxxm away" — empty when either endpoint is unknown so
  /// the location line collapses to just the address.
  String _distanceLabel() {
    final dLat = _destLat();
    final dLng = _destLng();
    if (dLat == 0.0 && dLng == 0.0) return '';
    final uLat = LocationService.lat;
    final uLng = LocationService.lng;
    if (uLat == 0.0 && uLng == 0.0) return '';
    final km = calculateDistanceKm(uLat, uLng, dLat, dLng);
    if (km.isNaN || km.isInfinite) return '';
    if (km < 1) return '${(km * 1000).round()}m away';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km away';
  }

  /// Routed through [openVisitProfile] so the type→screen mapping stays in
  /// one place. The fetched list item seeds the detail controller with a
  /// real record rather than an id-only stub.
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

  void _share() {
    final name = item.name ?? 'Hospital';
    final shareLink = hospitalDeepLink(hospitalId: item.userId);
    ShareService.instance.openShareSheet(
      text: 'Check out ${item.name} on BlueEra\n$shareLink',
      subject: name,
    );
  }

  /// Per-hospital sub-category from the listing payload
  /// (`sub_category_details.name`, mapped onto [HospitalFullData.subCategoryName]
  /// by the business/filter adapter). Falls back to a tab-derived default so
  /// a hospital without a sub-category still shows a meaningful label.
  String _specialtyLabel() {
    final sub = item.subCategoryName?.trim() ?? '';
    if (sub.isNotEmpty) return sub;
    switch (serviceType.toUpperCase()) {
      case 'HOSPITALS':
      case 'HOSPITAL':
      case 'HOSPITAL_SECTOR':
        return 'Multi Speciality Hospital';
      case 'WELLNESS':
        return 'Wellness Center';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openDetail,
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
                  bottom: SizeConfig.size4),
              child: _buildInfoBlock(),
            ),
            // Footer collapses when the hospital reports neither departments
            // nor facilities, so the card doesn't leave an empty pill row.
            // if (_hasFooter)
            Padding(
              padding: EdgeInsets.all(SizeConfig.size8),
              child: _buildDepartmentsFacilities(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  Widget _buildCoverSection() {
    final cover = _coverImage();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            (cover != null && cover.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    placeholder: (_, __) => Container(color: AppColors.greyE5),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.greyE5,
                      child: const Icon(Icons.image_outlined,
                          size: 32, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: AppColors.greyE5,
                    child: const Icon(Icons.image_outlined,
                        size: 32, color: Colors.grey),
                  ),
            Positioned(
              top: SizeConfig.size6,
              right: SizeConfig.size6,
              child: GestureDetector(
                onTap: _share,
                child: _circleIcon(AppIconAssets.share_bold),
              ),
            ),
            // Always-on per product spec (no hospital hours payload today).
            // Same shape/palette as [ServiceBusinessCard]'s Open pill.
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
            'Open Now',
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
    final name = _valueOr(item.name, fallback: "Unknown Hospital");
    // Hospital listing payload doesn't carry a rating yet
    // (see rating-ui-integration.md §1). Slot stays wired for when it does.
    const rating = '';
    final subCategory = _specialtyLabel();
    final distance = _distanceLabel();
    final address =
        _isEmpty(item.location?.name) ? '' : item.location!.name!.trim();
    final showLocation = distance.isNotEmpty || address.isNotEmpty;
    final showMeta = rating.isNotEmpty || subCategory.isNotEmpty;

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
          _buildMetaRow(rating, subCategory),
        ],
        if (showLocation) ...[
          SizedBox(height: SizeConfig.size4),
          _buildLocationRow(distance, address),
        ],
      ],
    );
  }

  /// ★ 4.8 | Multi Speciality Hospital — mirrors
  /// [ServiceBusinessCard._buildMetaRow]. Rating half is empty today so the
  /// specialty renders on its own; the separator only appears when both
  /// halves are present.
  Widget _buildMetaRow(String rating, String subCategory) {
    final separator = TextSpan(
      text: '  |  ',
      style: TextStyle(
        color: AppColors.grey7E,
        fontSize: SizeConfig.extraSmall,
      ),
    );

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
        if (subCategory.isNotEmpty)
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  if (rating.isNotEmpty) separator,
                  TextSpan(
                    text: subCategory,
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

  /// pin + distance (primary) | address (secondary). Same treatment as
  /// [ServiceBusinessCard._buildLocationRow] so both directories share the
  /// same location line style.
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

  // ─── FOOTER (departments / facilities) ────────────────────────────
  int get _deptCount => item.departmentCount ?? _departmentNames().length;
  int get _facilityCount => item.facilityCount ?? _buildFacilities().length;
  bool get _hasFooter => _deptCount > 0 || _facilityCount > 0;

  /// Sits below a hairline in the same footer slot [ServiceBusinessCard]
  /// uses for its Price Range block, styled at the same weight so the two
  /// cards share visual rhythm when placed side by side.
  Widget _buildDepartmentsFacilities() {
    final showDept = _deptCount > 0;
    final showFacilities = _facilityCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDept)
          _footerRow('assets/svg/department.svg', _deptCount, 'Departments'),
        if (showDept && showFacilities) SizedBox(height: SizeConfig.size6),
        if (showFacilities)
          _footerRow(
              'assets/svg/hands_brain.svg', _facilityCount, 'Facilities'),
      ],
    );
  }

  /// Pill styled to match `img_1.png`: light grey background, dark icon +
  /// count in bold with a bullet separator before the label.
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

/// Placeholder tile. Wrap the list-level widget in a single
/// [buildLoadingShimmer] so all tiles share one animation controller —
/// per-tile shimmers saturate Android's BLASTBufferQueue on mid-range devices.
class _HospitalCardSkeletonBody extends StatelessWidget {
  const _HospitalCardSkeletonBody();

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
          Container(height: 1, color: _kCardDivider),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmerContainer(height: 10, width: 100),
                SizedBox(height: SizeConfig.size6),
                shimmerContainer(height: 10, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
