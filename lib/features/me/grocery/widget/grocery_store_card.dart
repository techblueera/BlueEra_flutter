import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:pro_image_editor/core/constants/editor_shader_constants.dart';

class _GroceryCardPalette {
  final Color cardBorder;
  final Color tileBorder;
  final Color dividerLine;

  const _GroceryCardPalette({
    required this.cardBorder,
    required this.tileBorder,
    required this.dividerLine,
  });
}

const _palettes = <_GroceryCardPalette>[
  _GroceryCardPalette(
    cardBorder: Color(0xFFC0DDE1),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _GroceryCardPalette(
    cardBorder: Color(0xFFECD3F6),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

class GroceryStoreCard extends StatelessWidget {
  final GetAllStoreResModel store;
  final Color bgColor;

  const GroceryStoreCard({
    super.key,
    required this.store,
    required this.bgColor,
  });

  _GroceryCardPalette get _palette {
    final key = (store.id ?? store.userId ?? '').hashCode;
    return _palettes[key.abs() % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
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
          color: bgColor,
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

  // --- Header: Logo + Name + Rating/Category badges + Chat icon ---
  Widget _buildHeader() {
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
              Row(
                children: [
                  _buildRatingBadge(store.avgRating.toString()),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _buildCategoryBadge(
                        store.subCategoryOfBusiness?.name ?? AppStrings.na),
                  ),
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

  // --- Body: address card + 2 stat cards on the left, hero image on right.
  Widget _buildBodyRow({
    required BuildContext context,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
    required _GroceryCardPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: SizedBox(
        height: 100,
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
                        count: _formatCount(store.totalCategoryCount ??
                            (store.categories?.length ?? 0)),
                        label: 'Category',
                        iconColor: const Color(0xFF9964F4),
                        borderColor: palette.tileBorder,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      _buildStatBox(
                        icon: AppIconAssets.productCartIcon,
                        count: _formatCount(store.totalProductCount ?? 0),
                        label: 'Product',
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

  // --- Address card: matches the prior grocery card design — soft white
  // tile with shadowed location icon, "X Km Away" + address stacked, and
  // a blue directions affordance on the right.
  Widget _buildAddressCard(BuildContext context, _GroceryCardPalette palette) {
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
            // const SizedBox(width: 6),
            // Icon(
            //   Icons.directions_rounded,
            //   size: 20,
            //   color: Colors.blue.shade400,
            // ),
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

  // --- Stat box: matches the prior grocery card design (purple staggered
  // icon for Category, blue cart icon for Product) with count + label
  // stacked beside the icon tile.
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
    final natureOfBusiness = store.categoryOfBusiness?.name ??
        store.natureOfBusiness ??
        'OTHER';
    final fullList =
        livePhotos.isNotEmpty ? livePhotos : (heroImage.isNotEmpty ? [heroImage] : <String>[]);

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

  // --- Footer: mint banner with camera icon + last-visit / quirky message.
  Widget _buildLastVisitFooter(_GroceryCardPalette palette) {
    final views = int.tryParse(store.views ?? '') ?? 0;
    final viewLabel = views == 1 ? 'view' : 'views';
    final countText = _formatCount(views);
    final clicks = store.chatClickCount ?? 0;
    final clickLabel = clicks == 1 ? 'order' : 'orders';
    final clickCountText = _formatCount(clicks);
    final quirky = (store.quirkyMessage ?? '').trim();
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
          color: Colors.transparent,
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
              imgColor: AppColors.secondaryTextColor
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

  /// Rating badge — gradient gold pill, bold rating numeral, soft amber
  /// glow. Reads as a badge of quality rather than a tag.
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

  /// Subcategory badge — gradient mint pill paired with the rating badge.
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
      builder: (_) => _GroceryPhotoDialog(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  void _openStore() {
    Get.toNamed(
      RouteHelper.getVisitGroceryStoreScreenRoute(),
      arguments: {
        ApiKeys.userId: store.userId,
        ApiKeys.businessId: store.id,
      },
    );
  }

  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? 'Store',
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
      storeBusinessID: store.id ?? "",
      storeUserID: store.userId ?? "",
    );
  }
}

class _GroceryPhotoDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _GroceryPhotoDialog({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_GroceryPhotoDialog> createState() => _GroceryPhotoDialogState();
}

class _GroceryPhotoDialogState extends State<_GroceryPhotoDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          width: size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
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
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: size.height * 0.5,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: widget.images[i],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
