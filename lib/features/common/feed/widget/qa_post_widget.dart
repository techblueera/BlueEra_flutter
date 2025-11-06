import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_poll_options_widget.dart';
import 'package:BlueEra/features/common/feed/widget/message_post_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
    return FeedCardWidget(
      horizontalPadding:widget.horizontalPaddingChannel?? 0,
      bottomPadding: widget.bottomPadding,
      childWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: SizeConfig.size8,
                bottom: SizeConfig.size5,
                right: SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.authorSection(),
                SizedBox(
                  height: SizeConfig.size5,
                ),
                _buildPollOptions(),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: SizeConfig.size5,
                      bottom: SizeConfig.size5,
                      left: SizeConfig.size32,
                      right: SizeConfig.size5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ViewFeedActionWidget(
                          iconPath: AppIconAssets.clock_new,
                          data: widget.postedAgo),
                      ViewFeedActionWidget(
                        iconPath: AppIconAssets.eye_new,
                        data:
                            formatNumberLikePost(widget.post?.viewsCount ?? 0),
                      ),
                      // InkWell(
                      //   onTap: () {
                      //     if (isGuestUser()) {
                      //       createProfileScreen();
                      //     } else {
                      //       widget.commentView();
                      //     }
                      //   },
                      //   child: ViewFeedActionWidget(
                      //       iconPath: AppIconAssets.comment_new,
                      //       data: formatNumberLikePost(
                      //           widget.post?.commentsCount ?? 0)),
                      // ),
                      InkWell(
                        onTap: () {
                          if (isGuestUser()) {
                            createProfileScreen();
                          } else {
                            widget.likeFeed();
                          }
                          // if ((_post.likesCount ?? 0) < 1) {
                          //   return;
                          // }

                          // showDialog(
                          //   context: context,
                          //   builder: (context) => PostLikeUserListDialog(
                          //     postId: widget.post?.id ?? '',
                          //   ),
                          // );
                        },
                        child: Padding(
                          padding:
                          EdgeInsets.only(right: SizeConfig.size10),
                          child: Row(
                            children: [
                              LocalAssets(
                                imagePath: AppIconAssets.like_new,
                                width: SizeConfig.size18,
                                height: SizeConfig.size18,
                                imgColor: (widget.post?.isLiked ?? false)
                                    ? AppColors.primaryColor
                                    : AppColors.secondaryTextColor,
                              ),
                              SizedBox(
                                width: SizeConfig.size5,
                              ),
                              CustomText(
                                formatNumberLikePost(widget.post?.likesCount ?? 0),
                                color: AppColors.secondaryTextColor,
                                fontSize: SizeConfig.size10,
                              ),
                            ],
                          ),
                        ) /*ViewFeedActionWidget(
                                  iconPath: AppIconAssets.like_new,
                                  data: formatNumberLikePost(
                                      _post.likesCount ?? 0))*/
                        ,
                      ),


                    ],
                  ),
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
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
    );
  }

  Widget _buildPollOptions() {
    return FeedPollOptionsWidget(
      question: widget.poll?.question ?? "",
      postId: widget.postId ?? "0",
      poll: widget.poll,
      postFilteredType: widget.postFilteredType,
      postedAgo: widget.postedAgo,
      message: widget.message,
    );
  }
}
