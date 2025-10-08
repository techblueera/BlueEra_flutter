
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/store/view/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/notifications/one_signal_services.dart';
import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/controller/chat_theme_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/controller/group_chat_view_controller.dart';
import '../../../chat/view/chat_screen.dart';
import '../../map/view/customize_map_screen.dart';
import '../auth/controller/bottom_bar_controller.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int chatNotificationCount = 0;
  final ValueNotifier<bool> bottomBarVisibleNotifier = ValueNotifier(true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final chatViewController = Get.put(ChatViewController());
  final bottomBarController = Get.put(BottomBarController());
  // final callController = Get.put(CallController());
  final groupChatViewController = Get.put(GroupChatViewController());

  @override
  void initState() {
    super.initState();

    if (channelId.isEmpty) {
      getChannelDetails().then((channelModel) {
        channelId = channelModel?.data.id??'';
        channelName = channelModel?.data.name??'';
        channelOwner = channelModel?.data.ownership.claimedBy??'';
        SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.channel_Id, channelId
        );
        SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.channelName, channelName
        );
        SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.channelOwner, channelOwner
        );
     });
    }
    chatViewController.connectSocket();
    // groupChatViewController.connectSocket();
    Get.put(ChatThemeController());
    getOneSignalUpdate();
  }

  ///GET CHANNEL DETAILS...
  Future<ChannelModel?> getChannelDetails() async {
    try {
      ResponseModel response =
          await ChannelRepo().getChannelDetails(channelOrUserId: userId);

      if (response.statusCode == 200) {

        return ChannelModel.fromJson(response.response?.data);

      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> getOneSignalUpdate() async {
    OnesignalService().onNotifiacation();
    OnesignalService().onNotificationClick();
    await Future.delayed(Duration(seconds: 1));
    await OnesignalService().checkOneSignalStatus();
  }

  @override
  void dispose() {
    bottomBarVisibleNotifier.dispose(); // 🧼 Clean up

    chatViewController.disposeSocket();
    super.dispose();
  }
  final List<Map<String, dynamic>> posts = [
    {
      "_id": "68e0fb4c5c2a9786da8f7efb",
      "type": "image_post",
      "createdAt": "2025-10-04T10:47:40.000Z",
      "reference_link": "",
      "repost_count": 0,
      "text": "",
      "media": [
        "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/media/1759574860128-compressed_1759574813024.jpg"
      ],
      "title": "",
      "sub_title": "Jumbo",
      "nature_of_post": "",
      "location": "",
      "tagged_users": [],
      "likes_count": 0,
      "comments_count": 0,
      "shares_count": 0,
      "views_count": 0,
      "song": null,
      "user": {
        "_id": "68dc954bcc805d4e15cbb117",
        "name": "Aditya Sharma",
        "username": "guest0781395e",
        "profile_image":
        "https://be-user-bck.s3.ap-south-1.amazonaws.com/user/68dc954bcc805d4e15cbb117/profile/1759286927400-cropped_image_01759286728921.png",
        "verified": "false",
        "account_type": "INDIVIDUAL",
        "designation": null,
        "location": null,
        "business_id": "null",
        "business_name": "null",
        "categoryOfBusiness": "null",
        "is_following": false
      },
      "isLiked": false,
      "tagged_users_details": []
    },
    {
      "_id": "68e0ea265c2a9786da8f7c12",
      "type": "image_post",
      "createdAt": "2025-10-04T09:34:30.000Z",
      "reference_link": "",
      "repost_count": 0,
      "text": "",
      "media": [
        "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/media/1759570470205-filtered_1759570411184_0.png"
      ],
      "title": "",
      "sub_title":
      "Huawei Watch D2 हुई भारत में लॉन्च – ECG, ब्लड प्रेशर मॉनिटर और 80+ स्पोर्ट्स मोड्स के साथ जबरदस्त हेल्थ स्मार्टवॉच www.websoftworld.in",
      "nature_of_post": "",
      "location": "",
      "tagged_users": [],
      "likes_count": 0,
      "comments_count": 0,
      "shares_count": 0,
      "views_count": 4,
      "song": {
        "id": "68c3ac4010a647e3d9744a1c",
        "name": "songs hindi",
        "artist": "renuka",
        "cover_url": "https://example.com/external_cover.jpg"
      },
      "user": {
        "_id": "68c8589cd4a6b6641d0913e3",
        "name": "Apoorva Mishra",
        "username": "apoorvam8124z",
        "profile_image":
        "https://be-user-bck.s3.ap-south-1.amazonaws.com/user/68c8589cd4a6b6641d0913e3/profile/1759162144596-cropped_image_01759162144256.png",
        "verified": "false",
        "account_type": "INDIVIDUAL",
        "designation": null,
        "location": null,
        "business_id": "null",
        "business_name": "null",
        "categoryOfBusiness": "null",
        "is_following": false
      },
      "isLiked": false,
      "tagged_users_details": []
    },
    {
      "_id": "68e0ce63ac8fb97331972dba",
      "type": "image_post",
      "createdAt": "2025-10-04T07:36:03.000Z",
      "reference_link": "",
      "repost_count": 0,
      "text": "",
      "media": [
        "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/media/1759563363454-filtered_1759563333879_0.png"
      ],
      "title": "",
      "sub_title": "",
      "nature_of_post": "",
      "location": "",
      "tagged_users": [],
      "likes_count": 0,
      "comments_count": 0,
      "shares_count": 0,
      "views_count": 4,
      "song": null,
      "user": {
        "_id": "68a00e5670d4fe4f10076d92",
        "name": "SUMIT PANDEY ",
        "username": "sumitpan4762o",
        "profile_image":
        "https://be-user-bck.s3.ap-south-1.amazonaws.com/user/68a00e5670d4fe4f10076d92/profile/1758341154682-cropped_image_01758341154090.png",
        "verified": "false",
        "account_type": "INDIVIDUAL",
        "designation": null,
        "location": null,
        "business_id": "null",
        "business_name": "null",
        "categoryOfBusiness": "null",
        "is_following": false
      },
      "isLiked": false,
      "tagged_users_details": []
    },
    {
      "_id": "68e0ce4eac8fb97331972da7",
      "type": "image_post",
      "createdAt": "2025-10-04T07:35:42.000Z",
      "reference_link": "",
      "repost_count": 0,
      "text": "",
      "media": [
        "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/media/1759563342542-filtered_1759563316639_0.png",
        "https://be-post-service-bck.s3.ap-south-1.amazonaws.com/media/1759563342542-filtered_1759563316639_0.png"
      ],
      "title": "",
      "sub_title": "",
      "nature_of_post": "",
      "location": "",
      "tagged_users": [],
      "likes_count": 0,
      "comments_count": 0,
      "shares_count": 0,
      "views_count": 4,
      "song": null,
      "user": {
        "_id": "68d7ac963330d1e652bb9b21",
        "name": "Himanshu Kumar ",
        "username": "himanshu5507i",
        "profile_image":
        "https://be-user-bck.s3.ap-south-1.amazonaws.com/user/68d7ac963330d1e652bb9b21/profile/1758965395985-cropped_image_01758965312495.png",
        "verified": "false",
        "account_type": "INDIVIDUAL",
        "designation": "OTHER",
        "location": null,
        "business_id": "null",
        "business_name": "null",
        "categoryOfBusiness": "null",
        "is_following": false
      },
      "isLiked": false,
      "tagged_users_details": []
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Post.fromJson(posts);
      //     // Get.to(StatusViewer(posts: posts,));
      //   },
      // ),
      // drawer: _buildProfileDrawer(),
      body: ValueListenableBuilder(
          valueListenable: bottomBarVisibleNotifier,
          builder: (context, isVisible, _) {
            return Stack(
              children: [
                // 👇 Your dynamic screen based on index
                Obx(() {
                  return Positioned.fill(
                    child: _getScreen(
                        bottomBarController.currentIndex.value, isVisible),
                  );
                }),

                // 👇 Bottom Nav Animation using ValueListenableBuilder
                Obx(() {
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSlide(
                      offset: isVisible ? Offset.zero : const Offset(0, 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: BottomNavigationBarWidget(
                        onHeaderVisibilityChanged: _toggleAppBar,
                        isBottomNavVisible: isVisible,
                        currentIndex: bottomBarController.currentIndex.value,
                        onTap: (index) {
                          bottomBarController.onChangeIndex(index);
                        },
                        chatNotificationCount: chatNotificationCount,
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
    );
  }

  Widget _getScreen(int index, bool isVisible) {
    switch (index) {
      case 0:
        return HomeScreen(
          isHeaderVisible: isVisible,
          onHeaderVisibilityChanged: _toggleAppBar,
        );
      // return HomeFeedScreen();
      // return HomeFeedScreen();

      case 1:
        return StoreScreen(
          isHeaderVisible: isVisible,
          onHeaderVisibilityChanged: _toggleAppBar,
        );
      case 2:
        return CustomizeMapScreen();
      case 3:
        return isGuestUser()
            ? GuestDashBoardScreen()
            : JobsScreen(
                isHeaderVisible: isVisible,
                onHeaderVisibilityChanged: _toggleAppBar);
      case 4:
      default:
        return isGuestUser() ? GuestDashBoardScreen() : ChatMainScreen();
    }
  }

  void _toggleAppBar(bool visible) {
    // Only update when different to avoid unnecessary rebuilds
    if (bottomBarVisibleNotifier.value != visible) {
      bottomBarVisibleNotifier.value = visible;
    }
  }
}
