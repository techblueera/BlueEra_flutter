import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/controller/overview_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/services/share_service.dart';

import '../../controller/profile_controller.dart';

class NewVisitProfileScreen extends StatefulWidget {
  final String authorId;
  final String screenFromName;
  final String? isScreenName;

  const NewVisitProfileScreen({
    super.key,
    required this.authorId,
    required this.screenFromName,
    this.isScreenName,
  });

  @override
  State<NewVisitProfileScreen> createState() => _NewVisitProfileScreenState();
}

class _NewVisitProfileScreenState extends State<NewVisitProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OverviewController overViewController = Get.put(OverviewController());
  final FeedController feedController = Get.put(FeedController());
  VisitProfileController visitController =
      Get.isRegistered<VisitProfileController>()
          ? Get.find<VisitProfileController>()
          : Get.put(VisitProfileController());

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overViewController.loadOverviewData(
        widget.authorId,
        VideoType.latest.name,
      );
      feedController.getPostsByType(PostType.otherPosts,
          isInitialLoad: true,
          refresh: true,
          id: widget.authorId,
          query: "",
          screenName: '');
      visitController.fetchUserById(userId: widget.authorId);
      visitController.getUserChannelDetailsController(userId: widget.authorId);
      visitController.getTestimonialController(userID: widget.authorId);
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (widget.isScreenName == AppConstants.deepLinkScreen) {
      Get.offAllNamed(
        RouteHelper.getBottomNavigationBarScreenRoute(),
        arguments: {ApiKeys.initialIndex: 1},
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isScreenName != AppConstants.deepLinkScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        // Transparent so the app-wide themed background (AppHomeBackground,
        // set via app_background_screen) shows through instead of white.
        backgroundColor: Colors.transparent,
        body: Obx(() {
          if (visitController.isProfileLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = visitController.userData.value?.user;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Safe area spacing — white so the header block reads as one
                // white area from the top down to the tab bar.
                SliverToBoxAdapter(
                  child: Container(
                      color: AppColors.white,
                      height: MediaQuery.of(context).padding.top),
                ),

                // Header section (banner + avatar + profile info)
                SliverToBoxAdapter(
                  child: _buildHeaderSection(user),
                ),

                // Pinned tab bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    tabBar: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.mainTextColor,
                      unselectedLabelColor: AppColors.secondaryTextColor,
                      indicatorColor: AppColors.primaryColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: AppConstants.OpenSans,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        fontFamily: AppConstants.OpenSans,
                      ),
                      tabs: [
                        Tab(text: AppStrings.posts.tr),
                        Tab(text: AppStrings.testimonials.tr),
                        Tab(text: AppStrings.channel.tr),
                      ],
                    ),
                    topPadding: MediaQuery.of(context).padding.top,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Posts
                Container(
                  // Transparent so the app background shows behind the feed.
                  color: Colors.transparent,
                  child: FeedScreen(
                    key: ValueKey('feedScreen_user_posts_${widget.authorId}'),
                    postFilterType: PostType.otherPosts,
                    isInParentScroll: true,
                    id: widget.authorId,
                  ),
                ),
                // Testimonials
                Center(child: CustomText('Coming soon')),

                // TestimonialsScreen(
                //   userName:
                //       visitController.userData.value?.user?.name ?? 'N/A',
                //   visitUserID: widget.authorId,
                //   isSelfTestimonial: false,
                //   screenFromName: widget.screenFromName,
                // ),
                // Channel

                Center(child: CustomText('Coming soon')),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER SECTION (banner + avatar + info)
  // Same pattern as social_home_screen _buildHeaderSection
  // ─────────────────────────────────────────────
  Widget _buildHeaderSection(dynamic user) {
    final bannerUrl = (user?.coverPicture?.isNotEmpty ?? false)
        ? user!.coverPicture!
        : (user?.profileImage ?? '');

    return Container(
      color: AppColors.white,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner + Avatar + Actions (Stack)
        SizedBox(
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner image
              ClipRRect(
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: const Color(0xFF8DD0F7),
                  child: bannerUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: bannerUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF8DD0F7),
                          ),
                        )
                      : null,
                ),
              ),

              // Profile avatar — overlaps banner
              Positioned(
                left: 20,
                top: 100,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.white,
                  child: CircleAvatar(
                    radius: 37,
                    backgroundImage: (user?.profileImage != null &&
                            (user?.profileImage?.isNotEmpty ?? false))
                        ? NetworkImage(user?.profileImage ?? "")
                        : null,
                    backgroundColor: AppColors.primaryColor,
                    child: (user?.profileImage == null ||
                            (user?.profileImage?.isEmpty ?? false))
                        ? CustomText(
                            getInitials(user?.name),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          )
                        : null,
                  ),
                ),
              ),

              // Back button
              Positioned(
                left: 8,
                top: 8,
                child: _circleButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: _onBack,
                ),
              ),

              // Share + More buttons
              Positioned(
                right: 8,
                top: 8,
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.share_outlined,
                      onTap: () async {
                        // ShareService owns the link + body + share
                        // sheet for someone-else's-profile shares.
                        await ShareService.instance.shareProfile(
                          userId: user?.id,
                          subject: user?.name,
                        );
                      },
                    ),
                    // const SizedBox(width: 4),
                    // _circleButton(
                    //   icon: Icons.more_vert,
                    //   onTap: () {},
                    // ),
                  ],
                ),
              ),

              // Follow button — positioned at right, below banner
              if (user?.id != null)
                Positioned(
                  right: 12,
                  top: 144,
                  child: Obx(() {
                    final isFollowing = visitController.isFollow.value;
                    return GestureDetector(
                      onTap: () async {
                        if (isGuestUser()) {
                          createProfileScreen();
                        } else {
                          if (isFollowing) {
                            await visitController.unFollowUserController(
                                candidateResumeId: user?.id);
                          } else {
                            await visitController.followUserController(
                                candidateResumeId: user?.id);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? AppColors.greyLite
                              : AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomText(
                          isFollowing
                              ? AppStrings.unfollow.tr
                              : AppStrings.follow.tr,
                          color: isFollowing
                              ? AppColors.secondaryTextColor
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size10,
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Name + Username + Profession
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                user?.name ?? '',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 4),
              if (user?.username != null && user!.username!.isNotEmpty)
                CustomText(
                  "@${user.username}",
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              if (user?.profession != null &&
                  user?.profession != "null" &&
                  (user?.profession?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 4),
                CustomText(
                  user.profession,
                  fontSize: 13,
                  color: AppColors.secondaryTextColor,
                ),
              ],

              // Bio
              if ((user?.bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ExpandableText(
                  text: user.bio ?? '',
                  trimLines: 3,
                  style: TextStyle(
                    color: AppColors.mainTextColor,
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: AppConstants.OpenSans,
                  ),
                  expandMode: ExpandMode.expandable,
                ),
              ],

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _statItem(
                    count: visitController.userData.value?.totalPosts
                            ?.toString() ??
                        "0",
                    label: AppStrings.post.tr,
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowersFollowingPage(
                          tabIndex: 0,
                          userID: user?.id ?? "",
                        ),
                      ),
                    ),
                    child: _statItem(
                      count: visitController.userData.value?.followingCount
                              ?.toString() ??
                          "0",
                      label: AppStrings.following.tr,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Obx(() => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowersFollowingPage(
                              tabIndex: 1,
                              userID: user?.id ?? "",
                            ),
                          ),
                        ),
                        child: _statItem(
                          count:
                              visitController.followerCount.value.toString(),
                          label: AppStrings.followers.tr,
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.whiteEE, thickness: 1, height: 1),
            ],
          ),
        ),
      ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _statItem({required String count, required String label}) {
    return Row(
      children: [
        CustomText(
          formatNumberLikePost(int.tryParse(count) ?? 0),
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.mainTextColor,
        ),
        SizedBox(width: 4),
        CustomText(
          label,
          fontSize: 14,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PINNED TAB BAR DELEGATE
// ─────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final double topPadding;

  _TabBarDelegate({required this.tabBar, required this.topPadding});

  @override
  double get minExtent => tabBar.preferredSize.height + topPadding;

  @override
  double get maxExtent => tabBar.preferredSize.height + topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // White so the header-through-tab-bar region stays one white block; the
      // tab content below is transparent and shows the app background.
      color: AppColors.white,
      child: Column(
        children: [
          SizedBox(height: topPadding),
          tabBar,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding;
}
