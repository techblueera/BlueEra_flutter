import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:flutter/material.dart';

class SubscriptionBannerVideo extends StatelessWidget {
  final String videoUrl;

  const SubscriptionBannerVideo({
    super.key,
    required this.videoUrl,
  });


  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: HorizontalVideoPlayer(
        videoUrls: [videoUrl],
        isNetworkUrl: true,
      ),
    );
  }
}