import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/features/common/comment/model/comment_model_response.dart';
import 'package:BlueEra/features/common/reelsModule/widget/comment_shimmer_ui.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_delete_conformation_dialog.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../business/visit_business_profile/view/visit_business_profile_new.dart';

enum CommentType { post, video }

class CommentBottomSheet extends StatefulWidget {
  final String id;
  final int totalComments;
  final CommentType
      commentType; // New parameter to distinguish between post and video
  final Function(int) onNewCommentCount;

  const CommentBottomSheet(
      {super.key,
      required this.id,
      required this.totalComments,
      this.commentType =
          CommentType.post, // Default to post for backward compatibility
      required this.onNewCommentCount});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  static CommentController commentController = Get.put(CommentController());

  @override
  void initState() {
    super.initState();
    // Choose the appropriate API based on comment type
    if (widget.commentType == CommentType.video) {
      commentController.getAllVideoComments(
          videoId: widget.id, isInitialized: true);
    } else {
      commentController.getAllPostComments(
          postId: widget.id, isInitialized: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      commentController.totalCommentCount.value = widget.totalComments;
    });

    // Listen to comment count changes
    ever(commentController.totalCommentCount, (count) {
      widget.onNewCommentCount(count);
    });
  }

  @override
  void dispose() {
    super.dispose();
    commentController.sendMessageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return CommonDraggableBottomSheet(
      initialChildSize: 0.95,
      minChildSize: 0.95,
      maxChildSize: 0.95,
      backgroundColor: AppColors.white,
      builder: (ScrollController scrollController) {
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 50),
            padding: EdgeInsets.only(
                bottom: bottomInset), // Push up when keyboard appears
            curve: Curves.easeOut,
            child: Obx(() => commentController.isLoading.value
                ? CommentShimmerUi()
                : Column(
                    children: [
                      /// Header
                      Padding(
                        padding: EdgeInsets.only(
                            right: SizeConfig.size10,
                            top: SizeConfig.size5,
                            bottom: SizeConfig.size5),
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                                onPressed: () {
                                  Get.back();
                                },
                                icon: Icon(Icons.close,
                                    size: SizeConfig.size24))),
                      ),

                      Obx(() {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size20),
                          child: Align(
                            alignment: Alignment.center,
                            child: CustomText(
                              "${commentController.totalCommentCount.value} Comments",
                              fontSize: SizeConfig.large,
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: SizeConfig.size15),

                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                        child: CommonHorizontalDivider(
                          color: AppColors.greyB3,
                          height: 0.4,
                        ),
                      ),

                      SizedBox(height: SizeConfig.size15),

                      /// Comment List
                      Expanded(
                        child: commentController.comments.isNotEmpty
                            ? ListView.builder(
                                itemCount: commentController.comments.length,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemBuilder: (context, index) {
                                  final comment =
                                      commentController.comments[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom: SizeConfig.size20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildCommentTile(comment: comment),
                                        if (comment.replies != null &&
                                            comment.replies!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 48.0),
                                            child:
                                                GetBuilder<CommentController>(
                                              id: 'replies-${comment.sId}',
                                              // optional ID if you want to update only specific comment
                                              builder: (commentController) {
                                                final visibleCount =
                                                    commentController
                                                                .visibleRepliesCountMap[
                                                            comment.sId] ??
                                                        0;
                                                final totalReplies =
                                                    comment.replies!.length;

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (visibleCount == 0)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: SizeConfig
                                                                    .size5),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            commentController
                                                                .toggleReplies(
                                                                    comment
                                                                        .sId!,
                                                                    totalReplies);
                                                          },
                                                          child: CustomText(
                                                            "View ${comment.repliesCount} replies",
                                                            fontSize: SizeConfig
                                                                .medium,
                                                            color: AppColors
                                                                .secondaryTextColor,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          ...comment.replies!
                                                              .take(
                                                                  visibleCount)
                                                              .map((reply) =>
                                                                  _buildCommentTile(
                                                                      comment:
                                                                          comment,
                                                                      reply:
                                                                          reply,
                                                                      isReplyTemplate:
                                                                          true))
                                                              .toList(),
                                                          GestureDetector(
                                                            onTap: () {
                                                              commentController
                                                                  .toggleReplies(
                                                                      comment
                                                                          .sId!,
                                                                      totalReplies);
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          4.0),
                                                              child: CustomText(
                                                                visibleCount <
                                                                        totalReplies
                                                                    ? "View more replies"
                                                                    : "Hide replies",
                                                                fontSize:
                                                                    SizeConfig
                                                                        .medium,
                                                                color: AppColors
                                                                    .secondaryTextColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: CustomText(
                                  'No comment yet.',
                                  fontSize: SizeConfig.extraLarge22,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),

                      /// Input Field
                      _buildSendCommentField(),
                    ],
                  )),
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(
      {required CommentData comment, Replies? reply, isReplyTemplate = false}) {
    String commentName =
        (comment.createdBy?.accountType == AppConstants.individual)
            ? comment.createdBy?.name ?? ''
            : comment.createdBy?.businessName ?? '';
    String replierName =
        (reply?.createdBy?.accountType == AppConstants.individual)
            ? reply?.createdBy?.name ?? ''
            : reply?.createdBy?.businessName ?? '';
    String commentDesignation =
        (comment.createdBy?.accountType == AppConstants.individual)
            ? comment.createdBy?.designation ?? ''
            : comment.createdBy?.businessCategory ?? '';
    String replierDesignation =
        (reply?.createdBy?.accountType == AppConstants.individual)
            ? reply?.createdBy?.designation ?? ''
            : reply?.createdBy?.businessCategory ?? '';

    String commentId = !isReplyTemplate ? comment.sId ?? '' : reply?.sId ?? '';
    int likeCount;
    if (!isReplyTemplate) {
      // Parent comment → use comment.likesCount directly
      likeCount = comment.likesCount ?? 0;
    } else {
      // Child reply → look inside comment.replies
      likeCount = comment.replies
              ?.firstWhere((r) => r.sId == commentId,
                  orElse: () => Replies(likesCount: 0))
              .likesCount ??
          0;
    }

    String profilePic = !isReplyTemplate
        ? comment.createdBy?.profilePic ?? ''
        : reply?.createdBy?.profilePic ?? '';
    String name = !isReplyTemplate ? commentName : replierName;
    String designation =
        !isReplyTemplate ? commentDesignation : replierDesignation;
    String message =
        !isReplyTemplate ? comment.message ?? '' : reply?.message ?? '';
    String timeAgo =
        !isReplyTemplate ? comment.timeAgo ?? '' : reply?.timeAgo ?? '';
    bool isLiked =
        !isReplyTemplate ? comment.isLiked ?? false : reply?.isLiked ?? false;


    return InkWell(
      onLongPress: () async {
        logs("userId==== ${userId}===== ${comment.createdBy?.sId}");
        if ((userId == comment.createdBy?.sId)||(userId==reply?.createdBy?.sId))
          await showCommonDialog(
              context: context,
              text: "Are you sure you want to delete this comment?",
              confirmCallback: () async {
                logs("widget.commentType==== ${widget.commentType}");
                Get.back();
                await commentController.commentPostDeleteController(
                    commentId: commentId,postID: widget.id, commentPostType: widget.commentType);
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              confirmText: AppLocalizations.of(context)!.yes,
              cancelText: AppLocalizations.of(context)!.no);
      },
      onTap: (){
        onProfileTap(
          context,
          userId: userId,
          commentUser: comment.createdBy,
          replyUser: reply?.createdBy,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size10, horizontal: SizeConfig.size15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Avatar
            CachedAvatarWidget(
              imageUrl: profilePic,
              size: SizeConfig.size30,
              borderRadius: SizeConfig.size15,
            ),
            SizedBox(width: SizeConfig.size10),

            /// Main Comment Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Username, designation
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: TextStyle(
                            fontSize: SizeConfig.small11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        if (designation
                            .isNotEmpty) // Show only if designation exists
                          TextSpan(
                            text: ' (${designation})',
                            style: TextStyle(
                              fontSize: SizeConfig.small11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size6),

                  /// Message
                  CustomText(
                    message,
                    fontSize: SizeConfig.size14,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: SizeConfig.size6),

                  /// Time ago + Reply
                  Row(
                    children: [
                      CustomText(
                        timeAgo,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(width: SizeConfig.size15),
                      GestureDetector(
                        onTap: () {
                          clickOnReply(
                              name: name, commentId: comment.sId ?? '0');
                        },
                        child: CustomText(
                          'Reply',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// Like Icon + Count
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.commentType == CommentType.video) {
                        commentController.addRemoveLikeFromVideo(
                            commentId: commentId);
                      } else {
                        commentController.addRemoveLike(commentId: commentId);
                      }
                    },
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppColors.black,
                      size: SizeConfig.size24,
                    ),
                  ),
                  SizedBox(height: SizeConfig.size1),
                  // You can even remove this if zero spacing is desired
                  CustomText(
                    likeCount.toString(),
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    fontSize: SizeConfig.size12,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSendCommentField() {
    final replyingTo = commentController.replyingToUser.value;

    return Container(
      color: AppColors.whiteFE,
      child: Padding(
        padding: EdgeInsets.only(
            left: SizeConfig.size15,
            right: SizeConfig.size15,
            top: SizeConfig.size15,
            bottom: SizeConfig.size15),
        child: Column(
          children: [
            if (replyingTo != null) // reply bar
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: AppColors.whiteEE.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          "Replying to @$replyingTo",
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          commentController.replyingToUser.value = null;
                          commentController.parentCommentId = null;
                          commentController.sendMessageController.clear();
                        },
                        child:
                            Icon(Icons.close, size: 20, color: AppColors.black),
                      )
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyE5)),
                    child: Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.chat_box_smile,
                          imgColor: AppColors.coloGreyText,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            focusNode: commentController.replyFocusNode,
                            controller: commentController.sendMessageController,
                            style: TextStyle(color: Colors.black),
                            onChanged: (value){
                              commentController.sendMessageController.text = value;
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: TextStyle(
                                color: AppColors.greyBf,
                                fontSize: SizeConfig.size14,
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                (commentController.sendMessageController.text.isNotEmpty) ?
                InkWell(
                  onTap: () {
                    if (commentController.isSendCommentLoading.isTrue) return;

                    if (commentController
                        .sendMessageController.value.text.isNotEmpty) {
                      // Use appropriate add comment method based on comment type
                      if (widget.commentType == CommentType.video) {
                        addVideoCommentToPost();
                      } else {
                        addCommentToPost();
                      }
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(18)),
                    child: commentController.isSendCommentLoading.isTrue
                        ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : LocalAssets(
                        height: 21,
                        width: 21,
                        imagePath: AppIconAssets.send_message_chat),
                  ),
                ) : Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.greyB3,
                      borderRadius: BorderRadius.circular(18)),
                  child: LocalAssets(
                      height: 21,
                      width: 21,
                      imagePath: AppIconAssets.send_message_chat),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void addCommentToPost({String? media}) {
    if (commentController.sendMessageController.value.text.isNotEmpty) {
      Map<String, dynamic> params = {
        ApiKeys.post_id: widget.id,
        ApiKeys.message: "${commentController.sendMessageController.text}",
      };
      if (commentController.parentCommentId != null)
        params[ApiKeys.parentCommentId] = commentController.parentCommentId;
      commentController.addPostComment(params: params, postId: widget.id);
    }
  }

  // New method for adding video comments
  void addVideoCommentToPost({String? media}) {
    if (commentController.sendMessageController.value.text.isNotEmpty) {
      Map<String, dynamic> params = {
        ApiKeys.videoId: widget.id,
        ApiKeys.content: "${commentController.sendMessageController.text}",
      };
      if (commentController.parentCommentId != null)
        params[ApiKeys.parentId] = commentController.parentCommentId;
        commentController.addVideoComment(params: params, videoId: widget.id);
    }
  }

  void clickOnReply({required String name, required String commentId}) {
    commentController.replyingToUser.value = name;
    commentController.parentCommentId = commentId;

    commentController.sendMessageController.text = "@$name ";
    commentController.sendMessageController.selection =
        TextSelection.fromPosition(
      TextPosition(offset: commentController.sendMessageController.text.length),
    );

    if (!commentController.replyFocusNode.hasPrimaryFocus) {
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(commentController.replyFocusNode);
      });
    }
  }

  void onProfileTap(BuildContext context, {
    required String userId,
    required CreatedBy? commentUser,
    CreatedBy? replyUser,
  }) {

    // Decide whose profile was clicked → reply user takes priority
    final targetUser = replyUser ?? commentUser;

    if (targetUser == null) return;

    final isSelf = userId == targetUser.sId;
    final accountType = targetUser.accountType?.toUpperCase();
    if (accountType == AppConstants.individual) {
      if (isSelf) {
        navigatePushTo(context, PersonalProfileSetupScreen());
      } else {
        Get.to(() => NewVisitProfileScreen(authorId: targetUser.sId ?? '', screenFromName: AppConstants.feedScreen,));
      }
    } else if (accountType == AppConstants.business) {
      if (isSelf) {
        navigatePushTo(context, BusinessOwnProfileScreen());
      } else {
        print('targetUser.sId--> ${targetUser.sId}');

       Get.to(() => VisitBusinessProfileNew(
          businessId: targetUser.sId ?? '', screenName:  AppConstants.feedScreen,
        ));
      }
    }
  }


}
