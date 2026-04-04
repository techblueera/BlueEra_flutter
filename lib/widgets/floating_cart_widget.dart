import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FloatingCartWidget extends StatelessWidget {
  final int itemCount;
  final List<String?> displayImages;
  final VoidCallback onTap;
  final String cartLabel;
  final String? itemLabel;

  const FloatingCartWidget({
    super.key,
    required this.itemCount,
    required this.displayImages,
    required this.onTap,
    this.cartLabel = 'View cart',
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final images = displayImages.take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size20),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overlapping images
            if (images.isNotEmpty)
              SizedBox(
                width: _calculateImagesWidth(images.length),
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(images.length, (index) {
                    return Positioned(
                      left: index * 22.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: images[index] != null &&
                                  images[index]!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: images[index]!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade300,
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: LocalAssets(
                                      imagePath:
                                          AppIconAssets.place_holder_image,
                                      boxFix: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: LocalAssets(
                                    imagePath:
                                        AppIconAssets.place_holder_image,
                                    boxFix: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            if (images.isNotEmpty) SizedBox(width: SizeConfig.size10),

            // Text column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  cartLabel,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                CustomText(
                  itemLabel ?? '$itemCount Items',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ],
            ),

            SizedBox(width: SizeConfig.size8),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateImagesWidth(int count) {
    if (count == 0) return 0;
    return 36.0 + (count - 1) * 22.0;
  }
}
