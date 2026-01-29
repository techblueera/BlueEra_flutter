import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/reel/controller/follower_controller.dart';
import 'package:BlueEra/features/common/reel/models/follow_following_res_model.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FollowersFollowingPage extends StatefulWidget {
  const FollowersFollowingPage(
      {super.key, required this.tabIndex, required this.userID});

  final int tabIndex;
  final String userID;

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final followFollowerController = Get.put(FollowerController());

  @override
  void initState() {
    super.initState();
    apiCalling(widget.tabIndex);

    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.tabIndex);
  }

  apiCalling(int index) {
    if (index == 0) {
      followFollowerController.getFollowingController(userID: widget.userID);
    }
    if (index == 1) {
      followFollowerController.getFollowerController(userID: widget.userID);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
          isFollowRefresh: true,
          isFollowRefreshWidget: () {
            return Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: IconButton(
                  onPressed: () {
                    apiCalling(followFollowerController.selectedIndex.value);
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                  )),
            );
          }),
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  followFollowerController.selectedIndex.value = index;
                  apiCalling(index);
                },
                labelColor: AppColors.primaryColor,
                labelStyle: const TextStyle(fontSize: 15),
                unselectedLabelColor: Colors.black,
                unselectedLabelStyle: const TextStyle(fontSize: 15),
                indicatorColor: AppColors.primaryColor,
                dividerColor: Colors.blue.shade100,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: AppStrings.following.tr),
                  Tab(text: AppStrings.followers.tr),
                ],
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    followFollowerController.isFollowingLoading.isFalse
                        ? (followFollowerController
                                        .followingResponse.value.status ==
                                    Status.COMPLETE &&
                                (followFollowerController
                                    .followingList.isNotEmpty))
                            ? RefreshIndicator(
                                onRefresh: () async {
                                  apiCalling(0);
                                },
                                child: ListView.builder(
                                  itemCount: followFollowerController
                                      .followingList.length,
                                  itemBuilder: (context, index) {
                                    FollowingData singleFollowingDta =
                                        followFollowerController
                                            .followingList[index];
                                    return _buildUserTile(
                                        singleFollowingDta.following,
                                        "FOLLOWING");
                                  },
                                ),
                              )
                            : EmptyStateWidget(
                                message: AppStrings.noFollow,
                                imageSize: SizeConfig.size120,
                              )
                        : Center(child: CircularProgressIndicator()),
                    followFollowerController.isFollowerLoading.isFalse
                        ? (followFollowerController
                                        .followerResponse.value.status ==
                                    Status.COMPLETE &&
                                (followFollowerController
                                    .followerList.isNotEmpty))
                            ? RefreshIndicator(
                                onRefresh: () async {
                                  apiCalling(1);
                                },
                                child: ListView.builder(
                                  itemCount: followFollowerController
                                      .followerList.length,
                                  itemBuilder: (context, index) =>
                                      _buildUserTile(
                                          followFollowerController
                                              .followerList[index].follower,
                                          "FOLLOWER"),
                                ),
                              )
                            : EmptyStateWidget(
                                message: AppStrings.noFollow,
                                imageSize: SizeConfig.size120,
                              )
                        : Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildUserTile(FollowingFollower? user, String? viewTag) {
    return InkWell(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user?.accountType?.toUpperCase() == AppConstants.business) {
            Get.off(() => VisitBusinessProfileNew(
                  businessId: user?.id ?? "",
                  screenName: AppConstants.feedScreen,
                ));
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewVisitProfileScreen(
                  authorId: user?.id ?? '',
                  screenFromName: AppConstants.feedScreen,
                ),
              ),
            );
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(
                  user?.accountType?.toUpperCase() == AppConstants.business
                      ? user?.business_logo ?? ""
                      : user?.profileImage ?? ""),
              backgroundColor: Colors.grey.shade100,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    user?.accountType?.toUpperCase() == AppConstants.business
                        ? user?.business_name
                        : user?.name ?? "",
                  ),
                  CustomText(
                    user?.username ?? "",
                    fontSize: SizeConfig.small,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (isGuestUser()) {
                  createProfileScreen();

                  return;
                }
                if (isValidation(user)) {
                  final controllerVisit = Get.put(VisitProfileController());

                  await controllerVisit.unFollowUserController(
                      candidateResumeId: user?.id);
                  apiCalling(viewTag == "FOLLOWER" ? 1 : 0);
                  // final chatViewController = Get.find<ChatViewController>();
                  // Map<String, dynamic> detas = {ApiKeys.user_id: user?.id};
                  // chatViewController.newVisitContactApiResponse?.value;
                  // await chatViewController.checkChatConnection(detas);
                  //
                  // chatViewController.openAnyOneChatFunction(
                  //   profileImage: user?.accountType?.toUpperCase() ==
                  //           AppConstants.business
                  //       ? user?.business_logo
                  //       : user?.profileImage,
                  //   otherUserId: (chatViewController.newVisitContactApiResponse
                  //                   ?.value?.data?.conversationId ??
                  //               '') ==
                  //           ""
                  //       ? chatViewController.newVisitContactApiResponse?.value
                  //               ?.data?.otherUserId ??
                  //           ''
                  //       : null,
                  //   type: user?.accountType?.toLowerCase(),
                  //   isInitialMessage: (chatViewController
                  //                   .newVisitContactApiResponse
                  //                   ?.value
                  //                   ?.data
                  //                   ?.conversationId ??
                  //               '') ==
                  //           ""
                  //       ? true
                  //       : false,
                  //   userId: user?.id,
                  //   conversationId: (chatViewController
                  //           .newVisitContactApiResponse
                  //           ?.value
                  //           ?.data
                  //           ?.conversationId ??
                  //       ''),
                  //   contactName: user?.accountType?.toUpperCase() ==
                  //           AppConstants.business
                  //       ? user?.business_name
                  //       : user?.name,
                  //   contactNo: "",
                  // );
                } else {
                  final controllerVisit = Get.put(VisitProfileController());

                  await controllerVisit.followUserController(
                      candidateResumeId: user?.id);
                  apiCalling(viewTag == "FOLLOWER" ? 1 : 0);


                }
                // setState(() => _isFollowing = !_isFollowing);
                // widget.onPressed();
              },
              child: AnimatedContainer(
                width: 100,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: !isValidation(user)
                      ? AppColors.primaryColor
                      : AppColors.white,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
                child: CustomText(
                  isValidation(user) ? "Unfollow" : AppStrings.follow,
                  color: !isValidation(user)
                      ? AppColors.white
                      : AppColors.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isValidation(FollowingFollower? user) {
    return ((user?.isFollowing ?? false) ||
        (user?.accountType?.toUpperCase() == AppConstants.business));
  }
}
