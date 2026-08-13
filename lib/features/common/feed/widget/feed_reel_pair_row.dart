import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart'
    show getVideoData;
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Two reels rendered side by side in the feed, as in the Feed design.
///
/// Only *consecutive* reel items are paired ([homeFeedReelPairing] in
/// `home_feed_screen_new.dart` does the grouping); a reel with a post on either
/// side stays a full-width [FeedVideoCard]. That keeps the backend's ordering
/// authoritative — we change how a run of reels is laid out, never the order
/// items arrive in.
///
/// Unlike [FeedVideoCard] these tiles do not play inline. Two simultaneous
/// autoplaying videos in one feed row is exactly the frame-time cliff the
/// single-video visibility manager exists to prevent, and the design shows
/// static covers.
class FeedReelPairRow extends StatelessWidget {
  const FeedReelPairRow({super.key, required this.reels});

  /// Always 1 or 2 items. A trailing odd reel renders alone at half width so
  /// the column alignment survives an odd-length run.
  final List<Post> reels;

  /// Width : height of one tile. Tuned to the Feed design, where the paired
  /// tiles are noticeably shorter than the portrait tiles in the Bites grid.
  static const double _tileAspect = 1.1;

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _FeedReelTile(post: reels.first, aspect: _tileAspect)),
          SizedBox(width: SizeConfig.size8),
          // Keeps a lone trailing reel at half width instead of letting it
          // stretch across the row and read as a different component.
          Expanded(
            child: reels.length > 1
                ? _FeedReelTile(post: reels[1], aspect: _tileAspect)
                : AspectRatio(
                    aspectRatio: _tileAspect,
                    child: const SizedBox.shrink(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeedReelTile extends StatelessWidget {
  const _FeedReelTile({required this.post, required this.aspect});

  final Post post;
  final double aspect;

  /// A reel arrives either wrapped (`item_type: "reel"`, payload under `reel`)
  /// or flat (`type: "short_video"`), so read both shapes.
  String? get _coverUrl {
    final reelCover = post.reel?.coverUrl;
    if (reelCover != null && reelCover.isNotEmpty) return reelCover;
    final thumbnail = post.thumbnail;
    if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;
    return post.media?.firstOrNull;
  }

  String get _title {
    final reelText = post.reel?.displayText ?? '';
    if (reelText.isNotEmpty) return reelText;
    final title = post.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    return post.message?.trim() ?? '';
  }

  int get _views => post.reel?.stats.views ?? post.viewsCount ?? 0;

  /// Same entry point [FeedVideoCard] uses: prime the dedicated home-feed
  /// bucket so the Reels tab's own list and scroll position stay untouched,
  /// then open the shared full-screen player.
  void _openPlayer(BuildContext context) {
    final item = getVideoData(post);
    if ((item.video?.videoUrl?.isEmpty ?? true)) return;

    final controller = Get.isRegistered<ShortsController>()
        ? Get.find<ShortsController>()
        : Get.put(ShortsController());
    controller.primeHomeFeed(isLong: false, initial: [item]);

    Navigator.pushNamed(
      context,
      RouteHelper.getShortsPlayerScreenRoute(),
      arguments: {
        ApiKeys.shorts: Shorts.homeShort,
        ApiKeys.videoItem: [item],
        ApiKeys.initialIndex: 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = _coverUrl;
    final title = _title;

    return GestureDetector(
      onTap: () => _openPlayer(context),
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null && cover.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: cover,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.whiteE5),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.whiteE5),
                )
              else
                Container(color: AppColors.whiteE5),
              // Scrim: the caption and count are white, and reel covers are
              // frequently bright.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0xB3000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                left: SizeConfig.size8,
                right: SizeConfig.size8,
                bottom: SizeConfig.size8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      CustomText(
                        title,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: SizeConfig.size4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: SizeConfig.size16,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 2),
                        CustomText(
                          formatNumberLikePost(_views),
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
