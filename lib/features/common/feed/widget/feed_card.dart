import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/chat/view/forward_screen/chat_forward_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_message_post_widget.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/feed_profile_navigation.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/feed/widget/message_post_widget.dart';
import 'package:BlueEra/features/common/feed/widget/qa_post_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  final double? horizontalPadding;
  final double? bottomPadding;
  final bool? isFromDetailsScreen;
  final bool? isRepost;
  final VoidCallback? likeFeed;

  /// Channel name passed from the channel feed (channel screen). Used to
  /// show the channel name on posts created via channel.
  final String? channelName;

  const FeedCard(
      {super.key,
      required this.post,
      required this.index,
      required this.postFilteredType,
      this.sortBy,
      this.horizontalPadding,
      this.bottomPadding,
      this.likeFeed,
      this.isFromDetailsScreen = false,
      this.isRepost = false,
      this.channelName});

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
    // One resolver for every feed profile tap — see [openFeedProfile]. It
    // routes on the author's type + sub-category, so a business author reaches
    // its own store / lab / pharmacy screen instead of the generic profile.
    openFeedProfile(_post?.user?.copyWith(id: authorId));
  }

  final feedController = Get.put(FeedController());

  @override
  Widget build(BuildContext context) {
    return buildPostWidget();
  }

  Widget buildPostWidget() {
    FeedType? feedType = FeedType.fromValue(_post?.type?.toUpperCase());
    logs("widget.postFilteredType= ${widget.postFilteredType}");
    logs("feedType ${feedType}");
    switch (feedType) {
      // `image_post` is a photo-first post that shares message_post's exact
      // schema (docs/backend/FRONTEND_FEED_INTEGRATION.md §4.2), so it renders
      // through the same widget. Without it, every `type: "image_post"` item
      // from /feed fell through to the default branch and rendered nothing.
      case FeedType.messagePost || FeedType.photoPost || FeedType.imagePost:
        return widget.postFilteredType == PostType.otherChannelPosts
            ? ChannelFeedMessagePostWidget(
                horizontalPadding: widget.horizontalPadding,
                bottomPadding: widget.bottomPadding,
                post: _post,
                isRepost: false,
                isShowOnlyDetails: widget.isFromDetailsScreen,
                authorSection: () => SizedBox.shrink(),
                commentView: () => _onCommentPressed(),
                buildActions: SizedBox.shrink,
                likeFeed: () {
                  _onLikeDislikePressed();
                },
                onShareButtonPressed: () {
                  onShareButtonPressed(_post);
                },
              )
            : MessagePostWidget(
                horizontalPadding: widget.horizontalPadding,
                bottomPadding: widget.bottomPadding,
                post: _post,
                isRepost: widget.isRepost,
                isShowOnlyDetails: widget.isFromDetailsScreen,
                postType: widget.postFilteredType,
                sortBy: widget.sortBy,
                authorSection: () => IgnorePointer(
                  ignoring: widget.isRepost == true ? true : false,
                  child: PostAuthorHeader(
                    post: _post,
                    isRepost: widget.isRepost,
                    channelName: widget.channelName,
                    authorId: _post?.user?.id ?? '0',
                    postedAgo: _post?.createdAt.toString(),
                    postType: widget.postFilteredType,
                    onTapAvatar: _shouldShowProfileNavigation()
                        ? () =>
                            _navigateToProfile(authorId: _post?.user?.id ?? '0')
                        : null,
                  ),
                ),
                commentView: () => _onCommentPressed(),
                buildActions: SizedBox.shrink,
                likeFeed: widget.likeFeed ??
                    () {
                      _onLikeDislikePressed();
                    },
                onShareButtonPressed: () {
                  onShareButtonPressed(_post);
                },
              );

      case FeedType.qaPost:
        return QaPostWidget(
          post: _post,
          horizontalPaddingChannel:
              widget.postFilteredType == PostType.otherChannelPosts
                  ? 0
                  : widget.horizontalPadding,
          bottomPadding: widget.bottomPadding,
          postId: _post?.id ?? "0",
          poll: Poll(
              options: _post?.poll?.options ?? [],
              question: _post?.poll?.question),
          authorId: _post?.id,
          natureOfPost: _post?.natureOfPost,
          message: _post?.subTitle ?? "",
          commentView: () => _onCommentPressed(),
          postedAgo: timeAgo(
              _post?.createdAt != null ? _post!.createdAt! : DateTime.now()),
          totalViews: _post?.viewsCount.toString() ?? "0",
          referenceLink: _post?.referenceLink ?? '',
          authorSection: widget.postFilteredType == PostType.otherChannelPosts
              ? () => SizedBox.shrink()
              : () => PostAuthorHeader(
                    post: _post,
                    channelName: widget.channelName,
                    authorId: _post?.user?.id ?? '0',
                    postType: widget.postFilteredType,
                    onTapAvatar: _shouldShowProfileNavigation()
                        ? () =>
                            _navigateToProfile(authorId: _post?.user?.id ?? '0')
                        : null,
                    postedAgo: "",
                    // postedAgo: timeAgo(
                    //     _post?.createdAt != null ? _post!.createdAt! : DateTime.now()),
                  ),
          /*  buildActions: () => PostActionsBar(
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
              try {
                onShareButtonPressed(_post!);
              } catch (e) {
                print("feed card share failed $e");
              }
            },
          ),*/
          postFilteredType: widget.postFilteredType,
          buildActions: () => SizedBox.shrink(),
          likeFeed: () {
            _onLikeDislikePressed();
          },
        );

      /*     case FeedType.shorts:
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
        );*/

      default:
        // Default for other post types or null
        return SizedBox();
    }
  }

  void _onLikeDislikePressed() {
    feedController.postLikeDislike(
        postId: _post?.id ?? '0',
        type: widget.postFilteredType,
        sortBy: widget.sortBy);
  }

  void _onCommentPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: CommentBottomSheet(
            id: _post?.id ?? '0',
            totalComments: _post?.commentsCount ?? 0,
            commentType: CommentType.post,
            onNewCommentCount: (int newCommentCount) {
              feedController.updateCommentCount(
                  postId: _post?.id ?? '0',
                  type: widget.postFilteredType,
                  sortBy: widget.sortBy,
                  newCommentCount: newCommentCount);
            }),
      ),
    );
  }
}

bool _isSharing = false;

void onShareButtonPressed(Post? post) {
  final shareUrl = postDeepLink(postId: post?.id.toString());
  showShareOptionsDialog(shareUrl);
}

void showShareOptionsDialog(String shareUrl) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: LocalAssets(
              imagePath: AppIconAssets.share_bold,
              height: 24,
              width: 24,
              imgColor: AppColors.primaryColor,
            ),
            title: CustomText(
              "Share within BlueEra",
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            onTap: () {
              Get.back();
              Get.to(() => ChatForwardScreen(
                    sharedText: shareUrl,
                    stopChatNav: true,
                  ));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.share_outlined,
              color: AppColors.primaryColor,
              size: 24,
            ),
            title: CustomText(
              "Share externally",
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            onTap: () async {
              Get.back();
              if (_isSharing) return;
              try {
                _isSharing = true;
                await SharePlus.instance.share(
                  ShareParams(text: shareUrl),
                );
              } catch (e) {
                debugPrint("Share failed: $e");
              } finally {
                _isSharing = false;
              }
            },
          ),
          SizedBox(
            height: 18,
          )
        ],
      ),
    ),
  );
}

// Future<void> onShareButtonPressed(Post? _post) async {
//   // Prevent multiple calls
//   if (_isSharing) return;
//
//   try {
//     _isSharing = true; // Set flag to prevent multiple calls
//     XFile? xFile;
//     if (_post?.media != null && (_post?.media?.isNotEmpty ?? false)) {
//       // Safely handle first media
//       xFile = await urlToCachedXFile(_post?.media?.first ?? "");
//     }
//
//     final shareUrl = postDeepLink(postId: _post?.id.toString());
//     final combinedText = shareUrl;
//
//     await SharePlus.instance.share(ShareParams(
//         text: combinedText,
//         title: _post?.title,
//         previewThumbnail: xFile,
//         files: [xFile ?? XFile("")]));
//
//     if (xFile != null) {
//       final file = File(xFile.path);
//       if (await file.exists()) {
//         await file.delete();
//         print("🗑️ File deleted from cache.");
//       }
//     }
//   } catch (e) {
//     print("feed card share failed inside _onShareButtonPressed $e");
//   } finally {
//     _isSharing = false;
// // Reset flag
//   }
// }

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
