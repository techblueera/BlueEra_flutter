import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/testimonials_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/portfolio_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_bio_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:BlueEra/core/constants/common_methods.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../controller/profile_controller.dart';

class VisitProfileScreen extends StatefulWidget {
  final String authorId;

  const VisitProfileScreen({super.key, required this.authorId});

  @override
  State<VisitProfileScreen> createState() => _VisitProfileScreenState();
}

class _VisitProfileScreenState extends State<VisitProfileScreen>
    with SingleTickerProviderStateMixin {
  List<String> postTab = [];
  int selectedIndex = 0;
  late VisitProfileController controller;
  List<SortBy>? filters;
  SortBy selectedFilter = SortBy.Latest;
  bool _isSharing = false;

  @override
  void initState() {
    controller = Get.put(VisitProfileController());
    setFilters();
    // controller.fetchUserById(userId: "6891a80e721656f3ca842eba");
    controller.fetchUserById(userId: widget.authorId);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  setFilters() {
    filters = SortBy.values.where((e) => e != SortBy.UnderProgress).toList();
  }

  void _showPersonalDetailsPopup() {
    final user = controller.userData.value?.user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'Personal Details',
                      fontSize: SizeConfig.size18,
                      fontWeight: FontWeight.bold,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                // SizedBox(height: SizeConfig.size20),
                // _buildDetailRow(
                //   icon: AppIconAssets.phone,
                //   label: 'Contact',
                //   value: "**********",
                // ),
                SizedBox(height: SizeConfig.size16),
                _buildDetailRow(
                  icon: AppIconAssets.mail,
                  label: 'Email',
                  value: user.email ?? 'Not available',
                ),
                SizedBox(height: SizeConfig.size16),
                _buildDetailRow(
                  icon: AppIconAssets.calander,
                  label: 'Date of Birth',
                  value: controller.formatDateOfBirth(user.dateOfBirth),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          icon,
          width: 20,
          height: 20,
          color: Colors.black,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                value,
                fontSize: SizeConfig.size16,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: Obx(() {
        final user = controller.userData.value?.user;
        if (user == null) {
          return Center(child: CircularProgressIndicator());
        }

        postTab = [
          if (user.profession == SELF_EMPLOYED) 'Portfolio',
          'Posts',
          'Testimonials',
          'Shorts',
          'Videos'
        ];
        final validIndexes = user.profession == SELF_EMPLOYED ? {3, 4} : {2, 3};

        return SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 18.0, top: 4),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryColor, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.grey,
                              backgroundImage: user.profileImage != null
                                  ? NetworkImage(user.profileImage!)
                                  : null,
                              child: user.profileImage == null
                                  ? CustomText(
                                      getInitials(user.name),
                                      fontSize: SizeConfig.size18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: CustomText(
                                            user.name ?? 'N/A',
                                            fontSize: SizeConfig.size18,
                                            fontWeight: FontWeight.w900,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                       
                                        InkWell(
                                          onTap: () async {
                                            if (_isSharing) return;

                                            try {
                                              _isSharing = true;

                                              final link = profileDeepLink(userId: widget.authorId);
                                              final message = "See my profile on BlueEra:\n$link\n";

                                              await SharePlus.instance.share(ShareParams(
                                                text: message,
                                                subject: user.name,
                                              ));

                                            } catch (e) {
                                              print("Profile share failed: $e");
                                            } finally {
                                              _isSharing = false; // Reset flag
                                            }

                                          },
                                          child: Image.asset( 
                                              'assets/images/arrow.png',
                                              height: 25,
                                              width: 25,
                                              fit: BoxFit.cover,
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.end,
                                  //   children: [
                                  //     IconButton(
                                  //       icon: const Icon(Icons.more_vert),
                                  //       onPressed: () {},
                                  //     ),
                                  //   ],
                                  // ),
                                ],
                              ),
                              CustomText(
                                user.profession ?? "OTHERS",
                                color: AppColors.secondaryTextColor,
                              ),
                              GestureDetector(
                                onTap: () => _showPersonalDetailsPopup(),
                                // Reuse method if applicable
                                child: CustomText(
                                  'Personal Details',
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(height: SizeConfig.size12),
                              Padding(
                                padding: EdgeInsets.only(right: 38.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatBlock(
                                        count: controller
                                                .userData.value?.totalPosts
                                                .toString() ??
                                            0.toString(),
                                        label: "Posts"),
                                    InkWell(
                                      onTap: () {
                                        Get.to(()=> FollowersFollowingPage(
                                          tabIndex: 1,
                                          userID: controller.userData.value?.user?.id ?? "",
                                        ));
                                      },
                                      child: StatBlock(
                                          count: controller.followerCount.value
                                              .toString(),
                                          label: "Followers"),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Get.to(()=> FollowersFollowingPage(
                                          tabIndex: 0,
                                          userID: controller.userData.value?.user?.id ?? "",
                                        ));
                                      },
                                      child: StatBlock(
                                          count: controller.userData.value
                                                  ?.followingCount
                                                  .toString() ??
                                              0.toString(),
                                          label: "Following"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.getAvailableSocialLinks().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.link,
                          imgColor: AppColors.primaryColor,
                        ),
                        SizedBox(
                          width: SizeConfig.size5,
                        ),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 12,
                            children: [
                              ...controller.getAvailableSocialLinks().map(
                                    (link) => _SocialLink(text: link.name),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: SizeConfig.size12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                            backgroundColor: AppColors.primaryColor,
                          ),
                          onPressed: () async {
                            if (isGuestUser()) {
                              createProfileScreen();
                            } else {
                              if (controller.isFollow.value) {
                                await controller.unFollowUserController(
                                    candidateResumeId: widget.authorId);
                              } else {
                                await controller.followUserController(
                                    candidateResumeId: widget.authorId);
                              }
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  controller.isFollow.value
                                      ? "Unfollow"
                                      : "Follow",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                SizedBox(width: SizeConfig.size8),
                                LocalAssets(
                                    imagePath: AppIconAssets.follow_person),
                              ],
                            ),
                          ),
                        ),
                      ),
                      /*  SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Colors.blue),
                          ),
                          onPressed: () {},
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  "Request Chat",
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                SizedBox(width: SizeConfig.size8),
                                LocalAssets(
                                    imagePath: AppIconAssets.request_chat),
                              ],
                            ),
                          ),
                        ),
                      ),*/
                    ],
                  ),
                  SizedBox(height: SizeConfig.size20),
                  if ((user.bio ?? '').trim().isNotEmpty)
                    ProfileBioWidget(
                      bioText: user.bio,
                    ),
                  HorizontalTabSelector(
                    horizontalMargin: 0,
                    tabs: postTab,
                    selectedIndex: selectedIndex,
                    onTabSelected: (index, value) {
                      setState(() => selectedIndex = index);
                    },
                    labelBuilder: (label) => label,
                  ),

                  if (validIndexes.contains(selectedIndex)) ...[
                    _filterButtons(),
                  ],

                  SizedBox(height: SizeConfig.size16),
                  _buildTabContent(selectedIndex)
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _filterButtons() {
    return SingleChildScrollView(
        padding:
        EdgeInsets.only(top: SizeConfig.size20, bottom: SizeConfig.size10),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Row(
                children: filters?.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      child: CustomText(
                        filter.label,
                        decoration: TextDecoration.underline,
                        color: isSelected ? Colors.blue : Colors.black54,
                        decorationColor:
                        isSelected ? Colors.blue : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList()??[],
              ),
            )
          ],
        ));
  }

  Widget _buildTabContent(int index) {
    switch (postTab[index]) {
      case 'Portfolio':
        return PortfolioWidget(
          isSelfPortfolio: false,
        );

      case 'Posts':
        return FeedScreen(
            key: ValueKey('feedScreen_user_posts_${widget.authorId}'),
            postFilterType: PostType.otherPosts,
            isInParentScroll: true,
            // or whatever enum value you have for user posts
            id: widget.authorId);
      // case 'Achievements':
      // return AchievementsWidget();
      case 'Testimonials':
        return TestimonialsScreen(
          userName: controller.userData.value?.user?.name ?? 'N/A',
          visitUserID: widget.authorId,
          isSelfTestimonial: false,
        );
      case 'Shorts':
        return ShortsChannelSection(
          isOwnShorts: true,
          channelId: '',
          authorId: widget.authorId,
          showShortsInGrid: true,
          sortBy: selectedFilter,
          postVia: PostVia.profile,
        );
      case 'Videos':
        return  VideoChannelSection(
          isOwnVideos: false,
          channelId: '',
          authorId: widget.authorId,
          sortBy: selectedFilter,
          padding: 0.0,
          postVia: PostVia.profile,
        );
      default:
        return const Center(child: CustomText('Coming soon'));
    }
  }
}

class StatBlock extends StatelessWidget {
  final String count;
  final String label;

  const StatBlock({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          count,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,

        ),
        SizedBox(width: SizeConfig.size5,),
        CustomText(
          label,
          color: AppColors.secondaryTextColor,

        ),
      ],
    );
  }
}

class _SocialLink extends StatelessWidget {
  final String text;

  const _SocialLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text,
      fontSize: SizeConfig.small,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w900,
    );
  }
}
