import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/all_message_post_res_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
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

  Future<void> fetchPosts({String? cursor, String? postId}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final Map<String, dynamic> queryParams = {
        ApiKeys.id: postId,
        ApiKeys.limit: 40,
        if (cursor != null)
          ApiKeys.cursor: nextCursor, // Fetch 40 items for enhancement
        ApiKeys.type: "MESSAGE_POST", // Fetch 40 items for enhancement
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
      fetchPosts(cursor: nextCursor);
    }
  }

  void toggleLike(String postId) {
    // Implement API call for like
    // Update local state
    int index = posts.indexWhere((e) => e.id == postId);
    posts[index].isLiked = !(posts[index].isLiked ?? false);
    posts.refresh();
  }
}

class AllMessagePostScreen extends StatefulWidget {
  AllMessagePostScreen({super.key, required this.postID});

  final String postID;

  @override
  State<AllMessagePostScreen> createState() => _AllMessagePostScreenState();
}

class _AllMessagePostScreenState extends State<AllMessagePostScreen> {
  final FeedControllerNew controller = Get.put(FeedControllerNew());

  final PageController _pageController = PageController();

  @override
  void initState() {
    // TODO: implement initState
    controller.fetchPosts(postId: widget.postID);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: controller.posts.length,
            onPageChanged: controller.onPageChanged,
            itemBuilder: (context, index) {
              // Using 'dynamic' here, but strictly map this to your Post model
              final post = controller.posts[index];

              final mediaUrl =
                  post.media != null && (post.media?.isNotEmpty ?? false)
                      ? post.media![0]
                      : "";

              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
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
                                if ((post.user?.businessName?.isNotEmpty ??
                                        false) &&
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
                          margin: EdgeInsets.only(bottom: SizeConfig.size20),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryTextColor
                                .withValues(alpha: 0.2),
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
                        //  CustomText(
                        //    post.subTitle ?? "",
                        //    maxLines: 3,
                        //    overflow: TextOverflow.ellipsis,
                        // color: Colors.white),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? const Icon(Icons.person) : null,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 35),
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:flutter/material.dart';
//
// class AllMessagePostScreen extends StatefulWidget {
//   const AllMessagePostScreen({super.key});
//
//   @override
//   State<AllMessagePostScreen> createState() => _AllMessagePostScreenState();
// }
//
// class _AllMessagePostScreenState extends State<AllMessagePostScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       appBar: CommonBackAppBar(),
//     );
//   }
// }
