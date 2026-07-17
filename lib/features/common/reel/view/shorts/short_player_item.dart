import 'dart:async';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/full_screen_short_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/widget/reels_shorts_popup_menu.dart';
import 'package:BlueEra/core/navigation/visit_profile_resolver.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/api/apiService/api_keys.dart';

class ShortPlayerItem extends StatefulWidget {
  final ShortFeedItem videoItem;
  final bool autoPlay;
  final VoidCallback onTapOption;
  final Shorts shorts;

  /* ------------- NEW ------------- */
  final VideoPlayerController? preloadedController;
  final Future<void>? initializeFuture;
  final String? coverUrl;

  /// Asks the parent (single controller owner) to rebuild this slot's
  /// controller after a load failure. Null when there is no parent owner.
  final VoidCallback? onReload;

  /* -------------------------------- */

  const ShortPlayerItem({
    super.key,
    required this.videoItem,
    required this.autoPlay,
    required this.onTapOption,
    required this.shorts,
    /* ------------- NEW ------------- */
    this.preloadedController,
    this.initializeFuture,
    this.coverUrl,
    this.onReload,
    /* -------------------------------- */
  });

  @override
  State<ShortPlayerItem> createState() => ShortPlayerItemState();
}

class ShortPlayerItemState extends State<ShortPlayerItem>
    with RouteAware, WidgetsBindingObserver {
  bool _showOverlayIcon = false;
  IconData _playPauseIcon = Icons.play_arrow;
  late final FullScreenShortController fullScreenShortController;
  late final String _controllerTag;

  VideoPlayerController? _controller;
  late String profileImage;
  late String name;
  late String designation;
  bool isVerified = false;
  bool _hasError = false;
  bool isShortSavedInDb = false;

  /// Follow state for an individual author's reel (seeded from
  /// `interactions.isFollowing`, falling back to `author.isFollowing` for the
  /// hot/trending feed; toggled optimistically on tap).
  bool _isFollowing = false;
  bool _isDisposed = false;
  Timer? _overlayTimer;
  Timer? _viewTimer;
  bool _viewCounted = false; // register the view at most once per item
  bool _isShortSharing = false;

  /* ------------- NEW ------------- */
  bool _useCover = true; // show cover until first frame ready
  bool _isBuffering = false; // show spinner while the network catches up
  bool _keywordsExpanded = false; // keyword chips: 3 + "+N more" → all
  /* -------------------------------- */

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'short_controller_${widget.videoItem.video?.id ?? DateTime.now().millisecondsSinceEpoch}';
    fullScreenShortController =
        Get.put(FullScreenShortController(), tag: _controllerTag);
    fullScreenShortController.videoItem = widget.videoItem;

    getAndSetData();

    // The parent (ShortsPlayerScreen) owns every controller and preloads the
    // current page ± 1. We are a pure consumer — attach to whatever it gives
    // us and react in didUpdateWidget when that controller instance changes.
    // This avoids the old double-controller bug (item self-creating one while
    // the parent also cached one for the same index).
    _attachController();

    // If this page is already the active one at creation, start counting now.
    _scheduleViewCount();
  }

  void _attachController() {
    final controller = widget.preloadedController;
    _controller = controller;
    _hasError = false;
    _isBuffering = false;

    if (controller == null) {
      // Parent hasn't created this page's controller yet — keep showing the
      // cover; didUpdateWidget fires once it does.
      _useCover = true;
      return;
    }

    _useCover = !controller.value.isInitialized;
    controller.setLooping(true);
    controller.addListener(_videoListener);

    final future = widget.initializeFuture;
    if (future != null) {
      future.then((_) {
        if (!mounted || _isDisposed || _controller != controller) return;
        setState(() => _useCover = false);
        if (widget.autoPlay) controller.play();
      }).catchError((_) {
        if (!mounted || _isDisposed || _controller != controller) return;
        setState(() => _hasError = true);
      });
    } else if (controller.value.isInitialized) {
      _useCover = false;
      if (widget.autoPlay) controller.play();
    }
  }

  /// Reacts to runtime player state: surface mid-playback failures as a Retry
  /// and show a spinner while the network buffers (instead of a frozen frame).
  void _videoListener() {
    final controller = _controller;
    if (controller == null || _isDisposed || !mounted) return;
    final value = controller.value;

    if (value.hasError && !_hasError) {
      setState(() => _hasError = true);
      return;
    }
    if (value.isBuffering != _isBuffering) {
      setState(() => _isBuffering = value.isBuffering);
    }
  }

  @override
  void didUpdateWidget(covariant ShortPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Parent swapped the controller for this slot (preload / reload / dispose):
    // detach from the old instance and bind to the new (or null) one. Without
    // this the item would keep pointing at a disposed controller → frozen page.
    if (!identical(
        widget.preloadedController, oldWidget.preloadedController)) {
      oldWidget.preloadedController?.removeListener(_videoListener);
      _attachController();
      if (mounted) setState(() {});
    } else if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay) {
        _controller?.play();
        // Became the active page — start the watch-time view timer.
        _scheduleViewCount();
      } else {
        _controller?.pause();
        // Swiped away before the threshold — don't count this as a view.
        _cancelViewCount();
      }
    }
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
  void didPushNext() {
    // user left the shorts screen
    _controller?.pause();
  }

  @override
  void didPopNext() {
    // user came back – resume only if this page is still the active one
    if (widget.autoPlay && !_isDisposed) {
      _controller?.play();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _overlayTimer?.cancel();
    _viewTimer?.cancel();
    RouteHelper.routeObserver.unsubscribe(this);

    // The parent owns the controller lifecycle — never dispose it here, just
    // detach our listener and pause so audio never leaks past this widget.
    _controller?.removeListener(_videoListener);
    _controller?.pause();
    deleteIfRegistered<FullScreenShortController>(tag: _controllerTag);
    super.dispose();
  }

  /* ------------- NEW: build – no spinner, only cover ------------- */
  Widget _buildVideoPlayer() {
    if (_useCover || _controller == null || !_controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller?.value.aspectRatio ?? 9 / 16,
        child: CachedNetworkImage(
          imageUrl: widget.coverUrl ?? widget.videoItem.video?.coverUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.black),
          errorWidget: (_, __, ___) => Container(color: Colors.black),
        ),
      );
    }
    return GestureDetector(
      onTap: _onVideoTap,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width > 0
                ? _controller!.value.size.width
                : MediaQuery.of(context).size.width,
            height: _controller!.value.size.height > 0
                ? _controller!.value.size.height
                : MediaQuery.of(context).size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );

    // return GestureDetector(
    //   onTap: _onVideoTap,
    //   child: FittedBox(
    //     fit: BoxFit.cover,
    //     child: SizedBox(
    //       width: _controller?.value.size.width,
    //       height: _controller?.value.size.height,
    //       child: VideoPlayer(_controller!),
    //     ),
    //   ),
    // );
  }

  /* ------------------------------------------------------------------ */

  void _onVideoTap() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller?.pause();
      _playPauseIcon = Icons.pause_rounded;
    } else {
      _controller?.play();
      _playPauseIcon = Icons.play_arrow;
    }
    setState(() => _showOverlayIcon = true);
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_isDisposed) {
        setState(() => _showOverlayIcon = false);
      }
    });
  }

  void getAndSetData() {
    if (fullScreenShortController.videoItem?.channel?.id != null) {
      profileImage =
          fullScreenShortController.videoItem?.channel?.logoUrl ?? '';
      name = fullScreenShortController.videoItem?.channel?.name ?? '';
      designation =
          fullScreenShortController.videoItem?.channel?.username ?? '';
      isVerified =
          fullScreenShortController.videoItem?.channel?.isVerified ?? false;
    } else {
      profileImage =
          fullScreenShortController.videoItem?.author?.profileImage ?? '';
      name = widget.videoItem.author?.name ?? '';
      designation = widget.videoItem.author?.username ?? '';
      isVerified = widget.videoItem.author?.isVerified ?? false;
    }
    isShortSavedInDb = HiveServices()
        .isVideoSaved(fullScreenShortController.videoItem?.videoId ?? '');
    _isFollowing =
        fullScreenShortController.videoItem?.interactions?.isFollowing ??
            fullScreenShortController.videoItem?.author?.isFollowing ??
            false;
    fullScreenShortController.isLiked.value =
        fullScreenShortController.videoItem?.interactions?.isLiked ?? false;
    fullScreenShortController.likes.value =
        fullScreenShortController.videoItem?.video?.stats?.likes ?? 0;
    fullScreenShortController.comments.value =
        fullScreenShortController.videoItem?.video?.stats?.comments ?? 0;
  }

  /// The text to show as the reel caption. Prefer `caption`, then `title`,
  /// then `description` — the feed fills different ones depending on source,
  /// so this keeps the caption from going blank when text exists.
  String _resolveCaption() {
    final v = fullScreenShortController.videoItem?.video;
    final caption = v?.caption ?? '';
    if (caption.trim().isNotEmpty) return caption;
    final title = v?.title ?? '';
    if (title.trim().isNotEmpty) return title;
    return v?.description ?? '';
  }

  /// Location · time-ago row + keyword chips — the extra metadata the user
  /// attaches on upload (location, keywords, created time). Renders nothing
  /// when none are present.
  Widget _buildMetaInfo({bool showKeywords = true}) {
    final v = fullScreenShortController.videoItem?.video;
    final createdAt = (v?.createdAt ?? '').trim();
    final keywords =
        (v?.keywords ?? const <String>[]).where((k) => k.trim().isNotEmpty).toList();

    // Address/location intentionally not shown.
    final parsedDate =
        createdAt.isNotEmpty ? DateTime.tryParse(createdAt)?.toLocal() : null;
    final timeStr = parsedDate != null ? timeAgo(parsedDate) : '';
    final hasTime = timeStr.isNotEmpty;
    final hasKeywords = showKeywords && keywords.isNotEmpty;

    if (!hasTime && !hasKeywords) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size8, right: SizeConfig.size40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTime)
            CustomText(
              timeStr,
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: SizeConfig.small,
            ),
          if (hasKeywords) ...[
            SizedBox(height: SizeConfig.size6),
            _buildKeywords(keywords),
          ],
        ],
      ),
    );
  }

  /// Max keyword chips shown before collapsing the rest behind "+N more".
  static const int _collapsedKeywordCount = 3;

  /// Keywords as plain `#hashtag` text (no chips/background). Collapsed shows
  /// the first [_collapsedKeywordCount] plus a "+N more" toggle; tapping it
  /// expands to all with "show less".
  Widget _buildKeywords(List<String> keywords) {
    final hasMore = keywords.length > _collapsedKeywordCount;
    final visible = (_keywordsExpanded || !hasMore)
        ? keywords
        : keywords.take(_collapsedKeywordCount).toList();
    final remaining = keywords.length - visible.length;

    return Wrap(
      spacing: SizeConfig.size6,
      runSpacing: SizeConfig.size4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...visible.map(_keywordChip),
        if (hasMore && !_keywordsExpanded)
          GestureDetector(
            onTap: () => setState(() => _keywordsExpanded = true),
            child: _keywordTogglePill('+$remaining more'),
          )
        else if (hasMore && _keywordsExpanded)
          GestureDetector(
            onTap: () => setState(() => _keywordsExpanded = false),
            child: _keywordTogglePill('show less'),
          ),
      ],
    );
  }

  /// Plain "+N more" / "show less" toggle text (primary-colored), inline with
  /// the hashtags.
  Widget _keywordTogglePill(String label) => CustomText(
        label,
        color: AppColors.primaryColor,
        fontSize: SizeConfig.size11,
        fontWeight: FontWeight.w700,
      );

  /// A single keyword as plain `#hashtag` text — no background container.
  Widget _keywordChip(String k) => CustomText(
        '#$k',
        color: AppColors.white,
        fontSize: SizeConfig.size11,
        fontWeight: FontWeight.w600,
      );

  /// True when [text] would render on more than one line at [maxWidth].
  bool _isMultiLine(String text, TextStyle style, double maxWidth) {
    if (text.trim().isEmpty || maxWidth <= 0) return false;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  /* public control methods */
  void playVideo() => _controller?.play();

  void pauseVideo() => _controller?.pause();

  /// A view is registered only after this short has stayed the active
  /// (auto-playing) page for [_viewThreshold] — so a quick swipe-past doesn't
  /// count, and rewatching the same item never double-counts.
  static const Duration _viewThreshold = Duration(seconds: 3);

  /// Schedule the (single) background view ping once this becomes the active
  /// page. A swipe-away before [_viewThreshold] cancels it via [_cancelViewCount].
  void _scheduleViewCount() {
    if (_viewCounted || !widget.autoPlay) return;
    _viewTimer?.cancel();
    _viewTimer = Timer(_viewThreshold, () {
      if (_isDisposed || !mounted || _viewCounted || !widget.autoPlay) return;
      final id = fullScreenShortController.videoItem?.video?.id ??
          widget.videoItem.videoId ??
          '';
      if (id.isEmpty || id == '0') return;
      _viewCounted = true;
      // Fire-and-forget — never awaited, never blocks playback.
      fullScreenShortController.shortVideoView(videoId: id);
    });
  }

  void _cancelViewCount() => _viewTimer?.cancel();

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      final cover = widget.coverUrl ?? widget.videoItem.video?.coverUrl ?? '';
      // Keep the cover thumbnail visible behind the error so the page never
      // goes to a blank black frame; dim it and overlay the Retry.
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (cover.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black),
              errorWidget: (_, __, ___) => Container(color: Colors.black),
            )
          else
            Container(color: Colors.black),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.white, size: 40),
              const SizedBox(height: 8),
              const CustomText('Failed to load video', color: AppColors.white),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _useCover = true;
                  });
                  // Ask the parent to rebuild this slot's controller; if there
                  // is no parent owner, just re-attach to what we already have.
                  if (widget.onReload != null) {
                    widget.onReload!.call();
                  } else {
                    _attachController();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      );
    }

    return SafeArea(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildVideoPlayer(),
          if (_isBuffering && !_useCover)
            const CircularProgressIndicator(color: Colors.white),
          _buildPlayPauseOverlay(),
          _buildActionButtons(),
          _buildVideoInfo(),
          _buildBackButton()
        ],
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return Center(
      child: AnimatedOpacity(
        opacity: _showOverlayIcon ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Transparent frosted glass: light tint over the blur with a
                // subtle bright rim so it reads on both dark and light frames.
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Icon(_playPauseIcon, size: 34, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: SizeConfig.size20,
      // Bottom-right: the action rail bottom-aligns near the caption instead
      // of floating at the vertical centre.
      bottom: SizeConfig.size40,
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
                imagePath: AppIconAssets.reelShare, imgColor: AppColors.white),
          ),
          SizedBox(height: SizeConfig.size3),

          InkWell(
            onTap: () => _shareVideoSimple(),
            child: CustomText(
              formatNumberLikePost(
                  fullScreenShortController.videoItem?.video?.stats?.shares ??
                      0),
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
              setState(() {});
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
                  shortFeedItem: widget.videoItem,
                  popUpMenuColor: AppColors.white,
                  shorts: widget.shorts)
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
                  shortFeedItem: widget.videoItem,
                  popUpMenuColor: AppColors.white,
                  shorts: widget.shorts)
          else if (fullScreenShortController.videoItem?.author?.accountType ==
              AppConstants.business)
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
                  shortFeedItem: widget.videoItem,
                  popUpMenuColor: AppColors.white,
                  shorts: widget.shorts),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    final v = fullScreenShortController.videoItem?.video;
    final title = (v?.title ?? '').trim();
    final description = (v?.description ?? '').trim();
    // Hide the keyword row when the title already wraps to more than one line
    // AND a separate description is present — keeps the overlay uncrowded.
    final captionStyle =
        TextStyle(color: AppColors.white, fontSize: SizeConfig.medium15);
    final captionWidth = MediaQuery.of(context).size.width -
        16 -
        SizeConfig.size20 -
        SizeConfig.size40;
    final showKeywords = !(_isMultiLine(title, captionStyle, captionWidth) &&
        description.isNotEmpty);

    return Positioned(
      left: 16,
      right: SizeConfig.size20,
      bottom: SizeConfig.size40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfo(),
          // Single caption block. The feed fills different fields by source
          // (trending shorts put the text in `title`, others use `caption` /
          // `description`), so show whichever is non-empty.
          Builder(builder: (_) {
            final caption = _resolveCaption();
            if (caption.trim().isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(
                  top: SizeConfig.size10, right: SizeConfig.size40),
              child: ExpandableText(
                text: caption,
                // Clamp to 2 lines; longer captions get an inline
                // "Read more" / "show less" toggle (not a dialog).
                trimLines: 2,
                expandMode: ExpandMode.expandable,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: SizeConfig.medium15,
                ),
              ),
            );
          }),
          _buildMetaInfo(showKeywords: showKeywords),
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
        // Flexible (not Expanded) so the name takes only the width it needs and
        // the Visit button sits right beside it instead of being pushed to the
        // far edge; the name still ellipsizes when long.
        Flexible(
          child: InkWell(
            onTap: () {
              _navigateToProfile();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CustomText(
                        name,
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      SizedBox(width: SizeConfig.size4),
                      Icon(Icons.verified,
                          size: SizeConfig.size16,
                          color: AppColors.primaryColor),
                    ],
                  ],
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
        _buildVisitButton(),
      ],
    );
  }

  /// Trailing action beside the author row:
  ///   * **own reel** → nothing (you can't visit/follow yourself),
  ///   * **business** (other) → frosted "Visit Store" pill → opens the store,
  ///   * **individual** (other) → Follow / Following toggle (user follow API).
  ///     No "View Profile" for individuals.
  Widget _buildVisitButton() {
    final item = fullScreenShortController.videoItem;
    final channel = item?.channel;
    final author = item?.author;

    // Own reel — nothing to show.
    if (_isOwnReel(item)) return const SizedBox.shrink();

    final isBusiness = channel?.id != null ||
        (author?.accountType ?? '').toUpperCase() ==
            AppConstants.business.toUpperCase();

    if (isBusiness) {
      // Business → Visit Store (unchanged behaviour).
      return _frostedPill(
        icon: Icons.storefront_rounded,
        label: 'Visit Store',
        onTap: _navigateToProfile,
      );
    }

    // Individual → Follow / Following (no profile visit).
    final authorId = author?.id ?? '';
    return _frostedPill(
      icon: _isFollowing ? Icons.check_rounded : Icons.person_add_alt_1,
      label: _isFollowing ? 'Following' : 'Follow',
      // Solid primary fill while not following so it reads as a clear CTA.
      filled: !_isFollowing,
      onTap: authorId.isEmpty ? null : () => _toggleFollow(authorId),
    );
  }

  /// True when the reel belongs to the signed-in user — by author id **or**
  /// channel. The author check runs regardless of whether a channel exists:
  /// the old logic skipped it whenever a channel was present, so an
  /// individual's own reel (which still carries a channel) was treated as
  /// someone else's and wrongly showed the visit button.
  bool _isOwnReel(ShortFeedItem? item) {
    final authorId = item?.author?.id ?? '';
    if (authorId.isNotEmpty && authorId == userId) return true;
    final chId = item?.channel?.id ?? '';
    if (chId.isNotEmpty && chId == channelId) return true;
    return false;
  }

  /// Shared frosted-glass pill (same language as the play/pause overlay) used
  /// for both the Visit Store and Follow actions. [filled] gives it a solid
  /// primary background for a stronger CTA.
  Widget _frostedPill({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.primaryColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  label,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Follow / unfollow the individual author of this reel. Optimistic — flips
  /// the local state immediately and reverts if the API call fails. Guests are
  /// routed to create a profile first.
  Future<void> _toggleFollow(String authorId) async {
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !wasFollowing);
    try {
      final res = wasFollowing
          ? await UserRepo().unfollowUser(followUserId: authorId)
          : await UserRepo().followUser(followUserId: authorId);
      if (!res.isSuccess) {
        if (mounted) setState(() => _isFollowing = wasFollowing);
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      if (mounted) setState(() => _isFollowing = wasFollowing);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Widget _buildBackButton() {
    return Positioned(
        left: 20.0,
        top: 20.0,
        child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Get.back();
            },
            icon: LocalAssets(
              imagePath: AppIconAssets.back_arrow,
              height: SizeConfig.paddingL,
              width: SizeConfig.paddingL,
              imgColor: AppColors.white,
            ))
        // child: Container(
        //   // padding: EdgeInsets.all(6.0),
        //   decoration: BoxDecoration(
        //     color: AppColors.black.withValues(alpha: 0.6),
        //     boxShadow: [AppShadows.textFieldShadow],
        //     shape: BoxShape.circle
        //   ),
        //   alignment: Alignment.center,
        //   child: IconButton(
        //       padding: EdgeInsets.zero,
        //       onPressed: () {
        //             Get.back();
        //           },
        //       icon: LocalAssets(
        //         imagePath: AppIconAssets.back_arrow,
        //         height: SizeConfig.paddingL,
        //         width: SizeConfig.paddingL,
        //         imgColor: AppColors.white,
        //       )),
        // ),
        );
  }

  void _navigateToProfile() {
    final item = fullScreenShortController.videoItem;
    final author = item?.author;

    // Channel-owned reel → channel screen.
    if (item?.channel?.id != null) {
      Navigator.pushNamed(
        context,
        RouteHelper.getChannelScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: author?.accountType,
          ApiKeys.channelId: item?.channel?.id,
          ApiKeys.authorId: author?.id,
        },
      );
      return;
    }

    final authorId = author?.id ?? '';

    // Own profile → no-op for now (the own profile screens are being reworked).
    if (authorId.isNotEmpty && authorId == userId) return;

    final isIndividual =
        author?.accountType?.toUpperCase() == AppConstants.individual;

    if (isIndividual) {
      // Individual → route by profile type (self-employed / professional /
      // gig / social). The rich Discover screen self-fetches by author id.
      VisitProfileResolver.openIndividual(
        profileType: author?.profileType ?? '',
        authorId: authorId,
      );
    } else {
      // Business → route by business type + category to the dedicated visit
      // screen (generic business profile when there's no dedicated match).
      VisitProfileResolver.open(
        accountType: author?.accountType,
        businessType: author?.businessType,
        businessCategory: author?.categoryOfBusiness,
        businessId: authorId,
        userId: authorId,
      );
    }
  }

  void _onLikeDislikePressed() async {
    final videoId = widget.videoItem.video?.id ?? '0';
    if (fullScreenShortController.isLiked.isTrue) {
      await fullScreenShortController.shortVideoUnLike(videoId: videoId);
      widget.videoItem.interactions?.isLiked = false;
      widget.videoItem.video?.stats?.likes =
          (widget.videoItem.video?.stats?.likes ?? 1) - 1;
    } else {
      await fullScreenShortController.shortVideoLike(videoId: videoId);
      widget.videoItem.interactions?.isLiked = true;
      widget.videoItem.video?.stats?.likes =
          (widget.videoItem.video?.stats?.likes ?? 0) + 1;
    }

    // finally sync controller again
    fullScreenShortController.isLiked.value =
        widget.videoItem.interactions?.isLiked ?? false;
    fullScreenShortController.likes.value =
        widget.videoItem.video?.stats?.likes ?? 0;

    // Sync changes back to ShortsController lists
    Get.find<ShortsController>().updateVideoLikeCount(
      shortsType: widget.shorts,
      videoId: videoId,
      isLiked: widget.videoItem.interactions?.isLiked ?? false,
      newLikeCount: widget.videoItem.video?.stats?.likes ?? 0,
    );
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
          widget.videoItem.video?.stats?.comments =
              fullScreenShortController.comments.value;

          // Sync comment count back to ShortsController lists
          Get.find<ShortsController>().updateVideoCommentCount(
            shortsType: widget.shorts,
            videoId: widget.videoItem.video?.id ?? '0',
            newCommentCount: newCommentCount,
          );
        },
      ),
    );
  }

  /// Simple, consistent share experience (like header_widget.dart)
  Future<void> _shareVideoSimple() async {
    // Prevent multiple calls
    if (_isShortSharing) return;

    try {
      _isShortSharing = true; // Set flag to prevent multiple calls

      final id = widget.videoItem.video?.id ?? widget.videoItem.videoId ?? '0';
      final link = shortDeepLink(shortId: id);
      final title = widget.videoItem.video?.title ?? 'BlueEra Short';

      final message = "Watch on BlueEra App:\n$link\n";

      await SharePlus.instance.share(ShareParams(
        text: message,
        subject: title,
      ));
    } catch (e) {
      print("Video share failed: $e");
    } finally {
      _isShortSharing = false; // Reset flag
    }
  }
}

// import 'dart:async';
// import 'dart:ui';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
// import 'package:BlueEra/features/common/feed/controller/full_screen_short_controller.dart';
// import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
// import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
// import 'package:BlueEra/widgets/cached_avatar_widget.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/expandable_text.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:video_player/video_player.dart';

// import 'dart:async';
// import 'dart:io';
// import 'dart:ui';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/core/services/hive_services.dart';
// import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
// import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
// import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
// import 'package:BlueEra/features/common/feed/controller/full_screen_short_controller.dart';
// import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
// import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
// import 'package:BlueEra/features/common/reel/widget/reels_shorts_popup_menu.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
// import 'package:BlueEra/widgets/cached_avatar_widget.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/expandable_text.dart';
// import 'package:BlueEra/widgets/image_view_screen.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:video_player/video_player.dart';
// import '../../../../../core/api/apiService/api_keys.dart';
// import '../../../../business/visit_business_profile/view/visit_business_profile_new.dart';
//
// class ShortPlayerItem extends StatefulWidget {
//   final ShortFeedItem videoItem;
//   final bool autoPlay;
//   final bool shouldPreload;
//   final VoidCallback onTapOption;
//   final Shorts shorts;
//
//   const ShortPlayerItem({
//     super.key,
//     required this.videoItem,
//     required this.autoPlay,
//     this.shouldPreload = false,
//     required this.onTapOption,
//     required this.shorts,
//   });
//
//   @override
//   State<ShortPlayerItem> createState() => ShortPlayerItemState();
// }
//
// class ShortPlayerItemState extends State<ShortPlayerItem>
//     with RouteAware, WidgetsBindingObserver {
//   bool _showOverlayIcon = false;
//   IconData _playPauseIcon = Icons.play_arrow;
//   final FullScreenShortController fullScreenShortController =
//   Get.put(FullScreenShortController());
//
//   VideoPlayerController? _controller;
//   late String profileImage;
//   late String name;
//   late String designation;
//   bool _initialized = false;
//   bool _hasError = false;
//   bool isShortSavedInDb = false;
//   bool _isDisposed = false;
//   bool _isCurrentPage = false; // Track if this is the current page
//   Timer? _overlayTimer;
//   Timer? _viewTimer;
//   bool _isShortSharing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     fullScreenShortController.videoItem = widget.videoItem;
//     getAndSetData();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_isDisposed) {
//         // Sync initial state from ShortsController lists to ensure consistency
//         final shortsController = Get.find<ShortsController>();
//         final videoId = widget.videoItem.video?.id ?? '0';
//
//         // Find the video in any of the lists to get the most up-to-date state
//         ShortFeedItem? updatedVideo;
//         final currentList =
//         shortsController.getListByType(shorts: widget.shorts);
//         for (final list in [currentList]) {
//           final index = list.indexWhere((v) => v.video?.id == videoId);
//           if (index != -1) {
//             updatedVideo = list[index];
//             break;
//           }
//         }
//
//         // Use updated video data if found, otherwise use widget data
//         final videoToUse = updatedVideo ?? widget.videoItem;
//
//         fullScreenShortController.isLiked.value =
//             videoToUse.interactions?.isLiked ?? false;
//         fullScreenShortController.likes.value =
//             videoToUse.video?.stats?.likes ?? 0;
//         fullScreenShortController.comments.value =
//             videoToUse.video?.stats?.comments ?? 0;
//
//         // Initialize player if should preload or autoplay
//         if (widget.shouldPreload || widget.autoPlay) {
//           _initializePlayer();
//         }
//
//         // Set up view tracking timer
//         _setupViewTimer();
//       }
//     });
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final route = ModalRoute.of(context);
//     if (route is PageRoute) {
//       RouteHelper.routeObserver.subscribe(this, route);
//     }
//   }
//
//   @override
//   void didUpdateWidget(ShortPlayerItem oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     // Handle autoplay changes
//     if (widget.autoPlay != oldWidget.autoPlay) {
//       _isCurrentPage = widget.autoPlay;
//       if (widget.autoPlay) {
//         // Only add lifecycle observer if this is the currently visible video
//         if (_isCurrentlyVisible()) {
//           WidgetsBinding.instance.addObserver(this);
//         }
//         _initializeAndPlay();
//       } else {
//         // Remove lifecycle observer when video becomes inactive
//         WidgetsBinding.instance.removeObserver(this);
//         _pauseVideo();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _isDisposed = true;
//     _overlayTimer?.cancel();
//     _viewTimer?.cancel();
//     RouteHelper.routeObserver.unsubscribe(this);
//     disposePlayer();
//     super.dispose();
//   }
//
//   @override
//   void didPushNext() {
//     // Pause video when navigating to another screen
//     if (_initialized &&
//         _controller != null &&
//         _controller?.value.isPlaying == true) {
//       _controller?.pause();
//     }
//     // Remove lifecycle observer when navigating away
//     WidgetsBinding.instance.removeObserver(this);
//     _isCurrentPage = false;
//   }
//
//   @override
//   void didPopNext() {
//     // Resume video when returning to this screen, but only if autoplay is enabled
//     if (_initialized && widget.autoPlay && _controller != null) {
//       _isCurrentPage = true;
//       // Only add lifecycle observer if this is the currently visible video
//       if (_isCurrentlyVisible()) {
//         WidgetsBinding.instance.addObserver(this);
//       }
//       // Add a small delay to ensure the navigation is complete
//       Future.delayed(const Duration(milliseconds: 200), () {
//         if (!_isDisposed && mounted && _isCurrentPage && widget.autoPlay) {
//           _controller?.play();
//         }
//       });
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     if (_isDisposed || _controller == null || !_initialized) return;
//
//     switch (state) {
//       case AppLifecycleState.paused:
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.detached:
//       // Pause video when app goes to background
//         if (_controller?.value.isPlaying ?? false) {
//           _controller?.pause();
//         }
//         break;
//       case AppLifecycleState.resumed:
//       // Only resume if this is the currently visible video and we're on the shorts player screen
//         if (_isCurrentlyVisible() && _controller != null) {
//           // Double-check that we're still on the shorts player screen
//           final route = ModalRoute.of(context);
//           if (route?.settings.name?.contains('shorts_player') == true) {
//             // Add a small delay to ensure the app is fully resumed
//             Future.delayed(const Duration(milliseconds: 300), () {
//               if (!_isDisposed && mounted && _isCurrentlyVisible()) {
//                 _controller?.play();
//               }
//             });
//           }
//         }
//         break;
//       default:
//         break;
//     }
//   }
//
//   void _setupViewTimer() {
//     _viewTimer = Timer(const Duration(seconds: 5), () {
//       if (!_isDisposed) {
//         fullScreenShortController.shortVideoView(
//           videoId: fullScreenShortController.videoItem?.video?.id ?? '0',
//         );
//       }
//     });
//   }
//
//   bool _isCurrentlyVisible() {
//     // Check if we're on the shorts player screen
//     final route = ModalRoute.of(context);
//     if (route?.settings.name?.contains('shorts_player') != true) {
//       return false;
//     }
//
//     // Check if this video is the currently active one
//     // You can add more specific logic here if needed
//     return widget.autoPlay && _isCurrentPage;
//   }
//
//   void _initializeAndPlay() async {
//     if (_controller == null && !_isDisposed) {
//       await _initializePlayer();
//     }
//     if (_initialized && !_isDisposed) {
//       _controller?.play();
//     }
//   }
//
//   void _onVideoTap() {
//     if (_controller == null || !_initialized) return;
//
//     if (_controller?.value.isPlaying ?? false) {
//       _controller?.pause();
//       _playPauseIcon = Icons.pause_rounded;
//     } else {
//       _controller?.play();
//       _playPauseIcon = Icons.play_arrow;
//     }
//
//     if (!_isDisposed) {
//       setState(() {
//         _showOverlayIcon = true;
//       });
//
//       // Cancel previous timer
//       _overlayTimer?.cancel();
//
//       // Hide after 1.5 seconds
//       _overlayTimer = Timer(const Duration(milliseconds: 1500), () {
//         if (mounted && !_isDisposed) {
//           setState(() {
//             if (_controller != null &&
//                 (_controller?.value.isPlaying ?? false)) {
//               _showOverlayIcon = false;
//             }
//           });
//         }
//       });
//     }
//   }
//
//   Future<void> _initializePlayer() async {
//     if (_controller != null || _isDisposed) return;
//
//     try {
//       final videoUrl = fullScreenShortController.videoItem?.video?.22transcodedUrls?.master ?? fullScreenShortController.videoItem?.video?.videoUrl;
//       if (videoUrl == null || videoUrl.isEmpty) {
//         if (!_isDisposed) {
//           setState(() => _hasError = true);
//         }
//         return;
//       }
//
//       _controller = VideoPlayerController.networkUrl(
//         Uri.parse(videoUrl),
//         videoPlayerOptions: isHlsUrl(videoUrl)
//             ? VideoPlayerOptions(mixWithOthers: true)
//             : null,
//       );
//
//       await _controller!.initialize();
//
//       if (!_isDisposed) {
//         _controller?.setLooping(true);
//         _controller?.setVolume(1.0);
//
//         if (widget.autoPlay) {
//           _controller?.play();
//         }
//
//         setState(() => _initialized = true);
//       }
//     } catch (e) {
//       debugPrint('Video init error: $e');
//       if (!_isDisposed) {
//         setState(() => _hasError = true);
//       }
//     }
//   }
//
//   void getAndSetData() {
//     if (fullScreenShortController.videoItem?.channel?.id != null) {
//       profileImage =
//           fullScreenShortController.videoItem?.channel?.logoUrl ?? '';
//       name = fullScreenShortController.videoItem?.channel?.name ?? '';
//       designation =
//           fullScreenShortController.videoItem?.channel?.username ?? '';
//     } else {
//       profileImage =
//           fullScreenShortController.videoItem?.author?.profileImage ?? '';
//       name = widget.videoItem.author?.name ?? '';
//       designation = widget.videoItem.author?.username ?? '';
//       // designation = widget.videoItem.author?.designation ?? '';
//     }
//     isShortSavedInDb = HiveServices()
//         .isVideoSaved(fullScreenShortController.videoItem?.videoId ?? '');
//   }
//
//   // Public methods for external control
//   void playVideo() {
//     if (_controller == null) {
//       _initializeAndPlay();
//     } else if (_initialized) {
//       _controller?.play();
//     }
//   }
//
//   void pauseVideo() {
//     _pauseVideo();
//   }
//
//   void _pauseVideo() {
//     if (_initialized && _controller != null) {
//       _controller?.pause();
//     }
//   }
//
//   void disposePlayer() {
//     _overlayTimer?.cancel();
//     _viewTimer?.cancel();
//     _controller?.dispose();
//     _controller = null;
//     _initialized = false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_hasError) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             LocalAssets(imagePath: AppIconAssets.appIcon),
//             const SizedBox(height: 8),
//             const CustomText('Failed to load video'),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _hasError = false;
//                   _initialized = false;
//                 });
//                 _initializePlayer();
//               },
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return SafeArea(
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           _buildVideoPlayer(),
//           _buildPlayPauseOverlay(),
//           _buildActionButtons(),
//           _buildVideoInfo(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVideoPlayer() {
//     return _initialized && _controller != null
//         ? Align(
//       alignment: Alignment.center,
//       child: GestureDetector(
//         onTap: _onVideoTap,
//         child: AspectRatio(
//           aspectRatio: _controller?.value.aspectRatio ?? 9 / 16,
//           child: VideoPlayer(_controller!),
//         ),
//       ),
//     )
//         : AspectRatio(
//       aspectRatio: 9 / 16,
//       child: CachedNetworkImage(
//         imageUrl: widget.videoItem.video?.coverUrl ?? '',
//         width: SizeConfig.screenWidth,
//         height: SizeConfig.size170,
//         fit: BoxFit.cover,
//         placeholder: (_, __) => Container(
//           width: SizeConfig.screenWidth,
//           height: SizeConfig.size140,
//           color: Colors.grey[300],
//           child: const Center(child: CircularProgressIndicator()),
//         ),
//         errorWidget: (_, __, ___) => Container(
//           width: SizeConfig.screenWidth,
//           height: SizeConfig.size140,
//           color: Colors.grey[300],
//           child: LocalAssets(imagePath: AppIconAssets.appIcon),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlayPauseOverlay() {
//     return Center(
//       child: AnimatedOpacity(
//         opacity: _showOverlayIcon ? 1.0 : 0.0,
//         duration: const Duration(milliseconds: 300),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(25.0),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Container(
//               height: 45,
//               width: 45,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white.withValues(alpha: 0.4),
//               ),
//               child: Icon(
//                 _playPauseIcon,
//                 size: 36,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Positioned(
//       right: SizeConfig.size20,
//       bottom: SizeConfig.size220,
//       child: Column(
//         children: [
//           Obx(() => Column(
//             children: [
//               InkWell(
//                 onTap: () {
//                   if (isGuestUser()) {
//                     createProfileScreen();
//                   } else {
//                     _onLikeDislikePressed();
//                   }
//                 },
//                 child: fullScreenShortController.isLiked.isTrue
//                     ? LocalAssets(imagePath: AppIconAssets.reel_like_fill)
//                     : LocalAssets(
//                     imagePath: AppIconAssets.reel_like,
//                     imgColor: AppColors.white),
//               ),
//               SizedBox(height: SizeConfig.size5),
//               CustomText(
//                 formatNumberLikePost(fullScreenShortController.likes.value),
//                 fontSize: SizeConfig.medium15,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.white,
//               ),
//             ],
//           )),
//           SizedBox(height: SizeConfig.size15),
//           InkWell(
//             onTap: () {
//               if (isGuestUser()) {
//                 createProfileScreen();
//               } else {
//                 _onCommentPressed();
//               }
//             },
//             child: LocalAssets(
//                 imagePath: AppIconAssets.reel_comment,
//                 imgColor: AppColors.white),
//           ),
//           SizedBox(height: SizeConfig.size5),
//           Obx(() => CustomText(
//             formatNumberLikePost(fullScreenShortController.comments.value),
//             fontSize: SizeConfig.medium15,
//             fontWeight: FontWeight.w700,
//             color: AppColors.white,
//           )),
//           SizedBox(height: SizeConfig.size15),
//           InkWell(
//             onTap: () => _shareVideoSimple(),
//             child: LocalAssets(
//                 imagePath: AppIconAssets.reel_share, imgColor: AppColors.white),
//           ),
//           SizedBox(height: SizeConfig.size3),
//           InkWell(
//             onTap: () => _shareVideoSimple(),
//             child: CustomText(
//               formatNumberLikePost(
//                   fullScreenShortController.videoItem?.video?.stats?.shares ?? 0),
//               fontSize: SizeConfig.medium15,
//               fontWeight: FontWeight.w700,
//               color: AppColors.white,
//             ),
//           ),
//           SizedBox(height: SizeConfig.size15),
//           InkWell(
//             onTap: () async {
//               isShortSavedInDb = await Get.find<ShortsController>()
//                   .saveVideosToLocalDB(
//                   videoFeedItem: fullScreenShortController.videoItem!);
//               if (!_isDisposed) {
//                 setState(() {});
//               }
//
//               // Sync saved state back to ShortsController lists
//               Get.find<ShortsController>().updateVideoSavedState(
//                 videoId: fullScreenShortController.videoItem?.video?.id ?? '0',
//                 isSaved: isShortSavedInDb,
//               );
//             },
//             child: LocalAssets(
//                 imagePath: isShortSavedInDb
//                     ? AppIconAssets.reel_save_fill
//                     : AppIconAssets.reel_save,
//                 imgColor: AppColors.white),
//           ),
//           SizedBox(height: SizeConfig.size5),
//
//           CustomText(
//             "Save",
//             fontSize: SizeConfig.medium15,
//             fontWeight: FontWeight.w700,
//             color: AppColors.white,
//           ),
//           // SizedBox(height: SizeConfig.size15),
//           // LocalAssets(
//           //     imagePath: AppIconAssets.audioOutlinedIcon,
//           //     imgColor: AppColors.white),
//
//           SizedBox(height: SizeConfig.size10),
//           if (fullScreenShortController.videoItem?.channel?.id != null)
//             if (fullScreenShortController.videoItem?.channel?.id != channelId)
//               IconButton(
//                 onPressed: () {
//                   if (isGuestUser()) {
//                     createProfileScreen();
//                   } else {
//                     widget.onTapOption();
//                   }
//                 },
//                 icon: LocalAssets(
//                     imagePath: AppIconAssets.blockIcon,
//                     imgColor: AppColors.white),
//               )
//             else
//               ReelShortPopUpMenu(
//                   shortFeedItem: widget.videoItem,
//                   popUpMenuColor: AppColors.black,
//                   shorts: widget.shorts)
//           else if (fullScreenShortController.videoItem?.author?.accountType ==
//               AppConstants.individual)
//             if (fullScreenShortController.videoItem?.author?.id != userId)
//               IconButton(
//                 onPressed: () {
//                   if (isGuestUser()) {
//                     createProfileScreen();
//                   } else {
//                     widget.onTapOption();
//                   }
//                 },
//                 icon: LocalAssets(
//                     imagePath: AppIconAssets.blockIcon,
//                     imgColor: AppColors.white),
//               )
//             else
//               ReelShortPopUpMenu(
//                   shortFeedItem: widget.videoItem,
//                   popUpMenuColor: AppColors.black,
//                   shorts: widget.shorts)
//           else if (fullScreenShortController.videoItem?.author?.accountType ==
//                 AppConstants.business)
//               if (fullScreenShortController.videoItem?.author?.id != userId)
//                 IconButton(
//                   onPressed: () {
//                     if (isGuestUser()) {
//                       createProfileScreen();
//                     } else {
//                       widget.onTapOption();
//                     }
//                   },
//                   icon: LocalAssets(
//                       imagePath: AppIconAssets.blockIcon,
//                       imgColor: AppColors.white),
//                 )
//               else
//                 ReelShortPopUpMenu(
//                     shortFeedItem: widget.videoItem,
//                     popUpMenuColor: AppColors.black,
//                     shorts: widget.shorts),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVideoInfo() {
//     return Positioned(
//       left: 16,
//       right: SizeConfig.size20,
//       bottom: SizeConfig.size40,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildUserInfo(),
//           if (fullScreenShortController.videoItem?.video?.title?.isNotEmpty ??
//               false) ...[
//             SizedBox(height: SizeConfig.size10),
//             ExpandableText(
//               text: fullScreenShortController.videoItem?.video?.title ?? '',
//               style: TextStyle(
//                 color: AppColors.white,
//                 fontSize: SizeConfig.medium15,
//               ),
//             )
//           ],
//           if (fullScreenShortController
//               .videoItem?.video?.description?.isNotEmpty ??
//               false) ...[
//             Container(
//               child: Padding(
//                 padding: EdgeInsets.only(right: SizeConfig.size40),
//                 child: ExpandableText(
//                   text:
//                   fullScreenShortController.videoItem?.video?.description ??
//                       '',
//                   style: TextStyle(
//                       color: AppColors.white,
//                       fontWeight: FontWeight.w500,
//                       fontSize: SizeConfig.size13),
//                 ),
//               ),
//             ),
//           ],
//           if ((fullScreenShortController.videoItem?.channel?.id?.isNotEmpty ??
//               false) &&
//               (fullScreenShortController
//                   .videoItem?.video?.acceptBookingsOrEnquiries ??
//                   false)) ...[
//             SizedBox(height: SizeConfig.size10),
//             Row(
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.blackD9,
//                     padding: EdgeInsets.symmetric(
//                         horizontal: SizeConfig.size20,
//                         vertical: SizeConfig.size10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: () {
//                     if (isGuestUser()) {
//                       createProfileScreen();
//                     } else {
//                       Navigator.pushNamed(
//                         context,
//                         RouteHelper.sentEnquiresRoute(),
//                         arguments: {
//                           ApiKeys.channelId:
//                           fullScreenShortController.videoItem?.channel?.id,
//                           ApiKeys.videoId:
//                           fullScreenShortController.videoItem?.videoId,
//                         },
//                       );
//                     }
//                   },
//                   child: CustomText(
//                     "Send Enquiry",
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//                 SizedBox(width: SizeConfig.size10),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.blackD9,
//                     padding: EdgeInsets.symmetric(
//                         horizontal: SizeConfig.size20,
//                         vertical: SizeConfig.size10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: () {
//                     if (isGuestUser()) {
//                       createProfileScreen();
//                     } else {
//                       Navigator.pushNamed(
//                         context,
//                         RouteHelper.getAppointmentBookingScreenRoute(),
//                         arguments: {
//                           ApiKeys.channelId:
//                           fullScreenShortController.videoItem?.channel?.id,
//                           ApiKeys.videoId:
//                           fullScreenShortController.videoItem?.videoId,
//                         },
//                       );
//                     }
//                   },
//                   child: CustomText(
//                     "Book Appointment",
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primaryColor,
//                   ),
//                 ),
//                 SizedBox(height: SizeConfig.size15),
//               ],
//             )
//           ],
//
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUserInfo() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         InkWell(
//           onTap: () => navigatePushTo(
//             context,
//             ImageViewScreen(
//               appBarTitle: '',
//               imageUrls: [profileImage],
//               initialIndex: 0,
//             ),
//           ),
//           child: CachedAvatarWidget(
//             imageUrl: profileImage,
//             size: SizeConfig.size40,
//             borderRadius: SizeConfig.size20,
//             borderColor: AppColors.primaryColor,
//           ),
//         ),
//         SizedBox(width: SizeConfig.size8),
//         Expanded(
//           child: InkWell(
//             onTap: () {
//               _navigateToProfile();
//             },
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CustomText(
//                   name,
//                   fontSize: SizeConfig.large18,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.white,
//                 ),
//                 SizedBox(height: SizeConfig.size1),
//                 CustomText(
//                   "@${designation}",
//                   fontSize: SizeConfig.small,
//                   color: AppColors.white,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         SizedBox(width: SizeConfig.size8),
//         // Column(
//         //   crossAxisAlignment: CrossAxisAlignment.center,
//         //   children: [
//         //     Row(
//         //       children: [
//         //         LocalAssets(
//         //             imagePath: AppIconAssets.viewIcon,
//         //             imgColor: AppColors.grey68),
//         //         SizedBox(width: SizeConfig.size1),
//         //         CustomText(
//         //           (fullScreenShortController.videoItem?.video?.stats?.views ??
//         //                   0)
//         //               .toString(),
//         //           color: AppColors.grey68,
//         //         ),
//         //       ],
//         //     ),
//         //     SizedBox(height: SizeConfig.size1),
//         //     CustomText(
//         //       timeAgo(DateTime.parse(
//         //           fullScreenShortController.videoItem?.video?.createdAt ??
//         //               DateTime.now().toIso8601String())),
//         //       color: AppColors.grey68,
//         //     ),
//         //   ],
//         // )
//       ],
//     );
//   }
//
//   void _navigateToProfile() {
//     if (fullScreenShortController.videoItem?.channel?.id != null) {
//       Navigator.pushNamed(
//         context,
//         RouteHelper.getChannelScreenRoute(),
//         arguments: {
//           ApiKeys.argAccountType:
//           fullScreenShortController.videoItem?.author?.accountType,
//           ApiKeys.channelId: fullScreenShortController.videoItem?.channel?.id,
//           ApiKeys.authorId: fullScreenShortController.videoItem?.author?.id
//         },
//       );
//     } else {
//       if (fullScreenShortController.videoItem?.author?.accountType
//           ?.toUpperCase() ==
//           AppConstants.individual) {
//         if (fullScreenShortController.videoItem?.author?.id == userId) {
//           navigatePushTo(context, PersonalProfileSetupScreen());
//         } else {
//           Get.to(() => VisitProfileScreen(
//               authorId: fullScreenShortController.videoItem?.author?.id ?? ''));
//         }
//       } else {
//         if (fullScreenShortController.videoItem?.author?.id == userId) {
//           navigatePushTo(context, BusinessOwnProfileScreen());
//         } else {
//           Get.to(() => VisitBusinessProfileNew(
//               businessId:
//               fullScreenShortController.videoItem?.author?.id ?? ''));
//         }
//       }
//     }
//   }
//
//   void _onLikeDislikePressed() async {
//     final videoId = widget.videoItem.video?.id ?? '0';
//     if (fullScreenShortController.isLiked.isTrue) {
//       await fullScreenShortController.shortVideoUnLike(videoId: videoId);
//       widget.videoItem.interactions?.isLiked = false;
//       widget.videoItem.video?.stats?.likes =
//           (widget.videoItem.video?.stats?.likes ?? 1) - 1;
//     } else {
//       await fullScreenShortController.shortVideoLike(videoId: videoId);
//       widget.videoItem.interactions?.isLiked = true;
//       widget.videoItem.video?.stats?.likes =
//           (widget.videoItem.video?.stats?.likes ?? 0) + 1;
//     }
//
//     // finally sync controller again
//     fullScreenShortController.isLiked.value =
//         widget.videoItem.interactions?.isLiked ?? false;
//     fullScreenShortController.likes.value =
//         widget.videoItem.video?.stats?.likes ?? 0;
//
//     // Sync changes back to ShortsController lists
//     Get.find<ShortsController>().updateVideoLikeCount(
//       shortsType: widget.shorts,
//       videoId: videoId,
//       isLiked: widget.videoItem.interactions?.isLiked ?? false,
//       newLikeCount: widget.videoItem.video?.stats?.likes ?? 0,
//     );
//   }
//
//
//   // void _onLikeDislikePressed() async {
//   //   final videoId = widget.videoItem.video?.id ?? '0';
//   //   final currentLikedState = fullScreenShortController.isLiked.isTrue;
//   //
//   //   // Update UI immediately for better user experience
//   //   if (currentLikedState) {
//   //     // Currently liked, so unlike
//   //     widget.videoItem.interactions?.isLiked = false;
//   //     widget.videoItem.video?.stats?.likes =
//   //         (widget.videoItem.video?.stats?.likes ?? 1) - 1;
//   //     fullScreenShortController.isLiked.value = false;
//   //   } else {
//   //     // Currently not liked, so like
//   //     widget.videoItem.interactions?.isLiked = true;
//   //     widget.videoItem.video?.stats?.likes =
//   //         (widget.videoItem.video?.stats?.likes ?? 0) + 1;
//   //     fullScreenShortController.isLiked.value = true;
//   //   }
//   //
//   //   // Update UI controller
//   //   fullScreenShortController.likes.value =
//   //       widget.videoItem.video?.stats?.likes ?? 0;
//   //
//   //   // Sync changes back to ShortsController lists immediately
//   //   Get.find<ShortsController>().updateVideoLikeCount(
//   //     shortsType: widget.shorts,
//   //     videoId: videoId,
//   //     isLiked: widget.videoItem.interactions?.isLiked ?? false,
//   //     newLikeCount: widget.videoItem.video?.stats?.likes ?? 0,
//   //   );
//   //
//   //   // Set pending API call state
//   //   fullScreenShortController.pendingLikeStates[videoId] = !currentLikedState; // New state after toggle
//   //
//   //   // Cancel existing timer for this video ID
//   //   fullScreenShortController.likeDebounceTimers[videoId]?.cancel();
//   //
//   //   // Start new timer for this video ID
//   //   fullScreenShortController.likeDebounceTimers[videoId] = Timer(const Duration(milliseconds: 400), () {
//   //     fullScreenShortController.executePendingLikeAction(videoId);
//   //   });
//   // }
//
//
//   void _onCommentPressed() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => CommentBottomSheet(
//         id: fullScreenShortController.videoItem?.video?.id ?? '0',
//         totalComments:
//         fullScreenShortController.videoItem?.video?.stats?.comments ?? 0,
//         commentType: CommentType.video,
//         onNewCommentCount: (int newCommentCount) {
//           fullScreenShortController.comments.value = newCommentCount;
//           widget.videoItem.video?.stats?.comments =
//               fullScreenShortController.comments.value;
//
//           // Sync comment count back to ShortsController lists
//           Get.find<ShortsController>().updateVideoCommentCount(
//             shortsType: widget.shorts,
//             videoId: widget.videoItem.video?.id ?? '0',
//             newCommentCount: newCommentCount,
//           );
//         },
//       ),
//     );
//   }
//   /// Simple, consistent share experience (like header_widget.dart)
//   Future<void> _shareVideoSimple() async {
//     // Prevent multiple calls
//     if (_isShortSharing) return;
//
//     try {
//       _isShortSharing = true; // Set flag to prevent multiple calls
//
//       final id = widget.videoItem.video?.id ?? widget.videoItem.videoId ?? '0';
//       final link = shortDeepLink(shortId: id);
//       final title = widget.videoItem.video?.title ?? 'BlueEra Short';
//
//       final message = "Watch on BlueEra App:\n$link\n";
//
//       await SharePlus.instance.share(ShareParams(
//         text: message,
//         subject: title,
//       ));
//
//     } catch (e) {
//       print("Video share failed: $e");
//     } finally {
//       _isShortSharing = false; // Reset flag
//     }
//   }
//
//
// }
