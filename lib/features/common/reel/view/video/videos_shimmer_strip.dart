import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VideosShimmerStrip extends StatelessWidget {
  const VideosShimmerStrip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        children: [
          // Cover image placeholder
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: SizeConfig.screenWidth,
              height: SizeConfig.size170,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),

          // Meta row (avatar + texts)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size15,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: SizeConfig.size34,
                    height: SizeConfig.size34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),

                // Title + 3 lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerBox(double.infinity, SizeConfig.size20),
                      SizedBox(height: SizeConfig.size4),
                      shimmerBox(SizeConfig.screenWidth * .4, SizeConfig.size12),
                      SizedBox(height: SizeConfig.size4),
                    ],
                  ),
                ),

                // Menu icon
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small helper to reduce repetition
  Widget shimmerBox(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
