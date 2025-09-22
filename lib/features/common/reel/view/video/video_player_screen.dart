import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
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
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../business/visit_business_profile/view/visit_business_profile_new.dart';

class VideoPlayerScreen extends StatefulWidget {
  final ShortFeedItem videoItem;
  final VideoType videoType;
  const VideoPlayerScreen({super.key, required this.videoItem, required this.videoType});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final VideoController videoController = Get.put(VideoController());
  late final SingleVideoPlayerController videoPlayerController;
  final ScrollController _scrollController = ScrollController();
  bool isCollapsed = false;
  final GlobalKey _contentKey = GlobalKey();
  bool _isMeasured = false;
  bool isUploadFromChannel = false;

  double _calculatedHeight = SizeConfig.size300;
  bool _isVideoSharing = false;

  RxBool _showControls = true.obs;
  Timer? _hideControlsTimer;

  // Track fullscreen mode to update the icon
  bool _isFullScreen = false;
  bool _isPortrait = true;

  @override
  void initState() {
    super.initState();
    videoPlayerController = Get.put(SingleVideoPlayerController(), tag: widget.videoItem.videoId);
    videoController.videoFeedItem = widget.videoItem;
    isUploadFromChannel = videoController.videoFeedItem?.channel?.id != null;
    _setupScrollListener();
    checkVideoSavedInDb();
    _scheduleVideoView();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeaderHeight();
      _initializeVideo();
      _setupVideoData();
      videoController.getAllFeedVideos(isInitialLoad: true);
    });
  }


  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   _checkOrientation(); // Safe to call MediaQuery here
  // }

  // // Listen to metrics change (like rotation)
  // @override
  // void didChangeMetrics() {
  //   final size = View.of(context).physicalSize;
  //   final orientation = size.width > size.height
  //       ? Orientation.landscape
  //       : Orientation.portrait;
  //
  //   if (orientation == Orientation.portrait && !_isPortraitReady) {
  //     Future.microtask(() {
  //       if (mounted) {
  //         setState(() => _isPortraitReady = true);
  //       }
  //     });
  //   }
  // }


  // void _checkOrientation() {
  //   final orientation = MediaQuery.of(context).orientation;
  //   if (orientation == Orientation.portrait && !_isPortraitReady) {
  //     // Delay rebuild slightly
  //     Future.delayed(const Duration(milliseconds: 50), () {
  //       if (mounted) {
  //         setState(() => _isPortraitReady = true);
  //       }
  //     });
  //   }
  // }


  void _initializeVideo() {
    _startHideControlsTimer();
    videoPlayerController.initializeVideo(
      widget.videoItem,
      autoPlay: !videoPlayerController.interstitialService.shouldShowAdOnThisVisit(),
      showAd: videoPlayerController.interstitialService.shouldShowAdOnThisVisit(),
      onAdShow: () => log('Ad is showing - video paused'),
      onAdClosed: () => log('Ad closed - video resumed'),
    );
  }

  void _setupVideoData() {
    videoController.isLiked.value = videoController.videoFeedItem?.interactions?.isLiked ?? false;
    videoController.likes.value = videoController.videoFeedItem?.video?.stats?.likes ?? 0;
    videoController.comments.value = videoController.videoFeedItem?.video?.stats?.comments ?? 0;
    if (isUploadFromChannel) {
      videoController.isChannelFollow.value = videoController.videoFeedItem?.channel?.isFollowing ?? false;
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
      videoController.videoView(videoId: videoController.videoFeedItem!.video!.id ?? '0');
    });
  }

  void checkVideoSavedInDb() {
    videoController.isVideoSavedInDb.value = HiveServices().isVideoSaved(videoController.videoFeedItem?.videoId ?? '');
  }

  @override
  void dispose() {
    Get.delete<SingleVideoPlayerController>(tag: widget.videoItem.videoId);
    _hideControlsTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_showControls.value) {
        _showControls.value = false;
      }
    });
  }

  void _onTapVideo() {
    _showControls.value = !_showControls.value;
    if (_showControls.value) {
      _startHideControlsTimer();
    }
  }

  Future<void> _toggleFullscreen(BuildContext context) async {
    setState(() {
      _isFullScreen = true;
    });

    // Enter fullscreen mode
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => FullScreenPlayer(
          singleVideoController: videoPlayerController,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // When fullscreen route is popped → restore UI
    if (!mounted) return;
    setState(() {
      _isFullScreen = false;
      _isPortrait = false;
    });
    await _restoreSystemUI();
  }

  Future<void> _restoreSystemUI() async {
    // First wait until pop animation is fully done
    await Future.delayed(const Duration(milliseconds: 200));

    // Restore system UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Then restore portrait orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    setState(() => _isPortrait = true);

  }


  void _measureHeaderHeight() {
    log('isMeasurd--$_isMeasured');
      final context = _contentKey.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final height = box.size.height;
        if (mounted) {
          setState(() {
            _isMeasured = true;
            _calculatedHeight = height;
          });
        }
      }

  }

  @override
  Widget build(BuildContext context) {
    if (!_isPortrait) {
      // Prevent render overflow during transition
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: SizedBox.shrink()),
      );
    }

    return Scaffold(
      appBar: CommonBackAppBar(isLeading: true),
      body: SafeArea(
        child: Column(
          children: [
            _buildVideoPlayerContainer(),
            _isMeasured
                ? Expanded(child: _buildMeasuredContent())
                : _buildPreMeasureWidget(),
          ],
        ),
      ),
    );
  }


  Widget _buildVideoPlayerContainer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width * (9/16),
        color: Colors.black,
        child: Obx(() {
          // Only the video rendering depends on RxBool
          if (!videoPlayerController.isVideoInitialized.value) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          return _VideoPlayerWithControls(
            controller: videoPlayerController,
            // singleVideoPlayerController: videoPlayerController,
            // showControls: _showControls,
            isFullScreen: _isFullScreen,
            onTapVideo: _onTapVideo,
            onToggleFullScreen: () => _toggleFullscreen(context),
          );
        }),
      ),
    );
  }



  // ... (All other build methods like _buildPreMeasureWidget, _buildMeasuredContent, _buildActions, etc., remain unchanged)
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
                  return staggeredDotsWaveLoading();
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
        builder: (_) => VideoPlayerScreen(
            videoItem: videoFeedItem,
            videoType: widget.videoType
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
              videoType: widget.videoType,
              params: params
          );
        }
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

  Future<void> _shareVideoSimple() async {
    // Prevent multiple calls
    if (_isVideoSharing) return;

    try {
      _isVideoSharing = true; // Set flag to prevent multiple calls

      final id = widget.videoItem.video?.id ?? widget.videoItem.videoId ?? '';
      final link = videoDeepLink(videoId: id);
      final title = widget.videoItem.video?.title ?? 'BlueEra Video';

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
                        imageUrl: isUploadFromChannel
                            ? videoController.videoFeedItem?.channel?.logoUrl ?? ''
                            : videoController.videoFeedItem?.author?.profileImage ?? '',
                        title: isUploadFromChannel
                            ? videoController.videoFeedItem?.channel?.name ?? ''
                            : videoController.videoFeedItem?.author?.username ?? '',
                        subtitle: isUploadFromChannel
                            ? videoController.videoFeedItem?.channel?.username ?? ''
                            : videoController.videoFeedItem?.author?.designation ?? "OTHERS",
                        avatarSize: SizeConfig.size40,
                        isVerifiedTickShow: true,
                      ),
                    ),
                  ),

                  if (isUploadFromChannel)
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
                                  videoType: widget.videoType
                              );
                            } else {
                              videoController.followChannel(
                                  channelId: videoController.videoFeedItem?.channel?.id ?? '',
                                  videoType: widget.videoType
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

  Future<void> _onLikeDislikePressed() async {
    final videoId = videoController.videoFeedItem?.video?.id ?? '0';

    // Update UI immediately
    if (videoController.isLiked.isTrue) {
      // Unlike action
      widget.videoItem.interactions?.isLiked = false;
      widget.videoItem.video?.stats?.likes = (widget.videoItem.video?.stats?.likes ?? 1) - 1;

      // Call debounced unlike API
      Get.find<VideoController>().videoUnLike(videoId: videoId);
    } else {
      // Like action
      widget.videoItem.interactions?.isLiked = true;
      widget.videoItem.video?.stats?.likes = (widget.videoItem.video?.stats?.likes ?? 0) + 1;

      // Call debounced like API
      Get.find<VideoController>().videoLike(videoId: videoId);
    }

    // Sync controller state and propagate to lists
    final isLiked = widget.videoItem.interactions?.isLiked ?? false;
    final likes = widget.videoItem.video?.stats?.likes ?? 0;
    videoController.isLiked.value = isLiked;
    videoController.likes.value = likes;
    Get.find<VideoController>().updateVideoLikeCount(
      videoType: widget.videoType,
      videoId: widget.videoItem.video?.id ?? '0',
      isLiked: isLiked,
      newLikeCount: likes,
    );
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
            widget.videoItem.video?.stats?.comments = videoController.comments.value;
            // propagate to controller lists
            Get.find<VideoController>().updateVideoCommentCount(
              videoType: widget.videoType,
              videoId: widget.videoItem.video?.id ?? '0',
              newCommentCount: newCommentCount,
            );
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
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
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

class _VideoPlayerWithControls extends StatelessWidget {
  final SingleVideoPlayerController controller;
  final bool isFullScreen;
  final VoidCallback onTapVideo;
  final VoidCallback onToggleFullScreen;

  const _VideoPlayerWithControls({
    required this.controller,
    required this.isFullScreen,
    required this.onTapVideo,
    required this.onToggleFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      // Show error
      if (controller.isVideoError.value) {
        return controller.getVideoErrorWidget();
      }

      final videoController = controller.videoPlayerController;
      if (videoController == null || controller.isVideoLoading.isTrue) {
        return const Center(child: CircularProgressIndicator());
      }

      final isCompleted = controller.isVideoCompleted.value;
      final isPlaying = controller.isVideoPlaying.value;

      return GestureDetector(
        onTap: (){
          controller.toggleControls();
          onTapVideo();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),

            // Replay overlay
            if (isCompleted) getReplayOverlayWidget(),

            // Controls overlay
            if (controller.showControls.value && !isCompleted)
              _buildControlsOverlay(context, isPlaying, videoController),

            // Center play/pause button
            if (controller.showControls.value && !isCompleted)
              _buildPlaybackControls(videoController),
          ],
        ),
      );
    });
  }

  Widget getReplayOverlayWidget() {
    return GestureDetector(
      onTap: () {
        log('Replay overlay tapped');
        controller.replay();
      },
      child: Container(
        color: Colors.black45,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.replay, size: 40, color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Tap to replay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context, bool isPlaying, VideoPlayerController videoController) {
    return Container(
      color: Colors.black38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildBottomBar(context, isPlaying, videoController),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isPlaying, VideoPlayerController videoController) {
    return ValueListenableBuilder(
      valueListenable: videoController,
      builder: (context, VideoPlayerValue value, child) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isFullScreen ? 25 : 15,
            vertical: 10,
          ),
          child: Row(
            children: [
              Text(
                _formatDuration(value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: VideoProgressIndicator(
                    videoController,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
              Text(
                _formatDuration(value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              IconButton(
                icon: Icon(
                  isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: onToggleFullScreen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls(VideoPlayerController videoController) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Backward button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
              onPressed: () {
                final currentPosition = videoController.value.position;
                final newPosition = currentPosition - const Duration(seconds: 10);
                videoController.seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);

                controller.showControlsTemporarily(); // Show controls after seeking
              },
            ),
          ),
          const SizedBox(width: 20),

          // Play / Pause button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Obx(() {
              final isPlaying = controller.isVideoPlaying.value;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40.0,
                ),
                onPressed: () {
                  isPlaying ? controller.pause() : controller.play();
                },
              );
            }),
          ),
          const SizedBox(width: 20),

          // Forward button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
              onPressed: () {
                final currentPosition = videoController.value.position;
                final duration = videoController.value.duration;
                final newPosition = currentPosition + const Duration(seconds: 10);
                videoController.seekTo(newPosition < duration ? newPosition : duration);

                controller.showControlsTemporarily(); // Show controls after seeking
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}


class FullScreenPlayer extends StatefulWidget {
  final SingleVideoPlayerController singleVideoController;

  const FullScreenPlayer({super.key, required this.singleVideoController});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late final RxBool _showControls = true.obs;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_showControls.value) _showControls.value = false;
    });
  }

  void _onTapVideo() {
    _showControls.value = !_showControls.value;
    if (_showControls.value) _startHideControlsTimer();
  }

  Future<void> _exitFullScreenSmoothly() async {
    // Fade overlay
    final overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: 0,
        duration: const Duration(milliseconds: 200),
        child: Container(color: Colors.black),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Wait for fade
    await Future.delayed(const Duration(milliseconds: 200));

    // Pop fullscreen
    Navigator.of(context).pop();

    // Delay a frame to let the main screen layout
    await Future.delayed(const Duration(milliseconds: 50));

    // Restore portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    overlayEntry.remove();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _VideoPlayerWithControls(
          controller: widget.singleVideoController,
          // showControls: _showControls,
          isFullScreen: true,
          onTapVideo: _onTapVideo,
          onToggleFullScreen: _exitFullScreenSmoothly,
        ),
      ),
    );
  }
}
