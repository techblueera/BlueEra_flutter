import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/chat/view/personal_chat/chat_requests_screen.dart';
import 'package:BlueEra/features/common/channel_feed_view/channel_feed_screen.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../../core/constants/getx_utils.dart';
import '../../../core/constants/shared_preference_utils.dart';
import '../../../core/constants/snackbar_helper.dart';
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
   ChatViewController  chatViewController = getOrPut(() => ChatViewController());
   ChatThemeController chatThemeController = getOrPut(() => ChatThemeController());

   final addSymbolController = getOrPut(() => AddChatSymbolController());
  final bottomBarController = getOrPut(() => BottomBarController());



  @override
  void initState() {

    super.initState();
    addSymbolController.getSymbolsForPartUser(userId);

    getOrPut(() => ChatFlagController());
    getOrPut(() => ChatPinArchiveController());
    getOrPut(() => CallController());
    if (widget.isForwardUI != null && (widget.isForwardUI ?? false)) {
      chatViewController.selectedUserIds.clear();
    }
    // Leads tab is commented out — clamp any persisted index to the new range.
    final rawIndex = chatViewController.selectedChatTabIndex.value;
    final pendingIndex = (rawIndex >= 0 && rawIndex < 2) ? rawIndex : 0;
    chatViewController.chatMainTabController = TabController(
      length: 2,
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
    return WillPopScope(
      onWillPop: () async{
        if(chatViewController.chatMainTabController?.index==0){
          bottomBarController.onChangeIndex(0);
        }else{
          chatViewController.chatMainTabController?.animateTo(0);
        }
        return false;
      },
      child: Scaffold(
        // floatingActionButton: (_isFromForward()) ||
        //     chatViewController.chatMainTabController?.index == 1 ||
        //     chatViewController.chatMainTabController?.index == 2 ||
        //     isSelectionMode
        //     ? SizedBox()
        //     : SafeArea(
        //   child: Padding(
        //       padding:
        //       const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
        //       child: FloatingActionButton(
        //         child: Icon(Icons.add),
        //         backgroundColor: AppColors.primaryColor,
        //         foregroundColor: Colors.white,
        //         onPressed: () {
        //           Get.toNamed(RouteHelper.getChatContactsRoute());
        //         },
        //       )),
        // ),
        body: SafeArea(
          child: BottomNavHideOnScroll(
            child: Column(
              children: [
                // Fixed search-bar header — kept outside the tab scrollables so
                // it can't get "stuck" in a half-collapsed state when the inner
                // ListView/CustomScrollView (each with its own ScrollController)
                // fails to coordinate with NestedScrollView's outer position.
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: _buildHeader(context),
                ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    onTap: (index) {
                      if (widget.isNewGroupUI != null &&
                          widget.isNewGroupUI == true) {
                        if (chatViewController.selectedChatList.isNotEmpty) {
                          commonSnackBar(
                              message: "You can't select personal & business both");
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
                    tabs: const [
                      Tab(text: "Social"),
                      Tab(text: "Community"),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.white,
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
                      ],
                    ),
                  ),
                ),
                (widget.isForwardUI != null && (widget.isForwardUI ?? false))
                    ?
                    Obx(() {
                      return InkWell(
                        onTap: (chatViewController.selectedUserIds.isNotEmpty)
                            ? () async
                        {
                          if (widget.isNewGroupUI != null &&
                              (widget.isNewGroupUI ?? false)) {
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //         builder: (context) => AddNewGroupPage(selectedUserIds: se,)));
                          } else {
                            Map<String, dynamic> data = {
                              ApiKeys.forward_id:
                              chatThemeController.selectedMessageIds,
                              ApiKeys.forward_to_conversations:
                              chatViewController.selectedUserIds,
                              // ApiKeys.additional_message: "${widget.message?.messageType}"
                              // ApiKeys.additional_message: "${widget.message?.messageType}"
                            };

                            bool value = await chatViewController
                                .forwardMessageApi(data);

                            if (value) {
                              chatViewController.emitEvent(
                                  ChatEmitEvents.ChatList,
                                  {ApiKeys.type: AppConstants.personal_Chat_Type});
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
                              color: chatViewController.selectedUserIds.isNotEmpty
                                  ? AppColors.primaryColor
                                  : chatThemeController.myMessageBgColor.value,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                (widget.isNewGroupUI != null &&
                                    (widget.isNewGroupUI ?? false))
                                    ? ""
                                    : "${chatViewController.selectedUserIds.length} Forward",
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
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: CommonSearchBar(
            onChange: (value) => chatViewController.onSearchChatList(value),
            borderRadius: 8,
            backgroundColor: AppColors.greyFill.withValues(alpha: 0.3),
            controller: TextEditingController(),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Get.to(() => const ChatRequestsScreen()),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: Icon(
              Icons.mail_outline,
              size: 24,
              color: Colors.black,
            ),
          ),
        ),
        // Mirrors `CommonBackAppBar`'s `isMore == true` slot — same "+" icon,
        // same PostCreationMenu popup with message/poll/job-post/symbol.
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
                value == PostCreationMenu.poll) {
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
          child: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: LocalAssets(
              imagePath: AppIconAssets.addOutlinedIcon,
              imgColor: AppColors.primaryColor,
            ),
          ),
        ),

        // if (!_isFromForward())
        //   InkWell(
        //     onTap: () {
        //       showDialog(
        //         context: context,
        //         builder: (context) => ReceivedRequestsDialog(),
        //       );
        //     },
        //     child: SvgPicture.asset(AppIconAssets.chat_receive_req,
        //         color: Colors.black),
        //   ),
        // if (!_isFromForward()) SizedBox(width: 18),
      ],
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
