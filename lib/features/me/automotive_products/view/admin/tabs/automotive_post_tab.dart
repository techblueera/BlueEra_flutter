import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Post** tab of the auto-parts merchant home — the merchant's own posts.
///
/// Content-only: the host wraps it in the shared refreshable scroll view, so
/// [FeedScreen] runs in `isInParentScroll` mode rather than owning a scroll.
class AutomotivePostTab extends StatelessWidget {
  const AutomotivePostTab({super.key});

  @override
  Widget build(BuildContext context) {
    // FeedScreen reads this controller on mount; the tab is built lazily by the
    // TabBarView, so registering here is the first chance we get.
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return FeedScreen(
      key: const ValueKey('inventory_v2_my_posts'),
      postFilterType: PostType.myPosts,
      id: userId,
      isInParentScroll: true,
      horizontalPaddingChannel: SizeConfig.size12,
    );
  }
}
