import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_join_list_model.dart';
import 'package:BlueEra/features/common/reel/models/follow_following_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelJoinedUserScreen extends StatefulWidget {
  const ChannelJoinedUserScreen({super.key, required this.userID});

  final String userID;

  @override
  State<ChannelJoinedUserScreen> createState() =>
      _ChannelJoinedUserScreenState();
}

class _ChannelJoinedUserScreenState extends State<ChannelJoinedUserScreen>
    with SingleTickerProviderStateMixin {
  final channelFeedController = Get.find<ChannelFeedController>();

  @override
  void initState() {
    super.initState();
    apiCalling();
  }

  apiCalling() {
    channelFeedController.getChannelMembersController(userID: widget.userID);
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
                    apiCalling();
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                  )),
            );
          }),
      body: SafeArea(
        child: Obx(() {
          return  (channelFeedController.followerResponse.value.status ==
              Status.COMPLETE &&
              (channelFeedController.channelDataList.isNotEmpty))
              ? RefreshIndicator(
            onRefresh: () async {
              apiCalling();
            },
            child: ListView.builder(
              itemCount: channelFeedController.channelDataList.length,
              itemBuilder: (context, index) =>
                  _buildUserTile(
                      channelFeedController
                          .userChannelList[index],
                      "FOLLOWER"),
            ),
          )
              : EmptyStateWidget(
            message: 'No followers',
            imageSize: SizeConfig.size120,
          );
        }),
      ),
    );
  }

  Widget _buildUserTile(UserChannelData? user, String? viewTag) {
    return InkWell(
      onTap: () {
        // if (user?.accountType?.toUpperCase() == AppConstants.business) {
        //   Get.to(() =>
        //       VisitBusinessProfileNew(
        //         businessId: user?.id ?? "",
        //         screenName: AppConstants.feedScreen,
        //       ));
        // }
        // if (user?.accountType?.toUpperCase() == AppConstants.individual) {
        //   Get.to(() =>
        //       NewVisitProfileScreen(
        //         authorId: user?.id ?? '',
        //         screenFromName: AppConstants.feedScreen,
        //       ));
        // }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(
                  user?.profileImage ?? ""),
              backgroundColor: Colors.grey.shade100,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    user?.accountType?.toUpperCase() == AppConstants.business
                        ? user?.businessName
                        : user?.name ?? "",
                  ),
                  CustomText(
                    user?.username ?? "",
                    fontSize: SizeConfig.small,
                  ),
                ],
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
