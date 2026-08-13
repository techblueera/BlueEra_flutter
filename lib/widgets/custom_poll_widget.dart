import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/common/feed/models/posts_response.dart';

class CustomPollWidget extends StatefulWidget {
  final String postId;
  final String question;
  final List<PollOption> options;
  final PostType postFilteredType;
  final String? postedAgo;
  final String? message;
  final Post? postData;

  const CustomPollWidget({
    super.key,
    required this.postId,
    required this.question,
    required this.options,
    required this.postFilteredType,
    this.postedAgo,
    this.message,
    this.postData,
  });

  @override
  State<CustomPollWidget> createState() => _CustomPollWidgetState();
}

class _CustomPollWidgetState extends State<CustomPollWidget> {
  final FeedController feedController = Get.find<FeedController>();

  late List<PollOption> localOptions;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();

    // Deep copy to preserve state locally
    localOptions = widget.options
        .map((e) => PollOption(
              text: e.text,
              votes: List<String>.from(e.votes ?? []),
              isCorrect: false,
            ))
        .toList();

    final currentUserId = userId;
    selectedIndex = localOptions.indexWhere(
      (option) => option.votes?.contains(currentUserId) ?? false,
    );
  }

  Future<void> _handleVote(int index) async {
    final userIdLocal = userId;

    // API call
    await feedController.answerPoll(
      optionId: index,
      postId: widget.postId,
      type: widget.postFilteredType,
    );

    if (!mounted) return;
    // Update local state
    setState(() {
      localOptions[index].votes?.add(userIdLocal);
      selectedIndex = index;
    });
  }

  /// Left inset for every row of the poll block.
  ///
  /// This used to indent to 32 on the main feed so the question cleared the
  /// avatar of the author header sitting above it. The byline moved below the
  /// options, so the indent no longer has anything to clear and the block now
  /// aligns with the rest of the card.
  double get _horizontalInset => SizeConfig.size15;

  @override
  Widget build(BuildContext context) {
    final totalVotes =
        localOptions.fold(0, (sum, o) => sum + (o.votes?.length ?? 0));
    final hasVoted = selectedIndex != -1;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: _horizontalInset, right: SizeConfig.size15),
          // Long questions truncate with an inline "Read more" rather than
          // pushing the options off the card. The running vote total that used
          // to sit beside the question is gone — the design carries per-option
          // percentages only, and the two competed on the same line.
          child: ExpandableText(
            text: widget.question,
            trimLines: 2,
            expandMode: ExpandMode.expandable,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.medium15,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        // Poll options with progress bars
        ...List.generate(localOptions.length, (index) {
          final option = localOptions[index];
          final isSelected = selectedIndex == index;
          final optionVotes = option.votes?.length ?? 0;
          final percentage =
              totalVotes == 0 ? 0 : ((optionVotes / totalVotes) * 100).round();

          return Padding(
            padding: EdgeInsets.only(
                left: _horizontalInset,
                right: SizeConfig.size15,
                bottom: SizeConfig.size8),
            child: _PollOptionRow(
              label: option.text,
              percentage: percentage,
              // Only the viewer's own pick is filled, per the design; the rest
              // report their share as a number alone.
              showFill: hasVoted && isSelected,
              isSelected: isSelected,
              showPercentage: hasVoted,
              onTap: () {
                if (isGuestUser()) {
                  createProfileScreen();
                } else if (!hasVoted) {
                  _handleVote(index);
                }
              },
            ),
          );
        }),
        // Total votes display
        if (widget.postFilteredType == PostType.otherChannelPosts) ...[
          SizedBox(width: SizeConfig.size8),
          Align(
            alignment: Alignment.centerRight,
            child: CustomText(
              '${totalVotes} votes',
              fontSize: SizeConfig.medium,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.only(
            left: _horizontalInset,
            right: SizeConfig.size15,
            top: SizeConfig.size5,
          ),
          child: widget.message?.isNotEmpty ?? false
              ? ExpandableText(
                  text: widget.message ?? '',
                  trimLines: 2,
                  style: TextStyle(
                    color: AppColors.mainTextColor,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                  ),
                  expandMode: ExpandMode.dialog,
                  dialogTitle: 'Poll Description',
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// One poll answer.
///
/// After the viewer votes, their own pick shows a blue pill sized to that
/// option's share, floating inside the row's border rather than filling it edge
/// to edge. The row content is painted twice — once in the resting colours, then
/// again all-white and clipped to exactly the pill's right edge. That keeps both
/// the label and the percentage legible wherever the pill happens to end: a
/// single white copy would vanish on a 10% share, and a single dark copy would
/// go muddy against the blue.
class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.label,
    required this.percentage,
    required this.showFill,
    required this.isSelected,
    required this.showPercentage,
    required this.onTap,
  });

  final String label;
  final int percentage;
  final bool showFill;
  final bool isSelected;
  final bool showPercentage;
  final VoidCallback onTap;

  static const double _radius = 12;

  /// Gap between the row's border and the pill inside it.
  static const double _fillInset = 4;

  @override
  Widget build(BuildContext context) {
    final height = SizeConfig.size40;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final track = width - (_fillInset * 2);
          final fillWidth = track * (percentage.clamp(0, 100) / 100);
          // Where the white copy stops: the pill's own right edge.
          final clipWidth = _fillInset + fillWidth;

          return SizedBox(
            height: height,
            child: Stack(
              children: [
                // Base: white pill, blue-rimmed once it is the viewer's pick.
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.greyE5,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                ),
                if (showFill)
                  Padding(
                    padding: const EdgeInsets.all(_fillInset),
                    child: Container(
                      width: fillWidth,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius:
                            BorderRadius.circular(_radius - _fillInset),
                      ),
                    ),
                  ),
                // Resting colours — what shows past the pill's end.
                SizedBox(
                  width: width,
                  height: height,
                  child: _content(
                    labelColor: AppColors.secondaryTextColor,
                    percentColor: AppColors.mainTextColor,
                  ),
                ),
                // The same content in white, clipped to the pill. OverflowBox
                // lets the inner row lay out at the FULL width so every glyph
                // lands exactly over its counterpart underneath.
                if (showFill)
                  ClipRect(
                    child: SizedBox(
                      width: clipWidth,
                      height: height,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: width,
                        maxWidth: width,
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: _content(
                            labelColor: AppColors.white,
                            percentColor: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _content({
    required Color labelColor,
    required Color percentColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              label,
              fontSize: SizeConfig.medium15,
              color: labelColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showPercentage) ...[
            SizedBox(width: SizeConfig.size8),
            CustomText(
              '$percentage%',
              fontSize: SizeConfig.medium15,
              color: percentColor,
              fontWeight: FontWeight.w700,
            ),
          ],
        ],
      ),
    );
  }
}
