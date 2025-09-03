import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import 'package:BlueEra/features/common/reel/widget/reel_popup_menu.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/video_post_meta_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoCard extends StatefulWidget {
  final VideoFeedItem videoItem;
  final VoidCallback onTapOption;
  final Videos videoType;
  final VoidCallback? voidCallback;

  const VideoCard({
    super.key,
    required this.videoItem,
    required this.onTapOption,
    required this.videoType,
    this.voidCallback,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  // final ValueNotifier<String?> activeVideoIdNotifier = ValueNotifier<String?>(null);
  String? creator;
  String? channelProfile;
  String? postedAgo;

  @override
  void initState() {
    super.initState();
    creator = widget.videoItem.channel?.id!=null
        ? widget.videoItem.channel?.name??''
        : widget.videoItem.author?.name??'';
    channelProfile = widget.videoItem.channel?.id!=null
        ? widget.videoItem.channel?.logoUrl??''
        : widget.videoItem.author?.profileImage??'';
    postedAgo = timeAgo(DateTime.parse(widget.videoItem.video?.createdAt??DateTime.now().toIso8601String()));

  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8.0)
        ),
        child: Stack(
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: widget.voidCallback ?? () {
                    if(widget.videoType == Videos.underProgress){
                      return;
                    }

                    Navigator.pushNamed(
                        context,
                        RouteHelper.getVideoPlayerScreenRoute(),
                        arguments: {ApiKeys.videoItem: widget.videoItem}
                    );
                  },
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 18/9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                          child: CachedNetworkImage(
                            imageUrl: widget.videoItem.video?.coverUrl??"",
                            width: SizeConfig.screenWidth, // makes it take full width
                            height: SizeConfig.size170, // fixed height like your original
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: SizeConfig.screenWidth,
                              height: SizeConfig.size140,
                              color: Colors.grey[300],
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: SizeConfig.screenWidth,
                              height: SizeConfig.size140,
                              color: Colors.grey[300],
                              child: LocalAssets(imagePath: AppIconAssets.appIcon),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: SizeConfig.size12,
                        right: SizeConfig.size12,
                        bottom: SizeConfig.size12,
                        child: VideoPostMetaInfo(
                          totalVideoDuration: formatDuration( Duration(seconds: widget.videoItem.video?.duration??0)),
                          totalLikes: widget.videoItem.video?.stats?.likes.toString()??'0',
                        ),
                      ),

                    ],
                  ),
                ),

                GestureDetector(
                  onTap: (){
                    if(widget.videoItem.channel?.id!=null){
                      Navigator.pushNamed(
                          context,
                          RouteHelper.getChannelScreenRoute(),
                          arguments: {
                            ApiKeys.argAccountType: widget.videoItem.author?.accountType,
                            ApiKeys.channelId: widget.videoItem.channel?.id,
                            ApiKeys.authorId: widget.videoItem.author?.id
                          }
                      );
                    }else{
                      /// we don't have channel so will call profile
                      if (widget.videoItem.author?.accountType?.toUpperCase() == AppConstants.individual) {
                        if (widget.videoItem.author?.id == userId) {
                          navigatePushTo(context, PersonalProfileSetupScreen());
                        } else {
                          Get.to(() => VisitProfileScreen(authorId: widget.videoItem.author?.id??''));
                        }
                      }else{
                        if (widget.videoItem.author?.id == businessId) {
                          navigatePushTo(context, BusinessOwnProfileScreen());
                        } else {
                          Get.to(() => VisitBusinessProfile(businessId: widget.videoItem.author?.id??''));
                        }
                      }
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size5, horizontal: SizeConfig.size10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: ()=> navigatePushTo(
                            context,
                            ImageViewScreen(
                              appBarTitle: '',
                              // imageUrls: [post?.author.profileImage ?? ''],
                              imageUrls: [channelProfile??''],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                widget.videoItem.video?.title??'',
                                color: AppColors.mainTextColor,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w400,
                                maxLines: 2,
                              ),
                              SizedBox(height: SizeConfig.size2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      "${creator} ${widget.videoItem.video?.stats?.views.toString() ?? '0'} views ${postedAgo}",
                                      fontSize: SizeConfig.small11,
                                      color: AppColors.secondaryTextColor,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),

                        if(widget.videoItem.channel?.id!=null)
                          if(widget.videoItem.channel?.id != channelId)
                            IconButton(
                              onPressed: ()=> widget.onTapOption(),
                              icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
                            )
                          else
                            ReelVideoPopUpMenu(
                                videoFeedItem: widget.videoItem,
                                popUpMenuColor: AppColors.black,
                                videoType: widget.videoType
                            )
                        else
                          if(widget.videoItem.author?.accountType == AppConstants.individual)
                            if(widget.videoItem.author?.id != userId)
                              IconButton(
                                onPressed: ()=> widget.onTapOption(),
                                icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
                              )
                            else
                              ReelVideoPopUpMenu(
                                  videoFeedItem: widget.videoItem,
                                  popUpMenuColor: AppColors.black,
                                  videoType: widget.videoType
                              )
                          else if(widget.videoItem.author?.accountType == AppConstants.business)
                            if(widget.videoItem.author?.id != businessId)
                              IconButton(
                                onPressed: widget.onTapOption,
                                icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
                              )
                            else
                              ReelVideoPopUpMenu(
                                  videoFeedItem: widget.videoItem,
                                  popUpMenuColor: AppColors.black,
                                  videoType: widget.videoType
                              ),


                      ],
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
