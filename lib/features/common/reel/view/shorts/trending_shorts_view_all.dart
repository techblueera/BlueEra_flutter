import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TrendingShortsViewAll extends StatelessWidget {
  final String query;
   TrendingShortsViewAll({super.key, required this.query});
  final  shortsFeedController = Get.find<ShortsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Trending"),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          final metrics = scrollNotification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            if (shortsFeedController.trendingVideoFeedHasMore &&
                shortsFeedController.trendingVideoFeedIsLoadingMore.isFalse) {
              shortsFeedController.getAllFeedTrending(query: query);
            }
          }
          return false;
        },
        child: Container(
          height: Get.height,
          width: Get.width,
          child: Obx(() {
            final trendingShorts = shortsFeedController.trendingVideoFeedPosts;
            final isLoading = shortsFeedController.trendingVideoFeedIsLoadingMore;

            return GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.paddingXSL,
                vertical: 8,
              ),
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 columns
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 0.63, // square cells
              ),
              itemCount: trendingShorts.length + (isLoading.isTrue ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == trendingShorts.length && isLoading.isTrue) {
                  return staggeredDotsWaveLoading();
                } else {
                  // ✅ Normal grid items
                  final item = trendingShorts[index];
                  return SingleShortStructure(
                    shorts: Shorts.trending,
                    allLoadedShorts: trendingShorts,
                    initialIndex: index,
                    shortItem: item,
                    withBackground: true,
                  );
                }
              },
            );
          }),
        ),
      ),
    );
  }
}
