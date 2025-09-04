import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/widgets/custom_poll_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_enum.dart';

class FeedPollOptionsWidget extends StatefulWidget {

  const FeedPollOptionsWidget({
    super.key,
    // required this.quesOptions,
    required this.question,
    // required this.quesPostResponses,
    required this.postId,
    // required this.authorId,
    required this.poll,
    required this.postFilteredType,
    this.sortBy,
  });

  // final Map<String, bool>? quesOptions;
  final String question;
  // final List<QuestResponse>? quesPostResponses;
  final String postId;
  // final int authorId;
  final Poll? poll;
  final PostType postFilteredType;
  final SortBy? sortBy;

  @override
  State<FeedPollOptionsWidget> createState() => _FeedPollOptionsWidgetState();
}

class _FeedPollOptionsWidgetState extends State<FeedPollOptionsWidget> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomPollWidget(postId: widget.postId, options: widget.poll!.options, postFilteredType: widget.postFilteredType, sortBy: widget.sortBy);
  }


}


