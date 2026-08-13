import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_poll_options_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_stats_strip.dart';
import 'package:BlueEra/widgets/dashed_divider.dart';
import 'package:flutter/material.dart';

class QaPostWidget extends StatefulWidget {
  final String? postId;
  final String? authorId;
  final String? natureOfPost;
  final String? message;
  final String postedAgo;
  final String totalViews;
  final Poll? poll;
  final String referenceLink;
  final Widget Function() authorSection;
  final Widget Function() buildActions;
  final PostType postFilteredType;
  final Post? post;
  final double? bottomPadding;
  final double? horizontalPaddingChannel;
  final VoidCallback likeFeed;

  final VoidCallback commentView;

  const QaPostWidget({
    super.key,
    required this.postId,
    required this.authorId,
    required this.natureOfPost,
    required this.message,
    required this.postedAgo,
    required this.totalViews,
    required this.poll,
    required this.referenceLink,
    required this.authorSection,
    required this.buildActions,
    required this.postFilteredType,
    this.post,
    required this.commentView,
    this.bottomPadding,   this.horizontalPaddingChannel, required this.likeFeed,
  });

  @override
  State<QaPostWidget> createState() => _QaPostWidgetState();
}

class _QaPostWidgetState extends State<QaPostWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: FeedCardWidget(
        horizontalPadding:widget.horizontalPaddingChannel?? 0,
        bottomPadding: widget.bottomPadding,
        childWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: SizeConfig.size15,
                  bottom: SizeConfig.size5,
                  right: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question and options lead the card; the byline follows,
                  // separated by a dashed rule. A poll's subject is what the
                  // reader is deciding on, so it comes before who asked.
                  _buildPollOptions(),
                  SizedBox(height: SizeConfig.size12),
                  Padding(
                    // Right-5 balances the outer right-10 so the rule is
                    // inset equally on both sides of the card.
                    padding: EdgeInsets.only(
                        left: SizeConfig.size15, right: SizeConfig.size5),
                    child: const DashedDivider(),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  widget.authorSection(),
                  SizedBox(height: SizeConfig.size10),
                  Padding(
                    padding: EdgeInsets.only(
                      left: SizeConfig.size15,
                      right: SizeConfig.size5,
                      bottom: SizeConfig.size5,
                    ),
                    // A poll takes no comments, reposts or shares, so its strip
                    // carries only time, reach and likes — clustered left
                    // rather than spread, which three entries cannot fill.
                    child: FeedStatsStrip(
                      spread: false,
                      items: [
                        FeedStatItem(
                          iconPath: AppIconAssets.clock_new,
                          label: timeAgo(
                              widget.post?.createdAt?.toIso8601String()),
                        ),
                        FeedStatItem(
                          iconPath: AppIconAssets.eye_new,
                          label: formatNumberLikePost(
                              widget.post?.viewsCount ?? 0),
                        ),
                        FeedStatItem(
                          iconPath: AppIconAssets.like_new,
                          label: formatNumberLikePost(
                              widget.post?.likesCount ?? 0),
                          iconColor: (widget.post?.isLiked ?? false)
                              ? AppColors.primaryColor
                              : null,
                          onTap: () {
                            if (isGuestUser()) {
                              createProfileScreen();
                            } else {
                              widget.likeFeed();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(
                  //   height: SizeConfig.size10,
                  // ),
                  // Padding(
                  //   padding: EdgeInsets.only(
                  //       top: SizeConfig.size5,
                  //       bottom: SizeConfig.size5,
                  //       left: SizeConfig.size20,
                  //       right: SizeConfig.size5),
                  //   child: widget.buildActions(),
                  // ),
                  // SizedBox(
                  //   height: SizeConfig.size10,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollOptions() {
    return FeedPollOptionsWidget(
      question: widget.poll?.question ?? "",
      postId: widget.postId ?? "0",
      poll: widget.poll,
      postFilteredType: widget.postFilteredType,
      postedAgo: widget.postedAgo,
      message: widget.message, postData: widget.post,
    );
  }
}
