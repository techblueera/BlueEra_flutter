import 'package:BlueEra/widgets/remote_icon_image.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class GroceryCategoryItem extends StatelessWidget {
  final String url;
  final String label;
  final VoidCallback onTap;

  const GroceryCategoryItem({
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
    // Routes by what the path actually IS. This used to send every network
    // URL to the SVG decoder, so a PNG category icon threw an XML parse error
    // off a background isolate.
    return RemoteIconImage(
      path: path,
      width: SizeConfig.size30,
      height: SizeConfig.size30,
    );
  }


}
