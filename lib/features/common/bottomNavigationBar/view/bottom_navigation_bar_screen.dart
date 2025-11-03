import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_widget.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
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
// import 'package:http/http.dart' as http;
// import 'package:googleapis_auth/auth_io.dart' as auth;
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
  final viewPersonalDetailsController =
      Get.put(ViewPersonalDetailsController());
  final inventoryController = Get.put(InventoryController());

  // final callController = Get.put(CallController());
  // final groupChatViewController = Get.put(GroupChatViewController());

  @override
  void initState() {
    super.initState();

    _initializeControllers();
    _initializeUserData();
    _initializeSocketConnections();
    // _initializeOneSignal();

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
    AppNotificationHandler().getInitialMsg();
    AppNotificationHandler().onMsgOpen();
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
    channelId = data.id;
    channelName = data.name;
    channelOwner = data.ownership.claimedBy;

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
    await getBusinessUserOwnProduct();
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

  // Future<void> getOneSignalUpdate() async {
  //   OnesignalService().onNotifiacation();
  //   OnesignalService().onNotificationClick();
  //   await Future.delayed(Duration(seconds: 1));
  //   await OnesignalService().checkOneSignalStatus();
  // }

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
    /*  floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 18.0),
        child: FloatingActionButton(onPressed: () async {
          final serviceAccountJson = {
            "type": "service_account",
            "project_id": "blueera-50c05",
            "private_key_id": "402a80dac7372154b30156c81177bfe781af242d",
            "private_key":
                "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCh7175TtiMtURf\nRuYa9hDkpAQNiEuTTBV/edWRs0dnBZMTWEMbBFREM68N4GTgv3zSLMYaEPZakAvB\nigvpPeCxl6W+EJ2N3WAAmMeoBIQOMwc2mFMg6aXlN9zsD1dU33p5BnZuWOqIBDOv\nKbHhYLhFTDFVYsm+y5i5BdgMBRvhFCUJGjCp46wfYzYhzKlXfeUsUYbFb7tZ0BYD\nMy9OjnDQyfeF5+8JKTXvldQG8YsRcuXw2Z9Uy08vVwZIpaCQ4nPmI3fERhyLI9BF\n/7JmyyneotZXtZJ89R2x6QILgskBKqn7Wr0JCdpG5SnSZFmvRcIiBw5VbZPFsIbj\nnUlY5TEDAgMBAAECggEAFflCXPgrAGT0gy0+ujfbsPrkpeVxw+oWHLcumNfH/53N\nCFn4uSjMOnj87xgc+DZjvK1gsFbO5xkWz0tpNFw2KkMWtYTRrFd22H3i0dTTCo44\nE1t2JEgwP7tl2g523kh4+QU8etrL8GsJjGJPBfM27ghZxWljUOWVsr2tRGxJDTCU\nNzAoi6Ok6W/QQ/ccIVXz/B2ZNsF/gZiAwOEmNWNisbaMs4RJKn6FvTj/4E8VUwms\nodsTaKJMDJyhWPmzaHYL2swabOrjPXn8FkS41mMxg4bKlof0LwPm7H9V8Rw1RVUp\n079E07nktlrfIwAub58qcJzcFroJfd1xmL8tWAndEQKBgQDZ++vLu55kqxUvQD0e\nAypJYHDTms7/k21Vw9XtE2Emb9a/GFEyFahLRHkiCWRbliV6/U3nzDPRF8erEi57\nuo4pdK4MGy17ZwFFrxPu+hZAEG9Bqgs4L3SUxT+y3hMiqB75nIoetoXaVaydkcs0\nRnq2UdbNDzvwqKDkTfguV5pSiQKBgQC+LRhLM4ajSBFLqKrcLanm3r642yf3PtuW\nYXNV5+FDNT6v63HQXBg2eJlWuk6VwdvOZOMpy9iPQGOD7bD3Hoq/AUc2JT6CGT9B\nFv+YJ7RBCYWl+EsxMj0W446rQNWD0Sj13S+KWDHUd5vvI2Y9G0DW6OD8K1URObSn\n55QPqCm0KwKBgQCS0KXjth3cV44RIQcI68DTYu0a2C2K3VTKavfukRrhtHnCgzJM\ntWGAMEIVtpWtSdc8mtaZxGMx9P46Lii4lNGjAj8nUDa14o5szJp0XmQWCfulEk40\nLWIrwR5B7mic8vbJz7EHNo+4mfOEvOlL8Bw+J6iwvA327NxQaGM7cy0xYQKBgHz7\n6A5sQ50F3RALPpdLj3DCjTeyGHb+oZQYYZNgvIPN92/oXblg/Sy3X5dHBCSZ7lqb\npUuvw5iJ6Z0n1njiYq8bKPDl00nvS8n8UmhuF6Hynxovr0Ma0Fk9nmLgTjK+gJvt\nDLRwN/d50Ep+yk94nMlg7ZPs6pBSi28Z3A3aJ+ZXAoGBAKR1igkCFD7U4pdw2TMd\ncUaFE6SHClOs1F4oxS1FMhVHXV4P+VkGsbPP/RFIfnq/jvMums0sFQxEtx1hPBvZ\n5Tsxdrco7ks9RykXsLcYKENSn4O1t5TYpiCyO0IefcPWP/t5QC0tx23qoxu9W+ZW\ncSRoaX431CQynOdF+SwqTgNG\n-----END PRIVATE KEY-----\n",
            "client_email":
                "firebase-adminsdk-fbsvc@blueera-50c05.iam.gserviceaccount.com",
            "client_id": "108051446785289900962",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url":
                "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url":
                "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40blueera-50c05.iam.gserviceaccount.com",
            "universe_domain": "googleapis.com"
          };
          List<String> scopes =
          [
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/firebase.database",
            "https://www.googleapis.com/auth/firebase.messaging"
          ];
          http.Client client = await auth.clientViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
          );

        // get the access token
          auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
              auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
              scopes,
              client
          );

          client.close();

           logs("ACCESS TOKEN ===${credentials.accessToken.data}");
           print("ACCESS TOKEN ===${credentials.accessToken.data}");
           debugPrint("ACCESS TOKEN ===${credentials.accessToken.data}");

          // arguments: {"postId": (uri.toString().split("/").last)});
        }),
      ),*/
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
