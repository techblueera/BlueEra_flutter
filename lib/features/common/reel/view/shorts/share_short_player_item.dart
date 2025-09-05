import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/full_screen_short_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/widget/reels_shorts_popup_menu.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/api/apiService/api_keys.dart';

class ShareShortPlayerItem extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final bool shouldPreload;
  final VoidCallback onTapOption;
  final Shorts shorts;

  const ShareShortPlayerItem({
    super.key,
    required this.videoId,
    required this.autoPlay,
    this.shouldPreload = false,
    required this.onTapOption,
    required this.shorts,
  });

  @override
  State<ShareShortPlayerItem> createState() => ShareShortPlayerItemState();
}

class ShareShortPlayerItemState extends State<ShareShortPlayerItem>
    with RouteAware, WidgetsBindingObserver {
  bool _showOverlayIcon = false;
  IconData _playPauseIcon = Icons.play_arrow;
  final FullScreenShortController fullScreenShortController =
      Get.put(FullScreenShortController());

  VideoPlayerController? _controller;
  late String profileImage;
  late String name;
  late String designation;
  bool _initialized = false;
  bool _hasError = false;
  bool isShortSavedInDb = false;
  bool _isDisposed = false;
  bool _isCurrentPage = false; // Track if this is the current page
  Timer? _overlayTimer;
  Timer? _viewTimer;

  @override
  void initState() {
    super.initState();
    _fetchVideoDataAndSetup();
  }

  Future<void> _fetchVideoDataAndSetup() async {
    try {
      // Fetch video data using VideoController
      final videoController = Get.put(VideoController());
      final videoData = await videoController.getVideoById(widget.videoId);
      
      if (videoData != null) {
        fullScreenShortController.videoItem = videoData;
        getAndSetData();
        _setupVideoAfterFetch();
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  void _setupVideoAfterFetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        // Sync initial state from ShortsController lists to ensure consistency
        final shortsController = Get.find<ShortsController>();
        final videoId = fullScreenShortController.videoItem?.video?.id ?? '0';

        // Find the video in any of the lists to get the most up-to-date state
        ShortFeedItem? updatedVideo;
        final currentList =
            shortsController.getListByType(shorts: widget.shorts);
        for (final list in [currentList]) {
          final index = list.indexWhere((v) => v.video?.id == videoId);
          if (index != -1) {
            updatedVideo = list[index];
            break;
          }
        }

        // Use updated video data if found, otherwise use widget data
        final videoToUse = updatedVideo ?? fullScreenShortController.videoItem;

        fullScreenShortController.isLiked.value =
            videoToUse?.interactions?.isLiked ?? false;
        fullScreenShortController.likes.value =
            videoToUse?.video?.stats?.likes ?? 0;
        fullScreenShortController.comments.value =
            videoToUse?.video?.stats?.comments ?? 0;

        // Initialize player if should preload or autoplay
        if (widget.shouldPreload || widget.autoPlay) {
          _initializePlayer();
        }

        // Set up view tracking timer
        _setupViewTimer();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(ShareShortPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle autoplay changes
    if (widget.autoPlay != oldWidget.autoPlay) {
      _isCurrentPage = widget.autoPlay;
      if (widget.autoPlay) {
        // Only add lifecycle observer if this is the currently visible video
        if (_isCurrentlyVisible()) {
          WidgetsBinding.instance.addObserver(this);
        }
        _initializeAndPlay();
      } else {
        // Remove lifecycle observer when video becomes inactive
        WidgetsBinding.instance.removeObserver(this);
        _pauseVideo();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _overlayTimer?.cancel();
    _viewTimer?.cancel();
    RouteHelper.routeObserver.unsubscribe(this);
    disposePlayer();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Pause video when navigating to another screen
    if (_initialized &&
        _controller != null &&
        _controller?.value.isPlaying == true) {
      _controller?.pause();
    }
    // Remove lifecycle observer when navigating away
    WidgetsBinding.instance.removeObserver(this);
    _isCurrentPage = false;
  }

  @override
  void didPopNext() {
    // Resume video when returning to this screen, but only if autoplay is enabled
    if (_initialized && widget.autoPlay && _controller != null) {
      _isCurrentPage = true;
      // Only add lifecycle observer if this is the currently visible video
      if (_isCurrentlyVisible()) {
        WidgetsBinding.instance.addObserver(this);
      }
      // Add a small delay to ensure the navigation is complete
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_isDisposed && mounted && _isCurrentPage && widget.autoPlay) {
          _controller?.play();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isDisposed || _controller == null || !_initialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Pause video when app goes to background
        if (_controller?.value.isPlaying ?? false) {
          _controller?.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // Only resume if this is the currently visible video and we're on the shorts player screen
        if (_isCurrentlyVisible() && _controller != null) {
          // Double-check that we're still on the shorts player screen
          final route = ModalRoute.of(context);
          if (route?.settings.name?.contains('shorts_player') == true) {
            // Add a small delay to ensure the app is fully resumed
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!_isDisposed && mounted && _isCurrentlyVisible()) {
                _controller?.play();
              }
            });
          }
        }
        break;
      default:
        break;
    }
  }

  void _setupViewTimer() {
    _viewTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        fullScreenShortController.shortVideoView(
          videoId: fullScreenShortController.videoItem?.video?.id ?? '0',
        );
      }
    });
  }

  bool _isCurrentlyVisible() {
    // Check if we're on the shorts player screen
    final route = ModalRoute.of(context);
    if (route?.settings.name?.contains('shorts_player') != true) {
      return false;
    }

    // Check if this video is the currently active one
    return widget.autoPlay && _isCurrentPage;
  }

  void _initializeAndPlay() async {
    if (_controller == null && !_isDisposed) {
      await _initializePlayer();
    }
    if (_initialized && !_isDisposed) {
      _controller?.play();
    }
  }

  void _onVideoTap() {
    if (_controller == null || !_initialized) return;

    if (_controller?.value.isPlaying ?? false) {
      _controller?.pause();
      _playPauseIcon = Icons.pause_rounded;
    } else {
      _controller?.play();
      _playPauseIcon = Icons.play_arrow;
    }

    if (!_isDisposed) {
      setState(() {
        _showOverlayIcon = true;
      });

      // Cancel previous timer
      _overlayTimer?.cancel();

      // Hide after 1.5 seconds
      _overlayTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && !_isDisposed) {
          setState(() {
            if (_controller != null &&
                (_controller?.value.isPlaying ?? false)) {
              _showOverlayIcon = false;
            }
          });
        }
      });
    }
  }

  Future<void> _initializePlayer() async {
    if (_controller != null || _isDisposed) return;

    try {
      final videoUrl = fullScreenShortController.videoItem?.video?.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        if (!_isDisposed) {
          setState(() => _hasError = true);
        }
        return;
      }

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await _controller!.initialize();

      if (!_isDisposed) {
        _controller?.setLooping(true);
        _controller?.setVolume(1.0);

        if (widget.autoPlay) {
          _controller?.play();
        }

        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (!_isDisposed) {
        setState(() => _hasError = true);
      }
    }
  }

  void getAndSetData() {
    if (fullScreenShortController.videoItem == null) return;
    
    if (fullScreenShortController.videoItem?.channel?.id != null) {
      profileImage = fullScreenShortController.videoItem?.channel?.logoUrl ?? '';
      name = fullScreenShortController.videoItem?.channel?.name ?? '';
      designation = fullScreenShortController.videoItem?.channel?.username ?? '';
    } else {
      profileImage = fullScreenShortController.videoItem?.author?.profileImage ?? '';
      name = fullScreenShortController.videoItem?.author?.name ?? '';
      designation = fullScreenShortController.videoItem?.author?.username ?? '';
    }
    isShortSavedInDb = HiveServices()
        .isVideoSaved(fullScreenShortController.videoItem?.videoId ?? '');
  }

  // Public methods for external control
  void playVideo() {
    if (_controller == null) {
      _initializeAndPlay();
    } else if (_initialized) {
      _controller?.play();
    }
  }

  void pauseVideo() {
    _pauseVideo();
  }

  void _pauseVideo() {
    if (_initialized && _controller != null) {
      _controller?.pause();
    }
  }

  void disposePlayer() {
    _overlayTimer?.cancel();
    _viewTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    _initialized = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(imagePath: AppIconAssets.appIcon),
            const SizedBox(height: 8),
            CustomText('Failed to load video'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _initialized = false;
                });
                _fetchVideoDataAndSetup();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (fullScreenShortController.videoItem == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoPlayer(),
          _buildPlayPauseOverlay(),
          _buildActionButtons(),
          _buildVideoInfo(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return _initialized && _controller != null
        ? Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: _onVideoTap,
              child: AspectRatio(
                aspectRatio: _controller?.value.aspectRatio ?? 9 / 16,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget _buildPlayPauseOverlay() {
    return Center(
      child: AnimatedOpacity(
        opacity: _showOverlayIcon ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              child: Icon(
                _playPauseIcon,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: SizeConfig.size20,
      bottom: SizeConfig.size220,
      child: Column(
        children: [
          Obx(() => Column(
                children: [
                  InkWell(
                    onTap: () {
                      if (isGuestUser()) {
                        createProfileScreen();
                      } else {
                        _onLikeDislikePressed();
                      }
                    },
                    child: fullScreenShortController.isLiked.isTrue
                        ? LocalAssets(imagePath: AppIconAssets.reel_like_fill)
                        : LocalAssets(
                            imagePath: AppIconAssets.reel_like,
                            imgColor: AppColors.white),
                  ),
                  SizedBox(height: SizeConfig.size5),
                  CustomText(
                    formatNumberLikePost(fullScreenShortController.likes.value),
                    fontSize: SizeConfig.medium15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ],
              )),
          SizedBox(height: SizeConfig.size15),
          InkWell(
            onTap: () {
              if (isGuestUser()) {
                createProfileScreen();
              } else {
                _onCommentPressed();
              }
            },
            child: LocalAssets(
                imagePath: AppIconAssets.reel_comment,
                imgColor: AppColors.white),
          ),
          SizedBox(height: SizeConfig.size5),
          Obx(() => CustomText(
                formatNumberLikePost(fullScreenShortController.comments.value),
                fontSize: SizeConfig.medium15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              )),
          SizedBox(height: SizeConfig.size15),
          InkWell(
            onTap: () => _shareVideoSimple(),
            child: LocalAssets(
                imagePath: AppIconAssets.reel_share, imgColor: AppColors.white),
          ),
          SizedBox(height: SizeConfig.size3),
          InkWell(
            onTap: () => _shareVideoSimple(),
            child: CustomText(
              formatNumberLikePost(
                  fullScreenShortController.videoItem?.video?.stats?.shares ?? 0),
              fontSize: SizeConfig.medium15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: SizeConfig.size15),
          InkWell(
            onTap: () async {
              isShortSavedInDb = await Get.find<ShortsController>()
                  .saveVideosToLocalDB(
                      videoFeedItem: fullScreenShortController.videoItem!);
              if (!_isDisposed) {
                setState(() {});
              }

              // Sync saved state back to ShortsController lists
              Get.find<ShortsController>().updateVideoSavedState(
                videoId: fullScreenShortController.videoItem?.video?.id ?? '0',
                isSaved: isShortSavedInDb,
              );
            },
            child: LocalAssets(
                imagePath: isShortSavedInDb
                    ? AppIconAssets.reel_save_fill
                    : AppIconAssets.reel_save,
                imgColor: AppColors.white),
          ),
          SizedBox(height: SizeConfig.size5),
          CustomText(
            "Save",
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
          SizedBox(height: SizeConfig.size10),
          if (fullScreenShortController.videoItem?.channel?.id != null)
            if (fullScreenShortController.videoItem?.channel?.id != channelId)
              IconButton(
                onPressed: () {
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else {
                    widget.onTapOption();
                  }
                },
                icon: LocalAssets(
                    imagePath: AppIconAssets.blockIcon,
                    imgColor: AppColors.white),
              )
            else
              ReelShortPopUpMenu(
                  shortFeedItem: fullScreenShortController.videoItem!,
                  popUpMenuColor: AppColors.black,
                  shorts: Shorts.personalized)
          else if (fullScreenShortController.videoItem?.author?.accountType ==
              AppConstants.individual)
            if (fullScreenShortController.videoItem?.author?.id != userId)
              IconButton(
                onPressed: () {
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else {
                    widget.onTapOption();
                  }
                },
                icon: LocalAssets(
                    imagePath: AppIconAssets.blockIcon,
                    imgColor: AppColors.white),
              )
            else
              ReelShortPopUpMenu(
                  shortFeedItem: fullScreenShortController.videoItem!,
                  popUpMenuColor: AppColors.black,
                  shorts: Shorts.personalized)
          else if (fullScreenShortController.videoItem?.author?.accountType ==
              AppConstants.business)
            if (fullScreenShortController.videoItem?.author?.id != businessUserId)
              IconButton(
                onPressed: () {
                  if (isGuestUser()) {
                    createProfileScreen();
                  } else {
                    widget.onTapOption();
                  }
                },
                icon: LocalAssets(
                    imagePath: AppIconAssets.blockIcon,
                    imgColor: AppColors.white),
              )
            else
              ReelShortPopUpMenu(
                  shortFeedItem: fullScreenShortController.videoItem!,
                  popUpMenuColor: AppColors.black,
                  shorts: Shorts.personalized),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Positioned(
      left: 16,
      right: SizeConfig.size20,
      bottom: SizeConfig.size40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfo(),
          if (fullScreenShortController.videoItem?.video?.title?.isNotEmpty ??
              false) ...[
            SizedBox(height: SizeConfig.size10),
            ExpandableText(
              text: fullScreenShortController.videoItem?.video?.title ?? '',
              style: TextStyle(
                color: AppColors.white,
                fontSize: SizeConfig.medium15,
              ),
            )
          ],
          if (fullScreenShortController
                  .videoItem?.video?.description?.isNotEmpty ??
              false) ...[
            Container(
              child: Padding(
                padding: EdgeInsets.only(right: SizeConfig.size40),
                child: ExpandableText(
                  text:
                      fullScreenShortController.videoItem?.video?.description ??
                          '',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.size13),
                ),
              ),
            ),
          ],
          if ((fullScreenShortController.videoItem?.channel?.id?.isNotEmpty ??
                  false) &&
              (fullScreenShortController
                      .videoItem?.video?.acceptBookingsOrEnquiries ??
                  false)) ...[
            SizedBox(height: SizeConfig.size10),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blackD9,
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                      if (isGuestUser()) {
                        createProfileScreen();
                      } else {
                        Navigator.pushNamed(
                          context,
                          RouteHelper.sentEnquiresRoute(),
                          arguments: {
                            ApiKeys.channelId:
                            fullScreenShortController.videoItem?.channel?.id,
                            ApiKeys.videoId:
                            fullScreenShortController.videoItem?.videoId,
                          },
                        );
                      }
                  },
                  child: CustomText(
                    "Send Enquiry",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blackD9,
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (isGuestUser()) {
                      createProfileScreen();
                    } else {
                      Navigator.pushNamed(
                        context,
                        RouteHelper.getAppointmentBookingScreenRoute(),
                        arguments: {
                          ApiKeys.channelId:
                          fullScreenShortController.videoItem?.channel?.id,
                          ApiKeys.videoId:
                          fullScreenShortController.videoItem?.videoId,
                        },
                      );
                    }
                  },
                  child: CustomText(
                    "Book Appointment",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size15),
              ],
            )
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => navigatePushTo(
            context,
            ImageViewScreen(
              appBarTitle: '',
              imageUrls: [profileImage],
              initialIndex: 0,
            ),
          ),
          child: CachedAvatarWidget(
            imageUrl: profileImage,
            size: SizeConfig.size40,
            borderRadius: SizeConfig.size20,
            borderColor: AppColors.primaryColor,
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: InkWell(
            onTap: () {
              _navigateToProfile();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                SizedBox(height: SizeConfig.size1),
                CustomText(
                  "@${designation}",
                  fontSize: SizeConfig.small,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
      ],
    );
  }

  void _navigateToProfile() {
    if (fullScreenShortController.videoItem?.channel?.id != null) {
      Navigator.pushNamed(
        context,
        RouteHelper.getChannelScreenRoute(),
        arguments: {
          ApiKeys.argAccountType:
              fullScreenShortController.videoItem?.author?.accountType,
          ApiKeys.channelId: fullScreenShortController.videoItem?.channel?.id,
          ApiKeys.authorId: fullScreenShortController.videoItem?.author?.id
        },
      );
    } else {
      if (fullScreenShortController.videoItem?.author?.accountType
              ?.toUpperCase() ==
          AppConstants.individual) {
        if (fullScreenShortController.videoItem?.author?.id == userId) {
          navigatePushTo(context, PersonalProfileSetupScreen());
        } else {
          Get.to(() => VisitProfileScreen(
              authorId: fullScreenShortController.videoItem?.author?.id ?? ''));
        }
      } else {
        if (fullScreenShortController.videoItem?.author?.id == businessUserId) {
          navigatePushTo(context, BusinessOwnProfileScreen());
        } else {
          Get.to(() => VisitBusinessProfile(
              businessId:
                  fullScreenShortController.videoItem?.author?.id ?? ''));
        }
      }
    }
  }

  void _onLikeDislikePressed() async {
    final videoId = fullScreenShortController.videoItem?.video?.id ?? '0';
    if (fullScreenShortController.isLiked.isTrue) {
      await fullScreenShortController.shortVideoUnLike(videoId: videoId);
      fullScreenShortController.videoItem?.interactions?.isLiked = false;
      fullScreenShortController.videoItem?.video?.stats?.likes =
          (fullScreenShortController.videoItem?.video?.stats?.likes ?? 1) - 1;
    } else {
      await fullScreenShortController.shortVideoLike(videoId: videoId);
      fullScreenShortController.videoItem?.interactions?.isLiked = true;
      fullScreenShortController.videoItem?.video?.stats?.likes =
          (fullScreenShortController.videoItem?.video?.stats?.likes ?? 0) + 1;
    }

    // Update controller state
    fullScreenShortController.isLiked.value =
        fullScreenShortController.videoItem?.interactions?.isLiked ?? false;
    fullScreenShortController.likes.value =
        fullScreenShortController.videoItem?.video?.stats?.likes ?? 0;
  }

  void _onCommentPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        id: fullScreenShortController.videoItem?.video?.id ?? '0',
        totalComments:
            fullScreenShortController.videoItem?.video?.stats?.comments ?? 0,
        commentType: CommentType.video,
        onNewCommentCount: (int newCommentCount) {
          fullScreenShortController.comments.value = newCommentCount;
          fullScreenShortController.videoItem?.video?.stats?.comments =
              fullScreenShortController.comments.value;
        },
      ),
    );
  }

  /// Simple, consistent share experience using buildDeepLink
  Future<void> _shareVideoSimple() async {
    final id = fullScreenShortController.videoItem?.video?.id ?? widget.videoId;
    final link = shortDeepLink(shortId: id);
    final title = fullScreenShortController.videoItem?.video?.title ?? 'BlueEra Short';

    final message = "Check out this Short video on BlueEra:\n$link\n";

    await SharePlus.instance.share(ShareParams(
      text: message,
      subject: title,
    ));
  }
}
