
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/component_widgets.dart';
import '../widget/group_chat_input_box.dart';
import '../widget/group_message_card.dart';

class GroupChatScreen extends StatefulWidget {
  GroupChatScreen({
    required this.conversationId,
    this.profileImage,
    required this.type,
    this.name,
  });

  final String? conversationId;
  final String? profileImage;
  final String? name;
  final String? type;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final Color sentMessageColor = Color(0xFF255DF6);
  final Color receivedMessageColor = Color(0xFFECECEC);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final TextEditingController editingController=TextEditingController();


  @override
  void initState() {
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value=false;
    chatViewController.listenUserNewMessages(userId: "",
        conversationId: widget.conversationId ?? '');
    chatThemeController.resetSelection();

    checkPendingMessages();
    super.initState();
  }


  Future<void> checkPendingMessages()async{
    final connectivityResult = await NetworkUtils.isConnected();
    if(!connectivityResult){
      chatViewController.sendOfflineMessage(widget.conversationId??"");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  void launchDialPad(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch dialer';
    }
  }

  void _navigateToProfile({required String authorId}) {
    // Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewGroupMembers(
    //   conversationId: widget.conversationId,
    //   type: widget.type,
    //   name: widget.name,
    //   profileImage: widget.profileImage,
    // )));

  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        chatViewController.emitEvent(
            "ChatList", {ApiKeys.type: "group"}, true);
        return true;
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: (chatThemeController.isMessageSelectionActive.value &&
              widget.type != "Admin")
              ? getChatOptionsAppBar(
              context,
              profileImage: widget.profileImage,
              editingController: editingController,
              conversationId: widget.conversationId,
              userId: '',
              type: widget.type,
              name: widget.name,
              contactNo: '')
              : getChatTitleAppBar(context,
              userId: '',
              isGroupAppBar: true,
              type: widget.type,
              name: widget.name,
              profileImage: widget.profileImage,
              contactNo: '', conversationId: widget.conversationId),
          body: Obx(() {
            
            if (chatViewController.getListOfMessageResponse.value.status ==
                Status.COMPLETE) {
              List<Messages> messages = chatViewController
                  .getListOfMessageData??[];
              messages.sort((a, b) {
                final dateA = (a.createdAt != null && a.createdAt!.isNotEmpty)
                    ? DateTime.parse(a.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                final dateB = (b.createdAt != null && b.createdAt!.isNotEmpty)
                    ? DateTime.parse(b.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                return dateA.compareTo(dateB); // descending
              });
              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppImageAssets.chating_bg,
                      fit: BoxFit.cover,
                      width: SizeConfig.screenWidth,
                      height: SizeConfig.screenHeight,
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: (messages.isEmpty)? Center(
                            child: InkWell(
                              onTap: (){
                                Map<String,dynamic> data = {
                                  ApiKeys.conversation_id: widget.conversationId,
                                  ApiKeys.message: "Namaste 🙏",
                                  ApiKeys.message_type: "text",
                                };
                                chatViewController.sendInitialMessage(data);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5), // light color with 0.5 opacity
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "No conversation yet. ",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "Say Namaste 🙏",
                                        style: TextStyle(
                                          color: Colors.blue, // blue from theme
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                ,
                              ),
                            ),
                          )
                              :LayoutBuilder(
                            builder: (context, constraints) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.zero,
                                      controller:
                                      chatViewController.scrollController,
                                      reverse: true,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .end,
                                        children: messages.map((message) {
                                          return GroupMessageCard(
                                            message: message,
                                            isInitialMessage: false,
                                            conversationId: widget.conversationId,
                                            userId: '',
                                            name: widget.name,
                                            contactNo: '',
                                            profileImage: widget.profileImage,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        GroupChatInputBar(
                          isInitialMessage: false,
                          userId: '',
                          conversationId: widget.conversationId ?? '',
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return SafeArea(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        AppImageAssets.chating_bg,
                        fit: BoxFit.cover,
                        width: SizeConfig.screenWidth,
                        height: SizeConfig.screenHeight,
                      ),
                      Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    ],
                  ));
            }
          }),
        );
      }),
    );
  }

  void showMessageEditDialog(
      ){
    Get.dialog(
      AlertDialog(
        insetPadding:  EdgeInsets.symmetric( vertical: 12), // Reduced outer spacing
        contentPadding: const EdgeInsets.only(bottom: 10),
        backgroundColor: AppColors.appBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    'Message',
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: AppColors.greyB4),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextFormField(
                controller: editingController,
                maxLines: 6,
                minLines: 6,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    child: CustomText(
                      'Close',
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: ()async {
                      ApiKeys;
                      Map<String,dynamic> data={
                        ApiKeys.id: "${chatThemeController.selectedFirstMessage?.value?.id}",
                        ApiKeys.type: "message",
                        ApiKeys.message: "${editingController.text}"
                      };
                      bool value =await chatViewController.updateMessageApi(data);
                      if(value){
                        chatViewController.emitEvent("messageReceived", {
                          ApiKeys.conversation_id: widget.conversationId,
                          ApiKeys.page: 1,
                          ApiKeys.is_online_user: '',
                          ApiKeys.per_page_message: 30,
                        });
                        chatThemeController.resetSelection();
                        Get.back();
                      }
                    },
                    child: CustomText(
                      'Edit',
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      useSafeArea: true,
    );

  }





}


