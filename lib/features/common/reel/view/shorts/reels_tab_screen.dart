import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_player_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen vertical Reels feed shown in the "Reels" bottom-nav slot.
///
/// It loads the trending shorts feed once (reusing [ShortsController]) and
/// hands the live list to [ShortsPlayerScreen], which already owns the
/// smooth-scroll vertical PageView plus the ±1 preload/dispose video cache
/// (YouTube-Shorts style) and infinite pagination. So this widget is just a
/// thin loader/host — it does not re-implement playback or caching.
class ReelsTabScreen extends StatefulWidget {
  const ReelsTabScreen({super.key});

  @override
  State<ReelsTabScreen> createState() => _ReelsTabScreenState();
}

class _ReelsTabScreenState extends State<ReelsTabScreen> {
  late final ShortsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ShortsController>()
        ? Get.find<ShortsController>()
        : Get.put(ShortsController());
    // Defer the first fetch past the first frame so the cache-first path
    // (which reassigns observable lists synchronously) never notifies an
    // Obx mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.trendingVideoFeedPosts.isEmpty) {
        _controller.getAllFeedTrending(isInitialLoad: true, refresh: true);
      }
    });
  }

  void _retry() =>
      _controller.getAllFeedTrending(isInitialLoad: true, refresh: true);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: Obx(() {
        final list = _controller.trendingVideoFeedPosts;

        if (list.isEmpty) {
          if (_controller.isFirstLoadTrending.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            );
          }
          return _ReelsEmptyState(onRetry: _retry);
        }

        // Stable key → the player's State (PageController + video cache) is
        // preserved across feed-list mutations (e.g. load-more appends), so
        // playback is never interrupted by an outer rebuild.
        return ShortsPlayerScreen(
          key: const ValueKey('reels_tab_player'),
          shorts: Shorts.trending,
          initialShorts: list.toList(),
          initialIndex: 0,
        );
      }),
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
              color: AppColors.white, size: 56),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            'No reels to show right now',
            color: AppColors.white,
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
