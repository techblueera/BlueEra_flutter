import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/ask_inventory_chat_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/auth/controller/ai_chat_guest_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/food/view/grocery/my_grocery_listing/grocery_screen.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/store/view/new_store/new_store_screen2.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_main.dart';
import 'package:BlueEra/features/me/school/view/school_main.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/rider_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/inventory_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/service_provider_dialoge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/routes/route_helper.dart';
import '../../../chat/auth/controller/chat_theme_controller.dart';
import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/view/chat_screen_new.dart';
import '../../../me/hospital/view/hospital_main.dart';
import '../../../me/medical/view/medical_main.dart';
import '../../delivery_partner/controller/delivery_partner_orders_controller.dart';
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
  final chatViewController = Get.isRegistered<ChatViewController>()
      ? Get.find<ChatViewController>()
      : Get.put(ChatViewController());
  final bottomBarController = Get.put(BottomBarController());
  final moreCardsScreenController = Get.put(MoreCardsScreenController());
  final viewPersonalDetailsController =
      Get.put(ViewPersonalDetailsController());
  final inventoryController = Get.put(InventoryController());
  final orderController = Get.isRegistered<DeliverPartnerOrdersController>()
      ? Get.find<DeliverPartnerOrdersController>()
      : Get.put(DeliverPartnerOrdersController());
  final dialogService = Get.put(DialogService());

  void handleRejectOrder(String orderId) {
    orderController.updateOrderStatusFromPialot(
      {ApiKeys.action: "reject"},
      orderId,
    );
  }

  void handleAcceptOrder(String orderId) {
    orderController.updateOrderStatusFromPialot(
      {ApiKeys.action: "accept"},
      orderId,
    );
  }

  @override
  void initState() {
    super.initState();
    if (isGuestUser()) {
      logs("DIALOGE CALL");
      _checkAndShowDialog();
    }
    _checkAndFetchLocationData();
    _getAllBusinessCategories();
    _initializeControllers();
    _initializeUserData();
    _initializeSocketConnections();
    checkByRiderCall();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePostFrameInitialization();
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
        if (event?.event == Event.actionCallAccept) {
          // Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
          Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
          FlutterCallkitIncoming.endAllCalls();
        } else if (event?.event == Event.actionCallDecline) {
          commonSnackBar(message: "Your Order Rejected by You");
          Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
          // Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
          FlutterCallkitIncoming.endAllCalls();
        }
      });
    });
  }

  Future<void> checkByRiderCall() async {
    String? orderId = await getCurrentCall();
    if (orderId != null) {
      // Get.toNamed(RouteHelper.getEarnWithBlueEraNewScreenRoute());
      Get.toNamed(RouteHelper.getRiderServiceScreenRoute());
      FlutterCallkitIncoming.endAllCalls();
    }
  }

  Future<String?> getCurrentCall() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        bool accepted = calls[0]['accepted'];

        if (accepted) {
          return calls[0]['extra']['orderId'].toString();
        } else {
          return 'rejected';
        }
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> _checkAndFetchLocationData() async {
    await LocationService.fetchLocation();
  }

  void _getAllBusinessCategories() {
    bottomBarController.getAllCategories();
  }

  void _initializeControllers() {
    if (!isGuestUser()) {
      // Get.put(LocationServiceProviderController());
    }

    Get.put(ChatThemeController());
  }

  Future<void> _initializeUserData() async {
    AppNotificationHandler().getInitialMsg();
    AppNotificationHandler().onMsgOpen();
    if (isIndividual()) {
      await _initializeIndividualUser();
    } else {
      await _initializeBusinessUser();
    }
  }

  Future<void> _initializeIndividualUser() async {
    viewPersonalDetailsController.getEarnServiceStatus();
    await Future.delayed(Duration(seconds: 2));
    showEnableServiceDialog();

    if (channelId.isNotEmpty) return;

    final channelModel = await getChannelDetails();
    if (channelModel?.data == null) return;

    final data = channelModel!.data;
    channelId = data.id;
    channelName = data.name;
    channelOwner = data.username;
    // channelOwner = data.ownership.claimedBy;

    await Future.wait([
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channel_Id, channelId),
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channelName, channelName),
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channelOwner, channelOwner),
    ]);
  }

  Future<void> _initializeBusinessUser() async {
    // await getBusinessUserOwnProduct();
  }

  void _initializeSocketConnections() {
    chatViewController.connectSocket();
    // groupChatViewController.connectSocket();
  }

  // void _initializeOneSignal() {
  //   getOneSignalUpdate();
  // }

  void _handlePostFrameInitialization() {
    if (isBusiness()) {
      bottomBarController.currentIndex.value = widget.initialIndex ?? 0;

      final viewProfileController = Get.put(ViewBusinessDetailsController());
      if (viewProfileController.viewBusinessResponse.status !=
          Status.COMPLETE) {
        viewProfileController.viewBusinessProfile();
      }
    } else {
      if (viewPersonalDetailsController.viewPersonalResponse.value.status !=
          Status.COMPLETE) {
        viewPersonalDetailsController.viewPersonalProfile();
      }
    }
  }

  ///GET BUSINESS PRODUCTS...
  Future<void> getBusinessUserOwnProduct() async {
    await inventoryController.fetchProducts();
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
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //   // Get.to(ItemsScreen());
      //   Get.to(HotelMain());
      //   // Get.to(SchoolMain());
      //   // Get.to(RiderProfileStatusScreen());
      // }),
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
                        onTap: (index) async {
                          /// for store need location permission
                          if (index == 1 || index == 2) {
                            if (LocationService.lat == 0.0 ||
                                LocationService.lng == 0.0) {
                              await LocationService.askLocationPermission();
                            } else {
                              bottomBarController.onChangeIndex(index);
                            }
                          }

                          /// for chat need notification permission
                          else if (index == 3) {
                            await AppNotificationHandler()
                                .checkNotificationPermission();
                            if (await Permission.notification.isGranted) {
                              bottomBarController.onChangeIndex(index);
                            }
                          } else {
                            bottomBarController.onChangeIndex(index);

                            // Stay on the same screen until permission is granted
                          }
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
        // return StoreFeedScreen(
        //   isHeaderVisible: isVisible,
        //   onHeaderVisibilityChanged: _toggleAppBar,
        // );
        // return NewStoreScreen2(
        //   isHeaderVisible: isVisible,
        //   onHeaderVisibilityChanged: _toggleAppBar,
        // );
        return DiscoverScreen(
          isHeaderVisible: isVisible,
          onHeaderVisibilityChanged: _toggleAppBar,
        );
      case 2:
        return getHomeScreen();

      case 3:
      default:
        return isGuestUser()
            ? GuestDashBoardScreen()
            : NewChatMainScreen(
                onHeaderVisibilityChanged: _toggleAppBar,
              );
    }
  }

  void _toggleAppBar(bool visible) {
    // Only update when different to avoid unnecessary rebuilds
    if (bottomBarVisibleNotifier.value != visible) {
      bottomBarVisibleNotifier.value = visible;
    }
  }

  Widget getHomeScreen() {
    if (isGuestUser()) return GuestDashBoardScreen();
    if (isBusinessUser()) return resolveBusinessScreen();
    if (isIndividualUser()) return resolveIndividualScreen();

    // Fallback (required)
    return PersonalProfileSetupNewScreen();
    return HospitalMain();
  }

  Widget resolveBusinessScreen() {
    log('Resolving Screen... Type: $businessTypeGlobal | Category: $businessCategoryGlobal');

    // 1. First, check if it is a Food business
    if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Food.name.toUpperCase()) {
      log('goes into this');
      // 2. If it is Food, check the specific category
      if (businessCategoryGlobal == AppConstants.groceryVegetablesDairy) {
        return const GroceryScreen(fromBottomNavBar: true);
      } else {
        return const InventoryScreen(fromBottomNavBar: true);
      }
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Service.name.toUpperCase()) {
      if (businessCategoryGlobal == AppConstants.educationTraining) {
        return const SchoolMain();
      }else if (businessCategoryGlobal == AppConstants.hostelsStayService) {
        return const HotelMain();
      } else {
        return const InventoryScreen(fromBottomNavBar: true);
      }
    } else {
      // 3. If it is NOT Food (e.g., Product, Service, etc.)
      return const InventoryScreen(fromBottomNavBar: true);
    }
  }

  Widget resolveIndividualScreen() {
    logs("userProfessionGlobal==== ${userProfessionGlobal}");
    logs("userWorkTypeGlobal==== ${userWorkTypeGlobal}");
    return (userProfessionGlobal == SELF_EMPLOYED)
        ? (userWorkTypeGlobal == DELIVERY_RIDER)
            ? RiderServiceScreen(fromBottomNavBar: true)
            : EarnServiceScreen(fromBottomNavBar: true)
        : PersonalProfileSetupNewScreen();
  }

  void _checkAndShowDialog() async {
    if (await dialogService.shouldShowDialog()) {
      Future.delayed(Duration(seconds: 5), () async {
        await showCommonDialog(
            context: context,
            header: "Sarthi AI",
            text: "Start Chat with Sarthi",
            confirmCallback: () async {
              Navigator.of(context).pop();
            },
            cancelCallback: () {
              Navigator.of(context).pop();

              final chat = ChatViewController.inventoryAiChatListSearchModule;

              Get.to(() => AskInventoryChatScreen(
                    profileImage: chat?.sender?.profileImage,
                    name: chat?.sender?.name,
                    contactNo: chat?.sender?.contactNo,
                    conversationId: '',
                    userId: '',
                    businessId: '',
                    type: chat?.sender?.accountType,
                    isInitialMessage: false,
                  ));
              // Close the dialog
            },
            confirmText: AppStrings.cancel,
            cancelText: AppStrings.chatNow);
        dialogService.saveDialogShown();
      });
    }
  }
}
