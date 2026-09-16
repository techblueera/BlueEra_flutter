import 'package:BlueEra/widgets/remote_icon_image.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class MedicalCategoryItem extends StatelessWidget {
  final String url;
  final String label;
  final VoidCallback onTap;

  const MedicalCategoryItem({
    super.key,
    required this.url,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.black.withValues(alpha: 0.1),
          highlightColor: AppColors.black.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white,
              border: Border.all(color: AppColors.greyE5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildImage(url),
                SizedBox(width: SizeConfig.size12),
                Flexible(
                  child: CustomText(
                    label,
                    fontSize: SizeConfig.large18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {

    if (isNetworkImage(path)) {
      // Routes by what the path actually IS. Sending every network URL to the
      // SVG decoder threw an XML parse error on raster icons, and the loader
      // fails on a background isolate where it reads as a crash, not a broken
      // image.
      return RemoteIconImage(
        path: path,
        width: SizeConfig.size30,
        height: SizeConfig.size30,
        showLoader: true,
      );
    } else {
      // Local asset (svg or png/jpg)
      return LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        // imagePath: path??AppIconAssets.place_holder_image,
        width: SizeConfig.size30,
        height: SizeConfig.size30,
        boxFix: BoxFit.contain,

      );
    }
  }


}
