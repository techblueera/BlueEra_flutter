import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/ott/widget/logo_name_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BuildJoinedChannelsListWidget extends StatelessWidget {
  BuildJoinedChannelsListWidget({super.key});

  final channelFeedController = Get.find<ChannelFeedController>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: channelFeedController.channelDataList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final item = channelFeedController.channelDataList[index];
          return SizedBox(
              width: 100,
              child: LogoNameWidget(
                logoUrl: item.logoUrl ?? "",
                channelName: item.name ?? "",
                channelID: item.id ?? "",

              ));
        },
      ),
    );
  }
}
