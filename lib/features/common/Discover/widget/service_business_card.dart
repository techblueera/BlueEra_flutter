import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/common/Discover/controller/other_service_business_search_controller.dart';
import 'package:BlueEra/features/common/Discover/model/other_service_business_search_res_model.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card surface for the service tile. Matches the two-up school listing
/// (`AllEducationServiceScreen.selfProfessionCard`) — plain white with a
/// hairline border so cover imagery reads cleanly when two tiles sit
/// side by side.
const Color _kCardBorder = Color(0xFFE9EBF0);
const Color _kCardDivider = Color(0xFFEDEFF3);

/// Service-style business card used by the "Services Near Me" and
/// Automotive Other Services directories. Bound to
/// [OtherServiceBusinessItem] returned by
/// `other-service/business-profile/search`. Compact 2-up tile: hero
/// (category label overlay + share/rate stack + Open pill) → business
/// name → ★ rating + sub-category → location row → hairline → Price
/// Range. Missing values collapse gracefully.
class ServiceBusinessCard extends StatelessWidget {
  final OtherServiceBusinessItem item;

  /// Card position in the list — retained for API compatibility with the
  /// existing callers; the tile itself is a flat white surface so no
  /// palette rotation is needed.
  final int index;

  /// Category-themed placeholder shown on the hero when the business has
  /// no cover / gallery / management image. Callers on category-specific
  /// screens (e.g. Automotive) pass a themed image so the card doesn't
  /// fall back to a bare grey box. `null` keeps the old grey-box behaviour.
  final String? fallbackHeroImageUrl;

  const ServiceBusinessCard({
    super.key,
    required this.item,
    required this.index,
    this.fallbackHeroImageUrl,
  });

  // ─── DERIVED VALUES ──────────────────────────────────────────────
  OtherBusinessProfile? get _profile => item.profile;

  String get _heroImage {
    final logoUrl = _profile?.logoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty) return logoUrl;
    final cover = _profile?.coverUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    final fromGallery = item.gallery
        .expand((g) => g.imageUrls)
        .firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
    if (fromGallery.isNotEmpty) return fromGallery;
    final fromManagement = item.management
        .map((m) => m.imageUrl ?? '')
        .firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
    if (fromManagement.isNotEmpty) return fromManagement;
    return fallbackHeroImageUrl?.trim() ?? '';
  }

  String get _ratingText {
    final r = _profile?.rating ?? 0;
    return r > 0 ? r.toStringAsFixed(1) : '';
  }

  /// Sub-category shown next to the rating — falls back to the top-level
  /// category so the slot still carries a meaningful label when the
  /// listing hasn't set a sub-category yet.
  String get _subCategoryText {
    final sub = _profile?.subCategoryDetailsName?.trim() ?? '';
    if (sub.isNotEmpty) return sub;
    return _profile?.categoryDetailsName?.trim() ?? '';
  }

  /// Category label rendered as an overlay at the top-left of the hero.
  String get _categoryLabel => _profile?.categoryDetailsName?.trim() ?? '';

  bool get _isOpenToday {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    return today != null && today.hasHours;
  }

  /// "₹1,499-2,000" / "₹1,499+" / "Up to ₹2,000" / "" (empty when nothing set).
  String get _priceRangeText {
    final pr = item.priceRange;
    if (pr == null || !pr.hasAnyValue) return '';
    final min = pr.min;
    final max = pr.max;
    if (min != null && max != null) return '₹${_fmt(min)} - ${_fmt(max)}';
    if (min != null) return '₹${_fmt(min)}+';
    if (max != null) return 'Up to ₹${_fmt(max)}';
    return '';
  }

  String get _displayName {
    final b = _profile?.businessName?.trim() ?? '';
    if (b.isNotEmpty) return b;
    return _profile?.profileName?.trim() ?? '';
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
            if (_priceRangeText.isNotEmpty) ...[
              Container(height: 1, color: _kCardDivider),
              Padding(
                padding: EdgeInsets.all(SizeConfig.size10),
                child: _buildPriceRow(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  /// Uses an [AspectRatio] so the cover scales with tile width across
  /// phone (2-col) and tablet (3/4-col) breakpoints — same pattern as
  /// the school tile's `_buildCoverSection`.
  Widget _buildCoverSection() {
    final heroImage = _heroImage;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            heroImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: heroImage,
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
            // Top gradient wash so the white category label stays legible
            // over busy cover imagery.
            Positioned(
              top: SizeConfig.size6,
              right: SizeConfig.size6,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _shareBusiness,
                    child: _circleIcon(AppIconAssets.share_bold),
                  ),
                  SizedBox(height: SizeConfig.size6),
                  GestureDetector(
                    onTap: _onRateTap,
                    child: _circleIcon(AppIconAssets.star_rounded),
                  ),
                ],
              ),
            ),
            if (_isOpenToday)
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
                      CustomText(
                        'Open',
                        fontSize: SizeConfig.extraSmall,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenShade,
                        maxLines: 1,
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
    final name = _displayName;
    final rating = _ratingText;
    final subCategory = _subCategoryText;
    final loc = _profile?.businessLocation;
    final hasCoords = loc?.isValid ?? false;
    final km = hasCoords ? calculateDistance(loc!.lat!, loc.lng!) : null;
    final distance = _formatDistance(km);
    final address = _resolveAddress();
    final showLocation = distance.isNotEmpty || address.isNotEmpty;
    final showMeta = rating.isNotEmpty || subCategory.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasCoords ? () => _showMapBottomSheet(Get.context!) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (name.isNotEmpty)
            CustomText(
              name,
              fontSize: SizeConfig.medium,
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
      ),
    );
  }

  String _formatDistance(double? km) {
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m away';
    if (km < 10) return '${km.toStringAsFixed(1)}km away';
    return '${km.toStringAsFixed(0)}km away';
  }

  /// ★ 4.8 | HR & Placement Agency — sub-category sits inline with the
  /// rating per the design (img.png). Both halves ellipsize together so
  /// a long sub-category still leaves the rating visible.
  Widget _buildMetaRow(String rating, String subCategory) {
    final separator = TextSpan(
      text: '  |  ',
      style: TextStyle(
        color: AppColors.greyE5,
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
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
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
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.extraSmall,
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

  /// Inline distance + " | " + address, styled the same as the school
  /// tile's location row so both discover directories share the pin +
  /// primary-coloured distance + secondary-coloured address treatment.
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

  /// Footer line below the hairline — label above value, keeps the same
  /// visual weight as the school tile's students row so both cards feel
  /// like siblings.
  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Price Range',
                fontSize: SizeConfig.extraSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.grey7E,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                _priceRangeText,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _resolveAddress() {
    return _profile?.location?.address?.trim() ?? '';
  }

  void _showMapBottomSheet(BuildContext context) {
    final loc = _profile?.businessLocation;
    if (loc == null || !loc.isValid) return;
    RouteMapBottomSheet.show(
      context: context,
      destinationName: _profile?.businessName ?? '',
      destinationAddress: _resolveAddress(),
      destinationLat: loc.lat!,
      destinationLng: loc.lng!,
      livePhotos: const <String>[],
      visitCallback: _openStore,
    );
  }

  /// Routed through [openVisitProfile] so the type→screen mapping stays in one
  /// place. The service detail screen hydrates from the owner id alone.
  void _openStore() {
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: BusinessType.Service.name,
      businessId: _profile?.id,
      userId: _profile?.userId,
    );
  }

  Future<void> _onRateTap() async {
    // Uses `businessId` (be_user_service `businesses._id`) — the id the
    // ratings endpoint keys off, not the search-doc `_id` on `id`.
    final businessId = (_profile?.businessId ?? '').trim();
    if (businessId.isEmpty) return;
    final ctx = Get.context;
    if (ctx == null) return;
    final submitted = await showDialog<bool>(
      context: ctx,
      builder: (_) => RatingFeedbackDialog(
        businessId: businessId,
        reviewFor: AppConstants.business,
      ),
    );
    if (submitted == true) {
      // Refetch the list so the card's `_profile.rating` reflects the
      // new server-side average. Both callers (services-near-me and
      // automotive) share this controller and keep the last category
      // on `selectedCategory`.
      final listCtrl = Get.find<OtherServiceBusinessSearchController>();
      listCtrl.fetchInitial(listCtrl.selectedCategory.value);
    }
  }

  Future<void> _shareBusiness() async {
    final shareLink = serviceDeepLinkBusiness(
      id: _profile?.userId,
    );

    await ShareService.instance.openShareSheet(
      text:
          "Check out ${_profile?.businessName ?? 'this profile'} on BlueEra:\n$shareLink",
      subject: _profile?.businessName,
    );
  }
}
