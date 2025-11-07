import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_joined_user_screen.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/widget/new_profile_header_widget.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnjoinChannelCardWidget extends StatelessWidget {
  UnjoinChannelCardWidget({super.key, required this.channelModel});

  final ChannelFeedData channelModel;
  final channelFeedController = Get.find<ChannelFeedController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        appBarTitle: AppLocalizations.of(context)!.imageViewer,
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
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size10,
                            vertical: SizeConfig.size4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.secondaryTextColor),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: CustomText(
                          "@${channelModel.username}",
                          fontSize: SizeConfig.extraSmall,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          statBlock("Post", channelModel.posts.toString()),
                          const SizedBox(width: 20),

                          //  _divider(),
                          InkWell(
                            onTap: () {
                              Get.to(() => ChannelJoinedUserScreen(
                                  userID: channelModel.id ?? ""));
                            },
                            child: statBlock("Members",
                                channelModel.followers.toString()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing section (time, badge, link)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                        onTap: () {
                          channelFeedController.toggleFollow(
                              channelId: channelModel.id ?? ""); // 👈 Local toggle
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 4),
                          decoration: BoxDecoration(
                            color: channelModel.isFollowing
                                ? AppColors.colorTextDarkGrey
                                : AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              CustomText(
                                channelModel.isFollowing ? "Unjoin" : "Join",
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.size10,
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.person_add_alt,
                                color: Colors.white,
                                size: 14,
                              )
                            ],
                          ),
                        )
                        ),

                  ],
                ),
              ],
            ),
            if(channelModel.latestPost!=null)...[

              SizedBox(height: 10,),
              FeedCard(post: channelModel.latestPost, index: 0, postFilteredType: PostType.otherChannelPosts,isFromDetailsScreen: true,)

            ],

          ],
        ),
      ),
    );
  }
}
