import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Social-profile style gallery grid.
/// 1 image  → full width
/// 2 images → side by side
/// 3 images → 1 vertical left + 2 stacked right
/// 4 images → 2×2 grid
/// 5+ images → 2×2 with +N overlay on last tile
class SocialGalleryGrid extends StatelessWidget {
  final List<String> imageUrls;
  final double spacing;
  final double height;
  final double borderRadius;

  const SocialGalleryGrid({
    super.key,
    required this.imageUrls,
    this.spacing = 4,
    this.height = 260,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final count = imageUrls.length;

    if (count == 1) return _single(context);
    if (count == 2) return _two(context);
    if (count == 3) return _three(context);
    return _fourPlus(context);
  }

  /// 1 image — full width
  Widget _single(BuildContext context) {
    return SizedBox(
      height: height,
      child: _tile(context, 0, borderRadius: borderRadius),
    );
  }

  /// 2 images — side by side
  Widget _two(BuildContext context) {
    return SizedBox(
      height: height * 0.75,
      child: Row(
        children: [
          Expanded(
            child: _tile(context, 0,
                borderRadius: borderRadius, isLeft: true),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _tile(context, 1,
                borderRadius: borderRadius, isRight: true),
          ),
        ],
      ),
    );
  }

  /// 3 images — 1 vertical left + 2 stacked right
  Widget _three(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: _tile(context, 0,
                borderRadius: borderRadius, isLeft: true),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _tile(context, 1,
                      borderRadius: borderRadius, isTopRight: true),
                ),
                SizedBox(height: spacing),
                Expanded(
                  child: _tile(context, 2,
                      borderRadius: borderRadius, isBottomRight: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4+ images — 2×2 grid, last tile shows +N if more
  Widget _fourPlus(BuildContext context) {
    final remaining = imageUrls.length - 4;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _tile(context, 0,
                      borderRadius: borderRadius, isTopLeft: true),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _tile(context, 1,
                      borderRadius: borderRadius, isTopRight: true),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _tile(context, 2,
                      borderRadius: borderRadius, isBottomLeft: true),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _tile(context, 3,
                      borderRadius: borderRadius,
                      isBottomRight: true,
                      overlay: remaining > 0 ? '+$remaining' : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    int index, {
    double borderRadius = 0,
    bool isLeft = false,
    bool isRight = false,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
    String? overlay,
  }) {
    final radius = BorderRadius.only(
      topLeft: (isLeft || isTopLeft || (imageUrls.length == 1))
          ? Radius.circular(borderRadius)
          : Radius.zero,
      topRight: (isRight || isTopRight || (imageUrls.length == 1))
          ? Radius.circular(borderRadius)
          : Radius.zero,
      bottomLeft: (isLeft || isBottomLeft || (imageUrls.length == 1))
          ? Radius.circular(borderRadius)
          : Radius.zero,
      bottomRight: (isRight || isBottomRight || (imageUrls.length == 1))
          ? Radius.circular(borderRadius)
          : Radius.zero,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewScreen(
              appBarTitle: AppStrings.imageViewer,
              subTitle: AppStrings.imageViewer,
              imageUrls: imageUrls,
              initialIndex: index,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image,
                    color: Colors.grey[400], size: SizeConfig.size32),
              ),
            ),
            if (overlay != null)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: CustomText(
                  overlay,
                  color: Colors.white,
                  fontSize: SizeConfig.size24,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}