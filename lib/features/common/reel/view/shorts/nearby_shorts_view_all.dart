import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearByShortsViewAll extends StatelessWidget {
  final String query;
  NearByShortsViewAll({super.key, required this.query});
  final  shortsFeedController = Get.find<ShortsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "For You"),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          final metrics = scrollNotification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            if (shortsFeedController.nearByVideoFeedHasMore &&
                shortsFeedController.nearByVideoFeedIsLoadingMore.isFalse) {
              shortsFeedController.getAllFeedNearBy(query: query);
            }
          }
          return false;
        },
        child: Container(
          height: Get.height,
          width: Get.width,
          // color: Colors.red,
          child: Obx(() {
            final nearByVideoShorts = shortsFeedController.nearByVideoFeedPosts;
            final isLoading = shortsFeedController.nearByVideoFeedIsLoadingMore;

            // int itemCount = nearByVideoShorts.length;
            // if (itemCount > 10) itemCount = 10;
            // if (isLoading) itemCount += 1;

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
              itemCount: nearByVideoShorts.length + (isLoading.isTrue ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == nearByVideoShorts.length &&
                    isLoading.isTrue) {
                  // ✅ Loading indicator if API is fetching more
                  return staggeredDotsWaveLoading();
                } else {
                  // ✅ Normal grid items (up to 5)
                  final item = nearByVideoShorts[index];
                  return SingleShortStructure(
                    shorts: Shorts.nearBy,
                    allLoadedShorts: nearByVideoShorts,
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
