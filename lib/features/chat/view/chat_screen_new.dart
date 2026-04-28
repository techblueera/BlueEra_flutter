import 'dart:convert';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/chat/view/orders_chat/orders_chat_list.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/check_internet_connectivity.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../../core/constants/getx_utils.dart';
import '../../../core/constants/snackbar_helper.dart';
import '../../../core/routes/route_helper.dart';
import '../../../widgets/custom_text_cm.dart';
import '../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../auth/controller/add_chat_symbol_controller.dart';
import '../auth/controller/chat_flag_controller.dart';
import '../auth/controller/chat_pin_archive_controller.dart';
import '../auth/model/GetChatListModel.dart';
import '../auth/controller/chat_theme_controller.dart';
import '../auth/controller/chat_view_controller.dart';
import 'add_symbol/add_symbol_screen.dart';
import 'find_contacts_with_service/find_contact_with_service.dart';
import 'widget/chat_flag_bottom_sheet.dart';
import 'chat_theme/chat_background_screen.dart';
import 'contacts/view/contact_list_page.dart';
import 'symbol_view/symbol_view_images.dart';
import 'wallet_chat/wallet_chat_screen.dart';
import '../../../features/personal/personal_profile/view/manage_notification/notification.dart';
import 'reminder_chat/reminder_todo_screen.dart';

class NewChatMainScreen extends StatefulWidget {
  const NewChatMainScreen({super.key,
    this.isNewGroupUI,
    this.isForwardUI=false,
    this.onHeaderVisibilityChanged});
  final bool? isForwardUI;
  final bool? isNewGroupUI;
  final Function(bool)? onHeaderVisibilityChanged;


  @override
  _NewChatMainScreenState createState() => _NewChatMainScreenState();
}

class _NewChatMainScreenState extends State<NewChatMainScreen>
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
    final pendingIndex = chatViewController.selectedChatTabIndex.value;
    chatViewController.chatMainTabController = TabController(
      length:3,
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

        if (index == 0) {
          chatViewController.emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.personal_Chat_Type});
        } else if (index == 1) {
          chatViewController.emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.business_Chat_Type});
        } else if (index == 2) {
          chatViewController.emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.order_Chat_Type});
        }
      }
    });

    // If a pending tab index was set before the screen was built (e.g. from
    // order placement), ensure the correct chat list is emitted after the
    // first frame so the UI matches.
    if (pendingIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (chatViewController.chatMainTabController != null &&
            chatViewController.chatMainTabController!.index == pendingIndex) {
          if (pendingIndex == 1) {
            chatViewController.emitEvent(ChatEmitEvents.ChatList,
                {ApiKeys.type: AppConstants.business_Chat_Type});
          } else if (pendingIndex == 2) {
            chatViewController.emitEvent(ChatEmitEvents.ChatList,
                {ApiKeys.type: AppConstants.order_Chat_Type});
          }
        }
      });
    }
    _loadContactsFromStorage();
    // First-time-only contacts sync. On entry to the chat tab we ask for
    // contacts permission, upload the phone book, and persist the response.
    // Subsequent entries short-circuit on the Hive cache and never hit the
    // network again. Offline entries skip the sync entirely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContactsIfNeeded();
    });
  }

  Future<void> _syncContactsIfNeeded() async {
    // Already synced (memory or Hive)? Nothing to do.
    final hydrated = await chatViewController.hydrateContactsFromCache();
    if (hydrated) return;

    // First-time sync needs internet. Offline → skip; ContactsPage will
    // render from cache (empty if none yet).
    final online = await checkInternetStatus();
    if (!online) return;

    // Ask for contacts permission.
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) return;
    }

    // Read the device phone book and upload once.
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withAccounts: true,
    );
    final formatted = contacts
        .where((c) => c.phones.isNotEmpty)
        .map<Map<String, dynamic>>((c) => {
              ApiKeys.contact_no: c.phones.first.number,
              ApiKeys.name: c.displayName,
            })
        .toList();
    if (formatted.isEmpty) return;
    await chatViewController.uploadContacts(formatted);
  }

  List<Map<String, dynamic>> getFormattedContacts(
      List<Map<String, dynamic>> rawContacts) {
    return rawContacts.map((c) {
      final phones = (c["phones"] as List).cast<String>();
      return {
        ApiKeys.name: c["displayName"] ?? "",
        ApiKeys.contactNo: phones.isNotEmpty ? phones.first : "",
      };
    }).toList();
  }

  Future<void> _loadContactsFromStorage() async {
    String? storedData = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.saved_contacts);
    if (storedData != null) {
      Map<String, dynamic> decoded =
      await compute(jsonDecode, storedData) as Map<String, dynamic>;
      chatViewController.loadContactsFromLocalStorage(decoded);
    } else {
      // await _refreshContacts();
    }
  }

  List<Map<String, String>> formatContactsInIsolate(
      List<Map<String, dynamic>> rawContacts) {
    return rawContacts
        .where((c) => (c["phones"] as List).isNotEmpty)
        .map((c) =>
    {
      ApiKeys.contact_no: (c["phones"] as List).first as String,
      ApiKeys.name: c["displayName"] as String,
    })
        .toList();
  }

  bool _isFromForward() {
    return (widget.isForwardUI != null && (widget.isForwardUI ?? false));
  }

  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      widget.onHeaderVisibilityChanged?.call(true);
    });

    return Obx(() {
      final isSelectionMode = chatViewController.isChatListSelectionMode.value;
      final selectedCount = chatViewController.selectedConversationIds.length;

      return WillPopScope(
      onWillPop: () async{
        if (isSelectionMode) {
          chatViewController.exitChatListSelectionMode();
          return false;
        }
        if(chatViewController.chatMainTabController?.index==0){
          bottomBarController.onChangeIndex(0);
        }else{
          chatViewController.chatMainTabController?.animateTo(0);
        }
        return false;
      },
      child: Scaffold(
        floatingActionButton: (_isFromForward()) ||
            chatViewController.chatMainTabController?.index == 1 ||
            chatViewController.chatMainTabController?.index == 2 ||
            isSelectionMode
            ? SizedBox()
            : SafeArea(
          child: Padding(
              padding:
              const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
              child: FloatingActionButton(
                child: Icon(Icons.add),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                onPressed: () {
                  Get.toNamed(RouteHelper.getChatContactsRoute());
                },
              )),
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                if (isSelectionMode)
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0.5,
                    floating: false,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 0,
                    title: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => chatViewController.exitChatListSelectionMode(),
                        ),
                        CustomText(
                          "$selectedCount",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    actions: [
                      _selectionActionIcon(Icons.flag_outlined, () {
                        final ids = chatViewController.selectedConversationIds.toList();
                        if (ids.isEmpty) return;
                        // Show flag bottom sheet for the first selected conversation,
                        // then apply the chosen flag to all selected conversations
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _MultiFlagBottomSheet(
                            conversationIds: ids,
                            onDone: () {
                              chatViewController.exitChatListSelectionMode();
                            },
                          ),
                        );
                      }),
                      _selectionActionIcon(Icons.push_pin_outlined, () {
                        final controller = Get.find<ChatPinArchiveController>();
                        final ids = chatViewController.selectedConversationIds.toList();
                        final isBiz = (chatViewController.chatMainTabController?.index ?? 0) == 1;
                        final allPinned = ids.every((id) => controller.isPinned(id, isBusiness: isBiz));
                        if (allPinned) {
                          controller.unpinMultiple(ids, isBusiness: isBiz);
                        } else {
                          controller.pinMultiple(ids, isBusiness: isBiz);
                        }
                        chatViewController.exitChatListSelectionMode();
                      }),
                      _selectionActionIcon(Icons.volume_off_outlined, () {
                        // Mute action
                      }),
                      _selectionActionIcon(Icons.archive_outlined, () {
                        final controller = Get.find<ChatPinArchiveController>();
                        final ids = chatViewController.selectedConversationIds.toList();
                        final isBiz = (chatViewController.chatMainTabController?.index ?? 0) == 1;
                        controller.archiveMultiple(ids, isBusiness: isBiz);
                        chatViewController.exitChatListSelectionMode();
                      }),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black),
                        offset: const Offset(0, 40),
                        color: Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'mark_unread':
                              break;
                            case 'select_all':
                              final currentTab = chatViewController.chatMainTabController?.index ?? 0;
                              final List<ChatList> allChats;
                              if (currentTab == 1) {
                                allChats = chatViewController
                                    .getBusinessChatListModel?.value.chatList
                                    ?.whereType<ChatList>()
                                    .toList() ?? [];
                              } else {
                                allChats = chatViewController
                                    .getPersonalChatListModel?.value.chatList
                                    ?.whereType<ChatList>()
                                    .toList() ?? [];
                              }
                              chatViewController.selectAllChats(allChats);
                              break;
                            case 'lock_chats':
                              break;
                            case 'add_favourites':
                              break;
                            case 'clear_chats':
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'mark_unread', child: Text('Mark as unread')),
                          const PopupMenuItem(value: 'select_all', child: Text('Select all')),
                          const PopupMenuItem(value: 'lock_chats', child: Text('Lock chats')),
                          const PopupMenuItem(value: 'add_favourites', child: Text('Add to Favourites')),
                          const PopupMenuItem(value: 'clear_chats', child: Text('Clear chats')),
                        ],
                      ),
                    ],
                  )
                else
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  pinned: false,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildHeader(context),
                  ),
                  expandedHeight: 72,
                ),
                if (!isSelectionMode)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
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
                      tabs:  [
                        Tab(text: "Leads"),
                        Tab(text: "Inquiry"),
                        // Tab(text: "Finder"),
                        Tab(text: "Orders"),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Container(
              color: AppColors.white,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: chatViewController.chatMainTabController,
                      children: [
                        PersonalChatsList(isForwardUI: widget.isForwardUI,
                          isNewGroupUI: widget.isNewGroupUI,),
                        BusinessChatsList(isForwardUI: widget.isForwardUI,
                          isNewGroupUI: widget.isNewGroupUI,),
                        // FindContactWithService(fromBottomNav: true),
                        OrdersTabView()
                      ],
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
      ),
    );
    });
  }

  Widget _selectionActionIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.black),
      onPressed: onPressed,
      splashRadius: 20,
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
            : Obx(() {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 1.0, top: 3),
                child: InkWell(
                  onTap: () => _openProfileDrawer(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(2.4),
                    decoration: addSymbolController.mySymbols.isNotEmpty
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
                        imageUrl: Get
                            .find<AuthController>()
                            .imgPath
                            .value,
                        size: SizeConfig.size36,
                        borderRadius: SizeConfig.size34 / 2,
                        showProfileOnFullScreen: false,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      Get.to(()=>AddChatSymbolScreen());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.primaryColor),
                      padding: EdgeInsets.all(1.4),
                      child: Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 15,
                      ),
                    ),
                  ))
            ],
          );
        }),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: CommonSearchBar(
            onChange: (value) => chatViewController.onSearchChatList(value),
            borderRadius: 8,
            backgroundColor: AppColors.greyFill.withValues(alpha: 0.3),
            controller: TextEditingController(),
          ),
        ),
        const SizedBox(width: 18),
        InkWell(
          onTap: () {
            Get.to(() => const ReminderTodoScreen());
          },
          child: const Icon(Icons.lock_clock),
        )
        // InkWell(
        //   onTap: () {
        //     Get.to(FindContactWithService());
        //   },
        //   child: Container(
        //     decoration: BoxDecoration(
        //       // gradient:  LinearGradient(
        //       //   begin: Alignment.bottomCenter,
        //       //   end: Alignment.topCenter,
        //       //   transform: GradientRotation(10),
        //       //   colors: [
        //       //  AppColors.primaryColor.withOpacity(0.1),
        //       //     AppColors.primaryColor.withOpacity(0.05),
        //       //   ],
        //       // ),
        //         borderRadius: BorderRadius.circular(10),
        //         border: Border.all(
        //             color: AppColors.primaryColor
        //         )
        //     ),
        //     margin: EdgeInsets.only(right: 6),
        //     child: Container(
        //       decoration: BoxDecoration(
        //         color: Colors.white, // inner background
        //         borderRadius: BorderRadius.circular(14),
        //       ),
        //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        //       child: Row(
        //         children: [
        //           SvgPicture.asset(AppIconAssets.chat_find,
        //               color: AppColors.primaryColor),
        //           SizedBox(width: 4,),
        //           CustomText("Find",
        //             color: AppColors.primaryColor,),
        //         ],
        //       ),
        //     ),
        //   ),
        // )

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
}

/// Bottom sheet to apply a flag to multiple selected conversations
class _MultiFlagBottomSheet extends StatefulWidget {
  final List<String> conversationIds;
  final VoidCallback onDone;

  const _MultiFlagBottomSheet({
    required this.conversationIds,
    required this.onDone,
  });

  @override
  State<_MultiFlagBottomSheet> createState() => _MultiFlagBottomSheetState();
}

class _MultiFlagBottomSheetState extends State<_MultiFlagBottomSheet> {
  final flagController = Get.find<ChatFlagController>();
  String? selectedFlagId;

  @override
  void initState() {
    super.initState();
    // If all selected conversations have the same flag, pre-select it
    final flags = widget.conversationIds
        .map((id) => flagController.getFlagForConversation(id))
        .toSet();
    if (flags.length == 1 && flags.first != null) {
      selectedFlagId = flags.first!.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                "Label ${widget.conversationIds.length} Chat${widget.conversationIds.length > 1 ? 's' : ''}",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showAddFlagLabelDialog(context, flagController);
                },
                child: const CustomText(
                  "+ New Label",
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: flagController.allFlags.length,
                itemBuilder: (context, index) {
                  final flag = flagController.allFlags[index];
                  final isSelected = selectedFlagId == flag.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedFlagId = isSelected ? null : flag.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? flag.color.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: flag.color, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: flag.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              flag.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              flag.label,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: flag.color, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    for (final id in widget.conversationIds) {
                      flagController.removeFlagFromConversation(id);
                    }
                    Navigator.pop(context);
                    widget.onDone();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText(
                    "Remove Label",
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedFlagId == null
                      ? null
                      : () {
                          final flag = flagController.allFlags
                              .firstWhere((f) => f.id == selectedFlagId);
                          for (final id in widget.conversationIds) {
                            flagController.assignFlagToConversation(id, flag);
                          }
                          Navigator.pop(context);
                          widget.onDone();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText(
                    "Apply",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
