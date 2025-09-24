import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/view/saved_feed_screen.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/features/common/more/view/more_cards_screen.dart';
import 'package:BlueEra/features/common/more/widget/greeting_card_dialog.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/video/video_feed_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';

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
  final List<String> postTab = ["All Posts", "Videos", "Shorts", "Saved", "My Cards"];
  int selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  List<SavedFeedTab> filters = SavedFeedTab.values.toList();
  late SavedFeedTab _selectedSavedTab;
  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());
  final MoreCardsScreenController moreCardsScreenController = Get.put(MoreCardsScreenController());

  @override
  void initState() {
    super.initState();
    getPackageData();
    searchController.addListener(() {
      setState(() {});
    });
    _selectedSavedTab = SavedFeedTab.posts;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
       checkAndShowGreetingDialog(context);
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

  Future<void> checkAndShowGreetingDialog(BuildContext context) async {
    final result = await canCallCardApi();
    final canCall = result.canCall;
    final today = result.today;
    log('can call-- $canCall');

    if (canCall) {
      try {
        await moreCardsScreenController.getCardCategoriesSortedByDate(todayDate: today);

        await saveApiCallDate();

        final List<Cards> cards = moreCardsScreenController.dayCards;
        log('length of card--> ${cards.length}');

        if (cards.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return GreetingCardDialog(cards: cards);
            },
          );
        }
      } catch (e) {
        print("API error: $e");
      }
    } else {
      print("Already called today ✅ Last call was on $today");
    }
  }

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

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Obx(() => Stack(
              children: [
                /// Main Scrollable Area with Dynamic Padding
                AnimatedPadding(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(
                    top: (selectedIndex == 3
                            ?  _headerHeight* (1 - homeScreenController.headerOffset.value) + SizeConfig.size30
                            : _headerHeight * (1 - homeScreenController.headerOffset.value))),
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
      case 4:
        return MoreCardsScreen(
            isFromHomeScreen: true,
            headerHeight: _headerHeight,
            onHeaderVisibilityChanged: _toggleAppBarAndBottomNav,
        );

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
