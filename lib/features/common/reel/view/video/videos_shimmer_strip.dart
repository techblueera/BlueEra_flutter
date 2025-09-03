import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VideosShimmerStrip extends StatelessWidget {
  const VideosShimmerStrip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Cover image placeholder
            Container(
              width: SizeConfig.screenWidth,
              height: SizeConfig.size170,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            // Meta row (avatar + texts)
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size15, horizontal: SizeConfig.size10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circle
                  Container(
                    width: SizeConfig.size34,
                    height: SizeConfig.size34,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  // Title + 3 lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: SizeConfig.size14,
                          color: AppColors.white,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        Container(
                          width: SizeConfig.screenWidth * .4,
                          height: SizeConfig.size12,
                          color: AppColors.white,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        Container(
                          width: SizeConfig.screenWidth * .25,
                          height: SizeConfig.size12,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                  // Menu icon
                  Container(
                    width: SizeConfig.size18,
                    height: SizeConfig.size18,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}