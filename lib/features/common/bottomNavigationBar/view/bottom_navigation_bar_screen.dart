import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/home/view/home_feed_screen.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/store/view/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/notifications/one_signal_services.dart';
import '../../../chat/auth/controller/chat_theme_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/auth/controller/group_chat_view_controller.dart';
import '../../../chat/view/chat_screen.dart';
import '../../map/view/customize_map_screen.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int chatNotificationCount = 0, currentIndex = 0;
  final ValueNotifier<bool> bottomBarVisibleNotifier = ValueNotifier(true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final chatViewController = Get.put(ChatViewController());
  final groupChatViewController = Get.put(GroupChatViewController());

  @override
  void initState() {
    super.initState();


    if (channelId.isEmpty) {
      getChannelDetails().then((value) => channelId = value ?? '');
    }
    chatViewController.connectSocket();
    groupChatViewController.connectSocket();
    Get.put(ChatThemeController());
    getOneSignalUpdate();
  }


  ///GET CHANNEL DETAILS...
  Future<String?> getChannelDetails() async {
    try {
      ResponseModel response =
          await ChannelRepo().getChannelDetails(channelOrUserId: userId);

      if (response.statusCode == 200) {
        ChannelModel channelModel =
            ChannelModel.fromJson(response.response?.data);
        String channelId = channelModel.data.id;
        SharedPreferenceUtils.setSecureValue(
            SharedPreferenceUtils.channel_Id, channelId);
        return channelId;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // drawer: _buildProfileDrawer(),
      body: ValueListenableBuilder(
          valueListenable: bottomBarVisibleNotifier,
          builder: (context, isVisible, _) {
            return Stack(
              children: [
                // 👇 Your dynamic screen based on index
                Positioned.fill(
                  child: _getScreen(currentIndex, isVisible),
                ),

                // 👇 Bottom Nav Animation using ValueListenableBuilder
                Positioned(
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
                      currentIndex: currentIndex,
                      onTap: (index) {
                        setState(() => currentIndex = index);
                      },
                      chatNotificationCount: chatNotificationCount,
                    ),
                  ),
                ),
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
