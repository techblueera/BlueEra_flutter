import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/ott/view/all_channel_video_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogoNameWidget extends StatelessWidget {
  const LogoNameWidget(
      {super.key,
      required this.logoUrl,
      required this.channelName,
      required this.channelID});

  final String logoUrl;
  final String channelName;
  final String channelID;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => VideoListScreen(
              channelID: channelID,
              channelName: channelName,
            ));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Container

          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ],
            ),
            // Check if URL exists before trying to load
            child: ((logoUrl.isNotEmpty))
                ? CachedNetworkImage(
                    imageUrl: logoUrl, filterQuality: FilterQuality.low,
                    // 1. If image loads successfully, show it in a CircleAvatar
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: imageProvider,
                    ),
                    // 2. While loading, show a spinner (or you can use a Shimmer widget)
                    placeholder: (context, url) => CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade100,
                      child: const SizedBox(
                        height: 20,
                        width: 20,
                      ),
                    ),
                    // 3. If image fails to load, show the fallback icon
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.tv, color: Colors.grey),
                    ),
                  )
                // 4. If URL is null/empty originally, show the fallback immediately
                : CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade100,
                    child: const Icon(Icons.tv, color: Colors.grey),
                  ),
          ),

          const SizedBox(height: 10),
          // Channel Name
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: CustomText(
                channelName.capitalizeFirst,
                color: AppColors.mainTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
