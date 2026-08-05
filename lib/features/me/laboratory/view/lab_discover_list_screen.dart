import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_detail_screen.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tinted surface set for a lab card. Mirrors the palette used by the
/// hotel `PropertyCard` — the outer card is the lighter wash, the inner
/// "Available Tests" tile uses the fuller hue (#DBFAFD teal / #F7E6FF
/// lavender) so the whole card reads as one visual family.
class _CardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color bodyDashedDivider;

  const _CardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.bodyDashedDivider,
  });
}

const List<_CardPalette> _cardPalettes = <_CardPalette>[
  _CardPalette(
    cardBg: Color(0xFFEDFCFE),
    cardBorder: Color(0xFFCFEEF2),
    tileBg: Color(0xFFDBFAFD),
    tileBorder: Color(0xFFBFE9EE),
    bodyDashedDivider: Color(0xFFBBE3E8),
  ),
  _CardPalette(
    cardBg: Color(0xFFFBF2FF),
    cardBorder: Color(0xFFEDD3F7),
    tileBg: Color(0xFFF7E6FF),
    tileBorder: Color(0xFFE5C6F5),
    bodyDashedDivider: Color(0xFFE3D4E9),
  ),
];

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
                index: index,
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

  /// Card position in the list — drives the palette rotation so alternating
  /// cards read as a set rather than a wall of identical tiles.
  final int index;
  final VoidCallback onTap;
  final VoidCallback onInquiry;

  const _LabDiscoverCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onInquiry,
  });

  _CardPalette get _palette =>
      _cardPalettes[index.abs() % _cardPalettes.length];

  // ── Data helpers ──────────────────────────────────────────────
  /// Cover banner: `coverPicture` (see `viewBusinessProfileModel.dart` —
  /// `coverimage` deserialises from `coverPicture`), falling back to the
  /// first live photo when the lab hasn't uploaded a cover yet.
  String get _cover {
    final cover = item.raw['coverPicture']?.toString() ?? '';
    if (cover.isNotEmpty) return cover;
    final photos = item.raw['live_photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first?.toString() ?? '';
      if (first.isNotEmpty) return first;
    }
    return '';
  }

  /// Profile picture / logo.
  String get _logo => item.logo.trim();

  /// Hero image: cover first, DP as the fallback so the hero never
  /// collapses to a bare icon when only the profile photo is available.
  String get _heroImage {
    final c = _cover;
    return c.isNotEmpty ? c : _logo;
  }

  /// Identity-row logo: DP first, cover as the fallback so the avatar
  /// stays populated when only the cover exists.
  String get _identityLogo {
    final l = _logo;
    return l.isNotEmpty ? l : _cover;
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
  /// pharmacies list already consumes — and returns '' when coordinates are
  /// missing or zeroed so the identity row hides the distance slice.
  String get _distance {
    final loc = item.raw['business_location'];
    if (loc is! Map) return '';
    final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (loc['lon'] as num?)?.toDouble() ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
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

  /// True only when the lab actually has tests to show — used by the card
  /// build to hide the whole "Available Tests" block (and its spacer) when
  /// there's nothing to render.
  bool get _hasTests => _testCategories.isNotEmpty || _availableTestCount > 0;

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
    final palette = _palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
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
            _hero(),
            _buildBody(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_CardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size14, SizeConfig.size12, SizeConfig.size14, 0),
          child: _identityRow(),
        ),
        if (_hasTests) ...[
          SizedBox(height: SizeConfig.size12),
          _DashedDivider(color: palette.bodyDashedDivider),
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size14, 0, SizeConfig.size14, 0),
            child: _availableTestsBlock(palette),
          ),
        ],
        SizedBox(height: SizeConfig.size14),
        Padding(
          padding: EdgeInsets.fromLTRB(SizeConfig.size14, 0, SizeConfig.size14, SizeConfig.size10),
          child: _footer(),
        ),
      ],
    );
  }

  // ── Hero image + share/rate buttons ──────────────────────────
  Widget _hero() {
    final hero = _heroImage;
    return SizedBox(
      height: 175,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          hero.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: hero,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.greyE5),
                  errorWidget: (_, __, ___) => _imageFallback(),
                )
              : _imageFallback(),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _circleIcon(AppIconAssets.share_bold, onTap: _share),
                SizedBox(height: SizeConfig.size8),
                _circleIcon(AppIconAssets.star_rounded, onTap: () {}),
              ],
            ),
          ),
        ],
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

  /// Bordered rating pill for the header row — matches the hotel /
  /// service-business cards. Caller gates on `item.rating > 0`.
  Widget _ratingPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffDDE2EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.fill_star,
            width: SizeConfig.size10,
            height: SizeConfig.size10,
            imgColor: AppColors.yellow,
          ),
          SizedBox(width: SizeConfig.size3),
          CustomText(
            item.rating.toStringAsFixed(1),
            fontSize: SizeConfig.size10,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(String icon, {required VoidCallback onTap}) {
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

  /// Header-row timing pill driven by the `timing` payload. When timing is
  /// unset, returns `null` so the caller hides the pill entirely (no
  /// "Timing not set" placeholder).
  /// - `today.isOpen == false` → "Closed today" (red chip)
  /// - `today.isOpen == true` → "Open · HH:MM - HH:MM" (green); prefixed
  ///   with "Open now" when `liveState.isLive` confirms the current clock
  ///   is inside today's window, otherwise "Open today".
  Widget? _timingPill() {
    final today = _todayTiming;
    if (today == null) return null;

    final bool isOpen = today['isOpen'] == true;
    final String open = today['shopOpenTime']?.toString() ?? '';
    final String close = today['shopCloseTime']?.toString() ?? '';

    if (!isOpen || (open.isEmpty && close.isEmpty)) {
      return _timingChip(
        label: 'Closed today',
        // background: const Color(0xffFFF2F2),
        // foreground: AppColors.red,
      );
    }

    final String range = (open.isNotEmpty && close.isNotEmpty)
        ? '$open - $close'
        : (open.isNotEmpty ? open : close);
    final String label =
        _isLiveNow ? 'Open now · $range' : 'Open today · $range';

    return _timingChip(
      label: label,
    );
  }

  Widget _timingChip({
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
      decoration: BoxDecoration(
        // color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFDDE2EE), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 10, color: AppColors.green00),
          SizedBox(width: SizeConfig.size3),
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.size10,
              fontWeight: FontWeight.w500,
              color: AppColors.green00,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header row: logo + name + [rating + timing] + location ───
  Widget _identityRow() {
    bool isMeaningful(String s) => s.isNotEmpty && s != 'N/A';
    final distance = _distance;
    final address = _location;
    final bool showDistance = isMeaningful(distance);
    final bool showAddress = isMeaningful(address);
    final bool hasLocation = showDistance || showAddress;
    final bool hasRating = item.rating > 0;
    final Widget? timing = _timingPill();
    final bool hasTiming = timing != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: 50,
            height: 50,
            child: _identityLogo.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _identityLogo,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                item.name.isNotEmpty ? item.name : AppStrings.unknown.tr,
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w800,
                color: AppColors.black22,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasRating || hasTiming) ...[
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (hasRating) ...[
                      _ratingPill(),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    if (hasTiming) Flexible(child: timing),
                  ],
                ),
              ],
              if (hasLocation) ...[
                SizedBox(height: SizeConfig.size6),
                Row(
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
                            if (showDistance)
                              TextSpan(
                                text: distance,
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: SizeConfig.size8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (showDistance && showAddress)
                              TextSpan(
                                text: '  |  ',
                                style: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.size8,
                                ),
                              ),
                            if (showAddress)
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

  // ── Available Tests block — original data layout, palette container ──
  /// Keeps the original icon-box + inline "Available Test · N · names,
  /// +M More" data layout untouched — only the container fill / border are
  /// swapped for the card's palette (`#DBFAFD` / `#F7E6FF`) so the tile
  /// visibly belongs to its parent card.
  Widget _availableTestsBlock(_CardPalette palette) {
    final categories = _testCategories;
    final count = _availableTestCount;
    const inlineLimit = 2;
    final inline = categories.take(inlineLimit).join(', ');
    final more = categories.length - inlineLimit;

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: palette.tileBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.tileBorder, width: 0.5),
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
                height: SizeConfig.size20,
                width: SizeConfig.size20),
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
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black22,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.grey7E,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '$count',
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black22,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size2),
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        inline.isNotEmpty ? inline : 'No tests listed yet',
                        fontSize: SizeConfig.size12,
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
                          fontSize: SizeConfig.size12,
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

  // ── Footer: Consultation & Test Cost + Inquiry Now (inline) ──
  /// Inherits the card's palette tint — no grey band. When `price` is
  /// empty the cost column collapses and a [Spacer] takes its place so
  /// the Inquiry button always sits at the trailing edge.
  Widget _footer() {
    final price = _priceRange;
    final hasPrice = price.isNotEmpty;
    return Row(
      children: [
        if (hasPrice)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Consultation & Test Cost',
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey7E,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  price,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        else
          const Spacer(),
        _InquiryNowBtn(onTap: onInquiry),
      ],
    );
  }
}

/// Full-width dashed horizontal rule between the header block and the
/// Available Tests tile — matches the hotel `PropertyCard` treatment.
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

class _InquiryNowBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _InquiryNowBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
              'Inquiry Now',
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
