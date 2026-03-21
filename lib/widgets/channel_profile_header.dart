import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_meta_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelProfileHeader extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? userName;
  final String subtitle;
  final double avatarSize;
  final Color? titleColor;
  final Color? subTitleColor;
  final Color? userNameColor;
  final VoidCallback? onTapAvatar;
  final Color? borderColor;
  final bool? isVerifiedTickShow;
  final String? postedAgo;

  const ChannelProfileHeader(
      {Key? key,
      required this.imageUrl,
      required this.title,
      required this.subtitle,
      this.onTapAvatar,
      this.userName,
      this.avatarSize = 42.0,
      this.titleColor,
      this.subTitleColor,
      this.userNameColor,
      this.borderColor,
      this.isVerifiedTickShow = false,
      this.postedAgo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imageUrl.isNotEmpty)
            InkWell(
              onTap: onTapAvatar ??
                  () {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        appBarTitle:AppStrings.imageViewer,
                        // imageUrls: [post?.author.profileImage ?? ''],
                        imageUrls: [imageUrl],
                        initialIndex: 0,
                      ),
                    );
                  },
              child: CachedAvatarWidget(
                  imageUrl: imageUrl,
                  size: avatarSize,
                  borderColor: borderColor,
                  borderRadius: 25),
            ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: Get.width,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: CustomText(
                          title,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: titleColor ?? AppColors.secondaryTextColor,
                        ),
                      ),
                      if (userName != null && (userName?.isNotEmpty ?? false))
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: CustomText(
                              " @$userName",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                              color: userNameColor??AppColors.shadowColor,
                            ),
                          ),
                        ),
                      if (isVerifiedTickShow ?? false)
                        Padding(
                          padding: EdgeInsets.only(
                              left: SizeConfig.size5, top: SizeConfig.size4),
                          child: LocalAssets(
                              imagePath: AppIconAssets.verifiedTickIcon),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        // The light blue background color from the image
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10), // Rounded "pill" shape
                      ),
                      child: CustomText(
                        subtitle, // e.g., "Politician - PM Of India"
                        fontSize: SizeConfig.small, // Adjust based on your SizeConfig.small
                        fontWeight: FontWeight.w500, // Medium weight looks closer to the UI
                        color: AppColors.primaryColor, // The blue text color
                      ),
                    ),
                    // CustomText(
                    //   subtitle,
                    //   fontSize: SizeConfig.small,
                    //   fontWeight: FontWeight.w400,
                    //   color: subTitleColor ?? AppColors.secondaryTextColor,
                    // ),
                    if (postedAgo?.isNotEmpty ?? false) ...[
                      SizedBox(width: SizeConfig.size8),
                      PostMetaInfo(
                        timeAgoText:  timeAgo(postedAgo != null
                            ? DateTime.parse(postedAgo??"")
                            : DateTime.now()),
                        fontSize: SizeConfig.extraSmall,
                      ),
                    ]
                  ],
                ),

                // Add optional follower/follow section if needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}
