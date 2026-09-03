import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/view_all_joined_channel_list_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/ott/controller/ott_home_controller.dart';
import 'package:BlueEra/features/common/ott/view/view_all_channel_screen.dart';
import 'package:BlueEra/features/common/ott/widget/build_all_channels_list_widget.dart';
import 'package:BlueEra/features/common/ott/widget/build_carousel_section_widget.dart';
import 'package:BlueEra/features/common/ott/widget/build_horizontal_video_list_widget.dart';
import 'package:BlueEra/features/common/ott/widget/build_joined_channels_list_widget.dart';
import 'package:BlueEra/features/common/ott/widget/build_section_header_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

DateTime? lastOTTFetchTime;
bool isChannelOTTFetching = false;

class OttScreen extends StatefulWidget {
  final Function(bool)? onHeaderVisibilityChanged;
  final double headerHeight;

  OttScreen({
    super.key,
    this.onHeaderVisibilityChanged,
    required this.headerHeight,
  });

  @override
  State<OttScreen> createState() => _OttScreenState();
}

class _OttScreenState extends State<OttScreen> {
  final ottHomeController = Get.put(OttHomeController());
  final channelFeedController = Get.put(ChannelFeedController());

  Future<void> _refreshChannelContent() async {
    final now = DateTime.now();

    // Guard: If already fetching or within the 5s window, do nothing
    if (isChannelOTTFetching) return;
    if (lastOTTFetchTime != null &&
        now.difference(lastOTTFetchTime!) < fetchThreshold) {
      return;
    }

    isChannelOTTFetching = true;
    lastOTTFetchTime = now;

    try {
      // Fire both APIs at the same time for maximum speed
      await Future.wait([
        channelFeedController.fetchChannelData(loadMore: false),
        channelFeedController.getAllChannelData(loadMore: false),
      ]);
    } catch (e) {
      debugPrint("Channel Fetch Error: $e");
    } finally {
      isChannelOTTFetching = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshChannelContent();
  }

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //
  //   ///GET ALL JOIN CHANNEL....
  //   channelFeedController.fetchChannelData(loadMore: false);
  //   channelFeedController.getAllChannelData(loadMore: false);
  // }

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final ottWidget = Material(
      color: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CAROUSEL SLIDER SECTION
                BuildCarouselSectionWidget(),

                const SizedBox(height: 20),

                // 2. JOINED CHANNELS (Horizontal List)
                Obx(() {
                  return BuildSectionHeaderWidget(
                    title: AppStrings.joinedChannels,
                    isShowArrow: (channelFeedController
                                .channelFeedModel.value.pagination?.total ??
                            0) >
                        20,
                    onTap: () {
                      Get.to(() => ViewAllJoinedChannelListScreen());
                    },
                  );
                }),
                const SizedBox(height: 10),
                Obx(() {
                  return channelFeedController.isLoading.value
                      ? CircularProgressIndicator()
                      : BuildJoinedChannelsListWidget();
                }),

                // 2. JOINED CHANNELS (Horizontal List)
                Obx(() {
                  return BuildSectionHeaderWidget(
                    title: AppStrings.allChannels,
                    isShowArrow: (channelFeedController.allChannelResModel.value
                                .pagination?.totalDocs ??
                            0) >
                        20,
                    onTap: () {
                      Get.to(() => ViewAllChannelScreen());
                    },
                  );
                }),
                const SizedBox(height: 10),
                Obx(() {
                  return channelFeedController.isAllChannelLoading.value
                      ? CircularProgressIndicator()
                      : BuildAllChannelsListWidget();
                }),

                // 3. CONTINUE WATCHING (Horizontal List)
                BuildSectionHeaderWidget(
                  title: AppStrings.continueWatching,
                  isShowArrow: false,
                ),
                const SizedBox(height: 10),
                BuildHorizontalVideoListWidget(
                    videos: ottHomeController.continueWatching,
                    isCompact: true),

                const SizedBox(height: 20),

                // 4. RECOMMENDED FOR YOU (Horizontal List)
                BuildSectionHeaderWidget(
                  title: AppStrings.recommendedForYou,
                  isShowArrow: false,
                ),
                const SizedBox(height: 10),
                BuildHorizontalVideoListWidget(
                    videos: ottHomeController.recommended, isCompact: false),

                const SizedBox(height: 100),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              width: Get.width,
              margin: EdgeInsets.symmetric(horizontal: 50, vertical: 90),
              decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: CustomText(
                  AppStrings.comingSoon,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          )
        ],
      ),
    );
    return setupScrollVisibilityNotification(
      controller: scrollController,
      headerHeight: (widget.headerHeight),
      onVisibilityChanged: (visible, offset) {
        final controller = HomeScreenController.to;
        controller.headerOffset.value = offset;
        controller.isVisible.value = visible;
        widget.onHeaderVisibilityChanged?.call(visible);
      },
      child: ottWidget,
    );
  }
}
