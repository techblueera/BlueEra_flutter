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
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/reel/view/shorts/reels_tab_screen.dart';
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

class OrderMainChatScreen extends StatefulWidget {
  const OrderMainChatScreen({
    super.key,
    this.isNewGroupUI,
    this.isForwardUI = false,
  });

  final bool? isForwardUI;
  final bool? isNewGroupUI;

  @override
  _OrderMainChatScreenState createState() => _OrderMainChatScreenState();
}

class _OrderMainChatScreenState extends State<OrderMainChatScreen>
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
    // Three tabs: Social, Community, Reels — clamp any persisted index to range.
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
        backgroundColor: Colors.transparent,
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
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.32),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    // Solid white tab strip — matches the Me-screen tabs
                    // (grocery_screen). Only the header above is glass.
                    color: Colors.white,
                    child: TabBar(
                      onTap: (index) {
                        // Reveal the search header again when switching tabs.
                        if (!_isSearchVisible) {
                          setState(() => _isSearchVisible = true);
                          _scrollAccumulator = 0;
                        }
                        if (widget.isNewGroupUI != null &&
                            widget.isNewGroupUI == true) {
                          if (chatViewController.selectedChatList.isNotEmpty) {
                            commonSnackBar(
                                message: AppStrings.cantSelectBothChatTypes.tr);
                            chatViewController.selectedUserIds.clear();
                          }
                        }
                      },
                      controller: chatViewController.chatMainTabController,
                      labelColor: Colors.black,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Colors.lightBlue,
                      tabs: [
                        Tab(text: AppStrings.social.tr),
                        Tab(text: AppStrings.community.tr),
                        Tab(text: "Bites"),
                      ],
                    ),
                  ),
                  Expanded(
                    // Transparent — the app-wide background banner
                    // (AppHomeBackground, set via app_background_screen) shows
                    // behind the feed content, like the rest of the app.
                    child: TabBarView(
                      controller: chatViewController.chatMainTabController,
                      children: [
                        HomeFeedScreenNew(
                          key: const ValueKey('orderMain_feed_social'),
                          postFilterType: PostType.all,
                          headerHeight: 0,
                          isInParentScroll: false,
                        ),
                        ChannelFeedScreen(
                          key: const ValueKey('orderMain_feed_community'),
                          headerHeight: 0,
                        ),
                        ReelsTabScreen(
                          key: const ValueKey('reels_tab_screen'),
                        ),
                      ],
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        (_isFromForward())
            ? InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios),
              )
            : const SizedBox.shrink(),
        // Profile (symbol avatar + drawer trigger) was here.
        // Moved to ConnectMainPage so the drawer is reachable from the
        // app's top-level Connect tab. Keeping the original code as a
        // reference in case we need to restore it on this screen:
        //
        // : Obx(() {
        //   return Stack(
        //     children: [
        //       Padding(
        //         padding: const EdgeInsets.only(right: 1.0, top: 3),
        //         child: InkWell(
        //           onTap: () => _openProfileDrawer(context),
        //           borderRadius: BorderRadius.circular(20),
        //           child: Container(
        //             padding: const EdgeInsets.all(2.4),
        //             decoration: addSymbolController.mySymbols.isNotEmpty
        //                 ? const BoxDecoration(
        //               shape: BoxShape.circle,
        //               gradient: SweepGradient(
        //                 startAngle: 0.0,
        //                 endAngle: 6.28319,
        //                 colors: [
        //                   AppColors.symbolBorderRed,
        //                   AppColors.symbolBorderBlue,
        //                   AppColors.symbolBorderYellow,
        //                   AppColors.symbolBorderGreen,
        //                   AppColors.symbolBorderRed,
        //                 ],
        //               ),
        //             )
        //                 : null,
        //             child: Container(
        //               padding: const EdgeInsets.all(2),
        //               decoration: const BoxDecoration(
        //                 shape: BoxShape.circle,
        //                 color: Colors.white,
        //               ),
        //               child: CachedAvatarWidget(
        //                 imageUrl: Get
        //                     .find<AuthController>()
        //                     .imgPath
        //                     .value,
        //                 size: SizeConfig.size36,
        //                 borderRadius: SizeConfig.size34 / 2,
        //                 showProfileOnFullScreen: false,
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //       Positioned(
        //           top: 0,
        //           right: 0,
        //           child: InkWell(
        //             onTap: () {
        //               Get.to(()=>AddChatSymbolScreen());
        //             },
        //             child: Container(
        //               decoration: BoxDecoration(
        //                   borderRadius: BorderRadius.circular(4),
        //                   color: AppColors.primaryColor),
        //               padding: EdgeInsets.all(1.4),
        //               child: Icon(
        //                 Icons.add,
        //                 color: AppColors.white,
        //                 size: 15,
        //               ),
        //             ),
        //           ))
        //     ],
        //   );
        // }),
        // Line-up: mail (left) · search (middle) · "+" (right) — each a
        // frosted-glass chip, matching the Me-screen header items.
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
              postVia(context, value);
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
          child: _glassCircle(
            child: LocalAssets(
              imagePath: AppIconAssets.addOutlinedIcon,
              width: 18,
              height: 18,
              imgColor: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Circular frosted-glass chip for the header icons — same recipe as the
  /// "Me" screen header buttons (translucent white over the blurred banner,
  /// hairline border, faint lift).
  Widget _glassCircle({required Widget child}) {
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
              border: Border.all(color: const Color(0xFFC9CDD5), width: 1),
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

// Profile drawer methods moved to ConnectMainPage. Kept here as a
// reference in case we need to restore the in-screen drawer.
/*
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
                    // Profile header
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
                          // const SizedBox(height: 10),
                          // CustomText(
                          //   userNameGlobal.isNotEmpty
                          //       ? userNameGlobal
                          //       : 'User',
                          //   fontSize: 16,
                          //   fontWeight: FontWeight.w700,
                          //   color: Colors.black,
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          // ),
                          // const SizedBox(height: 2),
                          // Row(
                          //   children: [
                          //     Container(
                          //       width: 7,
                          //       height: 7,
                          //       decoration: const BoxDecoration(
                          //         shape: BoxShape.circle,
                          //         color: AppColors.green0B,
                          //       ),
                          //     ),
                          //     const SizedBox(width: 5),
                          //     CustomText(
                          //       'Online',
                          //       fontSize: 12,
                          //       color: AppColors.secondaryTextColor,
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Menu items
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
                                final ctrl =
                                    Get.isRegistered<AddChatSymbolController>()
                                        ? Get.find<AddChatSymbolController>()
                                        : Get.put(AddChatSymbolController());
                                Get.to(() =>
                                    SymbolViewImages(mySymbols: ctrl.mySymbols));
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
  */
}
