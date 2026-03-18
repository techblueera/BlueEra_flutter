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
  final int? flex;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? margin;

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
    this.flex,
    this.color,
    this.textMaxLine,
    this.boxShadow,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String iconPath = getIcon(service);
    final bool isUrl = isNetworkImage(iconPath);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(service),
      child: AspectRatio(
        aspectRatio: 0.9,
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size10),
          margin: margin,
          decoration: BoxDecoration(
            color:color?? AppColors.white,
            // color:color?? AppColors.white,
            borderRadius: BorderRadius.circular(10),
            // boxShadow: boxShadow ?? [AppShadows.textFieldShadow],
            border: Border.all(
                color: isSelected ? AppColors.primaryColor : Color(0xffDDE2EE),
                width: borderWidth ?? 1.0
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Icon Container (Responsive size)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    // color: Colors.blue.withOpacity(0.05), // Light background like image
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // padding: EdgeInsets.all(SizeConfig.size10),
                  child: _buildImage(isUrl, iconPath),
                ),
              ),

              SizedBox(height: SizeConfig.size10),

              // 2. Text Container (Flexible height)
              Expanded(
                flex: flex??2,
                child: Center(
                  child: CustomText(
                    getName(service),
                    textAlign: TextAlign.center,
                    // style: TextStyle(
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    // ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(bool isUrl, String image) {
    final double effectiveHeight = iconHeight ?? SizeConfig.size50;

    if (image.isEmpty) {
      return _buildPlaceholder(effectiveHeight);
    }

    if (!isUrl) {
      return LocalAssets(
        imagePath: image,
        height: effectiveHeight,
      );
    }

    // 3. Handle Network Images
    return CachedNetworkImage(
      imageUrl: image,
      height: effectiveHeight,
      placeholder: (context, url) => _buildLoadingState(),
      errorWidget: (context, url, error) => _buildPlaceholder(effectiveHeight),
    );
  }

  Widget _buildPlaceholder(double effectiveHeight) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveHeight / 2),
      child: LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
        height: effectiveHeight,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

}
class CommonServiceCardHealth<T> extends StatelessWidget {
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
  final EdgeInsetsGeometry? margin;

  const CommonServiceCardHealth({
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
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String iconPath = getIcon(service);
    final bool isUrl = isNetworkImage(iconPath);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(service),
      child: Container(
        // padding: EdgeInsets.all(SizeConfig.size10),
        margin: margin,
        // alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icon Container (Responsive size)
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.white,

                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
                      width: borderWidth ?? 1.0
                  ),
                ),
                // padding: EdgeInsets.all(SizeConfig.size10),
                child: _buildImage(isUrl, iconPath),
              ),
            ),

            // SizedBox(height: SizeConfig.size10),

            // 2. Text Container (Flexible height)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: CustomText(
                  getName(service),
                  textAlign: TextAlign.center,
                  // style: TextStyle(
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  // ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            /*   _buildImage(isUrl, iconPath),
            SizedBox(height: spacing ?? SizeConfig.paddingXSL),
            Container(
              height: SizeConfig.size30,
              alignment: Alignment.center,
              child: CustomText(
                getName(service),
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: textMaxLine ?? 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isUrl, String image) {
    final double effectiveHeight = iconHeight ?? SizeConfig.size50;

    if (image.isEmpty) {
      return _buildPlaceholder(effectiveHeight);
    }

    if (!isUrl) {
      return LocalAssets(
        imagePath: image,
        height: effectiveHeight,
      );
    }

    // 3. Handle Network Images
    return CachedNetworkImage(
      imageUrl: image,
      height: effectiveHeight,
      placeholder: (context, url) => _buildLoadingState(),
      errorWidget: (context, url, error) => _buildPlaceholder(effectiveHeight),
    );
  }

  Widget _buildPlaceholder(double effectiveHeight) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveHeight / 2),
      child: LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
        height: effectiveHeight,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

}
