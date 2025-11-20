import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_card_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ViewAllJoinedChannelListScreen extends StatefulWidget {
  ViewAllJoinedChannelListScreen({super.key});

  @override
  State<ViewAllJoinedChannelListScreen> createState() =>
      _ViewAllJoinedChannelListScreenState();
}

class _ViewAllJoinedChannelListScreenState extends State<ViewAllJoinedChannelListScreen> {
  final channelFeedController = Get.find<ChannelFeedController>();

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(title: AppStrings.joined,),
      body: SafeArea(
        child: Obx(() {
          if (channelFeedController.isLoading.value &&
              channelFeedController.channelDataList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: channelFeedController.channelDataList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final channelData =
                        channelFeedController.channelDataList[index];

                    return InkWell(
                      onTap: () => Get.to(
                            () => ChannelFeedPostListingScreen(
                            channelData: channelData),
                      ),
                      child:
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        child: ChannelCardWidget(channelModel: channelData),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: kBottomNavigationBarHeight + 20,
              ),
            ],
          );
        }),
      ),
    );
  }
}
