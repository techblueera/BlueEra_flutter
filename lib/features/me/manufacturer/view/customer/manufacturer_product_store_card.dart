import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:BlueEra/features/me/manufacturer/view/customer/manufacturer_visit_product_store_details_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _ProductCardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerLine;

  const _ProductCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerLine,
  });
}

const _palettes = <_ProductCardPalette>[
  _ProductCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    // CSS #13DBF414 (RGBA) → Flutter ARGB 0x1413DBF4 — translucent
    // teal wash so the card's footer tints with the card's identity.
    tileBg: Color(0x1413DBF4),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _ProductCardPalette(
    cardBg: Color(0xFFFCF5FF),
    cardBorder: Color(0xFFECD3F6),
    // CSS #BE26FF14 (RGBA) → Flutter ARGB 0x14BE26FF — same low-alpha
    // tint, violet to match the second card's outer shell.
    tileBg: Color(0x14BE26FF),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

class ManufacturerProductStoreCard extends StatelessWidget {
  final GetAllStoreResModel? getAllStoreResData;
  final double Function(double) ds;

  /// Card position in the list — drives palette selection so the cards
  /// alternate (palette 0 → palette 1 → palette 0 …) instead of being
  /// picked by a hash of `store.id`, which produced unpredictable
  /// runs of the same palette.
  final int index;

  const ManufacturerProductStoreCard({
    super.key,
    required this.ds,
    required this.index,
    this.getAllStoreResData,
  });

  GetAllStoreResModel get _store =>
      getAllStoreResData ?? GetAllStoreResModel();

  _ProductCardPalette get _palette =>
      _palettes[index.abs() % _palettes.length];

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final livePhotos = (store.livePhotos ?? const <String>[])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final logo = store.logo ?? '';
    final hasLogo = logo.isNotEmpty;
    final heroImage = livePhotos.isNotEmpty
        ? livePhotos.first
        : (hasLogo ? logo : '');
    final extraPhotos = livePhotos.length > 1 ? livePhotos.length - 1 : 0;
    final palette = _palette;

    return InkWell(
      onTap: _openStore,
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
                  _buildHeader(),
                  SizedBox(height: SizeConfig.size10),
                  _buildDottedLine(palette.dividerLine),
                  SizedBox(height: SizeConfig.size10),
                  _buildBodyRow(
                    context: context,
                    heroImage: heroImage,
                    livePhotos: livePhotos,
                    extraPhotos: extraPhotos,
                    palette: palette,
                  ),
                ],
              ),
            ),
            _buildLastVisitFooter(palette),
          ],
        ),
      ),
    );
  }

  // --- Header: Logo + Name + Rating/Subcategory badges + Chat icon + Follow.
  Widget _buildHeader() {
    final store = _store;
    final ratingValue = (store.avgRating ?? 0) > 0
        ? store.avgRating.toString()
        : AppStrings.no.tr;
    final subCategory =
        store.subCategoryOfBusiness?.name ?? store.natureOfBusiness ?? 'OTHER';
    final sinceYear = store.dateOfIncorporation?.year;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedAvatarWidget(
          imageUrl: store.logo ?? '',
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
                store.businessName ?? 'Unknown Business',
                fontSize: SizeConfig.large18,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w800,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildRatingBadge(ratingValue),
                  _buildCategoryBadge(subCategory),
                  if (sinceYear != null) _buildSinceBadge(sinceYear),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        DiscoverChatIcon(
          userId: store.userId ?? '',
          name: store.businessName,
          profile: store.logo,
          businessId: store.id,
          trackingSource: ChatClickSource.searchResult,
        ),
      ],
    );
  }

  // --- Body: 2 stat cards + address card on the left, hero image on right.
  Widget _buildBodyRow({
    required BuildContext context,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
    required _ProductCardPalette palette,
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
                      _buildStatBox(
                        icon: AppIconAssets.staggeredIcon,
                        count: _formatCount(_store.totalCategoryCount ??
                            (_store.categories?.length ?? 0)),
                        label: 'Category',
                        iconColor: const Color(0xFF9964F4),
                        borderColor: palette.tileBorder,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      _buildStatBox(
                        icon: AppIconAssets.productCartIcon,
                        count: _formatCount(_store.totalProductCount ?? 0),
                        label: 'ManufacturerProduct',
                        iconColor: const Color(0xFF6179CD),
                        borderColor: palette.tileBorder,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Expanded(child: _buildAddressCard(context, palette)),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              flex: 3,
              child: _buildHeroImage(
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

  // --- Address card: white tile with shadowed location icon, distance + address.
  Widget _buildAddressCard(BuildContext context, _ProductCardPalette palette) {
    final store = _store;
    final lat = store.businessLocation?.lat?.toDouble() ?? 0.0;
    final lng = store.businessLocation?.lon?.toDouble() ?? 0.0;
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      lat,
      lng,
    );

    return GestureDetector(
      onTap: () => _showMapBottomSheet(context),
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
            _buildIconContainer(AppIconAssets.location_outline),
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
                    store.address ?? AppStrings.na,
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

  Widget _buildIconContainer(String iconPath) {
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

  // --- Stat box: SVG icon + count + label.
  Widget _buildStatBox({
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

  // --- Hero image with optional "+N" overlay for additional live photos.
  Widget _buildHeroImage({
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
  }) {
    final natureOfBusiness = _store.categoryOfBusiness?.name ??
        _store.natureOfBusiness ??
        'OTHER';
    final fullList = livePhotos.isNotEmpty
        ? livePhotos
        : (heroImage.isNotEmpty ? [heroImage] : <String>[]);

    return GestureDetector(
      onTap: fullList.isEmpty
          ? null
          : () => _showPhotoDialog(
                images: fullList,
                initialIndex: 0,
                title: natureOfBusiness,
              ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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

  // --- Footer: top-bordered banner with eye icon + total view count.
  Widget _buildLastVisitFooter(_ProductCardPalette palette) {
    final views = int.tryParse(_store.views ?? '') ?? 0;
    final viewLabel = views == 1 ? 'view' : 'views';
    final countText = _formatCount(views);
    final clicks = _store.chatClickCount ?? 0;
    final clickLabel = clicks == 1 ? 'order' : 'orders';
    final clickCountText = _formatCount(clicks);
    final quirky = (_store.quirkyMessage ?? '').trim();
    return InkWell(
      onTap: _openStore,
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
                      text: countText,
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
                      text: clickCountText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' $clickLabel'),
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

  /// Rating badge — gradient gold pill, bold rating numeral, soft amber glow.
  Widget _buildRatingBadge(String rating) {
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
        border: Border.all(
          color: goldFg.withValues(alpha: 0.28),
          width: 1,
        ),
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

  /// Subcategory badge — soft mint pill paired with the rating badge.
  Widget _buildCategoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.greenCB.withValues(alpha: 0.55),
        border: Border.all(
          color: AppColors.green2C.withValues(alpha: 0.25),
          width: 1,
        ),
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

  /// "Since YYYY" badge — neutral pill marking date of incorporation.
  Widget _buildSinceBadge(int year) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.greyE5.withValues(alpha: 0.4),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: CustomText(
        'Since $year',
        fontSize: 11,
        color: AppColors.secondaryTextColor,
        fontWeight: FontWeight.w600,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDottedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
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

  void _showPhotoDialog({
    required List<String> images,
    required int initialIndex,
    required String title,
  }) {
    final ctx = Get.context;
    if (ctx == null || images.isEmpty) return;
    showDialog<void>(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _ProductPhotoDialog(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  void _openStore() {
    Get.to(() => ManufacturerVisitProductStoreDetailsScreen(
          visitBusinessId: _store.id ?? "",
        ));
  }

  void _showMapBottomSheet(BuildContext context) {
    final store = _store;
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? 'Store',
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
      visitCallback: ()=> _openStore
    );
  }
}

/// Premium photo lightbox shown as a bordered, rounded dialog (not
/// full-page). Inside: a faint primary halo radial backdrop, a clean
/// header with a title pill + counter + circular close, an
/// `InteractiveViewer` PageView with double-tap-to-zoom, and an
/// animated dot indicator below — the active dot stretches into a
/// pill in the primary color.
class _ProductPhotoDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _ProductPhotoDialog({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_ProductPhotoDialog> createState() => _ProductPhotoDialogState();
}

class _ProductPhotoDialogState extends State<_ProductPhotoDialog>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _entry;
  late int _index;
  final Map<int, TransformationController> _transformers = {};
  TapDownDetails? _lastDoubleTap;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  TransformationController _transformerFor(int i) =>
      _transformers.putIfAbsent(i, TransformationController.new);

  @override
  void dispose() {
    _controller.dispose();
    _entry.dispose();
    for (final t in _transformers.values) {
      t.dispose();
    }
    super.dispose();
  }

  void _toggleZoom(int i) {
    final t = _transformerFor(i);
    final details = _lastDoubleTap;
    if (t.value != Matrix4.identity()) {
      t.value = Matrix4.identity();
    } else if (details != null) {
      const scale = 2.5;
      final pos = details.localPosition;
      t.value = Matrix4.identity()
        ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
        ..scale(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedBuilder(
        animation: _entry,
        builder: (_, __) => Opacity(
          opacity: _entry.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: size.width,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.96),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.32),
                                  width: 0.5,
                                ),
                              ),
                              child: CustomText(
                                widget.title,
                                fontSize: SizeConfig.small,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 0.5,
                            ),
                          ),
                          child: CustomText(
                            '${_index + 1} / ${widget.images.length}',
                            fontSize: SizeConfig.small,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.5,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.images.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) {
                        return GestureDetector(
                          onDoubleTapDown: (d) => _lastDoubleTap = d,
                          onDoubleTap: () => _toggleZoom(i),
                          child: Hero(
                            tag: 'photo_${widget.images[i]}_$i',
                            child: InteractiveViewer(
                              transformationController:
                                  _transformerFor(i),
                              minScale: 1,
                              maxScale: 5,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.images[i],
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => Container(
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        child: Center(
                                          child: SizedBox(
                                            width: 26,
                                            height: 26,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(Colors.white
                                                          .withValues(
                                                              alpha:
                                                                  0.55)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          LocalAssets(
                                        imagePath: AppIconAssets
                                            .place_holder_image,
                                        boxFix: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.images.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryColor
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
