import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/store/view/newstore_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/notifications/one_signal_services.dart';
import '../../../chat/auth/controller/chat_theme_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/view/chat_screen.dart';
import '../../map/view/customize_map_screen.dart';
import '../auth/controller/bottom_bar_controller.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final int? initialIndex;
  const BottomNavigationBarScreen({super.key, this.initialIndex = 0});

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
  final moreCardsScreenController = Get.put(MoreCardsScreenController());
  final viewPersonalDetailsController = Get.put(ViewPersonalDetailsController());
  final inventoryController = Get.put(InventoryController());

  // final callController = Get.put(CallController());
  // final groupChatViewController = Get.put(GroupChatViewController());

  @override
  void initState() {
    super.initState();

    _initializeControllers();
    _initializeUserData();
    _initializeSocketConnections();
    _initializeOneSignal();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePostFrameInitialization();
    });
  }

  void _initializeControllers() {
    if (!isGuestUser()) {
      // Get.put(LocationServiceProviderController());
    }

    Get.put(ChatThemeController());
  }

  Future<void> _initializeUserData() async {
    if (isIndividual()) {
      await _initializeIndividualUser();
    } else {
      await _initializeBusinessUser();
    }
  }

  Future<void> _initializeIndividualUser() async {
    // checkServiceExistence();

    if (channelId.isNotEmpty) return;

    final channelModel = await getChannelDetails();
    if (channelModel?.data == null) return;

    final data = channelModel!.data;
    channelId = data.id ?? '';
    channelName = data.name ?? '';
    channelOwner = data.ownership.claimedBy ?? '';

    await Future.wait([
      SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.channel_Id, channelId),
      SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.channelName, channelName),
      SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.channelOwner, channelOwner),
    ]);
  }

  Future<void> _initializeBusinessUser() async {
    await getBusinessUserOwnProduct();
  }

  void _initializeSocketConnections() {
    chatViewController.connectSocket();
    // groupChatViewController.connectSocket();
  }

  void _initializeOneSignal() {
    getOneSignalUpdate();
  }

  void _handlePostFrameInitialization() {
    if (isBusiness()) {
      bottomBarController.currentIndex.value = widget.initialIndex ?? 0;

      final viewProfileController = Get.put(ViewBusinessDetailsController());
      if (viewProfileController.viewBusinessResponse.status != Status.COMPLETE) {
        viewProfileController.viewBusinessProfile();
      }
    }
  }


  // Future<void> checkServiceExistence() async {
  //   viewPersonalDetailsController.isUserServiceExistsKey.value = await getUserServiceExistsKey();
  //   log('userServiceExistsKeyGlobal--> ${viewPersonalDetailsController.isUserServiceExistsKey.value}');
  //   if(viewPersonalDetailsController.isUserServiceExistsKey.value == 'false'){
  //     viewPersonalDetailsController.isUserServiceExistsKey.value = await viewPersonalDetailsController.getUserServiceExistenceStatus();
  //     await SharedPreferenceUtils.setSecureValue(
  //         SharedPreferenceUtils.userServiceExistsKey,
  //         viewPersonalDetailsController.isUserServiceExistsKey.value
  //     );
  //   } else{
  //     checkAndShowGreetingDialog(context);
  //   }
  // }
  //
  // void checkAndShowGreetingDialog(BuildContext context) async {
  //   try {
  //     await moreCardsScreenController.getCardCategoriesSortedByDate(
  //         todayDate: DateTime.now().toIso8601String()
  //     );
  //   } catch (e) {
  //     print("API error: $e");
  //   }
  //
  //   // final result = await canCallCardApi();
  //   // // final canCall = result.canCall;
  //   // final canCall = true;
  //   // final today = result.today;
  //   //
  //   // if (canCall) {
  //   //   try {
  //   //     await moreCardsScreenController.getCardCategoriesSortedByDate(
  //   //         todayDate: today
  //   //     );
  //   //
  //   //     await saveApiCallDate();
  //   //   } catch (e) {
  //   //     print("API error: $e");
  //   //   }
  //   // }
  //
  // }

  Future<void> getBusinessUserOwnProduct() async {
    await inventoryController.fetchProducts();
    // if(inventoryController.allProducts.isEmpty){
    //   checkAndShowGreetingDialog(context);
    // }
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      body: ValueListenableBuilder(
          valueListenable: bottomBarVisibleNotifier,
          builder: (context, isVisible, _) {
            return Stack(
              children: [
                // Your dynamic screen based on index
                Obx(() {
                  return Positioned.fill(
                    child: _getScreen(
                        bottomBarController.currentIndex.value, isVisible),
                  );
                }),

                // Bottom Nav Animation using ValueListenableBuilder
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
      case 1:
        // return StoreScreen(
        //   isHeaderVisible: isVisible,
        //   onHeaderVisibilityChanged: _toggleAppBar,
        // );
        return StoreFeedScreen(
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
