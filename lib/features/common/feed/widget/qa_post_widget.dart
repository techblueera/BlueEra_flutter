import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_poll_options_widget.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
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
  });

  @override
  State<QaPostWidget> createState() => _QaPostWidgetState();
}

class _QaPostWidgetState extends State<QaPostWidget> {
  @override
  Widget build(BuildContext context) {
    return FeedCardWidget(
      childWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SizeConfig.size8, bottom: SizeConfig.size5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                widget.authorSection(),

                _buildPollOptions(), // QA post specific widget

                Padding(
                  padding: EdgeInsets.only(left: SizeConfig.size15, right: SizeConfig.size15, top: SizeConfig.size15,bottom: 0),
                  child: CommonHorizontalDivider(
                    color: AppColors.secondaryTextColor,
                    height: 0.5,
                  ),
                ),

                widget.buildActions(),
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
