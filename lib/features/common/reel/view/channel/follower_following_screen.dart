import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/controller/follower_controller.dart';
import 'package:BlueEra/features/common/reel/models/follow_following_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
      appBar: CommonBackAppBar(),
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  apiCalling(index);
                },
                labelColor: AppColors.primaryColor,
                labelStyle: const TextStyle(fontSize: 15),
                unselectedLabelColor: Colors.black,
                unselectedLabelStyle: const TextStyle(fontSize: 15),
                indicatorColor: AppColors.primaryColor,
                dividerColor: Colors.blue.shade100,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Following'),
                  Tab(text: 'Followers'),
                ],
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    (followFollowerController.followingList?.isEmpty ?? true)
                        ? const _NotFoundView()
                        : ListView.builder(

                            itemCount:
                                followFollowerController.followingList?.length,
                            itemBuilder: (context, index) {
                              return _buildUserTile(followFollowerController
                                      .followingList?[index] ??
                                  FollowFollowingData());
                            },
                          ),
                    (followFollowerController.followerList?.isEmpty ?? true)
                        ? const _NotFoundView()
                        : ListView.builder(
                            itemCount:
                                followFollowerController.followerList?.length,
                            itemBuilder: (context, index) => _buildUserTile(
                                followFollowerController.followerList?[index] ??
                                    FollowFollowingData()),
                          ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildUserTile(FollowFollowingData user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(user.follower?.profileImage ?? ""),
            backgroundColor: Colors.grey.shade100,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  user.follower?.name ?? "",
                ),
                CustomText(
                  user.follower?.username ?? "",
                  fontSize: SizeConfig.small,
                ),
              ],
            ),
          ),
          _FollowButton(
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowing = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isFollowing = !_isFollowing);
        widget.onPressed();
      },
      child: AnimatedContainer(
        width: 100,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isFollowing ? Colors.white10 : AppColors.primaryColor,
          border: Border.all(
            color: _isFollowing ? AppColors.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: _isFollowing ? AppColors.primaryColor : Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/not_found.png',
            width: SizeConfig.size180,
            fit: BoxFit.fitWidth,
          ),
          SizedBox(height: SizeConfig.size20),
          Text(
            'No Result Found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          SizedBox(height: SizeConfig.size30),
        ],
      ),
    );
  }
}
