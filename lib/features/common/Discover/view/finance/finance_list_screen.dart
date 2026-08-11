import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/finance_search_res_model.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Card surface for the finance tile — matches the two-up school listing
/// (`AllEducationServiceScreen.selfProfessionCard`) and the service tile
/// (`ServiceBusinessCard`). Plain white with a hairline border so cover
/// imagery reads cleanly when two tiles sit side by side.
const Color _kCardBorder = Color(0xFFE9EBF0);
const Color _kCardDivider = Color(0xFFEDEFF3);

class FinanceListScreen extends StatefulWidget {
  final String categorySlugId;

  const FinanceListScreen({super.key, required this.categorySlugId});

  @override
  State<FinanceListScreen> createState() => _FinanceListScreenState();
}

class _FinanceListScreenState extends State<FinanceListScreen> {
  late final FinanceDiscoverController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => FinanceDiscoverController());
    controller.fetchInitial(widget.categorySlugId);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;
    if (metrics.pixels >= metrics.maxScrollExtent - 200) {
      controller.fetchMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.profiles.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor));
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
            "No services found",
            fontSize: SizeConfig.medium,
            color: AppColors.grey9B,
          ),
        );
      }
      // 2-column masonry so tiles of different heights pack tightly.
      // Native ads still render full-width between chunks via
      // [buildNativeAdGridSlivers] — same pattern as the school listing.
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          await controller.fetchInitial(widget.categorySlugId);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size6)),
              ...buildNativeAdGridSlivers(
                itemCount: controller.profiles.length,
                keyPrefix: 'finance_native_ad',
                adPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                gridSliverBuilder: (start, end) => SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size12,
                    vertical: SizeConfig.size6,
                  ),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: SizeConfig.size10,
                    crossAxisSpacing: SizeConfig.size10,
                    childCount: end - start,
                    itemBuilder: (context, i) => _FinanceCard(
                      item: controller.profiles[start + i],
                      index: start + i,
                    ),
                  ),
                ),
              ),
              if (controller.isLoadingMore.value)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size12)),
            ],
          ),
        ),
      );
    });
  }
}

/// Compact 2-up finance tile: hero (share icon + Open pill) → business
/// name → ★ rating + RBI Registered → location row → hairline → Min
/// Balance + Savings P.A. footer. Missing values collapse gracefully.
class _FinanceCard extends StatelessWidget {
  final FinanceBusinessItem item;

  /// Card position — kept for API compatibility with the previous
  /// palette-driven implementation, unused now that the tile is a flat
  /// white surface.
  final int index;

  const _FinanceCard({required this.item, required this.index});

  // ─── DERIVED VALUES ──────────────────────────────────────────────
  String get _heroImage {
    final logoUrl = item.logoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty) return logoUrl;
    final cover = item.coverUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    if (item.gallery != null) {
      for (final g in item.gallery!) {
        final urls = g.imageUrls;
        if (urls == null) continue;
        for (final u in urls) {
          if (u.trim().isNotEmpty) return u.trim();
        }
      }
    }
    return item.logoUrl?.trim() ?? '';
  }

  String get _displayName {
    final n = item.profileName?.trim() ?? '';
    return n.isNotEmpty ? n : 'Unknown';
  }

  String get _ratingText {
    final r = item.rating;
    return (r != null && r > 0) ? r.toStringAsFixed(1) : '';
  }

  bool get _hasRbiFlag => item.rbiRegistered == true;

  String get _distanceText {
    // Match the header (visit_business_common_header.dart:297): show
    // `X.X km away` when we have coords, empty otherwise. Coords come
    // from the GeoJSON `[lng, lat]` array on the finance model.
    final coords = item.contactUs?.firstOrNull?.branch?.location?.coordinates ??
        item.location?.coordinates;
    if (coords == null || coords.length < 2) return '';
    final lng = coords[0];
    final lat = coords[1];
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m away';
    if (km < 10) return '${km.toStringAsFixed(1)}km away';
    return '${km.toStringAsFixed(0)}km away';
  }

  String get _addressText {
    final candidates = <String?>[
      item.location?.address,
      item.location?.name,
    ];
    for (final c in candidates) {
      final t = c?.trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  /// Today's "Open | HH:MM - HH:MM" label with fallback to the legacy
  /// `businessHours` block. Returns null when the source only produces
  /// "Open | N/A" — the hero pill collapses in that case.
  String? get _openLabel {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    if (today != null && today.hasHours) {
      return 'Open | ${today.openTime} - ${today.closeTime}';
    }
    final bh = item.businessHours;
    if (bh?.hasHours == true) {
      return 'Open | ${bh!.openTime} - ${bh.closeTime}';
    }
    return null;
  }

  /// "₹500" style thousands separator for the min-balance cell.
  String? get _minBalanceText {
    final mb = item.financeDetails?.minBalance;
    if (mb == null || mb <= 0) return null;
    return '₹${_fmt(mb)}';
  }

  /// "3.0%" for the savings-rate cell — one decimal keeps the visual
  /// weight of the two footer values matched.
  String? get _savingsRateText {
    final s = item.financeDetails?.savingRatePA;
    if (s == null || s <= 0) return null;
    return '${s.toStringAsFixed(1)}%';
  }

  String _fmt(num n) {
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && (fromEnd - 1) % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final showFooter = _minBalanceText != null || _savingsRateText != null;

    return InkWell(
      onTap: _openStore,
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
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size10,
                SizeConfig.size10,
                SizeConfig.size10,
                SizeConfig.size10,
              ),
              child: _buildInfoBlock(),
            ),
            if (showFooter) ...[
              Container(height: 1, color: _kCardDivider),
              Padding(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: _buildFinanceRow(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  /// Hero uses an [AspectRatio] so the cover scales with tile width —
  /// same pattern as the school and service tiles.
  Widget _buildCoverSection() {
    final heroImage = _heroImage;
    final openLabel = _openLabel;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            heroImage.isNotEmpty
                ? GestureDetector(
                    onTap: () => Get.to(() => ImageViewScreen(
                          subTitle: item.type ?? 'Finance',
                          appBarTitle: AppStrings.imageViewer,
                          imageUrls: [heroImage],
                          initialIndex: 0,
                        )),
                    child: CachedNetworkImage(
                      imageUrl: heroImage,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      placeholder: (_, __) =>
                          Container(color: AppColors.greyE5),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.greyE5,
                        child: LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.liteWhite,
                    child: LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  ),
            Positioned(
              top: SizeConfig.size6,
              right: SizeConfig.size6,
              child: GestureDetector(
                onTap: _shareFinance,
                child: _circleIcon(AppIconAssets.share_bold),
              ),
            ),
            if (openLabel != null)
              Positioned(
                bottom: SizeConfig.size6,
                right: SizeConfig.size6,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size6,
                    vertical: SizeConfig.size3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF2FFF2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.greenShade, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time,
                          size: SizeConfig.size12, color: AppColors.greenShade),
                      SizedBox(width: SizeConfig.size3),
                      Flexible(
                        child: CustomText(
                          openLabel,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenShade,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  // ─── INFO BLOCK ──────────────────────────────────────────────────
  Widget _buildInfoBlock() {
    final rating = _ratingText;
    final distance = _distanceText;
    final address = _addressText;
    final showLocation = distance.isNotEmpty || address.isNotEmpty;
    final showMeta = rating.isNotEmpty || _hasRbiFlag;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          _displayName,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w800,
          color: AppColors.black22,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showMeta) ...[
          SizedBox(height: SizeConfig.size4),
          _buildMetaRow(rating),
        ],
        if (showLocation) ...[
          SizedBox(height: SizeConfig.size4),
          _buildLocationRow(distance, address),
        ],
      ],
    );
  }

  /// ★ 4.8  [verified] RBI Registered — RBI status is rendered in the
  /// brand green next to the rating per the design (img_1.png).
  Widget _buildMetaRow(String rating) {
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
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
          ),
          SizedBox(width: SizeConfig.size8),
        ],
        if (_hasRbiFlag)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: SizeConfig.size12,
                  color: AppColors.greenShade,
                ),
                SizedBox(width: SizeConfig.size3),
                Flexible(
                  child: CustomText(
                    'RBI Registered',
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenShade,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Inline pin + distance + " | " + address — matches the service /
  /// school tile so all discover directories share the same location
  /// styling.
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
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (distanceText.isNotEmpty && address.isNotEmpty)
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
                    ),
                  ),
                if (address.isNotEmpty)
                  TextSpan(
                    text: address,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
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

  /// Two-cell footer: Min Balance | Savings P.A. Cells collapse
  /// independently — a listing that only carries a savings rate will
  /// spread that cell across the row instead of leaving a blank column.
  Widget _buildFinanceRow() {
    final min = _minBalanceText;
    final savings = _savingsRateText;
    final cells = <Widget>[
      if (min != null) _statCell(label: 'Min Balance', value: min),
      if (savings != null) _statCell(label: 'Savings P.A.', value: savings),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          Expanded(child: cells[i]),
          if (i < cells.length - 1) SizedBox(width: SizeConfig.size8),
        ],
      ],
    );
  }

  Widget _statCell({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          fontWeight: FontWeight.w500,
          color: AppColors.grey7E,
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          value,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Routed through openVisitProfile so the type→screen mapping stays in
  /// one place. The lightweight list item goes with it and seeds
  /// `selectedDetail`, so the detail screen renders at once and upgrades
  /// itself to the full record.
  void _openStore() {
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: BusinessType.Finance.name,
      businessId: item.businessProfileId ?? item.id,
      userId: item.userId,
      financeData: item,
    );
  }

  Future<void> _shareFinance() async {
    final shareLink = financialDeepLink(
      businessId: item.userId,
    );

    await ShareService.instance.openShareSheet(
      text:
          "Check out ${item.profileName ?? 'this profile'} on BlueEra:\n$shareLink",
      subject: item.profileName,
    );
  }
}
