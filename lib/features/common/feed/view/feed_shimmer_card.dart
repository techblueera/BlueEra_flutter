import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FeedShimmerCard extends StatelessWidget {
  const FeedShimmerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingL,
          vertical: SizeConfig.size8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 cover
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size12),

            // Headline
            Container(
              width: double.infinity,
              height: SizeConfig.size20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: SizeConfig.size8),

            // 3-line description
            ...List.generate(
              3,
                  (_) => Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size4),
                child: Container(
                  width: SizeConfig.screenWidth * (0.9 - _ * 0.15),
                  height: SizeConfig.size14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}