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

  const CustomPollWidget(
      {super.key,
      required this.postId,
      required this.question,
      required this.options,
      required this.postFilteredType,
      this.postedAgo,
      this.message,
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

  @override
  Widget build(BuildContext context) {
    final totalVotes =
        localOptions.fold(0, (sum, o) => sum + (o.votes?.length ?? 0));
    final hasVoted = selectedIndex != -1;

    return Column(
      children: [

        Padding(
          padding: EdgeInsets.only(left: SizeConfig.size32, right: SizeConfig.size15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  widget.question,
                  color: AppColors.mainTextColor,
                  // fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              // if (hasVoted)
                CustomText(
                  '${totalVotes} votes',
                  fontSize: SizeConfig.medium,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
            ],
          ),
        ),

        SizedBox(height: SizeConfig.size5),

        // Poll options with progress bars
        ...List.generate(localOptions.length, (index) {
          final option = localOptions[index];
          final isSelected = selectedIndex == index;
          final optionVotes = option.votes?.length ?? 0;
          final percentage =
              totalVotes == 0 ? 0 : ((optionVotes / totalVotes) * 100).round();

          return Padding(
            padding: EdgeInsets.only(
                left: SizeConfig.size32,
                right: SizeConfig.size15,
                bottom: SizeConfig.size5),
            child: InkWell(
              // onTap: hasVoted ? null : () => _handleVote(index),
              onTap: () {
                if (isGuestUser()) {
                  createProfileScreen();
                } else {
                  hasVoted ? null : _handleVote(index);
                }
              },
              child: Container(
                height: SizeConfig.size35,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.secondaryTextColor,width: 0.5)
                ),
                child: Stack(
                  children: [
                    // Progress bar background (white)
                    Container(
                      height: SizeConfig.size45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),

                    // Progress bar fill (light grey based on percentage)
                    if (hasVoted)
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(
                          height: SizeConfig.size45,
                          decoration: BoxDecoration(
                            color: percentage > 50
                                ? Colors
                                    .grey[200]! // Lighter for high percentages
                                : percentage > 25
                                    ? Colors.grey[
                                        300]! // Medium for medium percentages
                                    : Colors.grey[400]!,
                            // Darker for low percentages
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    // Content container
                    Container(
                      height: SizeConfig.size35,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              option.text,
                              fontSize: SizeConfig.medium,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          // Percentage

                          if(hasVoted)...[
                            if (selectedIndex == index)
                              ...[
                                Icon(Icons.check_circle_outline, color: AppColors.primaryColor),
                                SizedBox(width: SizeConfig.size8),
                              ],
                            CustomText(
                              '$percentage%',
                              fontSize: SizeConfig.medium,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ]

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        // Total votes display

        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size32,
            right: SizeConfig.size15,
            top: SizeConfig.size5,
          ),
          child: widget.message?.isNotEmpty ?? false
              ?  ExpandableText(
            text: widget.message??'',
            trimLines: 2,
            style: TextStyle(
              color: AppColors.mainTextColor,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
            ),
            expandMode: ExpandMode.dialog,
            dialogTitle: 'Poll Description',
          ) : SizedBox.shrink(),
        ),

      ],
    );
  }
}
