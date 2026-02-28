import 'dart:convert';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/chat/view/group_chat/group_chat_list.dart';
import 'package:BlueEra/features/chat/view/orders_chat/orders_chat_list.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../../core/constants/snackbar_helper.dart';
import '../../../core/routes/route_helper.dart';
import '../../../widgets/custom_text_cm.dart';
import '../auth/controller/add_chat_symbol_controller.dart';
import '../auth/controller/chat_theme_controller.dart';
import '../auth/controller/chat_view_controller.dart';
import '../auth/model/GetListOfMessageData.dart';
import 'add_symbol/add_symbol_screen.dart';
import 'contacts/contact_list_page.dart';
import 'find_contacts_with_service/find_contact_with_service.dart';

class NewChatMainScreen extends StatefulWidget {
  const NewChatMainScreen(
      {super.key,
      this.forwardId,
      this.isNewGroupUI,
      this.message,
      this.isForwardUI,
      this.onHeaderVisibilityChanged});

  final String? forwardId;
  final bool? isForwardUI;
  final bool? isNewGroupUI;
  final Function(bool)? onHeaderVisibilityChanged;
  final Messages? message;

  @override
  _NewChatMainScreenState createState() => _NewChatMainScreenState();
}

class _NewChatMainScreenState extends State<NewChatMainScreen>
    with SingleTickerProviderStateMixin {
  late ChatViewController chatViewController;
  late ChatThemeController chatThemeController;
  final addSymbolController = Get.isRegistered<AddChatSymbolController>()
      ? Get.find<AddChatSymbolController>()
      : Get.put(AddChatSymbolController());

  @override
  void initState() {
    super.initState();
    addSymbolController.getSymbolsForPartUser(userId);
    if (Get.isRegistered<ChatViewController>()) {
      chatViewController = Get.find<ChatViewController>();
    } else {
      chatViewController = Get.put(ChatViewController());
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
      length: 4,
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
        .map((c) => {
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


    return Scaffold(
      floatingActionButton: (_isFromForward()) ||
              chatViewController.chatMainTabController?.index == 1
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
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                floating: true,
                // appear on scroll up
                snap: true,
                // instantly snap down
                pinned: false,
                // don't keep the header fixed
                automaticallyImplyLeading: false,
                flexibleSpace: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _buildHeader(context), // your header row
                ),
                expandedHeight: 72,
              ),
              SliverPersistentHeader(
                pinned: true, // TabBar should always stay visible
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
                    // isScrollable: true,

                    // REMOVE LEFT SPACE
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12), // adjust if needed

                    unselectedLabelColor: Colors.black54,
                    indicatorColor: Colors.lightBlue,
                    tabs: const [
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
                    PersonalChatsList(),
                    BusinessChatsList(),
                    GroupChatListTabPage(),

                    OrdersTabView()
                  ],
                ),
              ),
              (widget.isForwardUI != null && (widget.isForwardUI ?? false))
                  ? Positioned(
                      right: 30,
                      bottom: 28,
                      child: InkWell(
                        onTap: () async {
                          if (widget.isNewGroupUI != null &&
                              (widget.isNewGroupUI ?? false)) {
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //         builder: (context) => AddNewGroupPage(selectedUserIds: se,)));
                          } else {
                            Map<String, dynamic> data = {
                              ApiKeys.forward_id:
                                  chatThemeController.selectedId,
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
                                  {ApiKeys.type: "personal"});
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: chatThemeController.myMessageBgColor.value,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Row(
                              children: [
                                CustomText(
                                  (widget.isNewGroupUI != null &&
                                          (widget.isNewGroupUI ?? false))
                                      ? ""
                                      : "Forward",
                                  color: Colors.white,
                                ),
                                const SizedBox(
                                  width: 4,
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
                        ),
                      ))
                  : SizedBox()
            ],
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
            : Obx(() {
                return Stack(
                  children: [
                Padding(
                  padding: const EdgeInsets.only(right: 1.0,top: 3),
                  child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                    offset: const Offset(-6, 42),
                    onSelected: (value) {},
                    icon: Container(
                      padding: const EdgeInsets.all(2.4), // ⭐ ONLY THIS makes big outer circle
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
                          imageUrl: Get.find<AuthController>().imgPath.value,
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
                            Get.to(AddChatSymbolScreen());
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
          onTap: (){
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
                color:  AppColors.primaryColor
              )
            ),
            margin: EdgeInsets.only(right: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // inner background
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 7),
              child:  Row(
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
