import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/common_methods.dart' as CommonMethods;
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/widget/feed_action_widget.dart';
import 'package:BlueEra/features/common/reel/controller/single_video_player_controller.dart';
import 'package:BlueEra/features/common/reel/widget/video_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../business/visit_business_profile/view/visit_business_profile_new.dart';

class DeeplinkVideoScreen extends StatefulWidget {
  // final String videoId;
  final ShortFeedItem? videoItem; // Optional, will be fetched if null
  
  const DeeplinkVideoScreen({
    super.key, 
    // required this.videoId,
    required this.videoItem,
  });

  @override
  State<DeeplinkVideoScreen> createState() => _DeeplinkVideoScreenState();
}

class _DeeplinkVideoScreenState extends State<DeeplinkVideoScreen> {
  final VideoController videoController = Get.put(VideoController());
  late final SingleVideoPlayerController videoPlayerController;
  final ScrollController _scrollController = ScrollController();
  bool isCollapsed = false;
  final GlobalKey _contentKey = GlobalKey();
  bool _isMeasured = false;
  double _calculatedHeight = SizeConfig.size300;
  bool isLoading = true;
  String? errorMessage;
  bool _isVideoSharing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the video player controller
    videoPlayerController = Get.put(
      SingleVideoPlayerController(), 
      tag: widget.videoItem?.video?.id ?? ''
    );
    
    _initializeVideoData();
  }

  Future<void> _initializeVideoData() async {
    try {
      print('DEEPLINK_DEBUG: _initializeVideoData called');
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      if (widget.videoItem != null) {
        // Use provided video item
        print('DEEPLINK_DEBUG: Using provided videoItem');
        videoController.videoFeedItem = widget.videoItem;
        _setupVideoPlayer();
      } else {
        // Fetch video data by ID
        print('DEEPLINK_DEBUG: Fetching video by ID');
   
      }
    } catch (e) {
      print('DEEPLINK_DEBUG: Error in _initializeVideoData: $e');
      setState(() {
        errorMessage = 'Failed to load video: $e';
        isLoading = false;
      });
    }
  }

  

  void _setupVideoPlayer() {
    if (videoController.videoFeedItem != null) {
      /// measure height for sliver approach
      _measureHeaderHeight();

      /// fetch more videos and setup listeners
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideo();
        _setupVideoData();
        videoController.getAllFeedVideos(isInitialLoad: true);
      });

      _setupScrollListener();
      checkVideoSavedInDb();
      _scheduleVideoView();
      
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeVideo() {
    videoPlayerController.initializeVideo(
      videoController.videoFeedItem!,
      autoPlay: true, // videoPlayerController.interstitialService.shouldShowAdOnThisVisit() ? false : true,
      showAd: false, // videoPlayerController.interstitialService.shouldShowAdOnThisVisit() ? true : false,
      onAdShow: () {
        // log('Ad is showing - video paused');
      },
      onAdClosed: () {
        // log('Ad closed - video resumed');
      },
    );
  }

  void _setupVideoData() {
    videoController.isLiked.value = 
        videoController.videoFeedItem?.interactions?.isLiked ?? false;
    videoController.likes.value = 
        videoController.videoFeedItem?.video?.stats?.likes ?? 0;
    videoController.comments.value = 
        videoController.videoFeedItem?.video?.stats?.comments ?? 0;

    if (videoController.videoFeedItem?.channel?.id != null) {
      videoController.isChannelFollow.value = 
          videoController.videoFeedItem?.channel?.isFollowing ?? false;
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (videoController.isMoreDataAvailable && videoController.isLoadingMore.isFalse) {
          videoController.getAllFeedVideos();
        }
      }
    });
  }

  void _scheduleVideoView() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && videoController.videoFeedItem?.video?.id != null) {
        videoController.videoView(
          videoId: videoController.videoFeedItem!.video!.id!,
        );
      }
    });
  }

  void checkVideoSavedInDb() {
    videoController.isVideoSavedInDb.value = HiveServices()
        .isVideoSaved(videoController.videoFeedItem?.videoId ?? '');
  }

  void _measureHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _contentKey.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final height = box.size.height;

        debugPrint("Re-measured height: $height");

        if (mounted) {
          setState(() {
            _isMeasured = true;
            _calculatedHeight = height;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    Get.delete<SingleVideoPlayerController>(tag: widget.videoItem?.video?.id ?? '');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _buildErrorWidget()
                : Column(
                    children: [
                      // 🎥 Video Player Section with centralized controller
                      _buildVideoPlayer(),

                      // 📏 Measured or Scrollable Content
                      _isMeasured
                          ? Expanded(child: _buildMeasuredContent())
                          : _buildPreMeasureWidget(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: SizeConfig.size60,
              color: AppColors.grey99,
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              errorMessage!,
              fontSize: SizeConfig.large,
              textAlign: TextAlign.center,
              color: AppColors.grey99,
            ),
            SizedBox(height: SizeConfig.size20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _initializeVideoData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: 16/9,
      child: Obx(() {
        if (videoPlayerController.isVideoLoading.value) {
          return videoPlayerController.getVideoLoadingWidget();
        }

        if (videoPlayerController.isVideoError.value) {
          return videoPlayerController.getVideoErrorWidget();
        }

        if (videoPlayerController.hasController &&
            videoPlayerController.isVideoInitialized.value) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                  color: AppColors.black,
                  child: Chewie(controller: videoPlayerController.chewieController!)),
              // You can add additional overlays here if needed
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      }),
    );
  }

  Widget _buildPreMeasureWidget() {
    return Container(
      key: _contentKey,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: _buildExpandedWidget(),
      ),
    );
  }

  Widget _buildMeasuredContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 🧠 Collapsing SliverAppBar
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          expandedHeight: _calculatedHeight,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0.0,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.only(
                top: SizeConfig.size15,
                left: SizeConfig.size15,
                right: SizeConfig.size15,
              ),
              child: _buildExpandedWidget(),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Obx(() {
            final videos = videoController.videoFeedPosts;
            final isLoadingMore = videoController.isLoadingMore.value;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: SizeConfig.size5,
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                bottom: SizeConfig.size15,
              ),
              itemCount: videos.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == videos.length && isLoadingMore) {
                  return CommonMethods.staggeredDotsWaveLoading();
                }

                final videoFeedItem = videos[index];
                return VideoCard(
                  videoItem: videoFeedItem,
                  voidCallback: () => _navigateToVideoPlayer(videoFeedItem),
                  onTapOption: () => _showBlockDialog(videoFeedItem),
                  videoType: VideoType.videoFeed,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Future<void> _navigateToVideoPlayer(ShortFeedItem videoFeedItem) async {
    // Pause current video before navigation using centralized controller
    videoPlayerController.pauseForNavigation();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeeplinkVideoScreen(
          videoItem: videoFeedItem,
        ),
      ),
    );

    // Resume after coming back using centralized controller
    videoPlayerController.resumeAfterNavigation();
  }

  void _showBlockDialog(ShortFeedItem videoFeedItem) {

    openBlockSelectionDialog(
        context: context,
        reportType: 'VIDEO_POST',
        userId: videoFeedItem.video?.userId??'',
        contentId: videoFeedItem.video?.id??'',
        userBlockVoidCallback: () async {
          await Get.find<VideoController>().userBlocked(
            videoType: VideoType.videoFeed,
            otherUserId: videoFeedItem.video?.userId ?? '',
          );
        },
        reportCallback: (params){
          Get.find<VideoController>().videoPostReport(
              videoId: videoFeedItem.video?.id??'',
              videoType: VideoType.videoFeed,
              params: params
          );
        }
    );
  }

  Widget _buildExpandedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Like , comment , repost, saved
        _buildActions(),

        SizedBox(height: SizeConfig.size6),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                    color: AppColors.black25,
                    blurRadius: 4
                )
              ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                videoController.videoFeedItem?.video?.title ?? '',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
              ),

              SizedBox(height: SizeConfig.size15),

              ExpandableText(
                text: videoController.videoFeedItem?.video?.description ?? '',
                trimLines: 2,
                style: TextStyle(
                  color: AppColors.mainTextColor,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                ),
                expandMode: ExpandMode.dialog,
                dialogTitle: 'Video Description',
              ),

              SizedBox(height: SizeConfig.size15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: ()=> _openProfile(),
                      child: ChannelProfileHeader(
                        imageUrl: videoController.videoFeedItem?.channel?.id != null
                            ? videoController.videoFeedItem?.channel?.logoUrl ?? ''
                            : videoController.videoFeedItem?.author?.profileImage ?? '',
                        title: videoController.videoFeedItem?.channel?.id != null
                            ? videoController.videoFeedItem?.channel?.name ?? ''
                            : videoController.videoFeedItem?.author?.username ?? '',
                        subtitle: videoController.videoFeedItem?.channel?.id != null
                            ? videoController.videoFeedItem?.channel?.username ?? ''
                            : (videoController.videoFeedItem?.author?.accountType == AppConstants.individual)
                            ? videoController.videoFeedItem?.author?.designation ?? "OTHERS"
                            : videoController.videoFeedItem?.author?.designation ?? '',
                        avatarSize: SizeConfig.size40,
                        isVerifiedTickShow: true,
                      ),
                    ),
                  ),

                  if (videoController.videoFeedItem?.channel?.id != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Obx(() => CustomBtn(
                          onTap: () {
                            if (isGuestUser()) {
                              createProfileScreen();
                              return;
                            }
                            if (videoController.isChannelFollow.isTrue) {
                              videoController.unFollowChannel(
                                  channelId: videoController.videoFeedItem?.channel?.id ?? '',
                                  videoType: VideoType.videoFeed
                              );
                            } else {
                              videoController.followChannel(
                                  channelId: videoController.videoFeedItem?.channel?.id ?? '',
                                  videoType: VideoType.videoFeed
                              );
                            }
                          },
                          title: videoController.isChannelFollow.isTrue ? "Following" : "Follow",
                          textColor: AppColors.primaryColor,
                          width: SizeConfig.size70,
                          height: SizeConfig.size25,
                          borderColor: AppColors.primaryColor,
                          bgColor: AppColors.primaryColor.withValues(alpha: 0.1),
                        )),
                        SizedBox(height: SizeConfig.size4),
                      ],
                    )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActions() {
    return Obx(() => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
                color: AppColors.black25,
                blurRadius: 4
            )
          ]
      ),
      child: PostActionsBar(
        isLiked: videoController.isLiked.value,
        totalLikes: videoController.likes.value,
        totalComment: videoController.comments.value,
        totalRepost: videoController.videoFeedItem?.video?.stats?.shares ?? 0,
        isPostAlreadySaved: videoController.isVideoSavedInDb.value,
        onLikeDislikePressed: _onLikeDislikePressed,
        onCommentButtonPressed: _onCommentPressed,
        onSavedUnSavedButtonPressed: _onSavedPressed,
        onShareButtonPressed: () async {
          await _shareVideoSimple();
        },
      ),
    ));
  }

  /// Simple, consistent share experience (like header_widget.dart)
  Future<void> _shareVideoSimple() async {
    // Prevent multiple calls
    if (_isVideoSharing) return;

    try {
      _isVideoSharing = true; // Set flag to prevent multiple calls

      final id = widget.videoItem?.video?.id ?? widget.videoItem?.videoId ?? '';
      final link = videoDeepLink(videoId: id);
      final title = widget.videoItem?.video?.title ?? 'BlueEra Video';

      final message = "Watch on BlueEra App:\n$link\n";

      await SharePlus.instance.share(ShareParams(
        text: message,
        subject: title,
      ));

    } catch (e) {
      print("Video share failed: $e");
    } finally {
      _isVideoSharing = false; // Reset flag
    }
  }

  Future<void> _onLikeDislikePressed() async {
    if (videoController.isLiked.isTrue) {
      await Get.find<VideoController>().videoUnLike(
          videoId: videoController.videoFeedItem?.video?.id ?? '0'
      );
      log('videoController after unlike video--> ${videoController.isLiked.value}');
      // Update widget state if available
      if (widget.videoItem != null) {
        widget.videoItem!.interactions?.isLiked = false;
        widget.videoItem!.video?.stats?.likes = (widget.videoItem!.video?.stats?.likes ?? 1) - 1;
      }
    } else {
      await Get.find<VideoController>().videoLike(
          videoId: videoController.videoFeedItem?.video?.id ?? '0'
      );
      // Update widget state if available
      if (widget.videoItem != null) {
        widget.videoItem!.interactions?.isLiked = true;
        widget.videoItem!.video?.stats?.likes = (widget.videoItem!.video?.stats?.likes ?? 1) + 1;
      }
    }
  }

  void _onCommentPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
          id: videoController.videoFeedItem?.video?.id ?? '0',
          totalComments: videoController.videoFeedItem?.video?.stats?.comments ?? 0,
          commentType: CommentType.video,
          onNewCommentCount: (int newCommentCount) {
            videoController.comments.value = newCommentCount;
            if (widget.videoItem != null) {
              widget.videoItem!.video?.stats?.comments = videoController.comments.value;
            }
          }
      ),
    );
  }

  Future<void> _onSavedPressed() async {
    videoController.isVideoSavedInDb.value = await Get.find<VideoController>().saveVideosToLocalDB(
        videoFeedItem: videoController.videoFeedItem!
    );
    log('isvideo saved--> ${videoController.isVideoSavedInDb.value}');
  }

  void _openProfile() {
    if(videoController.videoFeedItem?.channel?.id!=null){
      Navigator.pushNamed(
          context,
          RouteHelper.getChannelScreenRoute(),
          arguments: {
            ApiKeys.argAccountType: videoController.videoFeedItem?.author?.accountType,
            ApiKeys.channelId: videoController.videoFeedItem?.channel?.id,
            ApiKeys.authorId: videoController.videoFeedItem?.author?.id
          }
      );
    }else{
      /// we don't have channel so will call profile
      if (videoController.videoFeedItem?.author?.accountType?.toUpperCase() == AppConstants.individual) {
        if (videoController.videoFeedItem?.author?.id == userId) {
          navigatePushTo(context, PersonalProfileSetupScreen());
        } else {
          Get.to(() => NewVisitProfileScreen(authorId: videoController.videoFeedItem?.author?.id??'', screenFromName: AppConstants.feedScreen,));
        }
      }else{
        if (videoController.videoFeedItem?.author?.id == userId) {
          navigatePushTo(context, BusinessOwnProfileScreen());
        } else {
          Get.to(() => VisitBusinessProfileNew(businessId: videoController.videoFeedItem?.author?.id??'', screenName:  AppConstants.feedScreen,));
        }
      }
    }
  }
}
