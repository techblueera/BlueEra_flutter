import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/view/tabs/rider_tab_scroll.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Post tab** of the rider dashboard — the rider's own posts.
///
/// Extracted from `RiderServiceScreen` along with the other three tabs: that
/// screen was a single 2,400-line State class holding four unrelated surfaces,
/// so an edit to the preference form landed in the same file as the QR card.
class RiderPostTab extends StatelessWidget {
  const RiderPostTab({super.key});

  @override
  Widget build(BuildContext context) {
    // [FeedScreen] reads its controller off the GetX registry rather than
    // taking one, so it has to exist before the first build.
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }

    return RiderTabScroll(
      children: [
        FeedScreen(
          key: const ValueKey('rider_service_my_posts'),
          postFilterType: PostType.myPosts,
          id: userId,
          isInParentScroll: true,
          horizontalPaddingChannel: SizeConfig.size12,
        ),
      ],
    );
  }
}
