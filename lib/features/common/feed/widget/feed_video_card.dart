import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Renders a `type: "short_video"` or `type: "long_video"` entry from the mixed
/// `/feed` response (see docs/backend/FRONTEND_FEED_INTEGRATION.md §4.4) as an
/// autoplaying card.
///
/// The two types share one schema and differ only in surface, so they share one
/// widget and branch on shape + destination:
///   * `short_video` → tall 9:16-ish card → full-screen vertical reels player.
///   * `long_video`  → 16:9 card → the long-form video player.
///
/// Playback is delegated to the shared [SimplePriorityVideoManager] — the same
/// manager `PostFeedAutoPlayVideoCard` uses for video attached to posts. It owns
/// a single [VideoPlayerController], so exactly one video plays across the whole
/// feed no matter which card type wins visibility; it also holds the startup
/// warmup guard and the global mute state. Registering here rather than spinning
/// up our own controller is what keeps a feed video and a post video from
/// playing over each other.
class FeedVideoCard extends StatefulWidget {
  final Post post;
  final double? horizontalPadding;
  final double? bottomPadding;

  const FeedVideoCard({
    super.key,
    required this.post,
    this.horizontalPadding,
    this.bottomPadding,
  });

  @override
  State<FeedVideoCard> createState() => _FeedVideoCardState();
}

class _FeedVideoCardState extends State<FeedVideoCard> {
  final videoManager = Get.isRegistered<SimplePriorityVideoManager>()
      ? Get.find<SimplePriorityVideoManager>()
      : Get.put(SimplePriorityVideoManager());

  Post get post => widget.post;

  bool get _isShort => post.feedType == 'short_video';

  /// The playable source. `/feed` video items carry it in `video_url`
  /// (guide §4.4); fall back to `media` for post-shaped payloads that inline it.
  String get _videoUrl {
    final url = post.videoUrl ?? '';
    if (url.isNotEmpty) return url;
    return post.media?.firstOrNull ?? '';
  }

  /// Cover art. The guide names this `thumbnail` for video items; fall back to
  /// the first media entry for older/looser payloads.
  String get _cover {
    final thumb = post.thumbnail ?? '';
    if (thumb.isNotEmpty) return thumb;
    return post.media?.firstOrNull ?? '';
  }

  @override
  void dispose() {
    // Drop out of the manager's visibility race, else a scrolled-away card can
    // still hold the "top video" slot and starve the visible one.
    videoManager.removeVideo(post.id);
    super.dispose();
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    // A sourceless item must never register: the manager would take it as the
    // priority video, fail to initialise an empty URL, and block a real video
    // from playing in its place.
    if (_videoUrl.isEmpty) return;
    videoManager.updateVideoVisibility(
      post.id,
      _videoUrl,
      info.visibleFraction,
    );
  }

  /// Opens the full-screen vertical reels player seeded with just the tapped
  /// video, then infinite-scrolls fresh content after it: `/videos/hot/short`
  /// for a short, `/videos/hot/long` for a long video. The player is shared
  /// with the Reels tab, so every action (like / comment / share / save /
  /// follow / report / block / view-count) works unchanged — it keys off the
  /// [Shorts] bucket we hand over here.
  ///
  /// We prime a dedicated home-feed bucket (`homeShort` / `homeLong`) rather
  /// than the trending list so the Reels tab's own list and scroll position are
  /// never disturbed.
  void _openInfiniteVideoPlayer() {
    final item = getVideoData(post);
    final controller = Get.isRegistered<ShortsController>()
        ? Get.find<ShortsController>()
        : Get.put(ShortsController());

    final shorts = _isShort ? Shorts.homeShort : Shorts.homeLong;
    controller.primeHomeFeed(isLong: !_isShort, initial: [item]);

    Navigator.pushNamed(
      context,
      RouteHelper.getShortsPlayerScreenRoute(),
      arguments: {
        ApiKeys.shorts: shorts,
        ApiKeys.videoItem: [item],
        ApiKeys.initialIndex: 0,
      },
    );
  }

  void _onTap() {
    // A video item with no playable source would open an empty player.
    if (_videoUrl.isEmpty) return;
    _openInfiniteVideoPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalPadding ?? SizeConfig.size14,
        SizeConfig.size6,
        widget.horizontalPadding ?? SizeConfig.size14,
        widget.bottomPadding ?? SizeConfig.size8,
      ),
      child: GestureDetector(
        onTap: _onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VisibilityDetector(
            // Namespaced so a feed video and a post video sharing an id can't
            // collide in VisibilityDetector's global key registry.
            key: ValueKey('feed_video_${post.id}'),
            onVisibilityChanged: _handleVisibilityChange,
            child: SizedBox(
              width: double.infinity,
              // A short is a tall teaser; a long video keeps its native 16:9.
              height: _isShort ? SizeConfig.screenHeight * 0.46 : null,
              child: _isShort
                  ? _buildCard()
                  : AspectRatio(aspectRatio: 16 / 9, child: _buildCard()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return GetBuilder<SimplePriorityVideoManager>(
      builder: (manager) {
        final controller = manager.controller;
        final isCurrent = manager.currentIndex.value == post.id.hashCode;
        final bool showVideo = isCurrent &&
            controller != null &&
            controller.value.isInitialized &&
            controller.value.size.width > 0 &&
            controller.value.size.height > 0;

        return ColoredBox(
          color: AppColors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover always paints underneath, so the card never flashes empty
              // while the shared controller initialises.
              _buildCover(),

              if (showVideo)
                FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),

              // Play affordance — only while this card isn't playing, so it
              // doesn't sit on top of live video. The cover underneath doubles
              // as the loading state while the shared controller spins up.
              if (!showVideo)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.white,
                      size: SizeConfig.size30,
                    ),
                  ),
                ),

              _buildTypeBadge(),

              if (showVideo) _buildMuteButton(manager),

              // Duration, bottom-right. Hidden while playing (the player's own
              // progress supersedes it) and for live streams, which have no
              // meaningful runtime.
              if ((post.duration ?? 0) > 0 && post.live != true && !showVideo)
                Positioned(
                  right: SizeConfig.size10,
                  bottom: SizeConfig.size10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size6,
                      vertical: SizeConfig.size2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CustomText(
                      _formatDuration(post.duration!),
                      color: AppColors.white,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              _buildMetaScrim(),

              // The manager replays once, then parks on this overlay.
              if (isCurrent) _buildReplayOverlay(manager),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCover() {
    final cover = _cover;
    if (cover.isNotEmpty && isNetworkImage(cover)) {
      return CachedNetworkImage(
        imageUrl: cover,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: AppColors.black30),
        errorWidget: (_, __, ___) => LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
        ),
      );
    }
    return LocalAssets(
      imagePath: AppIconAssets.place_holder_image,
      boxFix: BoxFit.cover,
    );
  }

  /// Type badge, top-left. A live stream outranks the short/long distinction —
  /// `live: true` is the thing the viewer needs to see.
  Widget _buildTypeBadge() {
    return Positioned(
      top: SizeConfig.size10,
      left: SizeConfig.size10,
      child: post.live == true
          ? const _Badge(
              icon: Icons.circle,
              label: 'LIVE',
              color: Colors.red,
              iconScale: 0.6,
            )
          : _Badge(
              icon: _isShort
                  ? Icons.movie_creation_outlined
                  : Icons.ondemand_video_rounded,
              label: _isShort ? 'Short' : 'Video',
            ),
    );
  }

  Widget _buildMuteButton(SimplePriorityVideoManager manager) {
    return Positioned(
      top: SizeConfig.size10,
      right: SizeConfig.size10,
      child: GestureDetector(
        // Muting must not also open the player.
        onTap: manager.toggleMute,
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size6),
          decoration: BoxDecoration(
            color: AppColors.blackCC,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: manager.isMuted,
            builder: (_, isMuted, __) => Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: AppColors.white,
              size: SizeConfig.size20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplayOverlay(SimplePriorityVideoManager manager) {
    return Obx(() {
      if (!manager.showReplayOverlay.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: GestureDetector(
          onTap: () => manager.playVideo(post.id),
          child: ColoredBox(
            color: Colors.black45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: AppColors.white, size: SizeConfig.size30),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  'Watch again',
                  color: AppColors.white,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMetaScrim() {
    final title = (post.title?.trim().isNotEmpty ?? false)
        ? post.title!.trim()
        : (post.subTitle?.trim() ?? '');

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size10,
            SizeConfig.size24,
            SizeConfig.size10,
            SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty) ...[
                CustomText(
                  title,
                  color: AppColors.white,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size4),
              ],
              Row(
                children: [
                  // Channel name when the video has one, else the author.
                  Flexible(
                    child: CustomText(
                      post.channel?.name ?? post.user?.name ?? '',
                      color: AppColors.white,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Icon(Icons.play_arrow_rounded,
                      color: AppColors.white, size: SizeConfig.size18),
                  SizedBox(width: SizeConfig.size2),
                  CustomText(
                    formatNumberLikePost(post.viewsCount ?? 0),
                    color: AppColors.white,
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `duration` arrives in seconds (guide §4.4) — render as m:ss / h:mm:ss.
  static String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final mm = d.inMinutes.remainder(60).toString();
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${mm.padLeft(2, '0')}:$ss';
    }
    return '$mm:$ss';
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final double iconScale;

  const _Badge({
    required this.icon,
    required this.label,
    this.color,
    this.iconScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: SizeConfig.size14 * iconScale),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            label,
            color: AppColors.white,
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
