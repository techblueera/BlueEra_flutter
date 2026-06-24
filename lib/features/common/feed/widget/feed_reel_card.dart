import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders one `item_type: "reel"` entry from the mixed post/reel feed
/// (see docs/backend/REELS_IN_FEED_FRONTEND_GUIDE.md) as a tappable cover card
/// that opens the full-screen vertical reels player.
///
/// Kept deliberately simple (cover + play + caption + views) — it's a teaser in
/// the post feed, not an autoplaying surface like the dedicated Reels tab.
class FeedReelCard extends StatelessWidget {
  final FeedReel reel;
  final double? horizontalPadding;
  final double? bottomPadding;

  const FeedReelCard({
    super.key,
    required this.reel,
    this.horizontalPadding,
    this.bottomPadding,
  });

  /// Open the existing full-screen vertical player seeded with this one reel.
  /// We hand it a single [ShortFeedItem] so it shows this reel immediately; the
  /// player owns its own paging from there.
  void _openPlayer(BuildContext context) {
    if ((reel.videoUrl ?? '').isEmpty) return;
    final item = ShortFeedItem(
      videoId: reel.id,
      viewsCount: reel.stats.views,
      likesCount: reel.stats.likes,
      commentsCount: reel.stats.comments,
      sharesCount: reel.stats.shares,
      video: VideoData(
        id: reel.id,
        userId: reel.userId,
        channelId: reel.channelId,
        title: reel.title,
        caption: reel.caption,
        description: reel.description,
        coverUrl: reel.coverUrl,
        videoUrl: reel.videoUrl,
        duration: reel.duration,
        type: reel.type ?? 'short',
        createdAt: reel.createdAt,
        stats: Stats(
          views: reel.stats.views,
          likes: reel.stats.likes,
          shares: reel.stats.shares,
          comments: reel.stats.comments,
        ),
      ),
    );

    Navigator.pushNamed(
      context,
      RouteHelper.getShortsPlayerScreenRoute(),
      arguments: {
        ApiKeys.shorts: Shorts.trending,
        ApiKeys.videoItem: [item],
        ApiKeys.initialIndex: 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = reel.coverUrl ?? '';
    final caption = reel.displayText;
    final views = reel.stats.views;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding ?? SizeConfig.size14,
        SizeConfig.size6,
        horizontalPadding ?? SizeConfig.size14,
        bottomPadding ?? SizeConfig.size8,
      ),
      child: GestureDetector(
        onTap: () => _openPlayer(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            // A reel teaser: tall enough to read as a short video without
            // dominating the post feed.
            height: SizeConfig.screenHeight * 0.46,
            width: double.infinity,
            child: ColoredBox(
              color: AppColors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover / thumbnail.
                  if (cover.isNotEmpty && isNetworkImage(cover))
                    CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ColoredBox(color: AppColors.black30),
                      errorWidget: (_, __, ___) => LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.cover,
                      ),
                    )
                  else
                    LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),

                  // Center play affordance.
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

                  // "Reel" badge, top-left.
                  Positioned(
                    top: SizeConfig.size10,
                    left: SizeConfig.size10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size8,
                        vertical: SizeConfig.size4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_creation_outlined,
                              color: AppColors.white, size: SizeConfig.size14),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            'Reel',
                            color: AppColors.white,
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom scrim with caption + view count.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
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
                          if (caption.isNotEmpty) ...[
                            CustomText(
                              caption,
                              color: AppColors.white,
                              fontSize: SizeConfig.size14,
                              fontWeight: FontWeight.w600,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: SizeConfig.size4),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: AppColors.white,
                                  size: SizeConfig.size18),
                              SizedBox(width: SizeConfig.size2),
                              CustomText(
                                formatNumberLikePost(views),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
