import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/widget/reel_video_popup_menu.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';


class CommonVideoCard extends StatelessWidget {
  final Widget mainContent; // AspectRatio part (thumbnail OR autoplay video)
  final ShortFeedItem videoItem;
  final VideoType videoType;
  final VoidCallback onTapOption;
  final VoidCallback? onTapCard;
  final List<BoxShadow>? boxShadow;

  const CommonVideoCard({
    super.key,
    required this.mainContent,
    required this.videoItem,
    required this.videoType,
    required this.onTapOption,
    this.onTapCard,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final creator = videoItem.channel?.id != null
        ? videoItem.channel?.name ?? ''
        : videoItem.author?.name ?? '';
    final channelProfile = videoItem.channel?.id != null
        ? videoItem.channel?.logoUrl ?? ''
        : videoItem.author?.profileImage ?? '';
    final postedAgo = timeAgo(
      DateTime.parse(videoItem.video?.createdAt ?? DateTime.now().toIso8601String()),
    );

    return GestureDetector(
      onTap: () {
        if (videoType == VideoType.underProgress) return;
        if (onTapCard != null) {
          onTapCard!();
        }
      },
      child: Card(
        child: Container(
          // elevation: 0,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: boxShadow
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                // 👇 main content (different per card type)
                mainContent,
        
                // 👇 common footer
                GestureDetector(
                  onTap:(){
                    if (isGuestUser()) {
                      createProfileScreen();
        
                      return;
                    }
                    onTapOption();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size5,
                      horizontal: SizeConfig.size10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => navigatePushTo(
                            context,
                            ImageViewScreen(
                              appBarTitle: '',
                              imageUrls: [channelProfile],
                              initialIndex: 0,
                            ),
                          ),
                          child: CachedAvatarWidget(
                            imageUrl: channelProfile,
                            size: SizeConfig.size40,
                            borderRadius: SizeConfig.size20,
                            borderColor: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child: InkWell(
                            onTap: ()=> _openProfile(context, videoItem),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  videoItem.video?.title ?? '',
                                  color: AppColors.mainTextColor,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: SizeConfig.size2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomText(
                                        "$creator ${videoItem.video?.stats?.views.toString() ?? '0'} views $postedAgo",
                                        fontSize: SizeConfig.small,
                                        color: AppColors.secondaryTextColor,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        _buildOptions(videoItem),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(ShortFeedItem videoItem) {
    // 1️⃣ If channel exists
    if (videoItem.channel?.id != null) {
      if (videoItem.channel?.id != channelId) {
        return IconButton(
          onPressed:(){
            if (isGuestUser()) {
              createProfileScreen();

              return;
            }
            onTapOption();
          },
          icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
        );
      }
      return ReelVideoPopUpMenu(
        videoFeedItem: videoItem,
        popUpMenuColor: AppColors.black,
        video: videoType,
      );
    }

    // 2️⃣ If Individual account
    if (videoItem.author?.accountType == AppConstants.individual) {
      final isMyProfile = videoItem.author?.id == userId;
      if (isMyProfile) {
        return ReelVideoPopUpMenu(
          videoFeedItem: videoItem,
          popUpMenuColor: AppColors.black,
          video: videoType,
        );
      }
      return IconButton(
        onPressed:(){
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          onTapOption();
        },        icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
      );
    }

    // 3️⃣ If Business account
    if (videoItem.author?.accountType == AppConstants.business) {
      final isMyBusiness = videoItem.author?.id == userId;
      if (isMyBusiness) {
        return ReelVideoPopUpMenu(
          videoFeedItem: videoItem,
          popUpMenuColor: AppColors.black,
          video: videoType,
        );
      }
      return IconButton(
        onPressed:(){
          if (isGuestUser()) {
            createProfileScreen();

            return;
          }
          onTapOption();
        },        icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
      );
    }

    // 4️⃣ Fallback
    return const SizedBox.shrink();
  }

  void _openProfile(BuildContext context, ShortFeedItem videoItem) {
    // 1️⃣ If channel exists → open channel screen
    if (videoItem.channel?.id != null) {
      Navigator.pushNamed(
        context,
        RouteHelper.getChannelScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: videoItem.author?.accountType,
          ApiKeys.channelId: videoItem.channel?.id,
          ApiKeys.authorId: videoItem.author?.id,
        },
      );
      return;
    }

    // 2️⃣ If Individual account
    if (videoItem.author?.accountType?.toUpperCase() == AppConstants.individual) {
      final isMyProfile = videoItem.author?.id == userId;
      if (isMyProfile) {
        navigatePushTo(context, PersonalProfileSetupScreen());
      } else {
        Get.to(() => NewVisitProfileScreen(authorId: videoItem.author?.id ?? '', screenFromName: AppConstants.feedScreen,));
      }
      return;
    }

    // 3️⃣ If Business account
    if (videoItem.author?.accountType?.toUpperCase() == AppConstants.business) {
      final isMyBusiness = videoItem.author?.id == userId;
      if (isMyBusiness) {
        navigatePushTo(context, BusinessOwnProfileScreen());
      } else {
        Get.to(() => VisitBusinessProfileNew(businessId: videoItem.author?.id ?? '', screenName:  AppConstants.feedScreen,));
      }
      return;
    }
  }

}
