import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:flutter/material.dart';

/// Posts tab — the owner's own feed, mirroring the hospital v2 posts tab.
/// `FeedScreen` is internally scrollable, so it lives in a bounded box to
/// play nicely with the parent `SingleChildScrollView`.
class VehiclePostsTabV2 extends StatelessWidget {
  const VehiclePostsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: FeedScreen(postFilterType: PostType.myPosts),
    );
  }
}
