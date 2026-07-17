import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_category_selector_widget.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearestPharmaciesListScreen extends StatefulWidget {
  final String category;
  final String? subCategory;

  const NearestPharmaciesListScreen({
    super.key,
    required this.category,
    this.subCategory,
  });

  @override
  State<NearestPharmaciesListScreen> createState() => _NearestPharmaciesListScreenState();
}

class _NearestPharmaciesListScreenState extends State<NearestPharmaciesListScreen> {
  late final NearestPharmaciesController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => NearestPharmaciesController());
    // Cache-aware on entry: re-entering (or switching back to) the same
    // sub-category within the TTL serves the loaded list instead of re-hitting
    // the API. Pull-to-refresh below is the explicit force-fresh path — the
    // same split grocery's stores screen uses.
    controller.fetchNearestIfNeeded(
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
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.error.value.isNotEmpty && controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              controller.error.value,
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              "No pharmacies found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () =>
              controller.fetchNearest(category: widget.category, subCategory: widget.subCategory),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: SizeConfig.size12,
              left: SizeConfig.size12,
              right: SizeConfig.size12,
              // +70 clears the floating cart stacked over this list, so the
              // last card can still be scrolled clear of it (same allowance
              // the grocery store list makes).
              bottom: SizeConfig.paddingL + 70,
            ),
            itemCount: controller.pharmacies.length,
            // No separator — the card carries its own bottom margin, and `index`
            // drives the alternating teal/violet palette.
            itemBuilder: (context, index) => PharmacyStoreCard(
              item: controller.pharmacies[index],
              index: index,
            ),
          ),
        );
      }),
    );
  }

  // ignore: unused_element
}

/// Colour set for one [PharmacyStoreCard] — card fill, border, inner-tile
/// border, dotted divider, and the footer strip's wash.
class _PharmacyCardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerLine;

  const _PharmacyCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerLine,
  });
}

/// The grocery store card's two palettes, verbatim — cards alternate teal →
/// violet → teal by list position so a run reads as a rhythm rather than a wall
/// of one tint, exactly as on the grocery stores screen.
const _kPharmacyPalettes = <_PharmacyCardPalette>[
  _PharmacyCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    // CSS #13DBF414 (RGBA) → Flutter ARGB 0x1413DBF4 — translucent teal wash so
    // the inner tiles tint with the card's identity.
    tileBg: Color(0x1413DBF4),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _PharmacyCardPalette(
    cardBg: Color(0xFFFCF5FF),
    cardBorder: Color(0xFFECD3F6),
    tileBg: Color(0x14BE26FF),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

/// A pharmacy in the listing. Follows the visual language of the grocery store
/// card (logo + rating/sub-category badges, dotted divider, address tile beside
/// a hero photo, stat footer) but is its own widget bound to [PharmacyItem] —
/// the two feeds are different shapes and the two verticals are free to
/// diverge.
///
/// The stat/footer numbers come from keys `business/filter` does not send yet,
/// so they read 0 for now — see docs/backend/PHARMACY_CUSTOMER_FLOW_INTEGRATION.md.
class PharmacyStoreCard extends StatelessWidget {
  final PharmacyItem item;

  /// Position in the list — picks the palette, so cards alternate.
  final int index;

  const PharmacyStoreCard({
    super.key,
    required this.item,
    required this.index,
  });

  _PharmacyCardPalette get _palette =>
      _kPharmacyPalettes[index.abs() % _kPharmacyPalettes.length];

  List<String> get _livePhotos {
    final photos = item.raw['live_photos'];
    if (photos is! List) return const [];
    return photos
        .map((p) => p?.toString() ?? '')
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }

  String? get _subCategoryName {
    final sub = item.raw['sub_category_details'] ?? item.raw['sub_category_Of_Business'];
    return sub is Map ? sub['name']?.toString() : null;
  }

  /// Title for the photo viewer — "Pharmacy" from `category_details`.
  String get _categoryName {
    final category = item.raw['category_details'];
    final name = category is Map ? category['name']?.toString() : null;
    return (name == null || name.isEmpty) ? 'Pharmacy' : name;
  }

  int? _rawInt(String key) {
    final value = item.raw[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Rating printed verbatim, so drop a trailing `.0` on whole numbers.
  String get _ratingLabel =>
      item.rating % 1 == 0 ? '${item.rating.toInt()}' : '${item.rating}';

  void _openDetail() =>
      Get.to(() => MedicalPharmacyDetailScreen(businessId: item.id));

  @override
  Widget build(BuildContext context) {
    final livePhotos = _livePhotos;
    final heroImage = livePhotos.isNotEmpty ? livePhotos.first : item.logo;
    final extraPhotos = livePhotos.length > 1 ? livePhotos.length - 1 : 0;
    final palette = _palette;

    return InkWell(
      onTap: _openDetail,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: palette.cardBg,
          border: Border.all(color: palette.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  SizedBox(height: SizeConfig.size10),
                  _dottedLine(palette.dividerLine),
                  SizedBox(height: SizeConfig.size10),
                  _bodyRow(
                    context: context,
                    heroImage: heroImage,
                    livePhotos: livePhotos,
                    extraPhotos: extraPhotos,
                    palette: palette,
                  ),
                ],
              ),
            ),
            _footer(palette),
          ],
        ),
      ),
    );
  }

  // --- Logo + name + rating / sub-category badges ---
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedAvatarWidget(
          imageUrl: item.logo,
          size: SizeConfig.size50,
          borderColor: Colors.white,
          borderRadius: SizeConfig.size25,
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                item.name.isNotEmpty ? item.name : AppStrings.unknown.tr,
                fontSize: SizeConfig.large18,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w800,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size6),
              Row(
                children: [
                  _ratingBadge(_ratingLabel),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _categoryBadge(_subCategoryName ?? AppStrings.na),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Stat boxes + address tile on the left, hero photo on the right ---
  Widget _bodyRow({
    required BuildContext context,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
    required _PharmacyCardPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statBox(
                        icon: AppIconAssets.staggeredIcon,
                        count: _formatCount(_rawInt('total_category_count') ?? 0),
                        label: 'Category',
                        iconColor: const Color(0xFF9964F4),
                        borderColor: palette.tileBorder,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      _statBox(
                        icon: AppIconAssets.productCartIcon,
                        count: _formatCount(_rawInt('total_product_count') ?? 0),
                        label: 'Product',
                        iconColor: const Color(0xFF6179CD),
                        borderColor: palette.tileBorder,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Expanded(child: _addressCard(context, palette)),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              flex: 3,
              child: _heroImage(
                heroImage: heroImage,
                livePhotos: livePhotos,
                extraPhotos: extraPhotos,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Distance + address; opens the route sheet ---
  Widget _addressCard(BuildContext context, _PharmacyCardPalette palette) {
    final location = item.raw['business_location'];
    final lat = location is Map ? (location['lat'] as num?)?.toDouble() ?? 0.0 : 0.0;
    final lng = location is Map ? (location['lon'] as num?)?.toDouble() ?? 0.0 : 0.0;
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      lat,
      lng,
    );

    return GestureDetector(
      onTap: () => RouteMapBottomSheet.show(
        context: context,
        destinationName: item.name.isNotEmpty ? item.name : 'Pharmacy',
        destinationAddress: item.address,
        destinationLat: lat,
        destinationLng: lng,
        livePhotos: _livePhotos,
        visitCallback: _openDetail,
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: palette.tileBorder, width: 1),
          color: AppColors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _iconContainer(AppIconAssets.location_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    '${km.toStringAsFixed(2)} Km Away',
                    fontSize: 12.0,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    item.address.isNotEmpty ? item.address : AppStrings.na,
                    fontSize: 10.0,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconContainer(String iconPath) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2.0,
          ),
        ],
      ),
      child: LocalAssets(
        imagePath: iconPath,
        imgColor: AppColors.secondaryTextColor,
        height: 24,
        width: 20,
      ),
    );
  }

  Widget _statBox({
    required String icon,
    required String count,
    required String label,
    required Color iconColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: borderColor, width: 1),
          color: AppColors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: icon,
              imgColor: iconColor,
              height: 12,
              width: 12,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              count,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              label,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroImage({
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
  }) {
    final fullList = livePhotos.isNotEmpty
        ? livePhotos
        : (heroImage.isNotEmpty ? [heroImage] : <String>[]);

    return GestureDetector(
      onTap: fullList.isEmpty
          ? null
          : () => _showPhotoDialog(images: fullList, title: _categoryName),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroImage.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: heroImage,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  placeholder: (_, __) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                  errorWidget: (_, __, ___) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                )
              else
                LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
              if (extraPhotos > 0)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      '+$extraPhotos',
                      fontSize: SizeConfig.small,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Footer: views + orders strip ---
  Widget _footer(_PharmacyCardPalette palette) {
    final views = _rawInt('views') ?? 0;
    final viewLabel = views == 1 ? 'view' : 'views';
    final orders = _rawInt('chat_click_count') ?? 0;
    final orderLabel = orders == 1 ? 'order' : 'orders';
    final quirky = (item.raw['quirky_message']?.toString() ?? '').trim();

    return InkWell(
      onTap: _openDetail,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12.0),
        bottomRight: Radius.circular(12.0),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size10, horizontal: SizeConfig.size12),
        decoration: BoxDecoration(
          color: palette.tileBg,
          border: Border(
            top: BorderSide(color: palette.cardBorder, width: 1),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.eye_view,
              height: SizeConfig.size12,
              width: SizeConfig.size12,
              imgColor: AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size8),
            Flexible(
              child: RichText(
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: _formatCount(views),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' Total $viewLabel on this store, '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size4),
                        child: LocalAssets(
                          imagePath: AppIconAssets.cartIcon,
                          height: SizeConfig.size12,
                          width: SizeConfig.size12,
                          imgColor: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: _formatCount(orders),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' $orderLabel'),
                    if (quirky.isNotEmpty) TextSpan(text: ', $quirky'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingBadge(String rating) {
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
        border: Border.all(color: goldFg.withValues(alpha: 0.28), width: 1),
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

  Widget _categoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.greenCB.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.green2C.withValues(alpha: 0.25), width: 1),
      ),
      child: CustomText(
        text,
        fontSize: 11,
        color: AppColors.green2C,
        fontWeight: FontWeight.w700,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _dottedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        );
      },
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    return '$n';
  }

  void _showPhotoDialog({required List<String> images, required String title}) {
    final ctx = Get.context;
    if (ctx == null || images.isEmpty) return;
    showDialog<void>(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => _PharmacyPhotoDialog(images: images, title: title),
    );
  }
}

/// Fullscreen-ish photo viewer for a pharmacy's live photos — swipeable,
/// pinch/double-tap zoomable, with a counter and close button.
class _PharmacyPhotoDialog extends StatefulWidget {
  final List<String> images;
  final String title;

  const _PharmacyPhotoDialog({required this.images, required this.title});

  @override
  State<_PharmacyPhotoDialog> createState() => _PharmacyPhotoDialogState();
}

class _PharmacyPhotoDialogState extends State<_PharmacyPhotoDialog> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  widget.title,
                  fontSize: SizeConfig.medium,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CustomText(
                '${_index + 1} / ${widget.images.length}',
                fontSize: SizeConfig.small,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.images[i],
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PharmacyDetailsSheet extends StatelessWidget {
  final PharmacyItem item;

  const PharmacyDetailsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: item.name,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row

            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(
                    title: "Inventories",
                  ),

                  SizedBox(height: SizeConfig.size8),
                  // Inventory List
                  ...item.inventories.map((inv) => _buildInventoryCard(inv)).toList(),
                  SizedBox(height: SizeConfig.size8),
                ],
              ),
            ),
            MedicalCategorySelectorWidget(),

            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(
                    title: "Contact Us",
                  ),
                  _ratingRow(item),
                  SizedBox(height: SizeConfig.size8),

                  // Pharmacy Details
                  CommonCardWidget(
                    cardMargin: 0,
                    borderColorColor: AppColors.whiteE5,
                    child: Column(
                      children: [
                        _detailText(
                            "Address", "${item.address.isNotEmpty ? item.address : 'Address not available'}"),
                        _detailText("Timing",
                            "${item.openFrom.isNotEmpty ? item.openFrom : '-'} - ${item.openTill.isNotEmpty ? item.openTill : '-'}"),
                        _detailText("Contact", "${item.phone.isNotEmpty ? item.phone : '-'}"),
                        _detailText("Email", "${item.email.isNotEmpty ? item.email : '-'}"),
                        _detailText("Pincode", "${item.pincode.isNotEmpty ? item.pincode : '-'}"),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to keep the build method clean
  Widget _detailText(
    String text,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "${text} : ",
            // fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          Expanded(
            child: CustomText(
              value,
              // fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(dynamic inv) {
    final Map<String, dynamic> j = inv as Map<String, dynamic>;
    final String pv = j['productVariant']?.toString() ?? '';
    final String city = j['cityName']?.toString() ?? '';
    final String pin = j['pincode']?.toString() ?? '';
    final List batches = (j['batches'] as List?) ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: SizedBox(
        width: Get.width,
        child: CommonCardWidget(
          cardMargin: 0,
          borderColorColor: AppColors.whiteE5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Variant: ${pv.isNotEmpty ? pv : '-'}",
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText("City: $city | Pincode: $pin", color: AppColors.secondaryTextColor),
              SizedBox(height: SizeConfig.size6),
              ...batches.map((b) {
                final Map<String, dynamic> bj = b as Map<String, dynamic>;
                return CustomText(
                  "Batch: ${bj['batchNumber'] ?? '-'} | Qty: ${bj['quantity'] ?? 0} | MRP: ${bj['mrp'] ?? 0} | Price: ${bj['sellingPrice'] ?? 0}",
                  color: AppColors.secondaryTextColor,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Note: Ensure _ratingRow is also accessible or moved here
  Widget _ratingRow(PharmacyItem item) {
    // Paste your existing _ratingRow logic here or pass it in
    return Container();
  }
}
