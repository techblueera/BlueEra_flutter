import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/comment/controller/comment_controller.dart';
import 'package:BlueEra/features/common/comment/model/comment_model_response.dart';
import 'package:BlueEra/features/common/comment/view/post_ai_comment_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/social_message_post_grid_widget.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_repost_screen.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Twitter/X-style post detail screen with inline comments
class TwitterPostDetailScreen extends StatefulWidget {
  final Post post;
  final PostType postType;
  final SortBy? sortBy;

  const TwitterPostDetailScreen({
    super.key,
    required this.post,
    required this.postType,
    this.sortBy,
  });

  @override
  State<TwitterPostDetailScreen> createState() =>
      _TwitterPostDetailScreenState();
}

class _TwitterPostDetailScreenState extends State<TwitterPostDetailScreen> {
  late final CommentController commentController;
  final FeedController feedController = Get.find<FeedController>();
  final FocusNode _replyFocus = FocusNode();
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    commentController = Get.put(CommentController());
    commentController.clearAiContent();
    commentController.replyingToUser.value = null;
    commentController.parentCommentId = null;
    commentController.getAllPostComments(
        postId: _post.id, isInitialized: true);
  }

  @override
  void dispose() {
    _replyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _post.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: AppStrings.post),
      body: Column(
        children: [
          // Scrollable: post content + comments
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorRow(user),
                  _buildPostContent(),
                  if (_post.is_reposted ?? false) _buildRepostContent(),
                  _buildTimestampAndViews(),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildStatsRow(),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildActionBar(),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildCommentsHeader(),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          // Sticky reply input
          _buildReplyInput(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // AUTHOR ROW
  // ─────────────────────────────────────────
  Widget _buildAuthorRow(User? user) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size12, SizeConfig.size12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _openProfile(user),
            child: CachedAvatarWidget(
              imageUrl: user?.profileImage,
              size: 44,
              borderRadius: 22,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(user),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    user?.name ?? '',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.username != null && user!.username!.isNotEmpty)
                    CustomText(
                      '@${user.username}',
                      fontSize: 13,
                      color: AppColors.secondaryTextColor,
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert,
                color: AppColors.secondaryTextColor, size: 20),
            itemBuilder: (_) => PopupMenuBuilders.popupMenuVisitProfileItems(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // POST CONTENT
  // ─────────────────────────────────────────
  Widget _buildPostContent() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_post.title?.isNotEmpty ?? false) ...[
            CustomText(
              _post.title,
              fontWeight: FontWeight.bold,
              color: AppColors.mainTextColor,
              fontSize: SizeConfig.large,
            ),
            SizedBox(height: 4),
          ],
          if ((_post.subTitle ?? '').isNotEmpty)
            ExpandableText(
              text: _post.subTitle ?? '',
              trimLines: 25,
              style: TextStyle(
                color: AppColors.mainTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: AppConstants.OpenSans,
              ),
            ),
          // Media
          if (_post.media?.isNotEmpty ?? false) ...[
            // Video
            if ((_post.media_types?.firstOrNull?.startsWith("video/") ??
                    false) ||
                isVideoUrl(_post.media?.firstOrNull))
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.size10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: PostFeedAutoPlayVideoCard(
                    videoItem: getVideoData(_post),
                    globalMuteNotifier: ValueNotifier(false),
                    videoType: VideoType.videoFeed,
                    onTapOption: () {},
                  ),
                ),
              ),
            // Image
            if ((_post.media_types?.firstOrNull?.startsWith("image/") ??
                    false) ||
                isImageUrl(_post.media?.firstOrNull))
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.size10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: (_post.media?.length == 1)
                      ? _buildFullWidthSingleImage(_post.media!.first)
                      : SocialImageGrid(
                          imageUrls: _post.media ?? [],
                          subTitle: _post.subTitle ?? "",
                          postData: _post,
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // REPOST CONTENT (embedded original post)
  // ─────────────────────────────────────────
  Widget _buildRepostContent() {
    final childPost = _post.children_post;
    if (childPost == null) return SizedBox.shrink();
    final childUser = childPost.user;

    final bool hasMedia = childPost.media?.isNotEmpty ?? false;
    final bool isVideo =
        (childPost.media_types?.firstOrNull?.startsWith("video/") ?? false) ||
            isVideoUrl(childPost.media?.firstOrNull);
    final bool isImage =
        (childPost.media_types?.firstOrNull?.startsWith("image/") ?? false) ||
            isImageUrl(childPost.media?.firstOrNull);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size4),
      child: InkWell(
        onTap: () {
          Get.to(() => TwitterPostDetailScreen(
                post: childPost,
                postType: widget.postType,
                sortBy: widget.sortBy,
              ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.secondaryTextColor.withValues(alpha: 0.2)),
            color: AppColors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original post author header
              Padding(
                padding: EdgeInsets.only(
                    top: SizeConfig.size10,
                    left: SizeConfig.size10,
                    right: SizeConfig.size10),
                child: Row(
                  children: [
                    CachedAvatarWidget(
                      imageUrl: childUser?.profileImage,
                      size: 30,
                      borderRadius: 25,
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Flexible(
                      child: CustomText(
                        childUser?.name ?? '',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    if (childUser?.username != null &&
                        (childUser!.username!.isNotEmpty))
                      Expanded(
                        child: CustomText(
                          ' @${childUser.username}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.shadowColor,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size10),
              // Media + text content
              if (hasMedia && (isVideo || isImage))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black,
                          child: CachedNetworkImage(
                            imageUrl: isVideo
                                ? (childPost.thumbnail ?? '')
                                : (childPost.media?.first ?? ''),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 110,
                              height: 110,
                              color: Colors.grey[300],
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.person, size: 21),
                          ),
                        ),
                      ),
                    ),
                    // Title + subtitle
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (childPost.title?.isNotEmpty ?? false)
                              CustomText(
                                childPost.title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainTextColor,
                              ),
                            SizedBox(height: 4),
                            CustomText(
                              childPost.subTitle ?? '',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.size13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                // No media — just show text content
                if (childPost.title?.isNotEmpty ?? false)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: CustomText(
                      childPost.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                if (childPost.subTitle?.isNotEmpty ?? false)
                  Padding(
                    padding: EdgeInsets.only(
                        left: SizeConfig.size10,
                        right: SizeConfig.size10,
                        top: 4),
                    child: CustomText(
                      childPost.subTitle ?? '',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.size13,
                    ),
                  ),
              ],
              SizedBox(height: SizeConfig.size10),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TIMESTAMP + VIEWS
  // ─────────────────────────────────────────
  Widget _buildTimestampAndViews() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
      child: Row(
        children: [
          CustomText(
            timeAgo(_post.createdAt ?? DateTime.now()),
            fontSize: 13,
            color: AppColors.secondaryTextColor,
          ),
          CustomText(' · ', color: AppColors.secondaryTextColor),
          CustomText(
            '${formatNumberLikePost(_post.viewsCount ?? 0)} ',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          CustomText('Views',
              fontSize: 13, color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // STATS ROW (Reposts · Comments · Likes)
  // ─────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
      child: Row(
        children: [
          _statText(formatNumberLikePost(_post.repostCount ?? 0), 'Reposts'),
          SizedBox(width: 16),
          Obx(() => _statText(
              formatNumberLikePost(commentController.totalCommentCount.value),
              'Comments')),
          SizedBox(width: 16),
          _statText(formatNumberLikePost(_post.likesCount ?? 0), 'Likes'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // ACTION BAR
  // ─────────────────────────────────────────
  Widget _buildActionBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Comment
          _actionIconWithCount(
            iconPath: AppIconAssets.comment_new,
            count: formatNumberLikePost(_post.commentsCount ?? 0),
            onTap: () => _replyFocus.requestFocus(),
          ),
          // Repost
          _actionIconWithCount(
            iconPath: AppIconAssets.repost_new,
            count: formatNumberLikePost(_post.repostCount ?? 0),
            onTap: () {
              if (isGuestUser()) {
                createProfileScreen();
                return;
              }
              _showRepostDialog();
            },
          ),
          // Like
          _actionIconWithCount(
            iconPath: AppIconAssets.like_new,
            count: formatNumberLikePost(_post.likesCount ?? 0),
            color: (_post.isLiked ?? false)
                ? AppColors.primaryColor
                : AppColors.secondaryTextColor,
            onTap: () {
              if (isGuestUser()) {
                createProfileScreen();
                return;
              }
              _onLikePressed();
            },
          ),
          // Share
          _actionIcon(AppIconAssets.share_bold, onTap: () {
            final url = postDeepLink(postId: _post.id.toString());
            showShareOptionsDialog(url);
          }),
        ],
      ),
    );
  }

  void _onLikePressed() {
    feedController.postLikeDislike(
      postId: _post.id,
      type: widget.postType,
      sortBy: widget.sortBy,
    );
    // Optimistic update for local state
    setState(() {
      final wasLiked = _post.isLiked ?? false;
      _post = _post.copyWith(
        isLiked: !wasLiked,
        likesCount: (_post.likesCount ?? 0) + (wasLiked ? -1 : 1),
      );
    });
  }

  void _showRepostDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: SizeConfig.size20),
                    // Direct Repost
                    InkWell(
                      onTap: () async {
                        Get.put(MessagePostController());
                        Get.back();
                        ResponseModel responseModel =
                            await PostRepo().addRePostNewRepo(
                          reqDataData: {
                            ApiKeys.type: AppConstants.MESSAGE_POST,
                            ApiKeys.repostId: _post.id,
                          },
                        );
                        if (responseModel.isSuccess) {
                          commonSnackBar(
                              message: AppStrings.repostedSuccessfully);
                          Get.find<NavigationHelperController>()
                              .shouldRefreshBottomBar
                              .value = true;
                          Get.until((route) =>
                              route.settings.name ==
                              RouteHelper
                                  .getBottomNavigationBarScreenRoute());
                        } else {
                          commonSnackBar(
                              message: AppStrings.alreadyReposted);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: SizeConfig.size30,
                            height: SizeConfig.size30,
                            child: LocalAssets(
                              imagePath: AppIconAssets.repost_new,
                              width: SizeConfig.size30,
                              height: SizeConfig.size30,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.Repost,
                                    textAlign: TextAlign.left,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.size16,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.sharePostWithFollowers,
                                    textAlign: TextAlign.left,
                                    color:
                                        AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.size13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: SizeConfig.size10,
                          bottom: SizeConfig.size10),
                      child: Divider(
                          color: AppColors.secondaryTextColor),
                    ),
                    // Quote Repost
                    InkWell(
                      onTap: () {
                        Get.back();
                        Get.to(CreateMessagePostScreenRepost(
                          isEdit: false,
                          post: _post,
                        ));
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: SizeConfig.size30,
                            height: SizeConfig.size30,
                            child: LocalAssets(
                              imagePath: AppIconAssets.pencilIcon,
                              width: SizeConfig.size20,
                              height: SizeConfig.size20,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.addYourThings,
                                    textAlign: TextAlign.left,
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.size16,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10),
                                  child: CustomText(
                                    AppStrings.addCommentBeforeShare,
                                    textAlign: TextAlign.left,
                                    color:
                                        AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.size13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionIconWithCount({
    required String iconPath,
    required String count,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: iconPath,
              width: 22,
              height: 22,
              imgColor: color ?? AppColors.secondaryTextColor,
            ),
            SizedBox(width: 4),
            CustomText(
              count,
              fontSize: SizeConfig.size12,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // COMMENTS HEADER
  // ─────────────────────────────────────────
  Widget _buildCommentsHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.size16, SizeConfig.size12, SizeConfig.size16, 4),
      child: CustomText(
        'Most relevant replies',
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }

  // ─────────────────────────────────────────
  // COMMENTS LIST
  // ─────────────────────────────────────────
  Widget _buildCommentsList() {
    return Obx(() {
      if (commentController.isLoading.value) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (commentController.comments.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size30),
          child: Center(
            child: CustomText(
              'No comments yet',
              color: AppColors.secondaryTextColor,
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
        itemCount: commentController.comments.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) => _commentTile(commentController.comments[i]),
      );
    });
  }

  Widget _commentTile(CommentData comment) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatarWidget(
            imageUrl: comment.createdBy?.profilePic,
            size: 34,
            borderRadius: 17,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        comment.createdBy?.name ?? '',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    CustomText(
                      '· ${comment.timeAgo ?? ''}',
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                SizedBox(height: 2),
                CustomText(
                  comment.message ?? '',
                  fontSize: 14,
                  color: AppColors.mainTextColor,
                  height: 1.4,
                ),
                SizedBox(height: 8),
                // Comment actions
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        commentController.parentCommentId = comment.sId;
                        commentController.replyingToUser.value =
                            comment.createdBy?.name;
                        _replyFocus.requestFocus();
                      },
                      child: Row(
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.comment_new,
                            width: 16,
                            height: 16,
                            imgColor: AppColors.secondaryTextColor,
                          ),
                          SizedBox(width: 4),
                          CustomText(
                            '${comment.repliesCount ?? 0}',
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.like_new,
                          width: 16,
                          height: 16,
                          imgColor: (comment.isLiked ?? false)
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                        ),
                        SizedBox(width: 4),
                        CustomText(
                          '${comment.likesCount ?? 0}',
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    LocalAssets(
                      imagePath: AppIconAssets.share_bold,
                      width: 14,
                      height: 14,
                      imgColor: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                // Inline replies
                if (comment.replies?.isNotEmpty ?? false) ...[
                  SizedBox(height: 8),
                  ...comment.replies!.take(2).map((reply) => Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedAvatarWidget(
                              imageUrl: reply.createdBy?.profilePic,
                              size: 24,
                              borderRadius: 12,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomText(
                                          reply.createdBy?.name ?? '',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12),
                                      SizedBox(width: 4),
                                      CustomText(
                                        reply.timeAgo ?? '',
                                        fontSize: 11,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ],
                                  ),
                                  CustomText(reply.message ?? '',
                                      fontSize: 13,
                                      color: AppColors.mainTextColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  if ((comment.replies!.length) > 2)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CustomText(
                        'Show more replies',
                        fontSize: 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM REPLY INPUT
  // ─────────────────────────────────────────
  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Obx(() {
                final replyingTo = commentController.replyingToUser.value;
                return TextField(
                  controller: commentController.sendMessageController,
                  focusNode: _replyFocus,
                  style: TextStyle(
                      fontSize: 14, fontFamily: AppConstants.OpenSans),
                  decoration: InputDecoration(
                    hintText: replyingTo != null
                        ? 'Replying to @$replyingTo'
                        : 'Post your reply',
                    hintStyle: TextStyle(
                        color: AppColors.secondaryTextColor, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (isGuestUser()) {
                          createProfileScreen();
                          return;
                        }
                        Get.to(() => PostAiCommentScreen(
                              dataId: commentController.parentCommentId ??
                                  _post.id,
                              commentType:
                                  commentController.parentCommentId != null
                                      ? "comment_reply"
                                      : "comment",
                            ));
                      },
                      icon: LocalAssets(
                        imagePath: AppIconAssets.ai_generative,
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(width: 8),
            InkWell(
              onTap: () async {
                if (isGuestUser()) {
                  createProfileScreen();
                  return;
                }
                final text =
                    commentController.sendMessageController.text.trim();
                if (text.isEmpty) return;

                Map<String, dynamic> params = {
                  ApiKeys.post_id: _post.id,
                  ApiKeys.message: text,
                };
                if (commentController.parentCommentId != null) {
                  params[ApiKeys.parentCommentId] =
                      commentController.parentCommentId;
                }
                await commentController.addPostComment(
                  params: params,
                  postId: _post.id,
                );

                feedController.updateCommentCount(
                  postId: _post.id,
                  type: widget.postType,
                  sortBy: widget.sortBy,
                  newCommentCount: commentController.totalCommentCount.value,
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  Widget _statText(String count, String label) {
    return Row(
      children: [
        CustomText(count, fontWeight: FontWeight.w700, fontSize: 14),
        SizedBox(width: 4),
        CustomText(label,
            fontSize: 14, color: AppColors.secondaryTextColor),
      ],
    );
  }

  Widget _buildFullWidthSingleImage(String imageUrl) {
    final double screenWidth = Get.width;
    final double mediaWidth = _post.media_width?.toDouble() ?? 0;
    final double mediaHeight = _post.media_height?.toDouble() ?? 0;
    final bool hasValidSize = mediaWidth > 0 && mediaHeight > 0;

    return GestureDetector(
      onTap: () {
        Get.to(() => ImageViewScreen(
              appBarTitle: 'Item Image',
              imageUrls: _post.media ?? [],
              initialIndex: 0,
            ));
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: screenWidth,
        fit: BoxFit.cover,
        placeholder: (context, _) => AspectRatio(
          aspectRatio: hasValidSize ? (mediaWidth / mediaHeight) : 16 / 9,
          child: Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, __) => AspectRatio(
          aspectRatio: hasValidSize ? (mediaWidth / mediaHeight) : 16 / 9,
          child: Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child:
                const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(String iconPath, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: LocalAssets(
          imagePath: iconPath,
          width: 22,
          height: 22,
          imgColor: color ?? AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  void _openProfile(User? user) {
    if (user?.id == null) return;
    if (userId == user?.id) {
      openMeOverview();

      // navigatePushTo(context, PersonalProfileSetupNewScreen());
    } else {
      Get.to(() => NewVisitProfileScreen(
            authorId: user?.id ?? '',
            screenFromName: AppConstants.feedScreen,
          ));
    }
  }
}
