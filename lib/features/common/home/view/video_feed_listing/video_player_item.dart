import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_cache_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPlayerItem extends StatefulWidget {
  final VideoPost video;
  final bool isActive;
  const VideoPlayerItem({
    Key? key,
    required this.video,
    required this.isActive,
  }) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  // bool _isInitializing = true;
  // bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // ✅ Use your custom cache manager to get the controller
      _controller =
          await VideoCacheManager().getController(widget.video.videoUrl);

      if (mounted && _controller != null) {
        _duration = _controller!.value.duration;
        _controller!.addListener(_onVideoProgress);
        _controller!.setLooping(true);

        // Play/pause based on visibility flag
         _playPauseBasedOnVisibility();

        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  void _onVideoProgress() {
    if (!mounted || _controller == null) return;
    setState(() {
      _position = _controller!.value.position;
    });
  }

  void _playPauseBasedOnVisibility() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) return;
    if (widget.isActive) {
      _controller!.play();
      _isPlaying = true;
    } else {
      _controller!.pause();
      _isPlaying = false;
    }
    setState(() {});
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _playPauseBasedOnVisibility();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause(); // ✅ stop playback
    }

    // Release controller reference from cache manager
    VideoCacheManager().releaseController(widget.video.videoUrl);

    super.dispose();
  }
  // @override
  // void dispose() {
  //   _controller?.removeListener(_onVideoProgress);
  //   // 🔥 Don't dispose controller here if using shared cache (let cache manage it)
  //   // _controller?.dispose();
  //   super.dispose();
  // }

  String _formatTime(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  final feedController = Get.isRegistered<FeedController>()
      ? Get.find<FeedController>()
      : Get.put(FeedController());
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: VisibilityDetector(
        key: Key(widget.video.id),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.6) {
            _controller?.play();
            _isPlaying = true;
          } else {
            _controller?.pause();
            _isPlaying = false;
          }

          if (!mounted) return;
          setState(() {});
          // if (_visible && widget.isActive) {
          //   _controller!.play();
          //   _isPlaying = true;
          // } else {
          //   _controller!.pause();
          //   _isPlaying = false;
          // }
          // if (!mounted) return;
          // setState(() {});
          // _playPauseBasedOnVisibility();
        },
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.size10,
            ),
            //
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // LocalAssets(imagePath: AppIconAssets.back_arrow),
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      )),
                  SizedBox(
                    width: SizeConfig.size10,
                  ),
                  Expanded(
                    child: SizedBox(
                      width: Get.width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.video.avatar.isNotEmpty)
                            InkWell(
                              onTap: () {
                                navigatePushTo(
                                  context,
                                  ImageViewScreen(
                                    appBarTitle: AppLocalizations.of(context)!
                                        .imageViewer,
                                    // imageUrls: [post?.author.profileImage ?? ''],
                                    imageUrls: [widget.video.avatar],
                                    initialIndex: 0,
                                  ),
                                );
                              },
                              child: CachedAvatarWidget(
                                  imageUrl: widget.video.avatar,
                                  size: 40,
                                  borderColor: Colors.white,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: CustomText(
                                          widget.video.authorName,
                                          fontWeight: FontWeight.w600,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      if (widget.video.authorUsername.isNotEmpty &&
                                          (widget.video.authorUsername
                                                  .isNotEmpty ??
                                              false))
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 3),
                                            child: CustomText(
                                              " @${widget.video.authorUsername}",
                                              fontWeight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: SizeConfig.size2),
                                CustomText(
                                  widget.video.account_type.toUpperCase() ==
                                          AppConstants.business
                                      ? widget.video.business_category
                                      : widget.video.designation,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  color: AppColors.white,
                                )
                                // Add optional follower/follow section if needed
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:  _controller != null &&
                  _controller!.value.isInitialized ? GestureDetector(
                onTap: _togglePlay,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🖼️ Video display
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    ),

                    // ▶️ Play/Pause button (center)
                    if (_controller != null && _controller!.value.isInitialized)
                      GestureDetector(
                        onTap: _togglePlay,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 0.8,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // 🔇 Mute button + Duration overlay (bottom-right)
                    Positioned(
                      bottom: 10,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_controller != null &&
                                  _controller!.value.isInitialized)
                                GestureDetector(
                                  onTap: _togglePlay,
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                ),
                              if (_controller != null)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 5.0,
                                    ),
                                    child: VideoProgressIndicator(
                                      _controller!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.white,
                                        backgroundColor: Colors.white30,
                                        bufferedColor: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // GestureDetector(
                              //   onTap: _toggleMute,
                              //   child: Icon(
                              //     _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              //     color: Colors.white,
                              //     size: 24,
                              //   ),
                              // ),
                              // const SizedBox(width: 12),
                              CustomText(
                                  "${_formatTime(_position)} / ${_formatTime(_duration)}",
                                  color: Colors.white,
                                  fontSize: 12),
                            ],
                          ),
                          // 📄 Title or Caption (bottom left)
                          if (widget.video.title.isNotEmpty)
                            SafeArea(
                              child: Container(
                                margin: EdgeInsets.only(top: 5),
                                padding:
                                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryTextColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ExpandableText(
                                  text: widget.video.title,
                                  trimLines: 2,
                                  isReadMoreNewLine: true,
                                  expandMode: ExpandMode.dialog,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: SizeConfig.large,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppConstants.OpenSans,
                                  ),
                                ),
                              ),
                            ),


                         SizedBox(height: SizeConfig.size30,),
                        ],
                      ),
                    ),
                  ],
                ),
              ) : const Center(
                child: CircularProgressIndicator(
                    color: Colors.white),
              ),
            ),
            /*Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15,
                  vertical: SizeConfig.size5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ViewFeedActionWidget(
                      iconPath: AppIconAssets.clock_new,
                      data: timeAgo(DateTime.parse(widget.video.createdAt))),
                  ViewFeedActionWidget(
                    iconPath: AppIconAssets.eye_new,
                    data: formatNumberLikePost(widget.video.views_count),
                  ),
                  InkWell(
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();
                      } else {
                        // widget.commentView();
                      }
                    },
                    child: ViewFeedActionWidget(
                        iconPath: AppIconAssets.comment_new,
                        data: formatNumberLikePost(
                            widget.video.comments_count)),
                  ),
                  InkWell(
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();
                      } else {
                        _onLikeDislikePressed();
                        // widget.likeFeed();
                      }

                    },
                    child: Padding(
                      padding:
                      EdgeInsets.only(right: SizeConfig.size10),
                      child: Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.like_new,
                            width: SizeConfig.size18,
                            height: SizeConfig.size18,
                            imgColor: (widget.video.isLiked ?? false)
                                ? AppColors.primaryColor
                                : AppColors.secondaryTextColor,
                          ),
                          SizedBox(
                            width: SizeConfig.size5,
                          ),
                          CustomText(
                            formatNumberLikePost(
                                widget.video.likes_count ?? 0),
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.size10,
                          ),
                        ],
                      ),
                    )
                    ,
                  ),
                  if (widget.video.type.toLowerCase() ==
                      "message_post")
                    InkWell(
                      onTap: () {
                        if (isGuestUser()) {
                          createProfileScreen();

                          return;
                        }
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return Dialog(
                              insetPadding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size20),
                              backgroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints:
                                  BoxConstraints(maxWidth: 800),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                        SizeConfig.size15),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                            height:
                                            SizeConfig.size20),
                                        InkWell(
                                          onTap: () async {
                                            Get.put(
                                                MessagePostController());

                                            ///REPOST MESSAGE AND POLL POST...
                                            Get.back();
                                            ResponseModel
                                            responseModel =
                                            await PostRepo()
                                                .addRePostNewRepo(
                                              reqDataData: {
                                                ApiKeys.type:
                                                AppConstants
                                                    .MESSAGE_POST,
                                                ApiKeys.repostId:
                                                widget.video?.id ??
                                                    ""
                                              },
                                            );
                                            if (responseModel
                                                .isSuccess) {
                                              commonSnackBar(
                                                  message:
                                                  "Reposted successfully");
                                              Get.find<
                                                  NavigationHelperController>()
                                                  .shouldRefreshBottomBar
                                                  .value = true;
                                              Get.until((route) =>
                                              route.settings
                                                  .name ==
                                                  RouteHelper
                                                      .getBottomNavigationBarScreenRoute());
                                            } else {
                                              commonSnackBar(
                                                  message:
                                                  "You have already reposted this post");
                                            }
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              Container(
                                                width:
                                                SizeConfig.size30,
                                                height:
                                                SizeConfig.size30,
                                                child: LocalAssets(
                                                  imagePath:
                                                  AppIconAssets
                                                      .repost_new,
                                                  width: SizeConfig
                                                      .size30,
                                                  height: SizeConfig
                                                      .size30,
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(
                                                          horizontal:
                                                          SizeConfig
                                                              .size10),
                                                      child:
                                                      CustomText(
                                                        "Repost",
                                                        textAlign:
                                                        TextAlign
                                                            .left,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        fontSize:
                                                        SizeConfig
                                                            .size16,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(
                                                          horizontal:
                                                          SizeConfig
                                                              .size10),
                                                      child:
                                                      CustomText(
                                                        "Share this post with your followers",
                                                        textAlign:
                                                        TextAlign
                                                            .left,
                                                        color: AppColors
                                                            .secondaryTextColor,
                                                        fontSize:
                                                        SizeConfig
                                                            .size13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: SizeConfig.size10,
                                              bottom:
                                              SizeConfig.size10),
                                          child: Divider(
                                            color: AppColors
                                                .secondaryTextColor,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Get.back();
                                            // Get.to(
                                            //     CreateMessagePostScreenRepost(
                                            //       isEdit: false,
                                            //       post: widget.video,
                                            //     ));
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              Container(
                                                width:
                                                SizeConfig.size30,
                                                height:
                                                SizeConfig.size30,
                                                child: LocalAssets(
                                                  imagePath:
                                                  AppIconAssets
                                                      .pencilIcon,
                                                  width: SizeConfig
                                                      .size20,
                                                  height: SizeConfig
                                                      .size20,
                                                  // imgColor: AppColors.secondaryTextColor,
                                                ),
                                              ),
                                              Flexible(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(
                                                          horizontal:
                                                          SizeConfig
                                                              .size10),
                                                      child:
                                                      CustomText(
                                                        "Add your things",
                                                        textAlign:
                                                        TextAlign
                                                            .left,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        fontSize:
                                                        SizeConfig
                                                            .size16,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(
                                                          horizontal:
                                                          SizeConfig
                                                              .size10),
                                                      child:
                                                      CustomText(
                                                        "Add a comment ,photo before you share this post",
                                                        textAlign:
                                                        TextAlign
                                                            .left,
                                                        color: AppColors
                                                            .secondaryTextColor,
                                                        fontSize:
                                                        SizeConfig
                                                            .size13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                            height:
                                            SizeConfig.size20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: ViewFeedActionWidget(
                          iconPath: AppIconAssets.repost_new,
                          data: formatNumberLikePost(
                              widget.video.repost_count)),
                    ),
                  // Padding(
                  //   padding: EdgeInsets.only(left: SizeConfig.size5),
                  //   child: InkWell(
                  //     onTap: () => widget.onShareButtonPressed(),
                  //     child: LocalAssets(
                  //       imagePath: AppIconAssets.share_bold,
                  //       imgColor: AppColors.secondaryTextColor,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),*/

          ],
        ),
      ),
    );
  }
}

  //
  // void _onLikeDislikePressed() {
  //   feedController.postLikeDislike(
  //       postId:  widget.video.id ?? '0',
  //       type: PostType.otherChannelPosts,
  //       sortBy: SortBy.Latest);
  // }
  //
  // void _onCommentPressed() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => FractionallySizedBox(
  //       heightFactor: 0.8,
  //       child: CommentBottomSheet(
  //           id: widget.video.id ?? '0',
  //           totalComments: widget.video.comments_count ?? 0,
  //           commentType: CommentType.post,
  //           onNewCommentCount: (int newCommentCount) {
  //             feedController.updateCommentCount(
  //                 postId: widget.video.id ,
  //                 type:PostType.otherChannelPosts,
  //                 sortBy: SortBy.Latest,
  //                 newCommentCount: newCommentCount);
  //           }),
  //     ),
  //   );
  // }
/*  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),

            if (!_isPlaying)
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 80),

            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.redAccent,
                      backgroundColor: Colors.white30,
                      bufferedColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(_position),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        _formatTime(_duration),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }*/

/*
class VideoPlayerItem extends StatefulWidget {
  final VideoPost video;
  final bool isActive;

  const VideoPlayerItem({
    Key? key,
    required this.video,
    required this.isActive,
  }) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );

    await _controller!.initialize();
    if (!mounted) return;

    _controller!.setLooping(true);
    _controller!.addListener(() {
      if (!mounted) return;
      setState(() => _position = _controller!.value.position);
    });

    _duration = _controller!.value.duration;

    if (widget.isActive) {
      _controller!.play();
      _isPlaying = true;
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller?.play();
        setState(() => _isPlaying = true);
      } else {
        _controller?.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  String _formatTime(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        if (!_isPlaying)
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 80),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            children: [
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.redAccent,
                  backgroundColor: Colors.white30,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(_position),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  Text(_formatTime(_duration),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
*/

/*
class VideoPlayerItem extends StatefulWidget {
  final VideoPost video;
  final bool isActive;

  const VideoPlayerItem({
    Key? key,
    required this.video,
    required this.isActive,
  }) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _visible = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    _controller =
        await VideoCacheManager().getController(widget.video.videoUrl);

    if (mounted && _controller != null) {
      _totalDuration = _controller!.value.duration;
      _controller!.addListener(_onVideoProgress);
      _playPauseBasedOnVisibility();
      setState(() {});
    }
  }

  void _onVideoProgress() {
    if (!mounted || _controller == null) return;
    final position = _controller!.value.position;
    if (position != _currentPosition) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    }
  }

  void _playPauseBasedOnVisibility() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_visible && widget.isActive) {
      _controller!.play();
      _isPlaying = true;
    } else {
      _controller!.pause();
      _isPlaying = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _toggleMute() {
    if (_controller == null) return;
    if (_isMuted) {
      _controller!.setVolume(1.0);
    } else {
      _controller!.setVolume(0.0);
    }
    setState(() => _isMuted = !_isMuted);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _playPauseBasedOnVisibility();
  }

  @override
  void dispose() {
    _timer?.cancel();

    _controller?.removeListener(_onVideoProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.video.id),
      onVisibilityChanged: (info) {
        _visible = info.visibleFraction > 0.6;
        _playPauseBasedOnVisibility();
      },
      child: Column(
        children: [
          Positioned(
            top: 10,
            child: ChannelProfileHeader(
                imageUrl: "",
                title: '${widget.video.authorName}',
                userName: '${widget.video.authorUsername}',
                subtitle: "",
                avatarSize: SizeConfig.size42,
                borderColor: AppColors.shadowColor,
                titleColor: Colors.white,
                userNameColor: Colors.white,
                postedAgo: ""),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🖼️ Video display
                Center(
                  child: _controller != null && _controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),

                // ▶️ Play/Pause button (center)
                if (_controller != null && _controller!.value.isInitialized)
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 0.8,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // 🔇 Mute button + Duration overlay (bottom-right)

                Positioned(
                  bottom: 10,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_controller != null &&
                              _controller!.value.isInitialized)
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),
                          if (_controller != null)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 5.0,
                                ),
                                child: VideoProgressIndicator(
                                  _controller!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.white,
                                    backgroundColor: Colors.white30,
                                    bufferedColor: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // GestureDetector(
                          //   onTap: _toggleMute,
                          //   child: Icon(
                          //     _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          //     color: Colors.white,
                          //     size: 24,
                          //   ),
                          // ),
                          // const SizedBox(width: 12),
                          CustomText(
                              "${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}",
                              color: Colors.white,
                              fontSize: 12),
                        ],
                      ),
                      // 📄 Title or Caption (bottom left)
                      if (widget.video.title.isNotEmpty)
                        ExpandableText(
                          text: widget.video.title ?? '',
                          trimLines: 4,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppConstants.OpenSans,
                          ),
                        )
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text(
                      //       _formatDuration(_currentPosition),
                      //       style: const TextStyle(color: Colors.white, fontSize: 12),
                      //     ),
                      //     Text(
                      //       _formatDuration(_totalDuration),
                      //       style: const TextStyle(color: Colors.white, fontSize: 12),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/
