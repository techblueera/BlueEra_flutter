import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BookHomeServiceCard<T> extends StatelessWidget {
  final T service;
  final String Function(T) getName;
  final String Function(T) getIcon;
  final ValueChanged<T> onTap;

  const BookHomeServiceCard({
    Key? key,
    required this.service,
    required this.getName,
    required this.getIcon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String iconPath = getIcon(service);
    final bool isUrl = isNetworkImage(iconPath);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onTap(service),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffDDE2EE), width: 1.0),
        ),
        padding: EdgeInsets.all(SizeConfig.size6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size4),
                child: _buildImage(isUrl, iconPath),
              ),
            ),
            SizedBox(height: SizeConfig.size6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomText(
                getName(service),
                textAlign: TextAlign.center,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isUrl, String image) {
    if (image.isEmpty) return _buildPlaceholder();

    if (!isUrl) {
      return LayoutBuilder(
        builder: (_, c) => LocalAssets(
          imagePath: image,
          height: c.maxHeight,
          width: c.maxWidth,
          boxFix: BoxFit.contain,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.contain,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return LocalAssets(
      imagePath: AppIconAssets.place_holder_image,
      boxFix: BoxFit.contain,
    );
  }
}
