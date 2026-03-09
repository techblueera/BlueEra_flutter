import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/ott/view/ott_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:share_handler/share_handler.dart';

import '../../../chat/view/forward_screen/chat_forward_screen.dart';

enum SavedFeedTab {
  posts;

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
  final List<String> iconTab = [
    AppIconAssets.message_post,
    AppIconAssets.community_tab,
    AppIconAssets.ott_tab,
    // AppIconAssets.save_tab,
  ];
  final List<String> postTab = [
    // AppStrings.allPosts,
    AppStrings.lekha,
    // AppStrings.channel,
    "Community",
    AppStrings.tab_ott,
    // AppStrings.tab_saved,
  ];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  final homeScreenController = Get.put(HomeScreenController());

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);

    initPlatformState();
    getPackageData();
    searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _calculateHeaderHeight();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  ///DO NOT DELETE THIS CODE.....
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;

    // App running, receiving new share while app is open
    handler.sharedMediaStream.listen((SharedMedia media) {
      _openChatScreen(media);
    });
  }

  void _openChatScreen(SharedMedia media) {
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final sharedText = media.content;
    final attachments = media.attachments ?? [];

    if (sharedText != null && sharedText.isNotEmpty) {
      Get.to(() => ChatForwardScreen(sharedText: sharedText));
    } else if (attachments.isNotEmpty) {
      Get.to(() => ChatForwardScreen(sharedFiles: attachments));
    }
  }

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

  void _calculateHeaderHeight() {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() => _headerHeight = renderBox.size.height);
    }
  }

  void _toggleAppBarAndBottomNav(bool visible) {
    if (!mounted) return;
    homeScreenController.isVisible.value = visible;
    widget.onHeaderVisibilityChanged.call(visible);
  }

  Widget _buildCustomAppBar() {
    return CommonBackAppBar(
      showElevation: 0,
      isDrawerMenu: true,
      isLeading: false,
      isMore: true,
      isSearch: true,
      isProfile: false,
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.lightBlueE9,
        extendBodyBehindAppBar: true,
        body: Obx(() => Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                      top: (_headerHeight *
                          (1 - homeScreenController.headerOffset.value))),
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index) {
                      logs("PAGE CHANGE CALL $index");
                      setState(() {
                        selectedIndex = index;
                        selectedSubIndex = 0;
                      });
                    },
                    children: [
                      HomeFeedScreenNew(
                        key: const ValueKey('feedScreen_all'),
                        onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                        postFilterType: PostType.all,
                        query: searchController.text.isEmpty
                            ? null
                            : searchController.text,
                        headerHeight: _headerHeight,
                        isInParentScroll: false,
                      ),
                      ChannelFeedScreen(
                        headerHeight: _headerHeight,
                        onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                      ),
                      OttScreen(
                        headerHeight: _headerHeight,
                        onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                      ),
                    ],
                  ),
                ),

                /// Sticky header — slides up/down like LinkedIn
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: -homeScreenController.headerOffset.value * _headerHeight,
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _headerKey,
                    child: Container(
                      color: Colors.white, // Background color for the tab area
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCustomAppBar(),

                          // --- PRIMARY TABS (Lekha, Community, etc.) ---
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(postTab.length, (index) {
                                bool isSelected = selectedIndex == index;
                                return Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: index == 0 ? 10.0 : 0),
                                    child: GestureDetector(
                                      onTap: () => _onTabTapped(index),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              LocalAssets(
                                                imagePath: iconTab[index],
                                                width: 16,
                                                height: 16,
                                              ),
                                              SizedBox(
                                                width: 3,
                                              ),
                                              Flexible(
                                                child: CustomText(
                                                  postTab[index],
                                                  fontSize: 14,
                                                  maxLines: 1,
                                                  fontWeight: FontWeight.w500,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  color: isSelected
                                                      ? AppColors.black28
                                                      : AppColors
                                                          .secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),

                                          // The Blue Indicator Line
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            height: 3,
                                            width: isSelected ? 90 : 0,
                                            // width: isSelected ? double.infinity : 0,
                                            color: AppColors.primaryColor,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          if (selectedIndex == 0) _buildSubFilterRow(),

                          if (selectedIndex == 1) _buildCommunitySubFilterRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildSubFilterRow() {
    return Container(
      padding: const EdgeInsets.only(top: 6, right: 16, left: 16, bottom: 6),
      // color: AppColors.appBackgroundColor,
      child: Row(
        children: [
          LocalAssets(imagePath: AppIconAssets.filterIcon),
          const SizedBox(width: 12),
          _subFilterChip("For You", index: 0),
          const SizedBox(width: 8),
          _subFilterChip("Near Me", index: 1),
          const SizedBox(width: 8),
          _subFilterChip("Treanding", index: 2),
        ],
      ),
    );
  }

  Widget _buildCommunitySubFilterRow() {
    return Container(
      padding: const EdgeInsets.only(top: 6, right: 16, left: 16, bottom: 6),
      color: AppColors.white,
      child: Row(
        children: [
          LocalAssets(imagePath: AppIconAssets.filterIcon),
          const SizedBox(width: 12),
          _communitySubFilterChip("Joined", index: 0),
          const SizedBox(width: 8),
          _communitySubFilterChip("Suggested", index: 1),
        ],
      ),
    );
  }

// Logic to handle tab switching
  void _onTabTapped(int index) {
    if (mounted) {
      searchController.clear();
      setState(() => selectedIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int selectedSubIndex = 0; // 0: For You, 1: Near Me, 2: Following

  Widget _subFilterChip(String title, {required int index}) {
    bool isActive = selectedSubIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : Color(0xffF3F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primaryColor
                : AppColors.transparent,
            width: 1,
          ),
        ),
        child: CustomText(
          title,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? Colors.white : AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _communitySubFilterChip(String title, {required int index}) {
    bool isActive = selectedSubIndex == index;
    return GestureDetector(
      onTap: () {
        Get.find<ChannelFeedController>().communityIndex.value = index;
        setState(() {
          selectedSubIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : Color(0xffF3F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primaryColor
                : AppColors.transparent,
            width: 1,
          ),
        ),
        child: CustomText(
          title,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? Colors.white : AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  void resetScrollingOnTabChanged() {
    homeScreenController.isVisible.value = true;
    widget.onHeaderVisibilityChanged.call(homeScreenController.isVisible.value);
    homeScreenController.headerOffset.value = 0.0;
  }
}

/* Old _HomeScreenState removed - DO NOT DELETE
(Preserved for reference only)
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;
  final List<String> postTab = [
    AppStrings.allPosts,
    AppStrings.channel,
    AppStrings.tab_ott,
    AppStrings.tab_saved,
  ];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  late SavedFeedTab _selectedSavedTab;
  final homeScreenController = Get.put(HomeScreenController());

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);

    initPlatformState();
    getPackageData();
    searchController.addListener(() {
      setState(() {});
    });
    _selectedSavedTab = SavedFeedTab.posts;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _calculateHeaderHeight();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    searchController.dispose();

    super.dispose();
  }

  ///DO NOT DELETE THIS CODE.....
  SharedMedia? sharedMedia;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;

    // App opened from share intent
    handler.getInitialSharedMedia().then((SharedMedia? media) {
      setState(() => sharedMedia = media);
      if (media?.content?.isNotEmpty ?? false) {
        _openChatScreen(media!);
      }
      if (media?.attachments?.isNotEmpty ?? false) {
        _openChatScreen(media!);
      }
    });

    // App running, receiving new share
    handler.sharedMediaStream.listen((SharedMedia media) {
      setState(() => sharedMedia = media);
      _openChatScreen(media);
    });
  }

  void _openChatScreen(SharedMedia media) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isGuestUser()) {
        createProfileScreen();
      } else {
        final _sharedText = media.content;
        List<SharedAttachment?>? attachments = media.attachments ?? [];

        if (_sharedText != null && _sharedText.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeAvailableContactsList(sharedText: _sharedText),
            ),
          );
        } else if ((attachments.isNotEmpty)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeAvailableContactsList(sharedFiles: attachments),
            ),
          );
        }
      }
    });
  }

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
      isDrawerMenu: true,
      isLeading: false,
      isMore: true,
      isSearch: true,
      isProfile: false,
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
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,

        body: Obx(() => Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                      top: (_headerHeight *
                          (1 - homeScreenController.headerOffset.value))),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    children: isIndividual()
                        ? [
                            if (selectedIndex == 0)
                              HomeFeedScreenNew(
                                key: ValueKey('feedScreen_all'),
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                                postFilterType: PostType.all,
                                query: searchController.text.isEmpty
                                    ? null
                                    : searchController.text,
                                headerHeight: _headerHeight,
                                isInParentScroll: false,
                              ),
                            if (selectedIndex == 1)
                              ChannelFeedScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 2)
                              OttScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 3)
                              SavedFeedScreen(
                                  onHeaderVisibilityChanged:
                                      _toggleAppBarAndBottomNav,
                                  query: searchController.text,
                                  selectedTab: _selectedSavedTab,
                                  headerHeight:
                                      _headerHeight + SizeConfig.size30),
                          ]
                        : [
                            if (selectedIndex == 0)
                              HomeFeedScreenNew(
                                key: ValueKey('feedScreen_all'),
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                                postFilterType: PostType.all,
                                query: searchController.text.isEmpty
                                    ? null
                                    : searchController.text,
                                headerHeight: _headerHeight,
                                isInParentScroll: false,
                              ),
                            if (selectedIndex == 1)
                              ChannelFeedScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 2)
                              OttScreen(
                                headerHeight: _headerHeight,
                                onHeaderVisibilityChanged:
                                    _toggleAppBarAndBottomNav,
                              ),
                            if (selectedIndex == 3)
                              SavedFeedScreen(
                                  onHeaderVisibilityChanged:
                                      _toggleAppBarAndBottomNav,
                                  query: searchController.text,
                                  selectedTab: _selectedSavedTab,
                                  headerHeight:
                                      _headerHeight + SizeConfig.size30),
                          ],
                  ),
                ),

                /// Header stays same
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
                        HorizontalTabSelector(
                          tabs: postTab,
                          selectedIndex: selectedIndex,
                          onTabSelected: (index, value) {
                            if (mounted) {
                              searchController.clear();
                              setState(() => selectedIndex = index);
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              resetScrollingOnTabChanged();
                            }
                          },
                          labelBuilder: (label) => label,
                        ),
                        SizedBox(height: SizeConfig.size10),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  void resetScrollingOnTabChanged() {
    homeScreenController.isVisible.value = true;
    widget.onHeaderVisibilityChanged.call(homeScreenController.isVisible.value);
    homeScreenController.headerOffset.value = 0.0;
  }
}
*/
