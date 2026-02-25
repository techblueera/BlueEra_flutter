import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class CommonServiceCard<T> extends StatelessWidget {
  final T service;
  final String Function(T) getName;
  final String Function(T) getIcon;
  final Function(T) onTap;
  final bool isSelected;
  final double? iconHeight;
  final double? spacing;
  final double? borderWidth;
  final int? textMaxLine;
  final List<BoxShadow>? boxShadow;

  const CommonServiceCard({
    Key? key,
    required this.service,
    required this.getName,
    required this.getIcon,
    required this.onTap,
    this.isSelected = false,
    this.iconHeight,
    this.spacing,
    this.borderWidth,
    this.textMaxLine,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String iconPath = getIcon(service);
    final bool isUrl = isNetworkImage(iconPath);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(service),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: boxShadow ?? [AppShadows.textFieldShadow],
          border: Border.all(
              color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
              width: borderWidth ?? 1.0
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildImage(isUrl, iconPath),
            SizedBox(height: spacing ?? SizeConfig.paddingXSL),
            Container(
              height: SizeConfig.size30,
              alignment: Alignment.center,
              child: CustomText(
                getName(service),
                fontSize: SizeConfig.small11,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                maxLines: textMaxLine ?? 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isUrl, String image){
    return !(isUrl)
        ? LocalAssets(
      imagePath: image,
      height: iconHeight ?? SizeConfig.size50,
    ) : CachedNetworkImage(
      imageUrl: image,
      // fit: BoxFit.fill,
      height: iconHeight ?? SizeConfig.size50,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
      ),
    );
  }

}
