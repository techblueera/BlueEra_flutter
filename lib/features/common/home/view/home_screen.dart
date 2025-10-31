import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/contacts/view/be_available_contacts_list.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/view/saved_feed_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/inventory_business_cards_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/service_provider_dialoge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'package:share_handler/share_handler.dart';
// import 'package:share_handler/share_handler.dart';


enum SavedFeedTab {
  posts;
  // videos,
  // shorts;

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
  final List<String> postTab = [
    "All Posts",
    "Channel",
    // "Videos",
    // "Shorts",
    "Saved",
    if (isBusiness()) "My Cards"
  ];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  List<SavedFeedTab> filters = SavedFeedTab.values.toList();
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
      if (isIndividual()) {
        await Future.delayed(Duration(seconds: 2));
        showEnableServiceDialog();
      }
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
        print("Received text: ${media.content}");
      }
      if (media?.attachments?.isNotEmpty ?? false) {
        _openChatScreen(media!);
        print("Received attachments: ${media.attachments}");
      }
    });

    // App running, receiving new share
    handler.sharedMediaStream.listen((SharedMedia media) {
      setState(() => sharedMedia = media);
      _openChatScreen(media);
      print("New shared text: ${media.content}");
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
    return SafeArea(
      child: Scaffold(
        // floatingActionButton: FloatingActionButton(onPressed: (){
        //   Get.to(() => VideoFeedScreen1(initialIndex: 0, ));
        //
        // }),
        extendBodyBehindAppBar: true,
        body: Obx(() => Stack(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                      top: (selectedIndex == 2
                          ? _headerHeight *
                                  (1 -
                                      homeScreenController.headerOffset.value) +
                              SizeConfig.size30
                          : _headerHeight *
                              (1 - homeScreenController.headerOffset.value))),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    children:  isIndividual()? [

                    HomeFeedScreenNew(
                      key: ValueKey('feedScreen_all'),
                      onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                      postFilterType: PostType.all,
                      query: searchController.text.isEmpty
                          ? null
                          : searchController.text,
                      headerHeight: _headerHeight,
                      isInParentScroll: false,
                    ),
                      ChannelFeedScreen(),
                      /*  VideoFeedScreen(
                          onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                          query: searchController.text,
                          headerHeight: _headerHeight),
                      ShortsFeedScreen(
                          query: searchController.text,
                          headerHeight: _headerHeight
                          // You can add _toggleAppBarAndBottomNav later if needed
                          ),*/
                      SavedFeedScreen(
                          onHeaderVisibilityChanged:
                          _toggleAppBarAndBottomNav,
                          query: searchController.text,
                          selectedTab: _selectedSavedTab,
                          headerHeight: _headerHeight + SizeConfig.size30),

                      ]: [

                        HomeFeedScreenNew(
                          key: ValueKey('feedScreen_all'),
                          onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                          postFilterType: PostType.all,
                          query: searchController.text.isEmpty
                              ? null
                              : searchController.text,
                          headerHeight: _headerHeight,
                          isInParentScroll: false,
                        ),
                        ChannelFeedScreen(),
                      /*  VideoFeedScreen(
                          onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                          query: searchController.text,
                          headerHeight: _headerHeight),
                      ShortsFeedScreen(
                          query: searchController.text,
                          headerHeight: _headerHeight
                          // You can add _toggleAppBarAndBottomNav later if needed
                          ),*/
                        SavedFeedScreen(
                            onHeaderVisibilityChanged:
                                _toggleAppBarAndBottomNav,
                            query: searchController.text,
                            selectedTab: _selectedSavedTab,
                            headerHeight: _headerHeight + SizeConfig.size30),

                      InventoryBusinessCardsScreen(
                              showBackAppBar: false,
                            )
                      // MoreCardsScreen(
                      //   isFromHomeScreen: true,
                      //   headerHeight: _headerHeight,
                      //   onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
                      // ),
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
                        if (postTab[selectedIndex] == "Saved") ...[
                          _filterButtons(),
                          SizedBox(height: SizeConfig.size10),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
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
