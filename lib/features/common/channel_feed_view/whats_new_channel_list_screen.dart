import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/unjoin_channel_card_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhatsNewChannelListScreen extends StatefulWidget {
  WhatsNewChannelListScreen({super.key});

  @override
  State<WhatsNewChannelListScreen> createState() =>
      _WhatsNewChannelListScreenState();
}

class _WhatsNewChannelListScreenState extends State<WhatsNewChannelListScreen> {
  final channelFeedController = Get.find<ChannelFeedController>();

  final scrollController = ScrollController();

  @override
  void initState() {
    channelFeedController.fetchUnJoinChannelData(loadMore: false);

    // TODO: implement initState
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        final bool hasMore =
            (channelFeedController.unJoinChannelFeedModel.value.pagination?.page ??
                    1) <
                (channelFeedController
                        .unJoinChannelFeedModel.value.pagination?.totalPages ??
                    1);
        channelFeedController.fetchChannelData(loadMore: hasMore);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "What's New",),
      body: SafeArea(
        child: Obx(() {
          if (channelFeedController.isUnJoinLoading.value &&
              channelFeedController.unJoinChannelDataList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: channelFeedController.unJoinChannelDataList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final channelData =
                        channelFeedController.unJoinChannelDataList[index];

                    return InkWell(
                      onTap: () {

                        // final channelData =
                        //     channelFeedController.unJoinChannelDataList[index];
                        Get.to(() => ChannelFeedPostListingScreen(
                              channelData: channelData,
                            ));
                      },
                      child: UnjoinChannelCardWidget(
                        channelModel: channelData,
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
