import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/unjoin_channel_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuggestedChannelsScreen extends StatefulWidget {
  const SuggestedChannelsScreen({super.key});

  @override
  State<SuggestedChannelsScreen> createState() =>
      _SuggestedChannelsScreenState();
}

class _SuggestedChannelsScreenState extends State<SuggestedChannelsScreen> {
  final ChannelFeedController _controller = Get.isRegistered<ChannelFeedController>()
      ? Get.find<ChannelFeedController>()
      : Get.put(ChannelFeedController());

  @override
  void initState() {
    super.initState();
    if (_controller.unJoinChannelDataList.isEmpty) {
      _controller.fetchUnJoinChannelData(loadMore: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const CustomText(
          AppStrings.suggested,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            _controller.fetchUnJoinChannelData(loadMore: false),
        child: Obx(() {
          final list = _controller.unJoinChannelDataList;
          if (list.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                const Center(
                  child: CustomText(
                    'No suggestions right now',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final channel = list[index];
              return InkWell(
                onTap: () => Get.to(
                  () => ChannelFeedPostListingScreen(channelData: channel),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: UnjoinChannelCardWidget(
                    channelModel: channel,
                    index: index,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
