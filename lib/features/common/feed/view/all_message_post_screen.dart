
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_message_post_widget.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/all_message_post_res_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeedControllerNew extends GetxController {
  var posts = <Post>[].obs; // Replace dynamic with your Post model
  var isLoading = false.obs;
  var currentPlayingIndex = 0.obs;

  // Pagination
  String? nextCursor;
  bool hasMoreData = true;

  Future<void> fetchPosts(
      {String? cursor, String? postId, String? postType}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final Map<String, dynamic> queryParams = {
        ApiKeys.id: postId,
        ApiKeys.limit: 40,
        if (cursor != null)
          ApiKeys.cursor: nextCursor, // Fetch 40 items for enhancement
        ApiKeys.type: postType, // Fetch 40 items for enhancement
        // ApiKeys.type: "MESSAGE_POST", // Fetch 40 items for enhancement
      };
      final response =
          await FeedRepo().fetchAllMessagePosts(queryParams: queryParams);

      // TODO: Replace with your actual API Call
      // SIMULATING API RESPONSE BASED ON YOUR JSON
      await Future.delayed(const Duration(seconds: 1)); // Mock delay
      AllMessagePostResModel allMessagePostResModel =
          AllMessagePostResModel.fromJson(response.response?.data);
      // Parse your response here.
      // Assuming 'response.data' is the list from your JSON.
      List<Post> newPosts = []; // mapped from apiResponse['data']

      newPosts = allMessagePostResModel.data ?? [];

      if (newPosts.isEmpty && cursor != null) {
        hasMoreData = false;
      }

      posts.addAll(newPosts);

      // Logic to get next cursor (usually the createdAt of the last item or specific field)
      nextCursor = allMessagePostResModel.meta?.nextCursor;
    } catch (e) {
      print("Error fetching posts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void onPageChanged(int index) {
    currentPlayingIndex.value = index;

    // Pagination Logic: Load more when we are 3 items away from end
    if (index >= posts.length - 3 && hasMoreData) {
      fetchPosts(
        cursor: nextCursor,
      );
    }
  }

  void toggleLike(String postId) {
    // Implement API call for like
    // Update local state
    int index = posts.indexWhere((e) => e.id == postId);
    posts[index].isLiked = !(posts[index].isLiked ?? false);
    posts[index].likesCount = (posts[index].likesCount ?? 0) +
        (posts[index].isLiked != null ? 1 : -1);

    posts.refresh();
  }

  void commentCount(String postId, int newCommentCount) {
    // Implement API call for like
    // Update local state
    int index = posts.indexWhere((e) => e.id == postId);
    posts[index].commentsCount = newCommentCount;

    posts.refresh();
  }
}

class AllMessagePostScreen extends StatefulWidget {
  AllMessagePostScreen(
      {super.key, required this.postID, required this.postType});

  final String postID;
  final String postType;

  @override
  State<AllMessagePostScreen> createState() => _AllMessagePostScreenState();
}

class _AllMessagePostScreenState extends State<AllMessagePostScreen> {
  final FeedControllerNew controller = Get.put(FeedControllerNew());

  final PageController _pageController = PageController();
  final PageController _imagePageController = PageController();
  RxInt currentIndex = 0.obs;
  bool _isSharing = false;
  final feedController = Get.put(FeedController());

  @override
  void initState() {
    // TODO: implement initState
    controller.fetchPosts(postId: widget.postID, postType: widget.postType);
    super.initState();
  }

  bool isShareLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return IgnorePointer(
                ignoring: isShareLoading,
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  itemCount: controller.posts.length,
                  onPageChanged: controller.onPageChanged,
                  itemBuilder: (context, index) {
                    final post = controller.posts[index];

                    return messageImagePostWidget(post, index);
                  },
                ),
              );
            }),
            if (isShareLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryColor, strokeWidth: 5)
                    // child: Lottie.asset(AppConstants.appLoader, height: 150.h, width: 150.w, ),
                    ),
              )
          ],
        ),
      ),
    );
  }

  messageImagePostWidget(Post post, int index) {
    final mediaUrls = post.media ?? [];
    post.media != null && (post.media?.isNotEmpty ?? false)
        ? post.media![0]
        : "";
    return Stack(
      fit: StackFit.expand,
      children: [
        mediaUrls.length == 1
            ? CachedNetworkImage(
                imageUrl: mediaUrls.first,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white),
              )
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _imagePageController,
                      itemCount: mediaUrls.length,
                      onPageChanged: (index) => currentIndex.value = index,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: mediaUrls[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.white),
                        );
                      },
                    ),
                  ),

                  // Dot Indicator
                  SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(mediaUrls.length, (index) {
                      return Obx(() => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: currentIndex.value == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentIndex.value == index
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ));
                    }),
                  ),
                ],
              ),

        // 2. Dark Gradient Overlay (for text visibility)
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // 3. Back Button
        Positioned(
          top: 10, // Adjust for SizeConfig
          left: 0,
          child: Row(
            children: [
              Container(
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    // remove internal padding
                    constraints: BoxConstraints(),
                    // remove minimum button size
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 25,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
              SizedBox(
                width: SizeConfig.size10,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      navigatePushTo(
                        context,
                        ImageViewScreen(
                          appBarTitle: AppStrings.imageViewer,
                          imageUrls: [post.user?.profileImage ?? ""],
                          initialIndex: 0,
                        ),
                      );
                    },
                    child: CachedAvatarWidget(
                        imageUrl: post.user?.profileImage,
                        size: 45,
                        borderRadius: 30),
                  ),
                  SizedBox(
                    width: SizeConfig.size20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "${post.user?.name}",
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      if (post.user?.designation?.isNotEmpty ?? false)
                        CustomText(
                          "${post.user?.designation}",
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      if ((post.user?.businessName?.isNotEmpty ?? false) &&
                          (post.user?.businessName != null) &&
                          (post.user?.businessName != "null"))
                        CustomText(
                          post.user?.businessName ?? "",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        /*    // 4. Right Side Interaction Bar
                  Positioned(
                    right: 10,
                    bottom: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        _buildAvatar(post.user?.profileImage),
                        const SizedBox(height: 20),

                        // Like
                        _buildActionButton(
                          icon: (post.isLiked ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              (post.isLiked ?? false) ? Colors.red : Colors.white,
                          label: (post.likesCount.toString()),
                          onTap: () => controller.toggleLike(post.id),
                        ),

                        // Comment
                        _buildActionButton(
                          icon: Icons.comment,
                          label: "${post.commentsCount}",
                          onTap: () {
                            // Open Comment BottomSheet
                          },
                        ),

                        // Share
                        _buildActionButton(
                          icon: Icons.share,
                          label: "${post.sharesCount ?? '0'}",
                          // JSON has shares_count
                          onTap: () {
                            // Share Logic
                          },
                        ),

                        // Menu
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {
                            // Existing Popup logic
                          },
                        ),
                      ],
                    ),
                  ),*/

        // 5. Bottom Info (Username & Caption)
        Positioned(
          bottom: 20,
          left: 10,
          right: 10, // Leave space for right side bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Expandable Text Logic
              Container(
                width: Get.width,
                margin: EdgeInsets.only(bottom: SizeConfig.size10),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpandableText(
                  text: post.subTitle ?? '',
                  trimLines: 4,
                  isReadMoreNewLine: true,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
                // child: Text(
                //   widget.subTitle ?? '',
                //   textAlign: TextAlign.left,
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: SizeConfig.screenWidth * 0.045,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ),

              Container(
                margin: EdgeInsets.only(bottom: SizeConfig.size20),
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ViewFeedActionWidget(
                        iconPath: AppIconAssets.clock_new,
                        fontColor: Colors.white,
                        data: timeAgo((post.createdAt ?? DateTime.now()))),
                    ViewFeedActionWidget(
                      iconPath: AppIconAssets.eye_new,
                      fontColor: Colors.white,
                      data: formatNumberLikePost(post.viewsCount ?? 0),
                    ),
                    InkWell(
                      onTap: () {
                        if (isGuestUser()) {
                          createProfileScreen();
                        } else {
                          onCommentPressed(context, post);
                        }
                      },
                      child: ViewFeedActionWidget(
                          iconPath: AppIconAssets.comment_new,
                          fontColor: Colors.white,
                          data: formatNumberLikePost(post.commentsCount ?? 0)),
                    ),
                    InkWell(
                      onTap: () {
                        if (isGuestUser()) {
                          createProfileScreen();
                        } else {
                          feedController.postLikeDislike(
                            postId: post.id,
                            type: PostType.all,
                          );
                          controller.toggleLike(post.id);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size10),
                        child: Row(
                          children: [
                            LocalAssets(
                              imagePath: AppIconAssets.like_new,
                              width: SizeConfig.size18,
                              height: SizeConfig.size18,
                              imgColor: (post.isLiked ?? false)
                                  ? AppColors.primaryColor
                                  : AppColors.white,
                            ),
                            SizedBox(
                              width: SizeConfig.size5,
                            ),
                            CustomText(
                              formatNumberLikePost(post.likesCount ?? 0),
                              color: AppColors.white,
                              fontSize: SizeConfig.size10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: SizeConfig.size5),
                      child: InkWell(
                        onTap: () async {
                          // Prevent multiple calls
                          if (_isSharing) return;
                          setState(() {
                            isShareLoading = true;
                          });
                          try {
                            _isSharing =
                                true; // Set flag to prevent multiple calls
                            onShareButtonPressed(post);
                            // XFile? xFile;
                            // if ((post.media?.first.isNotEmpty ?? false)) {
                            //   // Safely handle first media
                            //   xFile = await urlToCachedXFile(
                            //       post.media?.first ?? "");
                            // }
                            //
                            // final shareUrl =
                            //     postDeepLink(postId: post.id.toString());
                            // final combinedText = shareUrl;
                            //
                            // await SharePlus.instance.share(ShareParams(
                            //     text: combinedText,
                            //     title: post.subTitle,
                            //     previewThumbnail: xFile,
                            //     files: [xFile ?? XFile("")]));
                            //
                            // if (xFile != null) {
                            //   final file = File(xFile.path);
                            //   if (await file.exists()) {
                            //     await file.delete();
                            //     print("🗑️ File deleted from cache.");
                            //   }
                            // }
                          } catch (e) {
                            print(
                                "feed card share failed inside _onShareButtonPressed $e");
                          } finally {
                            _isSharing = false;
                            setState(() {
                              isShareLoading = false;
                            });
                            // Reset flag
                          }
                        },
                        child: LocalAssets(
                          imagePath: AppIconAssets.share_bold,
                          imgColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  void onCommentPressed(BuildContext context, Post _post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: CommentBottomSheet(
            id: _post.id,
            totalComments: _post.commentsCount ?? 0,
            commentType: CommentType.post,
            onNewCommentCount: (int newCommentCount) async {
              await feedController.updateCommentCount(
                  postId: _post.id,
                  type: PostType.all,
                  newCommentCount: newCommentCount);
              controller.commentCount(_post.id, newCommentCount);

              // _post.commentsCount = newCommentCount;
            }),
      ),
    );
  }
}
