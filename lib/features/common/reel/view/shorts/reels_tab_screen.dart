import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reels **discovery grid** shown in the "Reels" tab.
///
/// Industry-standard flow (Instagram / YouTube Shorts): the tab opens on a
/// scrollable grid of reel covers, and tapping any cover pushes the existing
/// [ShortsPlayerScreen] full-screen vertical player **at that index** (route
/// [RouteHelper.getShortsPlayerScreenRoute]). The player already owns the
/// smooth ±1 preload/dispose video cache and infinite pagination, so this
/// screen only handles the grid + its own load-more.
///
/// Both this grid and the player read the same [ShortsController.trendingVideoFeedPosts]
/// list, so anything the player paginates in is visible here on return and the
/// player opens straight onto the tapped item.
class ReelsTabScreen extends StatefulWidget {
  const ReelsTabScreen({super.key});

  @override
  State<ReelsTabScreen> createState() => _ReelsTabScreenState();
}

class _ReelsTabScreenState extends State<ReelsTabScreen> {
  late final ShortsController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ShortsController>()
        ? Get.find<ShortsController>()
        : Get.put(ShortsController());
    _scrollController.addListener(_onScroll);
    // Defer the first fetch past the first frame so the cache-first path
    // (which reassigns observable lists synchronously) never notifies an
    // Obx mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.trendingVideoFeedPosts.isEmpty) {
        _controller.getAllFeedTrending(isInitialLoad: true, refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Pre-fetch the next page well before the user hits the bottom so the grid
  /// keeps filling without a visible stall. The controller's own guards
  /// (`hasMore` / `isLoadingMore`) make repeated calls cheap no-ops.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      _controller.getAllFeedTrending();
    }
  }

  Future<void> _refresh() =>
      _controller.getAllFeedTrending(isInitialLoad: true, refresh: true);

  /// Open the full-screen vertical player at [index], handing it the live
  /// list so the user can keep scrolling reels from there.
  void _openPlayer(int index) {
    Navigator.pushNamed(
      context,
      RouteHelper.getShortsPlayerScreenRoute(),
      arguments: {
        ApiKeys.shorts: Shorts.trending,
        ApiKeys.videoItem: _controller.trendingVideoFeedPosts.toList(),
        ApiKeys.initialIndex: index,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Transparent so the app-wide [AppHomeBackground] (banner / colour chosen
    // in App Background settings) shows through, matching the Social/Community
    // tabs instead of a hardcoded black fill.
    return Obx(() {
      final list = _controller.trendingVideoFeedPosts;

      if (list.isEmpty) {
        if (_controller.isFirstLoadTrending.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        return _ReelsEmptyState(onRetry: _refresh);
      }

        final loadingMore = _controller.trendingVideoFeedIsLoadingMore.value;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(SizeConfig.size2),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    // 9:16 reel covers — tall portrait cells.
                    childAspectRatio: 0.58,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ReelGridTile(
                      item: list[index],
                      onTap: () => _openPlayer(index),
                    ),
                    childCount: list.length,
                  ),
                ),
              ),
              if (loadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
    });
  }
}

/// One reel cover in the grid: thumbnail fill + a play glyph and view count
/// over a bottom scrim (so the count stays legible on bright covers).
class _ReelGridTile extends StatelessWidget {
  final ShortFeedItem item;
  final VoidCallback onTap;

  const _ReelGridTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cover = item.video?.coverUrl ?? '';
    final views = item.video?.stats?.views ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: AppColors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover.isNotEmpty && isNetworkImage(cover))
              CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(
                  color: AppColors.black30,
                ),
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

            // Bottom scrim for legibility of the view count.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: SizeConfig.size40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: SizeConfig.size6,
              bottom: SizeConfig.size6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  SizedBox(width: SizeConfig.size2),
                  CustomText(
                    formatNumberLikePost(views),
                    color: AppColors.white,
                    fontSize: SizeConfig.size13,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelsEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ReelsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_collection_outlined,
              color: AppColors.secondaryTextColor, size: 56),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            'No reels to show right now',
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: SizeConfig.size12),
          TextButton(
            onPressed: onRetry,
            child: CustomText(
              'Retry',
              color: AppColors.primaryColor,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
