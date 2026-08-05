import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/model/other_service_business_search_res_model.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../business/widgets/rating_widget.dart';
import '../controller/other_service_business_search_controller.dart';

/// Tinted surface set for a service card. Mirrors the palette rotation used
/// by [SelfProfessionDiscoverScreenV2] so both discover directories share the
/// same visual family — the whole card body picks up the tint (lighter wash)
/// while the inner "Expertise" tile uses the fuller hue.
class _CardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerLine;
  final Color bodyDashedDivider;

  const _CardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerLine,
    required this.bodyDashedDivider,
  });
}

/// Two-palette rotation — cards alternate as the user scrolls. The `tileBg`
/// values are the hexes the design spec supplies (`#DBFAFD`, `#F7E6FF`);
/// `cardBg` is the ~50%-to-white washout of the same hue so the outer surface
/// is visibly the "lighter version" of the inner Expertise tile.
/// `bodyDashedDivider` is the hue used for the dashed rule between the header
/// block and the Expertise tile — a different shade per palette so the divider
/// visibly belongs to its card (`#BBE3E8` for the teal card, `#E3D4E9` for
/// the lavender card).
const List<_CardPalette> _cardPalettes = <_CardPalette>[
  _CardPalette(
    cardBg: Color(0xFFEDFCFE),
    cardBorder: Color(0xFFCFEEF2),
    tileBg: Color(0xFFDBFAFD),
    tileBorder: Color(0xFFBFE9EE),
    dividerLine: Color(0xFFBFE9EE),
    bodyDashedDivider: Color(0xFFBBE3E8),
  ),
  _CardPalette(
    cardBg: Color(0xFFFBF2FF),
    cardBorder: Color(0xFFEDD3F7),
    tileBg: Color(0xFFF7E6FF),
    tileBorder: Color(0xFFE5C6F5),
    dividerLine: Color(0xFFE5C6F5),
    bodyDashedDivider: Color(0xFFE3D4E9),
  ),
];

/// Service-style business card used by the "Services Near Me" screen.
///
/// Bound to [OtherServiceBusinessItem] returned by
/// `other-service/business-profile/search`. Visual structure mirrors the
/// electrician spec-card (see `SelfProfessionDiscoverScreenV2._buildSpecCard`)
/// so both directories feel uniform: hero (share / rate stack) → body row
/// (avatar, name, ★ rating, Open pill) → "Expertise" tile with a two-column
/// checklist derived from `services[].title` → Price Range + Book Now row.
/// Missing values collapse gracefully. Palette rotates on [index] so
/// alternating cards read as a set rather than a wall of identical tiles.
class ServiceBusinessCard extends StatelessWidget {
  final OtherServiceBusinessItem item;

  /// Card position in the list — drives the palette rotation.
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

  _CardPalette get _palette =>
      _cardPalettes[index.abs() % _cardPalettes.length];

  // ─── DERIVED VALUES ──────────────────────────────────────────────
  OtherBusinessProfile? get _profile => item.profile;

  String get _heroImage {
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

  String get _avatarUrl {
    final cover = _profile?.logoUrl?.trim() ?? '';
    if (cover.isNotEmpty) return cover;
    return item.management
        .map((m) => m.imageUrl ?? '')
        .firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
  }

  String get _ratingText {
    final r = _profile?.rating ?? 0;
    return r > 0 ? r.toStringAsFixed(1) : '';
  }

  /// Returns "Open | HH:MM - HH:MM" for today if open, else "Closed".
  ({String label, bool isOpen}) get _todayStatus {
    final today = item.timings?.forWeekday(DateTime.now().weekday);
    if (today != null && today.hasHours) {
      return (
        label: 'Open | ${today.openTime} - ${today.closeTime}',
        isOpen: true
      );
    }
    return (label: 'Closed', isOpen: false);
  }

  /// "₹1,499-2,000" / "₹1,499+" / "Up to ₹2,000" / "" (empty when nothing set).
  String get _priceRangeText {
    final pr = item.priceRange;
    if (pr == null || !pr.hasAnyValue) return '';
    final min = pr.min;
    final max = pr.max;
    if (min != null && max != null) return '₹${_fmt(min)}-${_fmt(max)}';
    if (min != null) return '₹${_fmt(min)}+';
    if (max != null) return 'Up to ₹${_fmt(max)}';
    return '';
  }

  String get _displayName {
    final b = _profile?.businessName?.trim() ?? '';
    if (b.isNotEmpty) return b;
    return _profile?.profileName?.trim() ?? '';
  }

  List<String> get _serviceTitles => item.services
      .where((s) => s.isDeleted != true)
      .map((s) => s.title?.trim() ?? '')
      .where((t) => t.isNotEmpty)
      .toList();

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
    final palette = _palette;
    return InkWell(
      onTap: _openStore,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  // ─── HERO ─────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    final heroImage = _heroImage;

    return SizedBox(
      height: 175,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: heroImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFEDEFF4)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFEDEFF4),
                      child: const Icon(Icons.image_outlined,
                          size: 40, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: const Color(0xFFEDEFF4),
                    child: const Icon(Icons.image_outlined,
                        size: 40, color: Colors.grey),
                  ),
          ),

          // ── Action icons (top-right) ──
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _circleIconBtn(AppIconAssets.share_bold, onTap: _shareBusiness),
                SizedBox(height: SizeConfig.size8),
                _circleIconBtn(AppIconAssets.star_rounded, onTap: _onRateTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(String icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size8),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
            height: SizeConfig.size14,
            width: SizeConfig.size14,
          ),
        ),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────────────
  Widget _buildBody() {
    final titles = _serviceTitles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size14, SizeConfig.size12, SizeConfig.size14, 0),
          child: _buildHeaderRow(),
        ),
        if (titles.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size12),
          _DashedDivider(color: _palette.bodyDashedDivider),
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size14, 0, SizeConfig.size14, 0),
            child: _buildExpertiseBox(titles),
          ),
        ],
        SizedBox(height: SizeConfig.size14),
        Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size14, 0, SizeConfig.size14, SizeConfig.size10),
          child: _buildFooterRow(),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    final status = _todayStatus;
    final rating = _ratingText;
    final name = _displayName;
    final loc = _profile?.businessLocation;
    final hasCoords = loc?.isValid ?? false;
    final km = hasCoords ? calculateDistance(loc!.lat!, loc.lng!) : null;
    final distanceText = km != null ? '${km.toStringAsFixed(0)}KM Away' : '';
    final address = _resolveAddress();
    final showLocationRow = distanceText.isNotEmpty || address.isNotEmpty;

    return GestureDetector(
      onTap: hasCoords ? () => _showMapBottomSheet(Get.context!) : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar tap opens this listing's [OthersServiceDetailScreen]
          // (same target as "Book Now"). `HitTestBehavior.opaque` stops
          // the tap from falling through to the outer map-sheet gesture.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStore,
            // Figma spec: 50×50 avatar (matches _schoolLogo in
            // all_education_service_screen.dart). White border removed
            // because `CachedAvatarWidget` draws a 1.5px inset border
            // per side and clips the inner image to `borderRadius-1`,
            // which was shrinking the visible content to ~47×47.
            child: CachedAvatarWidget(
              imageUrl: _avatarUrl,
              size: 50,
              borderRadius: 25,
              showProfileOnFullScreen: false,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name.isNotEmpty)
                  CustomText(
                    name,
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black22,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (rating.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0xffDDE2EE)),
                        ),
                        child: Row(
                          children: [
                            LocalAssets(
                              imagePath: AppIconAssets.fill_star,
                              width: SizeConfig.size10,
                              height: SizeConfig.size10,
                              imgColor: AppColors.yellow,
                            ),
                            SizedBox(width: SizeConfig.size3),
                            CustomText(
                              rating,
                              fontSize: SizeConfig.size10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Flexible(child: _buildOpenPill(status)),
                  ],
                ),
                if (showLocationRow) ...[
                  SizedBox(height: SizeConfig.size6),
                  _buildLocationRow(distanceText, address),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Inline distance + " | " + address, styled the same as the pre-redesign
  /// header (pin + primary-coloured distance + secondary-coloured address).
  /// The whole header row already dispatches the map bottom-sheet on tap,
  /// so this widget stays a passive display.
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
                      fontSize: SizeConfig.size8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (distanceText.isNotEmpty && address.isNotEmpty)
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.size8,
                    ),
                  ),
                if (address.isNotEmpty)
                  TextSpan(
                    text: address,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.size8,
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

  Widget _buildOpenPill(({String label, bool isOpen}) status) {
    final fg = status.isOpen ? AppColors.green00 : AppColors.grey83;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffDDE2EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.clock_new,
            imgColor: fg,
            height: 10,
            width: 10,
          ),
          SizedBox(width: SizeConfig.size5),
          Flexible(
            child: CustomText(
              status.label,
              fontSize: SizeConfig.size10,
              fontWeight: FontWeight.w500,
              color: fg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EXPERTISE BOX ─────────────────────────────────────────────
  /// "Expertise" checklist — mirrors the electrician spec card. Titles
  /// come from `services[].title`; when there are more than 6 we render
  /// the first 5 and place "+N more services" in the 6th cell so the
  /// grid stays neatly aligned. Fill / border / divider hues come from
  /// the card's palette so the tile visibly belongs to its parent card.
  Widget _buildExpertiseBox(List<String> titles) {
    const int maxVisible = 6;
    final showMore = titles.length > maxVisible;
    final visible = showMore
        ? titles.sublist(0, maxVisible - 1)
        : titles.sublist(0, titles.length);
    final extra = showMore ? titles.length - visible.length : 0;
    final palette = _palette;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: palette.tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Expertise',
            fontSize: SizeConfig.size13,
            fontWeight: FontWeight.w700,
            color: AppColors.black22,
          ),
          SizedBox(height: SizeConfig.size8),
          _DashedDivider(color: _palette.bodyDashedDivider),
          SizedBox(height: SizeConfig.size10),
          _servicesGrid(visible, extra),
        ],
      ),
    );
  }

  Widget _servicesGrid(List<String> items, int extra) {
    final cells = <Widget>[
      ...items.map(_serviceCheckItem),
      if (extra > 0) _moreServicesLink(extra),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cells[i]),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child:
                i + 1 < cells.length ? cells[i + 1] : const SizedBox.shrink(),
          ),
        ],
      ));
      if (i + 2 < cells.length) rows.add(SizedBox(height: SizeConfig.size8));
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
        LocalAssets(
          imagePath: AppIconAssets.expertiesIcon,
          height: SizeConfig.size15,
          width: SizeConfig.size15,
        ),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            text,
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _moreServicesLink(int extra) {
    return InkWell(
      onTap: _openStore,
      child: CustomText(
        '+$extra more services',
        fontSize: SizeConfig.size12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE53935),
      ),
    );
  }

  String _resolveAddress() {
    final locationAddress = _profile?.location?.address?.trim() ?? '';
    if (locationAddress.isNotEmpty) return locationAddress;
    return '';
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

  // ─── FOOTER ROW (inline; shares the card's tinted background) ────
  Widget _buildFooterRow() {
    final priceText = _priceRangeText;
    return Row(
      children: [
        if (priceText.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Price Range',
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey7E,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  priceText,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          )
        else
          const Spacer(),
        _BookNowBtn(onTap: _openStore),
      ],
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

/// Full-width dashed horizontal rule. Used inside the card body to separate
/// the header block from the "Expertise" tile — a hairline felt too heavy
/// against the tinted card background.
class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashWidth = 4;
  static const double _dashSpace = 4;
  static const double _thickness = 1;

  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final endX = (x + _dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += _dashWidth + _dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

class _BookNowBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BookNowBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        // height: 44,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20, vertical: SizeConfig.size10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              "Inquiry Now",
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            SizedBox(width: SizeConfig.size8),
            Icon(Icons.arrow_forward_rounded,
                size: SizeConfig.size16, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
