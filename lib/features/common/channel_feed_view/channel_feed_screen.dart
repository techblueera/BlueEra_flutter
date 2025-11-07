import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/unjoin_channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/whats_new_channel_list_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelFeedScreen extends StatefulWidget {
  ChannelFeedScreen({super.key});

  @override
  State<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends State<ChannelFeedScreen> {
  final channelFeedController = Get.put(ChannelFeedController());
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    /// Initial data load
    channelFeedController.fetchChannelData(loadMore: false);
    channelFeedController.fetchUnJoinChannelData(loadMore: false);

    /// Listen for scroll for pagination
    scrollController.addListener(() {
      // Trigger pagination when near bottom
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        // Joined channels pagination
        final hasMoreJoined =
            (channelFeedController.channelFeedModel.value.pagination?.page ??
                    1) <
                (channelFeedController
                        .channelFeedModel.value.pagination?.totalPages ??
                    1);

        if (hasMoreJoined && !channelFeedController.isLoading.value) {
          channelFeedController.fetchChannelData(loadMore: true);
        }

        // Suggested channels pagination
        final hasMoreSuggested = (channelFeedController
                    .unJoinChannelFeedModel.value.pagination?.page ??
                1) <
            (channelFeedController
                    .unJoinChannelFeedModel.value.pagination?.totalPages ??
                1);

        if (hasMoreSuggested && !channelFeedController.isUnJoinLoading.value) {
          channelFeedController.fetchUnJoinChannelData(loadMore: true);
        }
      }
    });
  }

  /*  final channelFeedController = Get.put(ChannelFeedController());

  final scrollController = ScrollController();

  @override
  void initState() {
    channelFeedController.fetchChannelData(loadMore: false);

    // TODO: implement initState
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        final bool hasMore =
            (channelFeedController.channelFeedModel.value.pagination?.page ??
                1) <
                (channelFeedController
                    .channelFeedModel.value.pagination?.totalPages ??
                    1);
        channelFeedController.fetchChannelData(loadMore: hasMore);
      }
    });
    super.initState();
  }*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: scrollController, // 👈 attach this!
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    return CustomText(
                      "Joined ${formatNumberLikePost(channelFeedController.channelFeedModel.value.pagination?.total ?? 0)} Channels",
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size16,
                      color: AppColors.mainTextColor,
                    );
                  }),
                  InkWell(
                    onTap: () => Get.to(WhatsNewChannelListScreen()),
                    child: CustomText(
                      "What’s New!",
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Joined Channels
          Obx(() => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final channel =
                        channelFeedController.channelDataList[index];
                    return InkWell(
                      onTap: () => Get.to(
                        () =>
                            ChannelFeedPostListingScreen(channelData: channel),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ChannelCardWidget(channelModel: channel),
                      ),
                    );
                  },
                  childCount: channelFeedController.channelDataList.length,
                ),
              )),

          // Suggested Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: CustomText(
                "Suggested",
                fontWeight: FontWeight.w500,
                fontSize: SizeConfig.size16,
                color: AppColors.mainTextColor,
              ),
            ),
          ),

          // Suggested Channels
          Obx(() => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final newChannel =
                        channelFeedController.unJoinChannelDataList[index];
                    return InkWell(
                      onTap: () => Get.to(() => ChannelFeedPostListingScreen(
                          channelData: newChannel)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child:
                            UnjoinChannelCardWidget(channelModel: newChannel),
                      ),
                    );
                  },
                  childCount:
                      channelFeedController.unJoinChannelDataList.length,
                ),
              )),

          // Bottom Spacer
          const SliverToBoxAdapter(
            child: SizedBox(height: kBottomNavigationBarHeight + 20),
          ),
        ],
      ),
    );
  }

/*  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // Pagination for Joined Channels
        if (scrollNotification.metrics.pixels ==
            scrollNotification.metrics.maxScrollExtent) {
          channelFeedController.fetchChannelData(loadMore: true);
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // 🔹 Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    return CustomText(
                      "Joined ${formatNumberLikePost(channelFeedController
                          .channelFeedModel.value.pagination?.total ??
                          0)} Channels",
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size16,
                      color: AppColors.mainTextColor,
                    );
                  }),
                  InkWell(
                    onTap: () {
                      Get.to(WhatsNewChannelListScreen());
                    },
                    child: CustomText(
                      "What’s New!",
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Joined Channels List
          Obx(() =>
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final channel =
                    channelFeedController.channelDataList[index];
                    return InkWell(
                      onTap: () =>
                          Get.to(
                                  () =>
                                  ChannelFeedPostListingScreen(
                                      channelData: channel)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        child: ChannelCardWidget(channelModel: channel),
                      ),
                    );
                  },
                  childCount: channelFeedController.channelDataList.length,
                ),
              )),

          // 🔹 Section Divider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: CustomText(
                "Suggested",
                fontWeight: FontWeight.w500,
                fontSize: SizeConfig.size16,
                color: AppColors.mainTextColor,
              ),
            ),
          ),

          // 🔹 “What’s New” List (has its own pagination)
          Obx(() =>
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final newChannel = channelFeedController
                        .unJoinChannelDataList[index];
                    return InkWell(
                      onTap: () =>
                          Get.to(() =>
                              ChannelFeedPostListingScreen(
                                channelData: newChannel,
                              )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        child: UnjoinChannelCardWidget(channelModel: newChannel),
                      ),
                    );
                  },
                  childCount: channelFeedController.unJoinChannelDataList
                      .length,
                ),
              )),

          // 🔹 Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: kBottomNavigationBarHeight + 20),
          ),
        ],
      ),
    );
  }*/
}
// return SafeArea(
// child: Obx(() {
// if (channelFeedController.isLoading.value &&
// channelFeedController.channelDataList.isEmpty) {
// return const Center(child: CircularProgressIndicator());
// }
//
// return Column(
// children: [
// Padding(
// padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
// child: Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// CustomText(
// "Joined ${formatNumberLikePost(
// channelFeedController.channelFeedModel.value.pagination
//     ?.total ?? 0)} Channels",
// fontWeight: FontWeight.w500,
// fontSize: SizeConfig.size16,
// color: AppColors.mainTextColor,
// ),
// InkWell(
// onTap: () {
// Get.to(WhatsNewChannelListScreen());
// },
// child: CustomText(
// "What’s New!",
// fontWeight: FontWeight.w500,
// fontSize: SizeConfig.size16,
// color: AppColors.primaryColor,
// ),
// ),
// ],
// ),
// ),
// Expanded(
// child: ListView.builder(
// controller: scrollController,
// padding: const EdgeInsets.all(10),
// itemCount: channelFeedController.channelDataList.length,
// shrinkWrap: true,
// itemBuilder: (context, index) {
// final channelData =
// channelFeedController.channelDataList[index];
//
// return InkWell(
// onTap: () {
// final channelData =
// channelFeedController.channelDataList[index];
// Get.to(() =>
// ChannelFeedPostListingScreen(
// channelData: channelData,
// ));
// },
// child: ChannelCardWidget(
// channelModel: channelData,
// ),
// );
// },
// ),
// ),
// SizedBox(
// height: kBottomNavigationBarHeight + 20,
// ),
// Expanded(child: WhatsNewChannelListScreen())
// ],
// );
// }),
// );
