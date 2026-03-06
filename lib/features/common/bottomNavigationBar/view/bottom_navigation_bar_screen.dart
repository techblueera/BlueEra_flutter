import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ask_chat_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/ai_chat_guest_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/home/view/home_screen.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/food/view/food_main_screen.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/grocery_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_main.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_main.dart';
import 'package:BlueEra/features/me/laboratory/view/laboratory_main.dart';
import 'package:BlueEra/features/me/medical_new/view/my_medical_listing/medical_screen.dart';
import 'package:BlueEra/features/me/others/others_main.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_main.dart';
import 'package:BlueEra/features/me/school/view/school_main.dart';
import 'package:BlueEra/features/me/social/view/social_main.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/emergency/view/emergency_basic_info_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_available_options_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/product/inventory_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_new_screen.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/service_provider_dialoge.dart';
import 'package:flutter/foundation.dart';
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
import '../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../delivery_partner/controller/pip_floating_page_controller.dart';
import 'package:share_handler/share_handler.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  final int? initialIndex;
  final SharedMedia? sharedMedia;

  const BottomNavigationBarScreen({super.key, this.initialIndex = 0, this.sharedMedia});

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int chatNotificationCount = 0;
  final ValueNotifier<bool> bottomBarVisibleNotifier = ValueNotifier(true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bottomBarController = Get.put(BottomBarController());
  final chatViewController = getOrPut(() => ChatViewController());
  final moreCardsScreenController = Get.put(MoreCardsScreenController());
  final viewPersonalDetailsController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final inventoryController = Get.put(InventoryController());
  final orderController = getOrPut(() => DeliverPartnerOrdersController());
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
    if (Platform.isAndroid) {
      final pipController = getOrPut(() => PipFloatingPageController());
      pipController.setPipStatus(false);
    }
    if (isGuestUser()) {
      logs("DIALOGE CALL");
      _checkAndShowDialog();
    }
    _checkAndFetchLocationData();
    // _getAllBusinessCategories();
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
    // _fetchAllAdminVideos();
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

  // void _getAllBusinessCategories() {
  //   bottomBarController.getAllCategories();
  // }

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
    // viewPersonalDetailsController.getEarnServiceStatus();
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
    chatViewController.connectSocket().then((_) {
      _handleSharedMedia();
    });
    // groupChatViewController.connectSocket();
  }

  void _handleSharedMedia() {
    final media = widget.sharedMedia;
    if (media == null || !mounted) return;

    final sharedText = media.content;
    final attachments = media.attachments ?? [];

    if (sharedText != null && sharedText.isNotEmpty) {
      Get.to(() => ChatForwardScreen(sharedText: sharedText));
    } else if (attachments.isNotEmpty) {
      Get.to(() => ChatForwardScreen(sharedFiles: attachments));
    }
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
      if (userDesignationGlobal == DELIVERY_RIDER) {
        bottomBarController.currentIndex.value = 2;
      } else {
        bottomBarController.currentIndex.value = widget.initialIndex ?? 0;
      }
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
  /*    floatingActionButton: kDebugMode
          ? FloatingActionButton(onPressed: () async {
              Get.to(EmergencyBasicInfoScreen());
            })
          : null,*/
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
                      duration: const Duration(milliseconds: 300),
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
        return DiscoverScreen(
          isHeaderVisible: isVisible,
          onHeaderVisibilityChanged: _toggleAppBar,
        );
      case 2:
        return meScreens();

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

  Widget meScreens() {
    if (isGuestUser()) return GuestDashBoardScreen();
    if (isBusinessUser()) return resolveBusinessScreen();
    if (isIndividualUser()) return resolveIndividualScreen();

    // Fallback (required)
    return PersonalProfileSetupNewScreen();
  }

  Widget resolveBusinessScreen() {
    log('Resolving Screen... Type: ${businessTypeGlobal.toUpperCase()}');
    log('Resolving Screen. businessCategoryGlobal .. Type: ${businessCategoryGlobal.toUpperCase()}');

    // 1. First, check if it is a Food business
    if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Food.name.toUpperCase()) {
      return const FoodMainScreen();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Grocery.name.toUpperCase()) {
      return const GroceryScreen(fromBottomNavBar: true);
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Siksha.name.toUpperCase()) {
      return const SchoolMain();
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Healthcare.name.toUpperCase()) {
      if ((businessCategoryGlobal.toUpperCase() ==
              AppConstants.HOSPITALS.toUpperCase()) ||
          (businessCategoryGlobal.toUpperCase() ==
              AppConstants.wellness.toUpperCase()) ||
          (businessCategoryGlobal.toUpperCase() ==
              AppConstants.clinic.toUpperCase())) {
        return const HospitalMain();
      } else if (businessCategoryGlobal.toUpperCase() ==
          AppConstants.DIAGNOSTIC_TESTING_CENTERS) {
        return const LaboratoryMain();
      } else if (businessCategoryGlobal.toUpperCase() ==
          AppConstants.SUPPORT_SERVICES) {
        return const OthersMain();
      }
      // else if(businessCategoryGlobal.toUpperCase() ==
      //     AppConstants.MEDICAL_EDUCATION_INSTITUTIONS.toUpperCase()){
      //   return const MedicalScreen(fromBottomNavBar: true);
      // }

      return const MedicalScreen(fromBottomNavBar: true);
    } else if (businessTypeGlobal.toUpperCase() ==
        BusinessType.Motel.name.toUpperCase()) {
      return const HotelMain();
    }
    // else if (businessTypeGlobal.toUpperCase() ==
    //     BusinessType.Healthcare.name.toUpperCase()) {
    //   return MedicalMain();
    // }
    else if (_isServiceOrSpecificAutomotive()) {
      return const OthersMain();
    } else if (checkInventoryEligibility(
        businessTypeGlobal, businessCategoryGlobal)) {
      return const InventoryScreen(fromBottomNavBar: true);
    } else {
      /// right now showing inventory (will remove this)
      return const InventoryScreen(fromBottomNavBar: true);
    }
  }

  bool _isServiceOrSpecificAutomotive() {
    final type = businessTypeGlobal.toUpperCase();
    final category = businessCategoryGlobal.toUpperCase();

    // 1. Check if it's a Service type
    if (type == BusinessType.Service.name.toUpperCase()) return true;

    // 2. Define the Automotive sectors that count as "Others"
    final automotiveOthersSectors = {
      AppConstants.RENTAL_SECTOR.toUpperCase(),
      AppConstants.SERVICE_SECTOR.toUpperCase(),
      AppConstants.SUPPORT_SECTOR.toUpperCase(),
      AppConstants.TRANSPORT_LOGISTIC.toUpperCase(),
    };

    // 3. Check if it's Automotive AND in one of those sectors
    return type == BusinessType.Automotive.name.toUpperCase() &&
        automotiveOthersSectors.contains(category);
  }

  bool checkInventoryEligibility(String type, String category) {
    final isProductOrMfg = [
      BusinessType.Product.name,
      BusinessType.Manufacturing.name
    ].any((t) => t.equalsIgnoreCase(type));

    final isAutoEligible =
        type.equalsIgnoreCase(BusinessType.Automotive.name) &&
            [AppConstants.SALES_SECTOR, AppConstants.PARTS_SECTOR]
                .any((s) => s.equalsIgnoreCase(category));

    return isProductOrMfg || isAutoEligible;
  }

  Widget resolveIndividualScreen() {
    String currentType = userProfileTypeGlobal;
    log("userProfileTypeGlobal: $currentType");

    return (currentType == SELF_EMPLOYED || currentType == GIG_WORKER)
        ? EarnServiceAvailableOptionsScreen(fromBottomNavBar: true)
        : currentType == SOCIAL_PROFILE
            ? SocialMainScreen()
            : (currentType == PROFESSIONAL)
                ? ProfessionalsMainScreen()
                : PersonalProfileSetupNewScreen();

    // return Obx(() {
    //   String currentType = viewPersonalDetailsController.userProfileType.value;
    //   log("userProfileTypeGlobal inside Obx: $currentType");
    //   return (currentType == SELF_EMPLOYED || currentType == GIG_WORKER)
    //       ? EarnServiceAvailableOptionsScreen(fromBottomNavBar: true)
    //       : currentType == SOCIAL_PROFILE
    //           ? SocialMainScreen()
    //           : (currentType == PROFESSIONAL)
    //               ? ProfessionalsMainScreen()
    //               : PersonalProfileSetupNewScreen();
    // });
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

              Get.to(() => AskChatScreen(
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
