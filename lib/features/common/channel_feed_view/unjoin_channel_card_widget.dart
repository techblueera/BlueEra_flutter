import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_joined_user_screen.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/widget/new_profile_header_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnjoinChannelCardWidget extends StatelessWidget {
  UnjoinChannelCardWidget({super.key, required this.channelModel, required this.index});

  final ChannelFeedData channelModel;
  final int index;
  final channelFeedController = Get.find<ChannelFeedController>();

  String displayUsername(String username) {
    return username.length > 5
        ? '@${username.substring(0, 5)}...'
        : '@$username';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: [channelModel.logoUrl ?? ""],
                        initialIndex: 0,
                      ),
                    );
                  },
                  child: CachedAvatarWidget(
                      imageUrl: channelModel.logoUrl,
                      size: 54,
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
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.large,
                        maxLines: 1,
                        color: AppColors.black,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomText(
                            displayUsername(channelModel.username ?? ""),
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.medium,
                            overflow: TextOverflow.ellipsis,

                            maxLines: 2,
                          ),
                          const SizedBox(width: 20),


                          //  _divider(),
                          InkWell(
                            onTap: () {
                              Get.to(() => ChannelJoinedUserScreen(
                                  userID: channelModel.id ?? ""));
                            },
                            child: statBlock(AppStrings.members,
                                channelModel.followers.toString()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing section (time, badge, link)
                Padding(
                  padding:  EdgeInsets.only(right: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        formatClaimedAt(channelModel.ownership?.claimedAt ?? ""),
                        fontSize: SizeConfig.small11,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),              ],
            ),
            if (channelModel.latestPost != null) ...[
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.only(left: 25.0),
                child: FeedCard(
                  post: channelModel.latestPost,
                  index: index,
                  postFilteredType: PostType.otherChannelPosts,
                  isFromDetailsScreen: true,
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
