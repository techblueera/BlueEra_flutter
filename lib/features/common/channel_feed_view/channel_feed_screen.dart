import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/unjoin_channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/view_all_joined_channel_list_screen.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          channelFeedController.clearList();
          await Future.delayed(Duration(microseconds: 200));

          await channelFeedController.fetchChannelData(loadMore: false);

          await channelFeedController.fetchUnJoinChannelData(loadMore: false);
        },

        child:

         CustomScrollView(
          controller: scrollController, // 👈 attach this!
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      return CustomText(
                        "${AppStrings.joined.tr} ${formatNumberLikePost(channelFeedController.channelFeedModel.value.pagination?.total ?? 0)} ${AppStrings.channels.tr}",
                        fontWeight: FontWeight.w500,
                        fontSize: SizeConfig.size16,
                        color: AppColors.mainTextColor,
                      );
                    }),
                    InkWell(
                      onTap: () => Get.to(ViewAllJoinedChannelListScreen()),
                      child: CustomText(
                        AppStrings.viewAll,
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
                          () => ChannelFeedPostListingScreen(
                              channelData: channel),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    CustomText(
                      AppStrings.suggested,
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size16,
                      color: AppColors.mainTextColor,
                    ),
                    InkWell(
                      onTap: () => Get.to(WhatsNewChannelListScreen()),
                      child: CustomText(
                        AppStrings.viewAll,
                        fontWeight: FontWeight.w500,
                        fontSize: SizeConfig.size16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
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
                        onTap: () async {
                          await Get.to(() => ChannelFeedPostListingScreen(
                              channelData: newChannel));

                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child:
                              UnjoinChannelCardWidget(channelModel: newChannel, index: index,),
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
        )
      ),
    );
  }
}
