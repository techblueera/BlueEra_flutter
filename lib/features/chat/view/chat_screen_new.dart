import 'dart:convert';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/chat/view/group_chat/group_chat_list.dart';
import 'package:BlueEra/features/chat/view/orders_chat/orders_chat_list.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

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
import 'contacts/view/contact_list_page.dart';
import 'find_contacts_with_service/find_contact_with_service.dart';

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
  late ChatViewController chatViewController;
  late ChatThemeController chatThemeController;
  final addSymbolController = getOrPut(() => AddChatSymbolController());
  final bottomBarController = getOrPut(() => BottomBarController());



  @override
  void initState() {

    super.initState();
    addSymbolController.getSymbolsForPartUser(userId);
    if (Get.isRegistered<ChatViewController>()) {
      chatViewController = Get.find<ChatViewController>();
    } else {
      chatViewController = Get.put(ChatViewController());
    }
    if (!Get.isRegistered<ChatFlagController>()) {
      Get.put(ChatFlagController());
    }
    if (!Get.isRegistered<ChatPinArchiveController>()) {
      Get.put(ChatPinArchiveController());
    }
    if (!Get.isRegistered<CallController>()) {
      Get.put(CallController());
    }
    if (Get.isRegistered<ChatThemeController>()) {
      chatThemeController = Get.find<ChatThemeController>();
    } else {
      chatThemeController = Get.put(ChatThemeController());
    }
    if (widget.isForwardUI != null && (widget.isForwardUI ?? false)) {
      chatViewController.selectedUserIds.clear();
    } else {
      chatViewController.socketConnected.value = false;
    }
    chatViewController.chatMainTabController = TabController(
      length:4,
      vsync: this,
      initialIndex: chatViewController.selectedChatTabIndex.value,
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
              {ApiKeys.type: AppConstants.group_Chat_Type});
        } else if (index == 3) {
          chatViewController.emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.order_Chat_Type});
        }
      }
    });
    _loadContactsFromStorage();
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
                  if (chatViewController.chatMainTabController?.index ==
                      2) {
                    Get.to(ContactsPage(
                      from: "group",
                    ));
                  } else {
                    Get.toNamed(RouteHelper.getChatContactsRoute());
                  }
                  //
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
                      _selectionActionIcon(Icons.label_outline, () {
                        // Label / flag action
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
                        Tab(text: "Personal"),
                        Tab(text: "Business"),
                        Tab(text: "Group"),
                        Tab(text: "Orders"),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: chatViewController.chatMainTabController,
                    children: [
                      PersonalChatsList(isForwardUI: widget.isForwardUI,
                        isNewGroupUI: widget.isNewGroupUI,),
                      BusinessChatsList(isForwardUI: widget.isForwardUI,
                        isNewGroupUI: widget.isNewGroupUI,),
                      GroupChatListTabPage(),
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
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(-6, 42),
                  onSelected: (value) {},
                  icon: Container(
                    padding: const EdgeInsets.all(2.4),
                    // ⭐ ONLY THIS makes big outer circle
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
                        size: SizeConfig.size36, // ⛔ unchanged
                        borderRadius: SizeConfig.size34 / 2,
                        showProfileOnFullScreen: false,
                      ),
                    ),
                  ),
                  itemBuilder: (context) => popupMenuChatCardItems(),
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
            Get.to(FindContactWithService());
          },
          child: Container(
            decoration: BoxDecoration(
              // gradient:  LinearGradient(
              //   begin: Alignment.bottomCenter,
              //   end: Alignment.topCenter,
              //   transform: GradientRotation(10),
              //   colors: [
              //  AppColors.primaryColor.withOpacity(0.1),
              //     AppColors.primaryColor.withOpacity(0.05),
              //   ],
              // ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryColor
                )
            ),
            margin: EdgeInsets.only(right: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // inner background
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  SvgPicture.asset(AppIconAssets.chat_find,
                      color: AppColors.primaryColor),
                  SizedBox(width: 4,),
                  CustomText("Find",
                    color: AppColors.primaryColor,),
                ],
              ),
            ),
          ),
        )

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
