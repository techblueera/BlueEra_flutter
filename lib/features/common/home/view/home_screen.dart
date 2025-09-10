import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/deeplink_network_resources.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/post_detail_screen.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/view/saved_feed_screen.dart';
import 'package:BlueEra/features/common/post/message_post/create_message_post_screen_new.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/video_feed_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:BlueEra/core/constants/app_enum.dart';

import 'package:BlueEra/features/common/reel/view/shorts/share_short_player_item.dart';
import 'package:BlueEra/features/common/reel/view/video/deeplink_video_screen.dart';

enum SavedFeedTab {
  posts,
  videos,
  shorts;

  /// Human-readable title (capitalised)
  String get title => name[0].toUpperCase() + name.substring(1);
}

class HomeScreen extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible) onHeaderVisibilityChanged;

  HomeScreen({
    super.key,
    required this.isHeaderVisible,
    required this.onHeaderVisibilityChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;
  final List<String> postTab = ["All Posts", "Videos", "Shorts", "Saved"];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  List<SavedFeedTab> filters = SavedFeedTab.values.toList();
  late SavedFeedTab _selectedSavedTab;
  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());

  @override
  void initState() {
    super.initState();
    // if(accountTypeGlobal.toUpperCase() == AppConstants.business){
    //   homeScreenController.getBusinessProfileData();
    // }else{}
    getPackageData();
    searchController.addListener(() {
      setState(() {});
    });
    _selectedSavedTab = SavedFeedTab.posts;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
      // checkAndShowDailyDialog(context);
    });
  }

  // getPersonalProfileData() async {
  //   await UserRepo().getUserById(userId: userId);
  //
  //
  //   await SharedPreferenceUtils.setSecureValue(
  //       SharedPreferenceUtils.businessName,
  //       businessProfileDetails?.data?.businessName);
  //
  //   await SharedPreferenceUtils.setSecureValue(
  //       SharedPreferenceUtils.businessOwnerName,
  //       businessProfileDetails?.data?.ownerDetails?[0].name);
  // }

  Future<void> getPackageData() async {
    if (!mounted) return;
    PackageInfo _packageInfo = await PackageManager.getPackageInfo();
    _checkForUpdate(context, _packageInfo);
  }

  Future<void> _checkForUpdate(
      BuildContext context, PackageInfo packageInfo) async {
    try {
      if (Platform.isAndroid) {
        InAppUpdateManager manager = InAppUpdateManager();
        AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();
        if (appUpdateInfo == null) return;
        if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress) {
          //If an in-app update is already running, resume the update.
          String? message =
              await manager.startAnUpdate(type: AppUpdateType.immediate);
          debugPrint(message ?? '');
        } else if (appUpdateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          ///Update available
          if (appUpdateInfo.immediateAllowed) {
            String? message =
                await manager.startAnUpdate(type: AppUpdateType.immediate);
            debugPrint(message ?? '');
          } else if (appUpdateInfo.flexibleAllowed) {
            String? message =
                await manager.startAnUpdate(type: AppUpdateType.flexible);
            debugPrint(message ?? '');
          } else {
            debugPrint(
                'Update available. Immediate & Flexible Update Flow not allow');
          }
        }
      } else if (Platform.isIOS) {
        VersionInfo? _versionInfo = await UpgradeVersion.getiOSStoreVersion(
            packageInfo: packageInfo, regionCode: "US");
        debugPrint(_versionInfo.toJson().toString());
      }
    } catch (e) {
      debugPrint("Error checking for update: $e");
    }
  }

  Future<void> checkAndShowDailyDialog(BuildContext context) async {
    if (await canCallApi()) {
      try {
        // 🔥 Call your API here
        final response = await homeScreenController.getDailyGreeting();
        // final data = response.data;

        // ✅ Save date after successful API call
        await saveApiCallDate();

        // 🎉 Show Dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Daily Content"),
            // content: Text(data['message'] ?? "No content"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          ),
        );
      } catch (e) {
        print("API error: $e");
      }
    } else {
      print("Already called today ✅");
    }
  }

  // Future<String> getAppVersion() async {
  //   final info = await PackageInfo.fromPlatform();
  //   return info.version;
  // }

  /// add version package
  // bool isUpdateRequired(String currentVersion, String minVersion) {
  //   List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
  //   List<int> minParts = minVersion.split('.').map(int.parse).toList();
  //
  //   // Pad shorter version arrays with zeros (e.g., "2.5" → "2.5.0")
  //   while (currentParts.length < minParts.length) {
  //     currentParts.add(0);
  //   }
  //   while (minParts.length < currentParts.length) {
  //     minParts.add(0);
  //   }
  //
  //   for (int i = 0; i < currentParts.length; i++) {
  //     if (currentParts[i] > minParts[i]) return false; // current is newer
  //     if (currentParts[i] < minParts[i]) return true;  // update required
  //   }
  //   return false; // same version
  // }
  //
  // void showForceUpdateDialog(BuildContext context, String storeUrl) {
  //   commonConformationDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       text: "Update Required, Please update the app to continue.",
  //       confirmCallback: () async {
  //         if (await canLaunchUrl(Uri.parse(storeUrl))) {
  //           await launchUrl(Uri.parse(storeUrl),
  //               mode: LaunchMode.externalApplication);
  //         }
  //       },
  //       cancelCallback: () {
  //         SystemNavigator.pop();
  //       });
  // }

  // @override
  // void didUpdateWidget(covariant HomeScreen oldWidget) {
  //   if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
  //     homeScreenController.isVisible.value = widget.isHeaderVisible;
  //     homeScreenController.headerOffset.value = 0.0;
  //     // animateHeader(1.0); // hide
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _calculateHeaderHeight() {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() => _headerHeight = renderBox.size.height);
    }
  }

  void _toggleAppBarAndBottomNav(bool visible) {
    if (widget.isHeaderVisible != visible && mounted) {
      homeScreenController.isVisible.value = visible;
      widget.onHeaderVisibilityChanged
          .call(visible); // Notify parent to hide/show bottom nav
    }
  }

  Widget _buildCustomAppBar() {
    return CommonBackAppBar(
      isLeading: false,
      isMore: true,
      isSearch: true,
      isProfile: true,
      isNotification: !isGuestUser(),
      bellIconNotEmpty: true,
      isGuestLogout: isGuestUser(),
      controller: searchController,
      onClearCallback: () => searchController.clear(),
      onNotificationTap: () {
        Navigator.pushNamed(
          context,
          RouteHelper.getNotificationScreenRoute(),
        );
      },
      // onProfileTap: widget.onProfileTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Obx(() => Stack(
              children: [
                /// Main Scrollable Area with Dynamic Padding
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                      top: (selectedIndex == 3)
                          ? _headerHeight *
                                  (1 -
                                      homeScreenController.headerOffset.value) +
                              SizeConfig.size30
                          : _headerHeight *
                              (1 - homeScreenController.headerOffset.value)),
                  child: _buildSelectedTabContent(),
                ),

                /// Sliding Header
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  top: -homeScreenController.headerOffset.value * _headerHeight,
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _headerKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomAppBar(),
                        SizedBox(height: SizeConfig.size15),
                        // PositiveCustomBtn(onTap: (){
                        //   Get.to(CreateMessagePostScreenNew(isEdit: false,));
                        // }, title: "Message POST"),
                        HorizontalTabSelector(
                          tabs: postTab,
                          selectedIndex: selectedIndex,
                          onTabSelected: (index, value) {
                            if (mounted) {
                              searchController.clear();
                              setState(() => selectedIndex = index);

                              resetScrollingOnTabChanged();
                            }
                          },
                          labelBuilder: (label) => label,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        if (selectedIndex == 3) ...[
                          _filterButtons(),
                          SizedBox(height: SizeConfig.size10),
                        ]
                      ],
                    ),
                  ),
                )
              ],
            )),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (selectedIndex) {
      case 0:
        return FeedScreen(
            key: ValueKey('feedScreen_all'),
            onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
            postFilterType: PostType.all,
            query: searchController.text.isEmpty ? null : searchController.text,
            headerHeight: _headerHeight);
      case 1:
        return VideoFeedScreen(
            onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
            query: searchController.text,
            headerHeight: _headerHeight);
      case 2:
        return ShortsFeedScreen(
            query: searchController.text, headerHeight: _headerHeight
            // You can add _toggleAppBarAndBottomNav later if needed
            );
      // case 3:
      //   return Center(child: CustomText("Coming soon..."));
      case 3:
        return SavedFeedScreen(
            onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
            query: searchController.text,
            selectedTab: _selectedSavedTab,
            headerHeight: _headerHeight + SizeConfig.size30);

      default:
        return SizedBox();
    }
  }

  Widget _filterButtons() {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
          child: Row(
            children: filters.map((filter) {
              final isSelected = _selectedSavedTab == filter;
              return Padding(
                padding: EdgeInsets.only(right: SizeConfig.size14),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSavedTab = filter;
                    });
                  },
                  child: CustomText(
                    filter.title, // use .label for display text
                    decoration: TextDecoration.underline,
                    color: isSelected ? Colors.blue : Colors.black54,
                    decorationColor: isSelected ? Colors.blue : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  void resetScrollingOnTabChanged() {
    homeScreenController.isVisible.value = true;
    widget.onHeaderVisibilityChanged.call(homeScreenController.isVisible.value);
    homeScreenController.headerOffset.value = 0.0;
  }
}
