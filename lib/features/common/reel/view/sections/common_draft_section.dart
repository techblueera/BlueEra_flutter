import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CommonDraftSection extends StatefulWidget {
  final bool isOwnProfile;
  final String channelId;
  final String authorId;
  const CommonDraftSection({super.key, this.isOwnProfile = false, required this.channelId, required this.authorId});

  @override
  State<CommonDraftSection> createState() => _CommonDraftSectionState();
}

class _CommonDraftSectionState extends State<CommonDraftSection> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildShortsVideos(), _buildVideos()],
    );
  }

  Widget _buildShortsVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
          child: CustomText(
            "Shorts",
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
          ),
        ),
                 ShortsChannelSection(
           isOwnChannel: widget.isOwnProfile,
           channelId: widget.channelId,
           authorId: widget.authorId,
           showShortsInGrid: false,
         ),
      ],
    );
  }

  Widget _buildVideos(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: SizeConfig.size15, top: SizeConfig.size10),
          child: CustomText(
            "Videos",
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
          ),
        ),
                 VideoChannelSection(
             isOwnChannel: widget.isOwnProfile,
             channelId: widget.channelId,
             authorId: widget.authorId,
             isScroll: false,
         )
      ],
    );
  }
}
