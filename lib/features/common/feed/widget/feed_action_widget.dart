import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/widgets/common_divider.dart';
import 'package:BlueEra/widgets/common_icon_row.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class PostActionsBar extends StatefulWidget {
  final Post? post;
  final bool isLiked;
  final int? totalLikes;
  final int? totalComment;
  final int? totalRepost;
  final bool? isPostAlreadySaved;
  final VoidCallback onLikeDislikePressed;
  final VoidCallback onCommentButtonPressed;
  final VoidCallback onSavedUnSavedButtonPressed;
  final VoidCallback onShareButtonPressed;

  const PostActionsBar({
    super.key,
    this.post,
    required this.isLiked,
    required this.totalLikes,
    required this.totalComment,
    required this.totalRepost,
    required this.isPostAlreadySaved,
    required this.onLikeDislikePressed,
    required this.onCommentButtonPressed,
    required this.onSavedUnSavedButtonPressed,
    required this.onShareButtonPressed,
  });

  @override
  State<PostActionsBar> createState() => _PostActionsBarState();
}

class _PostActionsBarState extends State<PostActionsBar> {
  late int _totalLikes;
  late int _totalComment;
  late bool _isLiked;
  late bool _isPostAlreadySaved;

  @override
  void initState() {
    super.initState();
    _totalLikes = widget.totalLikes ?? 0;
    _totalComment = widget.totalComment ?? 0;
    _isLiked = widget.isLiked;
    _isPostAlreadySaved = widget.isPostAlreadySaved ?? false;
  }

  @override
  void didUpdateWidget(covariant PostActionsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked ||
        oldWidget.isPostAlreadySaved != widget.isPostAlreadySaved ||
        oldWidget.totalLikes != widget.totalLikes ||
        oldWidget.totalComment != widget.totalComment ||
        oldWidget.totalRepost != widget.totalRepost ||
        oldWidget.post != widget.post) {
      _totalLikes = widget.totalLikes ?? 0;
      _totalComment = widget.totalComment ?? 0;
      _isLiked = widget.isLiked;
      _isPostAlreadySaved = widget.isPostAlreadySaved ?? false;
      log('_isPostAlreadySaved-- $_isPostAlreadySaved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CommonIconRow(
            onTap: () {
              if (isGuestUser()) {
                createProfileScreen();
              } else {
                widget.onLikeDislikePressed();
              }
            },
            imageIcon: _isLiked
                ? LocalAssets(imagePath: AppIconAssets.likeIcon)
                : LocalAssets(
                    imagePath: AppIconAssets.unlikeIcon,
                    imgColor: AppColors.secondaryTextColor),
            text: _totalLikes.toString(),
          ),
          CommonVerticalDivider(),

          // Comment
          CommonIconRow(
            onTap: () {
              if (isGuestUser()) {
                createProfileScreen();
              } else {
                widget.onCommentButtonPressed();
              }
            },
            imageIcon: LocalAssets(imagePath: AppIconAssets.commentIcon),
            text: _totalComment.toString(),
          ),
          CommonVerticalDivider(),

          // Save
          CommonIconRow(
            imageIcon: LocalAssets(
                imagePath: _isPostAlreadySaved
                    ? AppIconAssets.save_fill
                    : AppIconAssets.savedIcon),
            text: "Save",
            onTap: () {
              widget.onSavedUnSavedButtonPressed();
            },
          ),

          CommonVerticalDivider(),

          // upload
          CommonIconRow(
            imageIcon: LocalAssets(imagePath: AppIconAssets.uploadIcon),
            text: widget.totalRepost.toString(),
            onTap: () {
              widget.onShareButtonPressed();
            },
          ),
        ],
      ),
    );
  }
}
