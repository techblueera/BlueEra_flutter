import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';

class ChannelCardWidget extends StatelessWidget {
  ChannelCardWidget({super.key, required this.channelModel});

  final ChannelFeedData channelModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

              InkWell(
                onTap: () {
                  navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: AppStrings.imageViewer,
                      // imageUrls: [post?.author.profileImage ?? ''],
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
                  CustomText(
                  channelModel.latestPost?.subTitle,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppConstants.OpenSans,
                      fontSize: SizeConfig.medium,
                    overflow: TextOverflow.ellipsis,

                    maxLines: 2,
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
            ),
          ],
        ),
      ),
    );
  }
}
