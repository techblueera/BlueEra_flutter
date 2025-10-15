import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagePostDetailsScreen extends StatelessWidget {
  MessagePostDetailsScreen(
      {super.key, required this.post, required this.postType});

  final Post? post;
  final PostType postType;
  final feedController = Get.isRegistered<FeedController>()
      ? Get.find<FeedController>()
      : Get.put(FeedController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Details",
      ),
      body: CommonCardWidget(
        borderRadius: 0,
        cardMargin: 0,
        // padding: SizeConfig.size10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeedCard(
              post: (post?.is_reposted ?? false) ? post?.children_post : post,
              index: 0,
              postFilteredType: PostType.otherPosts,
              horizontalPadding: 0,
              isFromDetailsScreen: true,
              isRepost: false,
            ),
            Expanded(
              child: CommentBottomSheet(
                  id: post?.id ?? '0',
                  totalComments: post?.commentsCount ?? 0,
                  commentType: CommentType.post,
                  isFromFeedDetailsScreen: true,
                  onNewCommentCount: (int newCommentCount) {
                    feedController.updateCommentCount(
                        postId: post?.id ?? '0',
                        type: postType,
                        sortBy: SortBy.Latest,
                        newCommentCount: newCommentCount);
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
