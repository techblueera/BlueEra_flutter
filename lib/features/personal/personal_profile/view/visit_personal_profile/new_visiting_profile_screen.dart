import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/controller/overview_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

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
        arguments: {ApiKeys.initialIndex: 0},
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
        backgroundColor: AppColors.white,
        body: Obx(() {
          if (visitController.isProfileLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = visitController.userData.value?.user;
          final bannerUrl = (user?.coverPicture?.isNotEmpty ?? false)
              ? user!.coverPicture!
              : (user?.profileImage ?? '');

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Collapsing banner + back/actions
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: AppColors.white,
                  leading: _circleButton(
                    icon: Icons.arrow_back,
                    onTap: _onBack,
                  ),
                  actions: [
                    _circleButton(
                      icon: Icons.share_outlined,
                      onTap: () async {
                        final link = profileDeepLink(
                            userId: user?.id,
                            accountType: AppConstants.individual);
                        await SharePlus.instance.share(
                          ShareParams(
                              text: "See my profile on BlueEra:\n$link\n",
                              subject: user?.name),
                        );
                      },
                    ),
                    _circleButton(
                      icon: Icons.more_vert,
                      onTap: () {},
                    ),
                    SizedBox(width: 4),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: bannerUrl.isNotEmpty
                        ? Image.network(
                            bannerUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Color(0xFF8DD0F7),
                            ),
                          )
                        : Container(color: Color(0xFF8DD0F7)),
                  ),
                ),

                // Profile info section
                SliverToBoxAdapter(
                  child: _buildProfileInfo(user),
                ),

                // Pinned tab bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
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
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Posts
                FeedScreen(
                  key: ValueKey('feedScreen_user_posts_${widget.authorId}'),
                  postFilterType: PostType.otherPosts,
                  isInParentScroll: true,
                  id: widget.authorId,
                ),
                // Testimonials
                TestimonialsScreen(
                  userName:
                      visitController.userData.value?.user?.name ?? 'N/A',
                  visitUserID: widget.authorId,
                  isSelfTestimonial: false,
                  screenFromName: widget.screenFromName,
                ),
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
  // PROFILE INFO (below banner, above tabs)
  // ─────────────────────────────────────────────
  Widget _buildProfileInfo(dynamic user) {
    const double avatarRadius = 36;
    const double borderWidth = 4;
    const double avatarOverlap = 30;
    const double avatarTotalSize = (avatarRadius + borderWidth) * 2;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar row + Follow button — uses Stack to overlap into banner
          SizedBox(
            height: avatarTotalSize - avatarOverlap + 10, // visible height below banner
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar positioned to overlap banner
                Positioned(
                  left: 0,
                  top: -avatarOverlap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: borderWidth),
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
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
                // Follow button aligned right, vertically centered
                if (user?.id != null)
                  Positioned(
                    right: 0,
                    top: 4,
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? Colors.transparent
                                : AppColors.mainTextColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFollowing
                                  ? AppColors.secondaryTextColor
                                  : AppColors.mainTextColor,
                            ),
                          ),
                          child: CustomText(
                            isFollowing
                                ? AppStrings.unfollow
                                : AppStrings.follow,
                            color: isFollowing
                                ? AppColors.mainTextColor
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),

          // Name + username + bio + stats
          CustomText(
            user?.name ?? '',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: 2),
          if (user?.username != null && user!.username!.isNotEmpty)
            CustomText(
              "@${user.username}",
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          if (user?.profession != null &&
              user?.profession != "null" &&
              (user?.profession?.isNotEmpty ?? false)) ...[
            SizedBox(height: 4),
            CustomText(
              user.profession,
              fontSize: 13,
              color: AppColors.secondaryTextColor,
            ),
          ],

          // Bio
          if ((user?.bio ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 8),
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

          SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _statItem(
                count:
                    visitController.userData.value?.totalPosts?.toString() ?? "0",
                label: AppStrings.post,
              ),
              SizedBox(width: 20),
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
                  label: AppStrings.following,
                ),
              ),
              SizedBox(width: 20),
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
                      count: visitController.followerCount.value.toString(),
                      label: AppStrings.followers,
                    ),
                  )),
            ],
          ),
          SizedBox(height: 12),
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
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
