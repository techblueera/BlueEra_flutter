import 'dart:ui' show ImageFilter;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/chat_requests_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/feed/view/my_post_tab_screen.dart';
import 'package:BlueEra/features/common/reel/view/shorts/reels_tab_screen.dart';
import 'package:BlueEra/widgets/glass_surface.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../core/constants/getx_utils.dart';
import '../../../core/constants/snackbar_helper.dart';
import '../../common/search/controller/content_search_controller.dart';
import '../../common/search/widget/content_search_field.dart';
import '../../../widgets/custom_text_cm.dart';
import '../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../auth/controller/add_chat_symbol_controller.dart';
import '../auth/controller/chat_flag_controller.dart';
import '../auth/controller/chat_pin_archive_controller.dart';
import '../auth/controller/chat_theme_controller.dart';
import '../auth/controller/chat_view_controller.dart';

class SocialMainScreen extends StatefulWidget {
  const SocialMainScreen({
    super.key,
    this.isNewGroupUI,
    this.isForwardUI = false,
  });

  final bool? isForwardUI;
  final bool? isNewGroupUI;

  @override
  _SocialMainScreenState createState() => _SocialMainScreenState();
}

class _SocialMainScreenState extends State<SocialMainScreen>
    with SingleTickerProviderStateMixin {
  ChatViewController chatViewController = getOrPut(() => ChatViewController());
  ChatThemeController chatThemeController =
      getOrPut(() => ChatThemeController());

  final addSymbolController = getOrPut(() => AddChatSymbolController());
  final bottomBarController = getOrPut(() => BottomBarController());

  /// Shared with [ContentSearchField] in the header — read here only to keep
  /// the search row pinned while its suggestion panel is open.
  final contentSearchController = getOrPut(() => ContentSearchController());

  /// Drives the collapsing search header. The Social/Community TabBar stays
  /// pinned at the top; only the search row above it slides away on a
  /// sustained scroll-down and returns on the first upward scroll —
  /// mirroring the sticky-tabs behaviour on the "Me" screens.
  bool _isSearchVisible = true;
  double _scrollAccumulator = 0;

  /// Px of sustained downward scroll before the search header hides.
  static const double _hideThreshold = 40;

  bool _onScrollNotification(ScrollNotification notification) {
    // Vertical-only: horizontal carousels inside feed cards (and the
    // horizontal TabBarView swipe) must not drive the header collapse.
    if (notification.metrics.axis != Axis.vertical) return false;
    // Never collapse the row out from under an open suggestion panel — that
    // would tear the dropdown off its anchor mid-search.
    if (contentSearchController.isPanelOpen.value) return false;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0) {
        // Scrolling content up — accumulate, then hide once past threshold.
        if (_isSearchVisible) {
          _scrollAccumulator += delta;
          if (_scrollAccumulator >= _hideThreshold) {
            setState(() => _isSearchVisible = false);
            _scrollAccumulator = 0;
          }
        }
      } else if (delta < 0) {
        // Any upward scroll instantly restores the search header.
        _scrollAccumulator = 0;
        if (!_isSearchVisible) {
          setState(() => _isSearchVisible = true);
        }
      }
    } else if (notification is ScrollEndNotification) {
      _scrollAccumulator = 0;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    getOrPut(() => ChatFlagController());
    getOrPut(() => ChatPinArchiveController());
    getOrPut(() => CallController());
    if (widget.isForwardUI != null && (widget.isForwardUI ?? false)) {
      chatViewController.selectedUserIds.clear();
    }
    // Three tabs: Feed, Bites, My Post — clamp any persisted index to range.
    // Community was removed here (SOCIAL_SECTION_INTEGRATION_GUIDE.md §1);
    // ChannelFeedScreen itself is untouched and still reachable elsewhere.
    final rawIndex = chatViewController.selectedChatTabIndex.value;
    final pendingIndex = (rawIndex >= 0 && rawIndex < 3) ? rawIndex : 0;
    chatViewController.chatMainTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: pendingIndex,
    );

    chatViewController.chatMainTabController?.addListener(() {
      if (!(chatViewController.chatMainTabController?.indexIsChanging ??
              false) &&
          chatViewController.chatMainTabController?.index ==
              chatViewController.chatMainTabController?.animation?.value
                  .round()) {
        final index = chatViewController.chatMainTabController?.index;
        chatViewController.onSelectChatTab(index ?? 0);
        // Social / Community tabs are feed-based — no ChatList emit needed.
      }
    });
  }

  bool _isFromForward() {
    return (widget.isForwardUI != null && (widget.isForwardUI ?? false));
  }

  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final tabController = chatViewController.chatMainTabController;
    return WillPopScope(
      onWillPop: () async {
        if (chatViewController.chatMainTabController?.index == 0) {
          bottomBarController.onChangeIndex(0);
        } else {
          chatViewController.chatMainTabController?.animateTo(0);
        }
        return false;
      },
      child: Scaffold(
        // Transparent so the app-wide background banner (AppHomeBackground)
        // shows through and the glass header below can frost it.
        backgroundColor: Colors.white,
        body: SafeArea(
          // Top inset is handled manually inside the glass header so the
          // frosted glass extends behind the status bar (like the Me tab)
          // while the search row + tabs stay below the notch.
          top: false,
          child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: Column(
                children: [
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          // Soft top-to-bottom frost gives the glass a little
                          // depth instead of a flat wash; a hairline edge seats
                          // it against the content below.
                          //
                          // The bottom stop is no longer as light as it was:
                          // the tab strip moved into the pane, and it sits at
                          // exactly that end. The search row could afford the
                          // thinner frost because its field carries its own
                          // glass pill; bare tab labels can't, and on a dark
                          // banner they were reading on nearly nothing.
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.58),
                              Colors.white.withValues(alpha: 0.50),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black.withValues(alpha: 0.06),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Frosted status-bar inset — stays even when the
                            // search row collapses, keeping the tabs below it.
                            SizedBox(height: topInset),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: _isSearchVisible
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: _buildHeader(context),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            if (tabController != null)
                              AnimatedBuilder(
                                animation: tabController,
                                builder: (context, _) => TabBar(
                                  onTap: (index) {
                                    // Reveal the search header again when
                                    // switching tabs.
                                    if (!_isSearchVisible) {
                                      setState(() => _isSearchVisible = true);
                                      _scrollAccumulator = 0;
                                    }
                                    if (widget.isNewGroupUI != null &&
                                        widget.isNewGroupUI == true) {
                                      if (chatViewController
                                          .selectedChatList.isNotEmpty) {
                                        commonSnackBar(
                                            message: AppStrings
                                                .cantSelectBothChatTypes.tr);
                                        chatViewController.selectedUserIds
                                            .clear();
                                      }
                                    }
                                  },
                                  controller: tabController,
                                  padding: EdgeInsets.zero,
                                  labelPadding: EdgeInsets.zero,
                                  tabAlignment: TabAlignment.fill,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  // Rounded cap, and inset from the tab edges
                                  // so the bar sits under the label rather than
                                  // running the full third of the strip.
                                  indicator: UnderlineTabIndicator(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: BorderSide(
                                      width: 3,
                                      color: AppColors.primaryColor,
                                    ),
                                    insets: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.size18),
                                  ),
                                  // Grey track the indicator rides on. It was
                                  // transparent while the indicator was a bare
                                  // line; with a rounded bar the track is what
                                  // shows the other two tabs' extent.
                                  dividerColor: AppColors.greyE5,
                                  dividerHeight: 2,
                                  tabs: [
                                    _socialTab(
                                      icon: AppIconAssets.tabFeed,
                                      activeIcon: AppIconAssets.tabFeedActive,
                                      label: AppStrings.feed.tr,
                                      index: 0,
                                      controller: tabController,
                                    ),
                                    _socialTab(
                                      icon: AppIconAssets.tabBites,
                                      activeIcon: AppIconAssets.tabBitesActive,
                                      label: AppStrings.bites.tr,
                                      index: 1,
                                      controller: tabController,
                                    ),
                                    _socialTab(
                                      icon: AppIconAssets.tabMyPost,
                                      activeIcon: AppIconAssets.tabMyPostActive,
                                      label: AppStrings.myPost.tr,
                                      index: 2,
                                      controller: tabController,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(

                    // Transparent — the app-wide background banner
                    // (AppHomeBackground, set via app_background_screen) shows
                    // behind the feed content, like the rest of the app.
                    //
                    // [GlassScope] turns that from "shows in the gaps" into the
                    // glass look the header already has: the symbol rail, the
                    // post cards and the community sheet all go translucent so
                    // the banner reads THROUGH them. The scope is what keeps
                    // this local — the same widgets stay solid white on post
                    // detail, the repost composer and the profile screens,
                    // which have a plain page behind them. Reels is untouched:
                    // it is full-bleed video on black, with no white chrome to
                    // convert.
                    child: GlassScope(
                      enabled: true,
                      child: TabBarView(
                        controller: chatViewController.chatMainTabController,
                        children: [
                          HomeFeedScreenNew(
                            key: const ValueKey('orderMain_feed_social'),
                            postFilterType: PostType.all,
                            headerHeight: 0,
                            isInParentScroll: false,
                          ),
                          ReelsTabScreen(
                            key: const ValueKey('reels_tab_screen'),
                          ),
                          const MyPostTabScreen(
                            key: ValueKey('orderMain_my_post'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  (widget.isForwardUI != null && (widget.isForwardUI ?? false))
                      ? Obx(() {
                          return InkWell(
                            onTap: (chatViewController
                                    .selectedUserIds.isNotEmpty)
                                ? () async {
                                    if (widget.isNewGroupUI != null &&
                                        (widget.isNewGroupUI ?? false)) {
                                      // Navigator.push(
                                      //     context,
                                      //     MaterialPageRoute(
                                      //         builder: (context) => AddNewGroupPage(selectedUserIds: se,)));
                                    } else {
                                      Map<String, dynamic> data = {
                                        ApiKeys.forward_id: chatThemeController
                                            .selectedMessageIds,
                                        ApiKeys.forward_to_conversations:
                                            chatViewController.selectedUserIds,
                                        // ApiKeys.additional_message: "${widget.message?.messageType}"
                                        // ApiKeys.additional_message: "${widget.message?.messageType}"
                                      };

                                      bool value = await chatViewController
                                          .forwardMessageApi(data);

                                      if (value) {
                                        chatViewController.emitEvent(
                                            ChatEmitEvents.ChatList, {
                                          ApiKeys.type:
                                              AppConstants.personal_Chat_Type
                                        });
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      }
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: EdgeInsets.all(14),
                              margin: EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                  color: chatViewController
                                          .selectedUserIds.isNotEmpty
                                      ? AppColors.primaryColor
                                      : chatThemeController
                                          .myMessageBgColor.value,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText(
                                    (widget.isNewGroupUI != null &&
                                            (widget.isNewGroupUI ?? false))
                                        ? ""
                                        : "${chatViewController.selectedUserIds.length} ${AppStrings.forward.tr}",
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  (widget.isNewGroupUI != null &&
                                          (widget.isNewGroupUI ?? false))
                                      ? Icon(
                                          Icons.arrow_right_alt,
                                          size: 26,
                                          color: Colors.white,
                                        )
                                      : SvgPicture.asset(
                                          height: 18,
                                          width: 18,
                                          AppIconAssets.send_message_chat),
                                ],
                              ),
                            ),
                          );
                        })
                      : SizedBox()
                ],
              ),
            ),
        ),
      ),
    );
  }

  /// One Social-section tab: glyph beside its label, both tinted by selection.
  ///
  /// [controller] is read (not just listened to) so the colour is correct on
  /// the very first paint; the enclosing AnimatedBuilder handles every paint
  /// after that.
  /// Grey the resting tab glyphs are drawn in. The label matches it so the icon
  /// and its text read as one unit rather than two slightly different greys.
  static const Color _tabRestingColor = Color(0xFF66727E);

  Widget _socialTab({
    required String icon,
    required String activeIcon,
    required String label,
    required int index,
    required TabController controller,
  }) {
    final bool selected = controller.index == index;
    final Color color = selected ? AppColors.primaryColor : _tabRestingColor;

    return Tab(
      height: SizeConfig.size48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Swap the asset rather than tinting one: these glyphs carry their own
          // colours, and an `imgColor` would flatten every path to a single
          // shade.
          LocalAssets(
            imagePath: selected ? activeIcon : icon,
            height: SizeConfig.size20,
            width: SizeConfig.size20,
          ),
          SizedBox(width: SizeConfig.size6),
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        (_isFromForward())
            ? InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios),
              )
            : const SizedBox.shrink(),
        InkWell(
          onTap: () => Get.to(() => const ChatRequestsScreen()),
          customBorder: const CircleBorder(),
          child: _glassCircle(
            child: const Icon(
              Icons.mail_outline,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: _glassPill(
            // Type-ahead over posts/videos (search-service/search/content) plus
            // people, with its own floating suggestion panel — see
            // docs/backend/CONTENT_SEARCH_INTEGRATION.md.
            child: const ContentSearchField(),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        // "+" — same PostCreationMenu popup (message / poll / job post / symbol).
        PopupMenuButton<PostCreationMenu>(
          padding: EdgeInsets.zero,
          offset: const Offset(0, 36),
          color: AppColors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (value) async {
            if (isGuestUser()) {
              createProfileScreen();
            } else if (value == PostCreationMenu.message ||
                value == PostCreationMenu.poll ||
                value == PostCreationMenu.reel) {
              // Straight to the composer as a profile post — no channel /
              // profile chooser. `postVia()` would still raise that dialog for
              // an individual who happens to have a channel; the Social section
              // is the user's own feed, so everything created here is attributed
              // to the profile. Other entry points (the global app bar, the Me
              // dashboards) keep the chooser.
              postNavigations(context, value, PostVia.profile);
            } else if (value == PostCreationMenu.jobPost) {
              Get.toNamed(
                RouteHelper.getCreateJobPostScreenRoute(),
                arguments: {
                  'isEditMode': false,
                  'jobId': '',
                  'createJobVia': 'business',
                },
              );
            } else if (value == PostCreationMenu.symbol) {
              Get.to(() => AddChatSymbolScreen());
            }
          },
          itemBuilder: (context) => PopupMenuBuilders.popupMenuItems(),
          child: LocalAssets(
            imagePath: AppIconAssets.addOutlinedIcon,
            width: 32,
            height: 32,
            // imgColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  /// Circular frosted-glass chip for the header icons — same recipe as the
  /// "Me" screen header buttons (translucent white over the blurred banner,
  /// hairline border, faint lift).
  Widget _glassCircle({required Widget child, Color? borderColor}) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: CircleBorder()),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: SizeConfig.size36,
            width: SizeConfig.size36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(
                color: borderColor ?? const Color(0xFFC9CDD5),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Rounded frosted-glass pill — same chip treatment as [_glassCircle], used
  /// to wrap the search field so the trio reads as one glass family.
  Widget _glassPill({required Widget child}) {
    final radius = BorderRadius.circular(14);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(color: const Color(0xFFC9CDD5), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
