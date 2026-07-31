import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/image_post_feed_controller.dart';
import 'package:BlueEra/features/common/feed/feed_profile_navigation.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_repost_screen.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen, reels-style feed of IMAGE posts. Opened when the user taps an
/// image post in the home feed. Vertical [PageView] (one post per screen),
/// paginated through the existing home-feed API via [ImagePostFeedController]
/// (which wraps [HomeFeedController]). The tapped post shows first.
class ImagePostFeedScreen extends StatefulWidget {
  final Post initialPost;
  final int initialImageIndex;

  const ImagePostFeedScreen({
    super.key,
    required this.initialPost,
    this.initialImageIndex = 0,
  });

  @override
  State<ImagePostFeedScreen> createState() => _ImagePostFeedScreenState();
}

class _ImagePostFeedScreenState extends State<ImagePostFeedScreen> {
  late final String _tag;
  late final ImagePostFeedController controller;
  final PageController _pageController = PageController();
  final RxInt currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _tag =
        'image_feed_${widget.initialPost.id}_${DateTime.now().millisecondsSinceEpoch}';
    controller = Get.put(ImagePostFeedController(tag: _tag), tag: _tag);
    controller.seedInitial(widget.initialPost);
  }

  @override
  void dispose() {
    _pageController.dispose();
    Get.delete<ImagePostFeedController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final posts = controller.imagePosts;
        if (posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: posts.length,
          onPageChanged: (index) {
            currentIndex.value = index;
            // Prefetch the next page as we approach the end.
            if (index >= posts.length - 2 &&
                controller.hasMoreData.value &&
                !controller.isLoading.value) {
              controller.loadMore();
            }
          },
          itemBuilder: (context, index) {
            final post = posts[index];
            return _ImagePostFeedItem(
              key: ValueKey(post.id),
              post: post,
              index: index,
              controller: controller,
              initialImageIndex:
                  index == 0 ? widget.initialImageIndex : 0,
            );
          },
        );
      }),
    );
  }
}

class _ImagePostFeedItem extends StatefulWidget {
  final Post post;
  final int index;
  final ImagePostFeedController controller;
  final int initialImageIndex;

  const _ImagePostFeedItem({
    super.key,
    required this.post,
    required this.index,
    required this.controller,
    required this.initialImageIndex,
  });

  @override
  State<_ImagePostFeedItem> createState() => _ImagePostFeedItemState();
}

class _ImagePostFeedItemState extends State<_ImagePostFeedItem> {
  late final PageController _imagePageController;
  final RxInt _imageIndex = 0.obs;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _imageIndex.value = widget.initialImageIndex;
    _imagePageController =
        PageController(initialPage: widget.initialImageIndex);
    trackPostView(widget.post.id);
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Post get _post => widget.post;

  List<String> get _images => _post.media ?? const [];

  /// Same shared resolver as the feed list, so the author opens on whichever
  /// screen their profile type / sub-category owns.
  void _openProfile() => openFeedProfile(_post.user);

  void _openComments() {
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: CommentBottomSheet(
          id: _post.id,
          totalComments: _post.commentsCount ?? 0,
          commentType: CommentType.post,
          onNewCommentCount: (count) =>
              widget.controller.updateCommentCount(_post.id, count),
        ),
      ),
    );
  }

  Future<void> _onShare() async {
    if (_isSharing) return;
    try {
      _isSharing = true;
      onShareButtonPressed(_post);
    } finally {
      _isSharing = false;
    }
  }

  void _showRepostDialog() {
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15, vertical: SizeConfig.size20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _repostOption(
                  iconPath: AppIconAssets.repost_new,
                  title: AppStrings.Repost,
                  subtitle: AppStrings.sharePostWithFollowers,
                  onTap: () async {
                    Get.back();
                    final ResponseModel res =
                        await PostRepo().addRePostNewRepo(reqDataData: {
                      ApiKeys.type: AppConstants.MESSAGE_POST,
                      ApiKeys.repostId: _post.id,
                    });
                    if (res.isSuccess) {
                      widget.controller.incrementRepost(_post.id);
                      commonSnackBar(
                          message: AppStrings.repostedSuccessfully);
                      Get.find<NavigationHelperController>()
                          .shouldRefreshBottomBar
                          .value = true;
                    } else {
                      commonSnackBar(message: AppStrings.alreadyReposted);
                    }
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                  child: Divider(color: AppColors.secondaryTextColor),
                ),
                _repostOption(
                  iconPath: AppIconAssets.pencilIcon,
                  title: AppStrings.addYourThings,
                  subtitle: AppStrings.addCommentBeforeShare,
                  onTap: () {
                    Get.back();
                    Get.to(() => CreateMessagePostScreenRepost(
                          isEdit: false,
                          post: _post,
                        ));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _repostOption({
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: SizeConfig.size30,
            height: SizeConfig.size30,
            child: LocalAssets(
              imagePath: iconPath,
              width: SizeConfig.size24,
              height: SizeConfig.size24,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.size16,
                ),
                CustomText(
                  subtitle,
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.size13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canRepost {
    final type = _post.type?.toLowerCase();
    return type == 'message_post' ||
        type == 'image_post' ||
        type == 'photo_post';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size10),
          // Top bar: back + author
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
                SizedBox(width: SizeConfig.size10),
                if ((_post.user?.profileImage ?? '').isNotEmpty)
                  InkWell(
                    onTap: _openProfile,
                    child: CachedAvatarWidget(
                      imageUrl: _post.user?.profileImage,
                      size: 40,
                      borderColor: Colors.white,
                      borderRadius: 25,
                    ),
                  ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: InkWell(
                    onTap: _openProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          _post.user?.name ?? '',
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.white,
                        ),
                        if ((_post.user?.designation ?? '').isNotEmpty)
                          CustomText(
                            _post.user?.designation ?? '',
                            fontWeight: FontWeight.w400,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.white,
                            fontSize: SizeConfig.size12,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size10),

          // Image area + overlaid actions/caption
          Expanded(
            child: Stack(
              children: [
                // Zoomable, swipeable images for this post
                Positioned.fill(
                  child: PageView.builder(
                    controller: _imagePageController,
                    itemCount: _images.length,
                    onPageChanged: (i) => _imageIndex.value = i,
                    itemBuilder: (context, i) {
                      return InteractiveViewer(
                        panEnabled: true,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: _images[i],
                            fit: BoxFit.contain,
                            width: Get.width,
                            placeholder: (context, _) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            errorWidget: (context, _, __) => const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.white54, size: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Page dots when the post has more than one image
                if (_images.length > 1)
                  Positioned(
                    top: SizeConfig.size10,
                    left: 0,
                    right: 0,
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _imageIndex.value == i ? 8 : 6,
                            height: _imageIndex.value == i ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _imageIndex.value == i
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Actions + caption (bottom)
                Positioned(
                  bottom: SizeConfig.size10,
                  left: SizeConfig.size12,
                  right: SizeConfig.size12,
                  child: Obx(() {
                    // Read the latest reactive copy of this post so
                    // like/comment/repost counts update live.
                    final list = widget.controller.imagePosts;
                    final live = widget.index < list.length &&
                            list[widget.index].id == _post.id
                        ? list[widget.index]
                        : _post;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if ((live.title?.isNotEmpty ?? false))
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: SizeConfig.size5),
                            child: CustomText(
                              live.title ?? '',
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if ((live.subTitle?.isNotEmpty ?? false))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryTextColor
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ExpandableText(
                              text: live.subTitle ?? '',
                              trimLines: 2,
                              isReadMoreNewLine: false,
                              expandMode: ExpandMode.expandable,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppConstants.OpenSans,
                              ),
                            ),
                          ),
                        SizedBox(height: SizeConfig.size8),
                        // Horizontal action bar (same layout as the feed card).
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _action(
                              iconPath: AppIconAssets.eye_new,
                              count:
                                  formatNumberLikePost(live.viewsCount ?? 0),
                            ),
                            _action(
                              iconPath: AppIconAssets.comment_new,
                              count: formatNumberLikePost(
                                  live.commentsCount ?? 0),
                              onTap: _openComments,
                            ),
                            _action(
                              iconPath: AppIconAssets.like_new,
                              count:
                                  formatNumberLikePost(live.likesCount ?? 0),
                              iconColor: (live.isLiked ?? false)
                                  ? AppColors.primaryColor
                                  : AppColors.white,
                              onTap: () {
                                if (isGuestUser()) {
                                  createProfileScreen();
                                } else {
                                  widget.controller.toggleLike(widget.index);
                                }
                              },
                            ),
                            if (_canRepost)
                              _action(
                                iconPath: AppIconAssets.repost_new,
                                count: formatNumberLikePost(
                                    live.repostCount ?? 0),
                                onTap: _showRepostDialog,
                              ),
                            _action(
                              iconPath: AppIconAssets.share_bold,
                              count: '',
                              onTap: _onShare,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size5),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required String iconPath,
    required String count,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size6, vertical: SizeConfig.size6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: iconPath,
              width: SizeConfig.size20,
              height: SizeConfig.size20,
              imgColor: iconColor ?? AppColors.white,
            ),
            if (count.isNotEmpty) ...[
              SizedBox(width: SizeConfig.size4),
              CustomText(
                count,
                color: AppColors.white,
                fontSize: SizeConfig.size12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
