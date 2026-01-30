
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;

  const VideoPlayerItem({
    Key? key,
    required this.video,
    required this.isActive,
    required this.onLikeToggle,
    required this.onCommentTap,
  }) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false; // Track initialization explicitly

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // 1. Fetch controller
      final controller =
          await VideoCacheManager().getController(widget.video.videoUrl);

      // 2. CRITICAL: Check if user scrolled away while waiting for await
      if (!mounted) {
        // If unmounted, release the controller immediately and stop.
        VideoCacheManager().releaseController(widget.video.videoUrl);
        return;
      }

      // 3. Assign controller
      _controller = controller;

      // 4. Initialize if not already initialized (Cached controllers might be ready)
      if (!_controller!.value.isInitialized) {
        await _controller!.initialize();
      }

      if (!mounted) return; // Check again after second await

      _duration = _controller!.value.duration;
      _controller!.addListener(_onVideoProgress);
      _controller!.setLooping(true);

      // 5. Check visibility immediately
      _playPauseBasedOnVisibility();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing video: $e");
      // Handle error state if needed
    }
  }

  void _onVideoProgress() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized)
      return;

    // Optimization: Only update state if position actually changed significantly
    // or simply rely on the periodic update.
    final currentPos = _controller!.value.position;
    if (currentPos.inSeconds != _position.inSeconds) {
      setState(() {
        _position = currentPos;
      });
    }
  }

  void _playPauseBasedOnVisibility() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized)
      return;

    if (widget.isActive) {
      _controller!.play();
      _isPlaying = true;
    } else {
      _controller!.pause();
      _isPlaying = false;
    }
    // Only call setState if the values effectively changed to prevent rebuild loops
    setState(() {});
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _playPauseBasedOnVisibility();
    }
  }

  bool _isSharing = false;

  @override
  void dispose() {
    // 6. Safe Disposal
    if (_controller != null) {
      _controller!.removeListener(_onVideoProgress);
      _controller!.pause(); // Stop audio/video immediately
    }

    // Release from cache
    VideoCacheManager().releaseController(widget.video.videoUrl);

    _controller = null; // Prevent further access
    super.dispose();
  }

  // ... (Your _formatTime and feedController remain the same) ...
  String _formatTime(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    // 7. Calculate Aspect Ratio Safely
    // Default to 16/9 if not initialized or if ratio is 0 (prevents crash)
    double aspectRatio = 16 / 9;
    if (_controller != null && _controller!.value.isInitialized) {
      aspectRatio = _controller!.value.aspectRatio;
      if (aspectRatio <= 0.0) aspectRatio = 16 / 9;
    }

    return SafeArea(
      child: VisibilityDetector(
        key: Key(widget.video.id),
        onVisibilityChanged: (info) {
          if (!mounted || _controller == null || !_isInitialized) return;

          if (info.visibleFraction > 0.6) {
            if (!_isPlaying) {
              _controller?.play();
              _isPlaying = true;
              setState(() {});
            }
          } else {
            if (_isPlaying) {
              _controller?.pause();
              _isPlaying = false;
              setState(() {});
            }
          }
        },
        child: Column(
          children: [
            SizedBox(height: SizeConfig.size10),

            // ... (Your Top Bar / Back Button logic remains here) ...
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
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
                                // Your navigation logic
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: CustomText(
                                          widget.video.authorName
                                            ,
                                          fontWeight: FontWeight.w600,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ... rest of your header text
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
            SizedBox(height: SizeConfig.size10),

            // VIDEO PLAYER AREA
            Expanded(
              child: _isInitialized && _controller != null
                  ? GestureDetector(
                      onTap: _togglePlay,
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 🖼️ Video display with Safe AspectRatio
                          Center(
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: VideoPlayer(_controller!),
                            ),
                          ),

                          // ▶️ Play/Pause button overlay
                          if (_isInitialized)
                            AnimatedOpacity(
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

                          // 🔇 Controls (Bottom)
                          Positioned(
                            bottom: 10,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _togglePlay,
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 25,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
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
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomText(
                                        "${_formatTime(_position)} / ${_formatTime(_duration)}",
                                        color: Colors.white,
                                        fontSize: 12),
                                  ],
                                ),

                                // ... Your Title/Caption code ...
                                // 📄 Title or Caption (bottom left)
                                if (widget.video.subTitle.isNotEmpty)
                                  SafeArea(
                                    child: Container(
                                      margin: EdgeInsets.only(top: 5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ExpandableText(
                                        text: widget.video.subTitle,
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

                                SizedBox(
                                  height: SizeConfig.size30,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15, vertical: SizeConfig.size5),
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
                        widget.onCommentTap();
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
                        widget.onLikeToggle();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: SizeConfig.size10),
                      child: Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.like_new,
                            width: SizeConfig.size18,
                            height: SizeConfig.size18,
                            imgColor: (widget.video.isLiked)
                                ? AppColors.primaryColor
                                : AppColors.white,
                          ),
                          SizedBox(
                            width: SizeConfig.size5,
                          ),
                          CustomText(
                            formatNumberLikePost(widget.video.likes_count),
                            color: AppColors.white,
                            fontSize: SizeConfig.size10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.size5),
                    child: InkWell(
                      onTap: () async {
                        // Prevent multiple calls
                        if (_isSharing) return;

                        try {
                          _isSharing =
                              true; // Set flag to prevent multiple calls
                          onShareButtonPressed(Post(id: widget.video.id.toString(),subTitle:  widget.video.subTitle, ));
                          // XFile? xFile;
                          // if ((widget.video.thumbnail.isNotEmpty)) {
                          //   // Safely handle first media
                          //   xFile = await urlToCachedXFile(
                          //       widget.video.thumbnail);
                          // }
                          //
                          // final shareUrl =
                          //     postDeepLink(postId: widget.video.id.toString());
                          // final combinedText = shareUrl;
                          //
                          // await SharePlus.instance.share(ShareParams(
                          //     text: combinedText,
                          //     title: widget.video.title,
                          //     previewThumbnail: xFile,
                          //     files: [xFile ?? XFile("")]));
                          //
                          // if (xFile != null) {
                          //   final file = File(xFile.path);
                          //   if (await file.exists()) {
                          //     await file.delete();
                          //     print("🗑️ File deleted from cache.");
                          //   }
                          // }
                        } catch (e) {
                          print(
                              "feed card share failed inside _onShareButtonPressed $e");
                        } finally {
                          _isSharing = false;
// Reset flag
                        }
                      },
                      child: LocalAssets(
                        imagePath: AppIconAssets.share_bold,
                        imgColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size30),
          ],
        ),
      ),
    );
  }

  ViewFeedActionWidget({required String iconPath, required String data}) {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size10),
      child: Row(
        children: [
          LocalAssets(
            imagePath: iconPath,
            width: SizeConfig.size18,
            height: SizeConfig.size18,
            imgColor: AppColors.white,
          ),
          SizedBox(
            width: SizeConfig.size5,
          ),
          CustomText(
            data,
            color: AppColors.white,
            fontSize: SizeConfig.size10,
          ),
        ],
      ),
    );
  }
}

/*
class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
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
    if (!mounted || _controller == null || !_controller!.value.isInitialized)
      return;
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
        },
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.size10,
            ),
        */
/*    Row(
              children: [
                GestureDetector(
                  onTap: widget.onLikeToggle,
                  child: Column(
                    children: [
                      Icon(
                        widget.video.isLiked
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        color: widget.video.isLiked ? Colors.red : Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        "${widget.video.isLiked}-${widget.video.likes_count.toString()}",
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: widget.onCommentTap,
                  child: Column(
                    children: [
                      Icon(
                       Icons.comment,
                        color: widget.video.isLiked ? Colors.red : Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        "${widget.video.comments_count.toString()}",
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),*/ /*

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
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
                                    appBarTitle: AppStrings.imageViewer,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                      if (widget.video.authorUsername
                                              .isNotEmpty &&
                                          (widget
                                              .video.authorUsername.isNotEmpty))
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
              child: _controller != null && _controller!.value.isInitialized
                  ? GestureDetector(
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
                          )),

                          // ▶️ Play/Pause button (center)
                          if (_controller != null &&
                              _controller!.value.isInitialized)
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
                                          _isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor
                                            .withValues(alpha: 0.2),
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

                                SizedBox(
                                  height: SizeConfig.size30,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
