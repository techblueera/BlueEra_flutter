import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final String timeAgo;
  final String commentText;
  final String replyCount;
  final String likeCount;
  final bool isReply;
  final bool isMyComment; // 👈 NEW FLAG
  final List<CommentCard>? replies;
  final VoidCallback? onReadMore;

  const CommentCard({
    super.key,
    this.avatarUrl = "https://randomuser.me/api/portraits/women/32.jpg",
    this.username = "Somya_Singh",
    this.timeAgo = "5d ago",
    this.commentText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
    this.replyCount = "50 Replies",
    this.likeCount = "47k",
    this.isReply = false,
    this.isMyComment = false, // 👈 default false
    this.replies,
    this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.blackCC;
    // final alignment = isMyComment ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final marginStart = isReply ? 40.0 : 16.0;
    final marginEnd = isMyComment ? 16.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: isMyComment ? marginEnd : marginStart,
        right: isMyComment ? marginStart : marginEnd,
        bottom: 12,
      ),
      child: Align(
        alignment: isMyComment ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            crossAxisAlignment:  CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CachedAvatarWidget(
                    imageUrl: avatarUrl,
                    size: SizeConfig.size30,
                    borderColor: AppColors.primaryColor
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        CustomText(
                            username,
                            fontSize: SizeConfig.medium,
                            ),
                        const SizedBox(height: 2),
                        CustomText(
                            timeAgo,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.greyB8
                         ),
                      ],
                    ),
                  ),

                ],
              ),

              SizedBox(height: SizeConfig.size6),

              CustomText(
                commentText,
                fontSize: SizeConfig.small,
                textAlign: TextAlign.left,
              ),

              SizedBox(height: SizeConfig.size14),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomText(
                      replyCount,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                    ),
                  SizedBox(width: SizeConfig.size3),
                  LocalAssets(imagePath: AppIconAssets.forwardIcon),
                  SizedBox(width: SizeConfig.size12),
                  LocalAssets(imagePath: AppIconAssets.lightReplyIcon),
                  SizedBox(width: SizeConfig.size3),
                  CustomText("Reply"),
                  SizedBox(width: SizeConfig.size12),
                  LocalAssets(imagePath: AppIconAssets.likeIcon),
                  const SizedBox(width: 4),
                  CustomText("Reply", fontSize: SizeConfig.extraSmall),
                ],
              ),

              if (replies != null && replies!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...replies!,
                if (onReadMore != null)
                  TextButton(
                    onPressed: onReadMore,
                    child: CustomText(
                      'Read more',
                      fontSize: SizeConfig.medium,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
