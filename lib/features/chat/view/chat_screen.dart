import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/contacts/view/contact_list_page.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_profile.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_profile.dart';
import 'package:BlueEra/features/chat/view/widget/receive_req_dialoge.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../core/api/apiService/api_keys.dart';
import '../../../core/constants/app_icon_assets.dart';
import '../../../core/constants/snackbar_helper.dart';
import '../../../core/routes/route_helper.dart';
import '../../../widgets/common_search_bar.dart';
import '../../../widgets/custom_text_cm.dart';
import '../auth/controller/chat_theme_controller.dart';
import '../auth/controller/chat_view_controller.dart';
import '../auth/controller/group_chat_view_controller.dart';
import '../auth/model/GetListOfMessageData.dart';
import 'business_chat/business_chat_list.dart';

class ChatMainScreen extends StatefulWidget {
  const ChatMainScreen(
      {super.key,
      this.forwardId,
      this.isNewGroupUI,
      this.message,
      this.isForwardUI});

  final String? forwardId;
  final bool? isForwardUI;
  final bool? isNewGroupUI;
  final Messages? message;

  @override
  _ChatMainScreenState createState() => _ChatMainScreenState();
}

class _ChatMainScreenState extends State<ChatMainScreen>
    with SingleTickerProviderStateMixin {
  final chatViewController = Get.find<ChatViewController>();
  final groupChatViewController = Get.find<GroupChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();

  @override
  void initState() {
    super.initState();
    if (widget.isForwardUI != null && (widget.isForwardUI ?? false)) {
      chatViewController.selectedUserIds.clear();
    } else {
      chatViewController.socketConnected.value = false;
    }
    chatViewController.chatMainTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: chatViewController.selectedChatTabIndex.value,
    );

    chatViewController.chatMainTabController.addListener(() {

      if (!chatViewController.chatMainTabController.indexIsChanging &&
          chatViewController.chatMainTabController.index ==
              chatViewController.chatMainTabController.animation?.value
                  .round()) {
        final index = chatViewController.chatMainTabController.index;
        chatViewController.onSelectChatTab(index);
        if (index == 0) {
          chatViewController.emitEvent("ChatList", {ApiKeys.type: "personal"});
        }
        /* else if (index == 1) {
          groupChatViewController
              .emitEvent("ChatList", {ApiKeys.type: "group"});
        } */
        else if (index == 1) {

          chatViewController.emitEvent("ChatList", {ApiKeys.type: "business"});
        }
      }
    });
  }

  bool _isFromForward() {
    return (widget.isForwardUI != null && (widget.isForwardUI ?? false));
  }

  @override
  void dispose() {
    // chatViewController.chatMainTabController.removeListener((){});
    // chatViewController.chatMainTabController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: (_isFromForward())
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
      bottomSheet: Padding(padding: EdgeInsets.only(bottom: 120.0)),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      (_isFromForward())
                          ? InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(Icons.arrow_back_ios))
                          : Obx(() {
                              return CachedAvatarWidget(
                                  imageUrl:
                                      Get.find<AuthController>().imgPath.value,
                                  size: SizeConfig.size30,
                                  borderRadius: 5.0,
                                  showProfileOnFullScreen: false);
                            }),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CommonSearchBar(
                            onChange: (value) {
                              chatViewController.onSearchChatList(value);
                            },
                            borderRadius: 8,
                            backgroundColor:
                                AppColors.greyFill.withValues(alpha: 0.3),
                            controller: TextEditingController(),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      (_isFromForward())
                          ? SizedBox()
                          : InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      ReceivedRequestsDialog(),
                                );
                              },
                              child: SvgPicture.asset(
                                  AppIconAssets.chat_receive_req,
                                  color: Colors.black)),
                      (_isFromForward())
                          ? SizedBox()
                          : const SizedBox(
                              width: 18,
                            ),
                      (_isFromForward())
                          ? SizedBox()
                          : SizedBox() /*PopupMenuButton<String>(
                              icon: SvgPicture.asset(
                                AppIconAssets.chat_info_more,
                                color: Colors.black,
                              ),
                              onSelected: (value) {
                                if (value == "create_group") {
                                  Get.to(() => ContactsPage(
                                        from: 'Group',
                                      ));

                                  ///  Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessChatProfile(userId: '',),));
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (context) => ChatMainScreen(
                                  //               isNewGroupUI: true,
                                  //               isForwardUI: true,
                                  //               message: chatThemeController
                                  //                   .selectedFirstMessage
                                  //                   ?.value,
                                  //               forwardId: chatThemeController
                                  //                       .selectedFirstMessage
                                  //                       ?.value
                                  //                       ?.id ??
                                  //                   '',
                                  //             )));
                                } else if (value == "settings") {
                                  print("Open settings");
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: "create_group",
                                  child: Text("New Group"),
                                ),
                              ],
                            ),*/
                    ],
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                TabBar(
                  onTap: (index) {
                    if (widget.isNewGroupUI != null &&
                        widget.isNewGroupUI == true) {
                      if (chatViewController.selectedChatList.isNotEmpty) {
                        commonSnackBar(
                            message:
                                "You can't select personal & business both");
                        chatViewController.selectedUserIds.clear();
                      }
                    }
                  },
                  controller: chatViewController.chatMainTabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 0,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.lightBlue,
                  labelPadding: EdgeInsets.all(0),
                  physics: BouncingScrollPhysics(),
                  // allow swipe
                  indicatorPadding: EdgeInsets.only(right: 2),
                  labelStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: "Personal"),
                    // Tab(text: "Group"),
                    Tab(text: "Business"),
                    Tab(text: "Orders"),
                  ],
                ),
                Divider(height: 1, color: Colors.blue[50]),
                Expanded(
                  child: TabBarView(
                      controller: chatViewController.chatMainTabController,
                      children: [
                        PersonalChatsList(
                            isForwardUI: widget.isForwardUI,
                            isNewGroupUI: widget.isNewGroupUI),
                        // GroupChatList(),
                        BusinessChatsList(
                          isForwardUI: widget.isForwardUI,
                          isNewGroupUI: widget.isNewGroupUI,
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppIconAssets.chat,
                                color: Colors.black,
                                height: 70,
                                width: 70,
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              CustomText(
                                "Coming Soon",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              CustomText(
                                  "Thanks for your patience we will update soon"),
                              const SizedBox(
                                height: 6,
                              ),
                            ],
                          ),
                        )
                        // OrdersTabView()
                      ]),
                )
              ],
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
                            ApiKeys.forward_id: chatThemeController.selectedId,
                            ApiKeys.forward_to_conversations:
                                chatViewController.selectedUserIds,
                            // ApiKeys.additional_message: "${widget.message?.messageType}"
                            // ApiKeys.additional_message: "${widget.message?.messageType}"
                          };

                          bool value =
                              await chatViewController.forwardMessageApi(data);
                          print("dfncvkdjfvdf ${value}");

                          if (value) {
                            chatViewController.emitEvent(
                                "ChatList", {ApiKeys.type: "personal"});
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
    );
  }
}
