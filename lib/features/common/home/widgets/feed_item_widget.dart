import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeedItemWidget extends StatelessWidget {
  final Post item;
  final VoidCallback? onTap;
  final String type;

  const FeedItemWidget({
    Key? key,
    required this.item,
    required this.type,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: item.user?.profileImage ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        width: 40,
                        height: 40,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.person),
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          item.user?.name ?? '',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        CustomText(
                          '@${item.user?.username ?? ''}',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content based on type
            if (type == 'message_post')
              _buildPostContent(),
             if (type == 'short_video' || type == 'long_video')
              _buildVideoContent(),
             if (type == 'image_post')
              _buildImageContent(),

            // Stats
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.favorite, item.likesCount?.toString() ?? '0'),
                  _buildStatItem(Icons.comment, item.commentsCount?.toString() ?? '0'),
                  _buildStatItem(Icons.share, item.repostCount?.toString() ?? '0'),
                  _buildStatItem(Icons.visibility, item.viewsCount?.toString() ?? '0'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.title != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: CustomText(
              item.title!,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (item.message != null)
          Padding(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: CustomText(
              item.message!,
              fontSize: 14,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (item.media != null && item.media!.isNotEmpty)
          Container(
            height: 200,
            child: PageView.builder(
              itemCount: item.media!.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: item.media![index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVideoContent() {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: item.thumbnail ?? '',
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            height: 200,
            width: double.infinity,
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            height: 200,
            width: double.infinity,
            child: const Icon(Icons.error),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        if (item.title != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: CustomText(
                item.title!,
                fontSize: 14,
                color: Colors.white,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.title != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            child: CustomText(
              item.title!,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (item.media != null && item.media!.isNotEmpty)
          Container(
            height: 200,
            child: PageView.builder(
              itemCount: item.media!.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: item.media![index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        SizedBox(width: 4),
        CustomText(
          count,
          fontSize: 12,
          color: Colors.grey,
        ),
      ],
    );
  }
}