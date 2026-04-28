import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';

import 'package:BlueEra/features/chat/auth/controller/add_chat_symbol_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/call_screen/call_history_screen.dart';
import 'package:BlueEra/features/chat/view/chat_theme/chat_background_screen.dart';
import 'package:BlueEra/features/chat/view/contacts/view/contact_list_page.dart';
import 'package:BlueEra/features/chat/view/personal_chat/chat_search_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/view/reminder_chat/reminder_todo_screen.dart';
import 'package:BlueEra/features/chat/view/symbol_view/symbol_view_images.dart';
import 'package:BlueEra/features/chat/view/wallet_chat/wallet_chat_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/manage_notification/notification.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/ott/view/ott_screen.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
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

class ConnectMainPage extends StatefulWidget {
  const ConnectMainPage({super.key});

  @override
  State<ConnectMainPage> createState() => _ConnectMainPageState();
}

class _ConnectMainPageState extends State<ConnectMainPage>
    with SingleTickerProviderStateMixin {
  final List<String> iconTab = [
    AppIconAssets.chat,
    AppIconAssets.community_tab,
    AppIconAssets.message_post,
  ];
  final List<String> postTab = [
    AppStrings.chat,
    AppStrings.community,
    AppStrings.lekha,
  ];
  int selectedIndex = 0;
  int selectedSubIndex = 0;
  final TextEditingController searchController = TextEditingController();
  final homeScreenController = Get.put(HomeScreenController());
  final symbolFeedController = Get.put(SymbolFeedController());
  final addSymbolController = getOrPut(() => AddChatSymbolController());
  final LanguageListController langController =
      getOrPut(() => LanguageListController());

  late TabController _tabController;

  /// Single global subscription so the share-handler stream is never listened
  /// to more than once (ConnectMainPage is re-created on every tab switch).
  static StreamSubscription? _shareSubscription;
  /// Guard to prevent the forward screen from being pushed while one is
  /// already being opened (e.g. rapid share intents).
  static bool _isHandlingShare = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: postTab.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    initPlatformState();
    getPackageData();

    // Boot the personal chat list. Without this socket emit, the Chat tab
    // renders blank on first open until the user navigates away and back.
    final cvc = getOrPut(() => ChatViewController());
    cvc.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.personal_Chat_Type},
    );
    // Fire-and-forget: fetch the full chat export once on home entry.
    // Response is only logged right now (see ChatViewController.getChatExportAll).
    cvc.getChatExportAll();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index != selectedIndex && mounted) {
      setState(() {
        selectedIndex = _tabController.index;
        selectedSubIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  ///DO NOT DELETE THIS CODE.....
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Only subscribe once — subsequent ConnectMainPage rebuilds reuse the same
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

  void _toggleAppBarAndBottomNav(bool visible) {
    if (!mounted) return;
    // Bottom-nav visibility is now handled by `BottomNavHideOnScroll`
    // wrapping the page; this only updates the local header offset
    // controller used by feed children.
    homeScreenController.isVisible.value = visible;
  }

  Widget _buildCustomAppBar() {
    final bool isChatTab = selectedIndex == 0;
    return CommonBackAppBar(
      showElevation: 0,
      isLeading: false,
      // Hide the "+" icon on the Chat tab — its slot is replaced by
      // the search + call-history + reminder-clock actions below.
      isMore: !isChatTab,
      // Inline search is disabled on the Chat tab — the search icon below
      // pushes a fullscreen WhatsApp-style search page instead.
      isSearch: !isChatTab,
      isProfile: false,
      isNotification: false,
      isGuestLogout: isGuestUser(),
      controller: searchController,
      onClearCallback: () => searchController.clear(),
      leadingWidget: _buildSymbolAvatar(),
      buildCustomActionWidget: (isGuestUser() || !isChatTab)
          ? null
          : () => _buildChatTabActions(),
    );
  }

  Widget _buildChatTabActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 14.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Get.to(() => const ChatSearchScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              Icons.search,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => Get.to(() => const CallHistoryScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              Icons.call_outlined,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => Get.to(() => const ReminderTodoScreen()),
            borderRadius: BorderRadius.circular(20),
            child: const Icon(
              Icons.lock_clock,
              size: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolAvatar() {
    return Obx(() {
      final hasSymbols = addSymbolController.mySymbols.isNotEmpty;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: () => _openProfileDrawer(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
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
                  color: Colors.white,
                ),
                child: CachedAvatarWidget(
                  imageUrl: Get.find<AuthController>().imgPath.value,
                  size: SizeConfig.size36,
                  borderRadius: SizeConfig.size34 / 2,
                  showProfileOnFullScreen: false,
                ),
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
        floatingActionButton: selectedIndex == 0
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: kBottomNavigationBarHeight),
                  child: FloatingActionButton(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      Get.toNamed(RouteHelper.getChatContactsRoute());
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              )
            : null,
        body: BottomNavHideOnScroll(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  pinned: false,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  expandedHeight: 72,
                  flexibleSpace: Container(
                    color: Colors.white,
                    child: _buildCustomAppBar(),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeTabBarDelegate(
                    tabController: _tabController,
                    iconTab: iconTab,
                    postTab: postTab,
                    selectedIndex: selectedIndex,
                    onTabTapped: _onTabTapped,
                  ),
                ),
              ];
            },
            body: Container(
              color: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: [
                  PersonalChatsList(isForwardUI: false,),
                  ChannelFeedScreen(
                    headerHeight: 0,
                    onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                  ),
                  HomeFeedScreenNew(
                    key: const ValueKey('feedScreen_all'),
                    onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                    postFilterType: PostType.all,
                    query: searchController.text.isEmpty
                        ? null
                        : searchController.text,
                    headerHeight: 0,
                    isInParentScroll: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _onTabTapped(int index) {
    if (!mounted) return;
    searchController.clear();
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    setState(() {
      selectedIndex = index;
      selectedSubIndex = 0;
    });
  }

  void resetScrollingOnTabChanged() {
    homeScreenController.isVisible.value = true;
    homeScreenController.headerOffset.value = 0.0;
  }

  /// Slide-in profile drawer (lifted from OrderMainChatScreen). Opened by
  /// tapping the symbol avatar in the AppBar leading slot.
  void _openProfileDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final authController = Get.find<AuthController>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close drawer',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.5,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  AppColors.symbolBorderRed,
                                  AppColors.symbolBorderBlue,
                                  AppColors.symbolBorderYellow,
                                  AppColors.symbolBorderGreen,
                                  AppColors.symbolBorderRed,
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: CachedAvatarWidget(
                                imageUrl: authController.imgPath.value,
                                size: 52,
                                borderRadius: 26,
                                showProfileOnFullScreen: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _drawerMenuItem(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add Symbol',
                              iconColor: const Color(0xFF0086FF),
                              bgColor: const Color(0xFFE8F3FF),
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(() => AddChatSymbolScreen());
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.auto_awesome_rounded,
                              label: 'View Symbol',
                              iconColor: const Color(0xFFE88D1A),
                              bgColor: const Color(0xFFFFF3E0),
                              onTap: () {
                                Navigator.pop(context);
                                final ctrl = Get
                                        .isRegistered<AddChatSymbolController>()
                                    ? Get.find<AddChatSymbolController>()
                                    : Get.put(AddChatSymbolController());
                                Get.to(() => SymbolViewImages(
                                    mySymbols: ctrl.mySymbols));
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.group_add_rounded,
                              label: 'Create Group',
                              iconColor: const Color(0xFF2BB67F),
                              bgColor: const Color(0xFFE6F9F1),
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(() => ContactsPage(from: "group"));
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.palette_rounded,
                              label: 'Background',
                              iconColor: const Color(0xFF9C27B0),
                              bgColor: const Color(0xFFF3E5F5),
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(() => ChatBackgroundScreen());
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(height: 1),
                            ),
                            _drawerMenuItem(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Wallet',
                              iconColor: const Color(0xFF0086FF),
                              bgColor: const Color(0xFFE8F3FF),
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(() => const WalletChatScreen());
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.shield_rounded,
                              label: 'Private Room',
                              iconColor: const Color(0xFFD94A42),
                              bgColor: const Color(0xFFFFEBEE),
                              onTap: () {
                                Navigator.pop(context);
                                commonSnackBar(message: "Coming soon....");
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.devices_rounded,
                              label: 'Linked Device',
                              iconColor: const Color(0xFF505050),
                              bgColor: const Color(0xFFF0F0F0),
                              onTap: () {
                                Navigator.pop(context);
                                commonSnackBar(message: "Coming soon....");
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.lock_rounded,
                              label: 'Lock Chat',
                              iconColor: const Color(0xFFE88D1A),
                              bgColor: const Color(0xFFFFF3E0),
                              onTap: () {
                                Navigator.pop(context);
                                commonSnackBar(message: "Coming soon....");
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.notifications_rounded,
                              label: 'Notification',
                              iconColor: const Color(0xFF2BB67F),
                              bgColor: const Color(0xFFE6F9F1),
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(() => NotificationSettingScreen());
                              },
                            ),
                            _drawerMenuItem(
                              icon: Icons.person_add_alt_rounded,
                              label: 'Invite Friend',
                              iconColor: const Color(0xFF9C27B0),
                              bgColor: const Color(0xFFF3E5F5),
                              onTap: () {
                                Navigator.pop(context);
                                commonSnackBar(message: "Coming soon....");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  Widget _drawerMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                label,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> iconTab;
  final List<String> postTab;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;

  _HomeTabBarDelegate({
    required this.tabController,
    required this.iconTab,
    required this.postTab,
    required this.selectedIndex,
    required this.onTabTapped,
  });

  static const double _tabsHeight = 32;

  @override
  double get maxExtent => _tabsHeight;

  @override
  double get minExtent => _tabsHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: _tabsHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(postTab.length, (index) {
                  bool isSelected = selectedIndex == index;
                  return Flexible(
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: index == 0 ? 10.0 : 0),
                      child: GestureDetector(
                        onTap: () => onTabTapped(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LocalAssets(
                                  imagePath: iconTab[index],
                                  width: 16,
                                  height: 16,
                                  imgColor: isSelected
                                      ? AppColors.black28
                                      : AppColors.secondaryTextColor,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: CustomText(
                                    postTab[index].tr,
                                    fontSize: 14,
                                    maxLines: 1,
                                    fontWeight: FontWeight.w500,
                                    overflow: TextOverflow.ellipsis,
                                    color: isSelected
                                        ? AppColors.black28
                                        : AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 3,
                              width: isSelected ? 90 : 0,
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
          ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeTabBarDelegate oldDelegate) =>
      selectedIndex != oldDelegate.selectedIndex ||
      tabController != oldDelegate.tabController;
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
