import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildLoadingShimmer({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    period: const Duration(milliseconds: 1500),
    child: child,
  );
}

// Helper to create a grey rounded block
Widget shimmerContainer({double? width, double? height, double radius = 10}) {
  return Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget buildBusinessHeaderSkeleton() {
  return buildLoadingShimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerContainer(height: 130), // Banner placeholder
        const SizedBox(height: 10),
        Row(
          children: [
            shimmerContainer(width: 80, height: 80, radius: 40), // Profile Circle
            const SizedBox(width: 15),
            Expanded(
              child: Column(children: [
                shimmerContainer(height: 20),
                const SizedBox(height: 8),
                shimmerContainer(height: 15, width: 150),
              ]),
            )
          ],
        ),
      ],
    ),
  );
}

Widget buildHorizontalListSkeleton() {
  return SizedBox(
    height: SizeConfig.size265,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: buildLoadingShimmer(
          child: shimmerContainer(width: 150, height: 265),
        ),
      ),
    ),
  );
}

Widget buildCategoryGridSkeleton() {
  return CustomFormCard(
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLoadingShimmer(child: shimmerContainer(height: 20, width: 100)),
        const SizedBox(height: 15),
        buildLoadingShimmer(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => shimmerContainer(height: 80),
          ),
        ),
      ],
    ),
  );
}
