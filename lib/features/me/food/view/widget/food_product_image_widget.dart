import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final String? fallbackIcon;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.borderRadius = 8,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl ?? "",
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Error state: shows a local icon if URL fails or is empty
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[100],
          child: Center(
            child: LocalAssets(
              imagePath: fallbackIcon ?? AppIconAssets.foodIcon,
              width: width * 0.5, // Scale icon relative to box
            ),
          ),
        ),
        // Loading state: smooth grey shimmer/container
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          width: width,
          height: height,
        ),
      ),
    );
  }
}