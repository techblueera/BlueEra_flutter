import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_action_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/feed/widget/message_post_widget.dart';
import 'package:BlueEra/features/common/feed/widget/qa_post_widget.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/visiting_profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FeedCard extends StatefulWidget {
  final Post? post;
  final int index;
  final PostType postFilteredType;
  final SortBy? sortBy;

  const FeedCard(
      {super.key,
      required this.post,
      required this.index,
      required this.postFilteredType,
      this.sortBy});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  late Post? _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(covariant FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
  }

  bool _shouldShowProfileNavigation() {
    return widget.postFilteredType == PostType.all;
  }

  void _navigateToProfile({required String authorId}) {
    if (!_shouldShowProfileNavigation()) return;
    if (authorId == userId) {
      if (_post?.user?.accountType?.toUpperCase() == AppConstants.individual) {
        Get.to(() => VisitProfileScreen(authorId: authorId));
      } else if (_post?.user?.accountType?.toUpperCase() ==
          AppConstants.business) {
        Get.to(() =>
            VisitBusinessProfile(businessId: _post?.user?.business_id ?? ""));
      }
    } else {
      if (_post?.user?.accountType?.toUpperCase() == AppConstants.individual) {
        Get.to(() => VisitProfileScreen(authorId: authorId));
      } else if (_post?.user?.accountType?.toUpperCase() ==
          AppConstants.business) {
        Get.to(() =>
            VisitBusinessProfile(businessId: _post?.user?.business_id ?? ""));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildPostWidget();
  }

  Widget buildPostWidget() {
    FeedType? feedType = FeedType.fromValue(_post?.type?.toUpperCase());
    switch (feedType) {
      case FeedType.messagePost || FeedType.photoPost:
        return MessagePostWidget(
          post: _post,
          authorSection: () => PostAuthorHeader(
              post: _post,
              authorId: _post?.authorId ?? '0',
              postFilteredType: widget.postFilteredType,
              onTapAvatar: _shouldShowProfileNavigation()
                  ? () => _navigateToProfile(authorId: _post?.authorId ?? '0')
                  : null,
              sortBy: widget.sortBy),
          buildActions: () => PostActionsBar(
            post: _post,
            isLiked: _post?.isLiked ?? false,
            totalLikes: _post?.likesCount ?? 0,
            totalComment: _post?.commentsCount ?? 0,
            totalRepost: _post?.repostCount ?? 0,
            isPostAlreadySaved: _post?.isPostSavedLocal ?? false,
            onLikeDislikePressed: () {
              _onLikeDislikePressed();
            },
            onCommentButtonPressed: () {
              _onCommentPressed();
            },
            onSavedUnSavedButtonPressed: () {
              _onSavedUnSavedButtonPressed();
            },
            onShareButtonPressed: () async {
              _onShareButtonPressed();
            },
          ),
        );

      case FeedType.qaPost:
        return QaPostWidget(
          postId: _post?.id ?? "0",
          poll: _post?.poll,
          authorId: _post?.id,
          natureOfPost: _post?.natureOfPost,
          message: _post?.subTitle ?? "",
          postedAgo: timeAgo(
              _post?.createdAt != null ? _post!.createdAt! : DateTime.now()),
          totalViews: _post?.viewsCount.toString() ?? "0",
          referenceLink: _post?.referenceLink ?? '',
          authorSection: () => PostAuthorHeader(
            post: _post,
            authorId: _post?.authorId ?? '0',
            postFilteredType: widget.postFilteredType,
            sortBy: widget.sortBy,
            onTapAvatar: _shouldShowProfileNavigation()
                ? () => _navigateToProfile(authorId: _post?.authorId ?? '0')
                : null,
          ),
          buildActions: () => PostActionsBar(
            post: _post,
            isLiked: _post?.isLiked ?? false,
            totalLikes: _post?.likesCount ?? 0,
            totalComment: _post?.commentsCount ?? 0,
            totalRepost: _post?.repostCount ?? 0,
            isPostAlreadySaved: _post?.isPostSavedLocal ?? false,
            onLikeDislikePressed: () {
              _onLikeDislikePressed();
            },
            onCommentButtonPressed: () {
              _onCommentPressed();
            },
            onSavedUnSavedButtonPressed: () {
              _onSavedUnSavedButtonPressed();
            },
            onShareButtonPressed: () {
              _onShareButtonPressed();
            },
          ),
          postFilteredType: widget.postFilteredType,
          sortBy: widget.sortBy,
        );

      case FeedType.shorts:
        List trendingShorts = [];
        List<String> postVideo = _post?.media ?? [];
        for (String media in postVideo) {
          trendingShorts.add(media);
        }

        return Container(
          height: SizeConfig.size180,
          padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: trendingShorts.length,
            itemBuilder: (context, index) {
              return SingleShortStructure(
                shorts: Shorts.trending,
                imageHeight: SizeConfig.size180,
                imageWidth: SizeConfig.size100,
                withBackground: true,
              );
            },
          ),
        );

      default:
        // Default for other post types or null
        return SizedBox();
    }
  }

  void _onLikeDislikePressed() {
    Get.find<FeedController>().postLikeDislike(
        postId: _post?.id ?? '0',
        type: widget.postFilteredType,
        sortBy: widget.sortBy);
  }

  void _onCommentPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
          id: _post?.id ?? '0',
          totalComments: _post?.commentsCount ?? 0,
          commentType: CommentType.post,
          onNewCommentCount: (int newCommentCount) {
            Get.find<FeedController>().updateCommentCount(
                postId: _post?.id ?? '0',
                type: widget.postFilteredType,
                sortBy: widget.sortBy,
                newCommentCount: newCommentCount);
          }),
    );
  }

  Future<void> _onSavedUnSavedButtonPressed() async {
    Get.find<FeedController>().savePostToLocalDB(
        postId: _post?.id ?? '0',
        type: widget.postFilteredType,
        sortBy: widget.sortBy);
  }

  Future<void> _onShareButtonPressed() async {
    XFile xFile = await urlToCachedXFile(_post!.media!.first);
    // https://api.blueera.ai/api/post-service/app/post/
    // final linkShare="https://api.blueera.ai/api/post-service/app/post/${_post?.id.toString()}";
  //  logs("linkShare====${linkShare}");
    final shareUrl = postDeepLink(postId: _post!.id.toString()); //'https://blueera.ai/app/post/${(postId ?? "")}';
    final combinedText = shareUrl;
    await SharePlus.instance.share(ShareParams(
        text: combinedText,
        subject: _post!.title,
        previewThumbnail: xFile));
    final file = File(xFile.path);
    if (await file.exists()) {
      await file.delete();
      print("🗑️ File deleted from cache.");
    }
  }

  Future<XFile> urlToCachedXFile(String fileUrl) async {
    // Get temp (cache) directory
    final tempDir = await getTemporaryDirectory();
    final fileName = fileUrl.split('/').last; // keep original name if possible
    final filePath = "${tempDir.path}/$fileName";

    // Download file into cache
    await Dio().download(fileUrl, filePath);

    // Return as XFile
    return XFile(filePath);
  }
}
