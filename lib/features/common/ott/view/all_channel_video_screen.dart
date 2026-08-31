import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/ott/binding/ott_video_player_binding.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/ott/view/ott_video_player_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For DateFormat

class VideoListScreen extends StatefulWidget {
  VideoListScreen(
      {super.key, required this.channelID, required this.channelName});

  final String channelID;
  final String channelName;

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final channelFeedController = Get.find<ChannelFeedController>();
  final ScrollController _scrollController = ScrollController();

  apiCalling({required bool isLoadMore}) {
    channelFeedController.getAllChannelVideoData(
        loadMore: isLoadMore, channelId: widget.channelID);
  }

  @override
  void initState() {
    super.initState();
    channelFeedController.allVideoChannelDataList.clear();
    apiCalling(isLoadMore: false);
    // Listener for Pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        apiCalling(isLoadMore: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.channelName.capitalizeFirst,
      ),
      body: Obx(() {
        if (channelFeedController.isAllVideoChannelLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (channelFeedController.allVideoChannelDataList.isNotEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              apiCalling(isLoadMore: false);
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: channelFeedController.allVideoChannelDataList.length +
                  (channelFeedController.isAllVideoChannelLoading.value
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                // Loading indicator at bottom
                if (index ==
                    channelFeedController.allVideoChannelDataList.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                final video =
                    channelFeedController.allVideoChannelDataList[index];
                return InkWell(
                    onTap: () {
                      Get.to(
                          () => OttVideoPlayerScreen(
                                videoItems: video,
                              ),
                          binding: OttVideoPlayerBinding());
                    },
                    child: _buildVideoItem(video));
              },
            ),
          );
        }
        if (channelFeedController.allVideoChannelDataList.isEmpty) {
          return Center(child: CustomText(AppStrings.noVideoChannelFound));
        }
        return SizedBox.shrink();
      }),
    );
  }

  Widget _buildVideoItem(var video) {
    // Format Date: 2025-12-05 -> 5 Dec 2025
    DateTime parsedDate = DateTime.parse(video.createdAt);
    String formattedDate = DateFormat('d MMM yyyy').format(parsedDate);

    // Format Duration
    String durationStr =
        "${(video.duration / 60).ceil()}m"; // e.g. 47s -> 1m, 1200s -> 20m

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      height: 100, // Fixed height for consistency
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Thumbnail Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 160,
                  height: 100,
                  color: Colors.grey[900],
                  child: video.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: video.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                              child: Icon(Icons.image, color: Colors.grey)),
                          errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error, color: Colors.grey)),
                        )
                      : const Center(
                          child: Icon(Icons.movie_creation_outlined,
                              color: Colors.white24, size: 40)),
                ),
              ),
              // Play Button Overlay (Bottom Left)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Right: Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                CustomText(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 4),

                // Metadata Row (Date • Duration)
                // Note: API doesn't give Season/Episode, so we use Date • Time
                CustomText(
                  "$formattedDate • $durationStr",
                  color: AppColors.secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 4),

                // Description
                Expanded(
                  child: CustomText(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.secondaryTextColor,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
