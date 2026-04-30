import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';

import 'package:BlueEra/features/chat/auth/controller/add_chat_symbol_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_controllar.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:share_handler/share_handler.dart';

import '../../../chat/auth/controller/chat_view_controller.dart';
import '../../../chat/view/forward_screen/chat_forward_screen.dart';
import '../../../personal/personal_profile/controller/languge_list_controller.dart';
import '../../../../core/constants/getx_utils.dart';

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
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _tabsKey = GlobalKey();
  double _headerHeight = 0;
  double _appBarHeight = 0;
  double _tabsHeight = 0;
  final List<String> iconTab = [
    AppIconAssets.chat,
    AppIconAssets.community_tab,
    AppIconAssets.message_post,
    // AppIconAssets.ott_tab,
    // AppIconAssets.save_tab,
  ];
  final List<String> postTab = [
    AppStrings.chat,
    AppStrings.community,
    AppStrings.lekha,
  ];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  final homeScreenController = Get.put(HomeScreenController());
  final symbolFeedController = Get.put(SymbolFeedController());
  final addSymbolController = getOrPut(() => AddChatSymbolController());
  final LanguageListController langController =
      getOrPut(() => LanguageListController());

  late PageController _pageController;

  /// Single global subscription so the share-handler stream is never listened
  /// to more than once (HomeScreen is re-created on every tab switch).
  static StreamSubscription? _shareSubscription;
  /// Guard to prevent the forward screen from being pushed while one is
  /// already being opened (e.g. rapid share intents).
  static bool _isHandlingShare = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
    initPlatformState();
    getPackageData();
    // Fire-and-forget: fetch the full chat export once on home entry.
    // Response is only logged right now (see ChatViewController.getChatExportAll).
    getOrPut(() => ChatViewController()).getChatExportAll();
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
    // Only subscribe once — subsequent HomeScreen rebuilds reuse the same
    // subscription so the forward screen doesn't open multiple times.
    if (_shareSubscription != null) return;

    final handler = ShareHandlerPlatform.instance;

    // App running, receiving new share while app is open
    _shareSubscription = handler.sharedMediaStream.listen((SharedMedia media) {
      _openChatScreen(media);
    });
  }

  void _openChatScreen(SharedMedia media) {
    if (_isHandlingShare) return; // prevent duplicate opens
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final sharedText = media.content;
    final attachments = media.attachments ?? [];

    if (sharedText != null && sharedText.isNotEmpty) {
      _isHandlingShare = true;
      Get.to(() => ChatForwardScreen(sharedText: sharedText))
          ?.then((_) => _isHandlingShare = false);
    } else if (attachments.isNotEmpty) {
      _isHandlingShare = true;
      Get.to(() => ChatForwardScreen(sharedFiles: attachments))
          ?.then((_) => _isHandlingShare = false);
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
    final appBarBox =
        _appBarKey.currentContext?.findRenderObject() as RenderBox?;
    final tabsBox =
        _tabsKey.currentContext?.findRenderObject() as RenderBox?;
    if (mounted && (appBarBox != null || tabsBox != null)) {
      setState(() {
        if (appBarBox != null) _appBarHeight = appBarBox.size.height;
        if (tabsBox != null) _tabsHeight = tabsBox.size.height;
        _headerHeight = _appBarHeight + _tabsHeight;
      });
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
      isLeading: false,
      isMore: true,
      isSearch: true,
      isProfile: false,
      isNotification: !isGuestUser(),
      bellIconNotEmpty: true,
      isGuestLogout: isGuestUser(),
      controller: searchController,
      onClearCallback: () => searchController.clear(),
      leadingWidget: _buildSymbolAvatar(),
      onNotificationTap: () {
        Navigator.pushNamed(
          context,
          RouteHelper.getNotificationScreenRoute(),
        );
      },
      // onProfileTap: widget.onProfileTap,
    );
  }

  Widget _buildSymbolAvatar() {
    return Obx(() {
      final hasSymbols = addSymbolController.mySymbols.isNotEmpty;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2.4),
            decoration: hasSymbols
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      startAngle: 0.0,
                      endAngle: 6.28319,
                      colors: [
                        AppColors.symbolBorderRed,
                        AppColors.symbolBorderBlue,
                        AppColors.symbolBorderYellow,
                        AppColors.symbolBorderGreen,
                        AppColors.symbolBorderRed,
                      ],
                    ),
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEEF1F5),
              ),
              child: CachedAvatarWidget(
                imageUrl: Get.find<AuthController>().imgPath.value,
                size: SizeConfig.size36,
                borderRadius: SizeConfig.size34 / 2,
                showProfileOnFullScreen: false,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () {
                Get.to(() => AddChatSymbolScreen());
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.primaryColor,
                ),
                padding: const EdgeInsets.all(1.4),
                child: const Icon(
                  Icons.add,
                  color: AppColors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: AppColors.white,
        extendBodyBehindAppBar: true,
        body: Obx(() => Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                      top: (_appBarHeight *
                              (1 - homeScreenController.headerOffset.value)) +
                          _tabsHeight),
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index) {
                      logs("PAGE CHANGE CALL $index");
                      setState(() {
                        selectedIndex = index;
                        selectedSubIndex = 0;
                      });
                      // Recalculate header height after tab change
                      // (Community tab adds Joined/Suggested row)
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _calculateHeaderHeight();
                      });
                    },
                    children: [
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.only(top: _tabsHeight),
                        child: PersonalChatsList(),
                      ),
                      ChannelFeedScreen(
                        headerHeight: _headerHeight,
                        onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                      ),
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
                    ],
                  ),
                ),

                /// AppBar — slides up/off when scrolling
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: -homeScreenController.headerOffset.value * _appBarHeight,
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _appBarKey,
                    child: Container(
                      color: Colors.white,
                      child: _buildCustomAppBar(),
                    ),
                  ),
                ),

                /// Sticky tabs (Lekha / Community) — pin to top after scroll
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: _appBarHeight *
                      (1 - homeScreenController.headerOffset.value),
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _tabsKey,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              LocalAssets(
                                                imagePath: iconTab[index],
                                                width: 16,
                                                height: 16,
                                                imgColor: isSelected
                                                    ? AppColors.black28
                                                    : AppColors
                                                        .secondaryTextColor,
                                              ),
                                              SizedBox(
                                                width: 3,
                                              ),
                                              Flexible(
                                                child: CustomText(
                                                  postTab[index].tr,
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


  Widget _buildCommunitySubFilterRow() {
    return Obx(() {
      final channelFeedController = Get.isRegistered<ChannelFeedController>()
          ? Get.find<ChannelFeedController>()
          : Get.put(ChannelFeedController());
      final hasJoined = channelFeedController.channelDataList.isNotEmpty;
      // If joined chip is hidden, force-select Suggested as default.
      // Schedule outside the build phase to avoid markNeedsBuild while
      // the widget tree is locked.
      if (!hasJoined && channelFeedController.communityIndex.value != 1) {
        Future.microtask(() {
          if (!mounted) return;
          channelFeedController.communityIndex.value = 1;
        });
      }
      return Container(
        padding: const EdgeInsets.only(top: 6, right: 16, left: 16, bottom: 6),
        color: AppColors.white,
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.filterIcon),
            const SizedBox(width: 12),
            if (hasJoined) ...[
              _communitySubFilterChip(AppStrings.joined, index: 0),
              const SizedBox(width: 8),
            ],
            _communitySubFilterChip(AppStrings.suggested, index: 1),
          ],
        ),
      );
    });
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


  Widget _communitySubFilterChip(String title, {required int index}) {
    final channelFeedController = Get.isRegistered<ChannelFeedController>()
        ? Get.find<ChannelFeedController>()
        : Get.put(ChannelFeedController());
    bool isActive = channelFeedController.communityIndex.value == index;
    return GestureDetector(
      onTap: () {
        channelFeedController.communityIndex.value = index;
        if (mounted) {
          setState(() {
            selectedSubIndex = index;
          });
        }
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _calculateHeaderHeight();
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
