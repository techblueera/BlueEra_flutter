import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/ott/model/channel_model_new.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class BuildHorizontalVideoListWidget extends StatelessWidget {
   BuildHorizontalVideoListWidget({super.key, required this.isCompact, required this.videos});
 final bool isCompact;
 final  List<VideoModel> videos;
  @override
  Widget build(BuildContext context) {
    double height = isCompact ? 140 : 260;
    double width = isCompact ? 160 : 300;

    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final video = videos[index];
          return SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(video.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (video.isLive)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            color: Colors.red,
                            child: const Text("LIVE",
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Details
                if (!isCompact) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (video.channelIcon.isNotEmpty)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(video.channelIcon),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            CustomText(
                              video.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              video.views,
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ] else ...[
                  CustomText(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );  }
}
