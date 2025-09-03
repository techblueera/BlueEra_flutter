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
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
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
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/api/apiService/api_keys.dart';

class AutoPlayVideoCard extends StatefulWidget {
  final VideoFeedItem videoItem;
  final ValueNotifier<bool>? globalMuteNotifier;
  final Videos videoType;
  final VoidCallback onTapOption;

  const AutoPlayVideoCard({
    super.key,
    required this.videoItem,
    this.globalMuteNotifier,
    required this.videoType,
    required this.onTapOption,
  });

  @override
  State<AutoPlayVideoCard> createState() => _AutoPlayVideoCardState();
}

class _AutoPlayVideoCardState extends State<AutoPlayVideoCard> {

  @override
  void dispose() {
    final videoManager = Get.find<SimplePriorityVideoManager>();
    videoManager.removeVideo(widget.videoItem.videoId??'');
    super.dispose();
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    final videoManager = Get.find<SimplePriorityVideoManager>();

    print('Video ${widget.videoItem.videoId} visibility: ${info.visibleFraction}');

    videoManager.updateVideoVisibility(
      widget.videoItem.videoId??'',
      widget.videoItem.video?.videoUrl ?? '',
      info.visibleFraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SimplePriorityVideoManager videoManager = Get.put(SimplePriorityVideoManager());

    final creator = widget.videoItem.channel?.id != null
        ? widget.videoItem.channel?.name ?? ''
        : widget.videoItem.author?.name ?? '';
    final channelProfile = widget.videoItem.channel?.id != null
        ? widget.videoItem.channel?.logoUrl ?? ''
        : widget.videoItem.author?.profileImage ?? '';
    final postedAgo = timeAgo(
      DateTime.parse(
        widget.videoItem.video?.createdAt ?? DateTime.now().toIso8601String(),
      ),
    );

    return GestureDetector(
      onTap: () {
        if (widget.videoType == Videos.underProgress) return;
        Navigator.pushNamed(
          context,
          RouteHelper.getVideoPlayerScreenRoute(),
          arguments: {ApiKeys.videoItem: widget.videoItem},
        );
      },
      child: Card(
        elevation: 0,
        color: AppColors.white,
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide.none,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: VisibilityDetector(
                  key: ValueKey(widget.videoItem.videoId),
                  onVisibilityChanged: _handleVisibilityChange,
                  child: Obx(() {
                    final isCurrent = videoManager.currentIndex.value == widget.videoItem.videoId.hashCode;
                    final controller = videoManager.controller;
                    final isScrolling = videoManager.isScrolling.value;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail
                        CachedNetworkImage(
                          imageUrl: widget.videoItem.video?.coverUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),

                        // Video Player
                        if (isCurrent && controller != null && controller.value.isInitialized)
                          VideoPlayer(controller),

                        // Loading indicator during scroll
                        if (isScrolling && isCurrent)
                          Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 8),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Play indicator
                        // if (isCurrent)
                        //   Positioned(
                        //     top: 8,
                        //     right: 8,
                        //     child: Container(
                        //       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        //       decoration: BoxDecoration(
                        //         color: Colors.red,
                        //         borderRadius: BorderRadius.circular(3),
                        //       ),
                        //       child: const Text(
                        //         'PLAYING',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 9,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //     ),
                        //   ),


                        // Mute Button
                        if (isCurrent && controller != null)
                          Positioned(
                            top: SizeConfig.size12,
                            right: SizeConfig.size10,
                            child: GestureDetector(
                              onTap: videoManager.toggleMute,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size10,
                                  vertical: SizeConfig.size4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blackCC,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: videoManager.isMuted,
                                  builder: (context, isMuted, _) {
                                    // return LocalAssets(
                                    //   imagePath: isMuted
                                    //       ? AppIconAssets.volumeOffIcon
                                    //       : AppIconAssets.volumeOnIcon,
                                    // );
                                    return Icon(isMuted ? Icons.volume_off : Icons.volume_up, color: AppColors.white, size: SizeConfig.size20);
                                  },
                                ),
                              ),
                            ),
                          ),


                        // Mute Button
                        // if (isCurrent && controller != null)
                        //   Positioned(
                        //     top: SizeConfig.size12,
                        //     left: SizeConfig.size12,
                        //     child: GestureDetector(
                        //       onTap: videoManager.toggleMute,
                        //       child: Container(
                        //         padding: EdgeInsets.all(SizeConfig.size8),
                        //         decoration: BoxDecoration(
                        //           color: Colors.black54,
                        //           borderRadius: BorderRadius.circular(20),
                        //         ),
                        //         child: ValueListenableBuilder<bool>(
                        //           valueListenable: videoManager.isMuted,
                        //           builder: (context, isMuted, _) {
                        //             return Icon(
                        //               isMuted ? Icons.volume_off : Icons.volume_up,
                        //               color: Colors.white,
                        //               size: 16,
                        //             );
                        //           },
                        //         ),
                        //       ),
                        //     ),
                        //   ),

                        // Video Meta Info
                        Positioned(
                          left: SizeConfig.size12,
                          right: SizeConfig.size12,
                          bottom: SizeConfig.size12,
                          child: VideoPostMetaInfo(
                            totalLikes: widget.videoItem.video?.stats?.likes.toString() ?? '0',
                            totalVideoDuration: formatDuration(
                              Duration(
                                seconds: widget.videoItem.video?.duration ?? 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              // Footer - Your existing footer code
              GestureDetector(
                onTap: () => _openProfile(context, widget.videoItem),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              widget.videoItem.video?.title ?? '',
                              color: AppColors.mainTextColor,
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w400,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: SizeConfig.size2),
                            Row(
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
                      if (widget.videoItem.author?.accountType == AppConstants.individual)
                        if (widget.videoItem.author?.id != userId)
                          IconButton(
                            onPressed: widget.onTapOption,
                            icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
                          )
                        else
                          ReelVideoPopUpMenu(
                            videoFeedItem: widget.videoItem,
                            popUpMenuColor: AppColors.black,
                            videoType: Videos.videoFeed,
                          )
                      else if (widget.videoItem.author?.accountType == AppConstants.business)
                        if (widget.videoItem.author?.id != businessUserId)
                          IconButton(
                            onPressed: widget.onTapOption,
                            icon: LocalAssets(imagePath: AppIconAssets.blockIcon),
                          )
                        else
                          ReelVideoPopUpMenu(
                            videoFeedItem: widget.videoItem,
                            popUpMenuColor: AppColors.black,
                            videoType: Videos.videoFeed,
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, VideoFeedItem videoItem) {
    if (videoItem.channel?.id != null) {
      Navigator.pushNamed(
        context,
        RouteHelper.getChannelScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: videoItem.author?.accountType,
          ApiKeys.channelId: videoItem.channel?.id,
          ApiKeys.authorId: videoItem.author?.id
        },
      );
    } else {
      if (videoItem.author?.accountType?.toUpperCase() == AppConstants.individual) {
        if (videoItem.author?.id == userId) {
          navigatePushTo(context, PersonalProfileSetupScreen());
        } else {
          Get.to(() => VisitProfileScreen(authorId: videoItem.author?.id ?? ''));
        }
      } else {
        if (videoItem.author?.id == businessUserId) {
          navigatePushTo(context, BusinessOwnProfileScreen());
        } else {
          Get.to(() => VisitBusinessProfile(businessId: videoItem.author?.id ?? ''));
        }
      }
    }
  }
}


