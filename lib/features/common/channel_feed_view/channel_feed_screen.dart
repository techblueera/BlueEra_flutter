import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_post_listing_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
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
    return SafeArea(
      child: Obx(() {
        if (channelFeedController.isLoading.value &&
            channelFeedController.channelDataList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "Joined ${formatNumberLikePost(channelFeedController.channelFeedModel.value.pagination?.total ?? 0)} Channels",
                    fontWeight: FontWeight.w500,
                    fontSize: SizeConfig.size16,
                    color: AppColors.mainTextColor,
                  ),
                  CustomText(
                    "What’s New!",
                    fontWeight: FontWeight.w500,
                    fontSize: SizeConfig.size16,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
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
                    onTap: () {
                      final channelData =
                          channelFeedController.channelDataList[index];
                      Get.to(() => ChannelFeedPostListingScreen(
                            channelData: channelData,
                          ));
                    },
                    child: TravelCard(
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
    );
  }
}

class TravelCard extends StatelessWidget {
  TravelCard({super.key, required this.channelModel});

  final ChannelFeedData channelModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // // Avatar
            // CircleAvatar(
            //   radius: 28,
            //   backgroundColor: const Color(0xFFCCE5FF),
            //   child: LocalAssets(imagePath: AppIconAssets.userNew),
            // ),
            // /*CircleAvatar(
            //   radius: 28,
            //   backgroundColor: const Color(0xFFCCE5FF),
            //   child: Image.asset(
            //     'assets/traveler.png', // Replace with your image asset
            //     height: 36,
            //     fit: BoxFit.contain,
            //   ),
            // ),*/
            if (channelModel.logoUrl?.isNotEmpty ?? false)
              InkWell(
                onTap: () {
                  navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: AppLocalizations.of(context)!.imageViewer,
                      // imageUrls: [post?.author.profileImage ?? ''],
                      imageUrls: [channelModel.logoUrl ?? ""],
                      initialIndex: 0,
                    ),
                  );
                },
                child: CachedAvatarWidget(
                    imageUrl: channelModel.logoUrl,
                    size: 40,
                    borderColor: Colors.white,
                    borderRadius: 25),
              ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${channelModel.name}',
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.large,
                    maxLines: 1,
                    color: AppColors.secondaryTextColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ExpandableText(
                    text: channelModel.latestPost?.subTitle ?? "",
                    trimLines: 2,
                    expandMode: ExpandMode.dialog,
                    isReadMoreNewLine: false,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppConstants.OpenSans,
                      fontSize: SizeConfig.small
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Trailing section (time, badge, link)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  formatTime(channelModel.ownership?.claimedAt ?? ""),
                  fontSize: SizeConfig.small,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 6),
                // Container(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //   decoration: const BoxDecoration(
                //     shape: BoxShape.circle,
                //     color: Color(0xFF3B82F6),
                //   ),
                //   child: const Text(
                //     '5',
                //     style: TextStyle(color: Colors.white, fontSize: 12),
                //   ),
                // ),
                const SizedBox(height: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
