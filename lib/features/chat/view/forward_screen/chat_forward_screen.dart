import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:share_handler/share_handler.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';

import '../../../../core/constants/getx_utils.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../add_symbol/add_symbol_screen.dart';
import '../personal_chat/personal_chat_list.dart';

class ChatForwardScreen extends StatefulWidget {
  const ChatForwardScreen({super.key, this.sharedText, this.sharedFiles, this.maxSelectionCount});
  final String? sharedText;
  final List<SharedAttachment?>? sharedFiles;
  final int? maxSelectionCount;

  @override
  State<ChatForwardScreen> createState() => _ChatForwardScreenState();
}

class _ChatForwardScreenState extends State<ChatForwardScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());
 bool symbolSelected=false;
  @override
  void initState() {
    super.initState();
    chatViewController.selectedUserIds.clear();
    chatViewController.selectedChatList.clear();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        isShadowShow: false,
        title: "Forward to...",
        isForwardUi: true,
      ),
      // AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   leading: const BackButton(color: Colors.black),
      //   title: const Text(
      //     "Forward to...",
      //     style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      //   ),
      //   actions: const [
      //     Icon(Icons.person_add_alt, color: Colors.black),
      //     SizedBox(width: 16),
      //     Icon(Icons.search, color: Colors.black),
      //     SizedBox(width: 12),
      //   ],
      // ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topOptions(),
                  _sectionTitle("Recent chats"),
                  PersonalChatsList(isForwardUI: true),
                ],
              ),
            ),
          ),
          Obx(() {
            return _bottomMessageBar();
          }),
        ],
      ),
    );
  }

  Widget _topOptions() {
    return Column(
      children: [
        _chatTile(
          name: "My symbol",
          subtitle: "My contacts +",
          icon: Icons.account_circle_rounded,
          isGreen: true,
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CustomText(
        title,
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _chatTile({
    required String name,
    String? subtitle,
    String? image,
    IconData? icon,
    bool isGreen = false,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isGreen ? Colors.green : Colors.grey.shade200,
        backgroundImage: image != null ? NetworkImage(image) : null,
        child: icon != null
            ? Icon(icon, color: isGreen ? Colors.white : Colors.black)
            : null,
      ),
      title: CustomText(
        name,
          fontSize: 16,
          fontWeight: FontWeight.w500,
      ),
      subtitle: subtitle != null
          ? CustomText(
        subtitle,
       color: Colors.grey, fontSize: 13
      )
          : null,
      trailing: Theme(
        data: theme.copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: const BorderSide(color: Colors.black),
          ),
        ),
        child: Transform.scale(
          scale: 1.3, // 👈 increase this (1.2 – 1.8 recommended)
          child: Checkbox(
            activeColor: Colors.blue,
            checkColor: Colors.white,
            value: symbolSelected,
            onChanged: (_) {
              setState(() {
                symbolSelected=!symbolSelected;
              });
            },
          ),
        ),
      ),
      onTap: () {
        setState(() {
          symbolSelected=!symbolSelected;
        });
      },
    );
  }

  Widget _bottomMessageBar() {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 35, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CommonTextField(
          //   hintText: "Add Message...",
          //   maxLine: 3,
          // ),
          InkWell(
            onTap: ()async{
              if(symbolSelected==true){
                Get.to(()=>AddChatSymbolScreen());
              }else{
                if(widget.sharedFiles!=null||widget.sharedText!=null){
                  if (widget.sharedText != null) {
                    Map<String, dynamic> data = {
                      if ( chatViewController.selectedChatList.first?.conversationId == null|| chatViewController.selectedChatList.first?.conversationId =='')
                        ApiKeys.other_user_id:  chatViewController.selectedChatList.first?.sender?.id
                      else
                        ApiKeys.conversation_id:
                        chatViewController.selectedChatList.first?.conversationId,
                      ApiKeys.message: "${widget.sharedText}",
                      ApiKeys.message_type: "text",
                    };
                    if (chatViewController.selectedChatList.first?.conversationId == null|| chatViewController.selectedChatList.first?.conversationId =='') {
                      chatViewController.sendInitialMessage(data);
                    } else {
                      chatViewController.sendMessage(data);
                    }
                  }
                  chatViewController.openAnyOneChatFunction(
                    type: chatViewController.selectedChatList.first?.sender?.accountType,
                    isInitialMessage: false,
                    userId: chatViewController.selectedChatList.first?.sender?.id,
                    conversationId:
                    chatViewController.selectedChatList.first?.conversationId ?? '',
                    profileImage: chatViewController.selectedChatList.first?.sender?.profileImage,
                    contactName: chatViewController.selectedChatList.first?.sender?.name,
                    contactNo: chatViewController.selectedChatList.first?.sender?.contactNo,
                    isFromContactList: false,
                  );
                  // if (widget.sharedFiles != null) {
                  //   List<File> selectedFiles = [];
                  //   List<SharedAttachment?>? sharedList =
                  //       widget.sharedFiles;
                  //
                  //   if (sharedList != null && sharedList.isNotEmpty) {
                  //     selectedFiles = sharedList
                  //         .where((e) =>
                  //     e?.path != null && e!.path.isNotEmpty)
                  //         .map((e) => File(e!.path))
                  //         .toList();
                  //   }
                  //
                  //   List<String?> fileNames = [];
                  //   List<String?> fileTypes = [];
                  //   for (var file in selectedFiles) {
                  //     Map<String, String?> fileInfo = getFileInfo(file);
                  //     fileNames.add(fileInfo['fileName']);
                  //     fileTypes.add(fileInfo['mimeType']);
                  //   }
                  //
                  //   String firstFileExtension = selectedFiles.first.path
                  //       .split('.')
                  //       .last
                  //       .toLowerCase();
                  //   String messageType = ['mp4', 'mov', 'avi', 'mkv']
                  //       .contains(firstFileExtension)
                  //       ? 'video'
                  //       : 'image';
                  //
                  //   final uploadParams = {
                  //     ApiKeys.fileName: fileNames,
                  //     ApiKeys.fileType: fileTypes,
                  //   };
                  //
                  //   chatViewController.generateUploadUrlsApi(
                  //     params: uploadParams,
                  //     listFile: selectedFiles,
                  //     isInitialMessage:
                  //     (_selectedUsers.first.conversationId == null||_selectedUsers.first.conversationId =='')
                  //         ? true
                  //         : false,
                  //     userId: _selectedUsers.first.id ?? '',
                  //     conversationId:
                  //     _selectedUsers.first.conversationId ?? '',
                  //     messageType: messageType,
                  //   );
                  // }
                  // else if (widget.sharedText != null) {
                  //   Map<String, dynamic> data = {
                  //     if (_selectedUsers.first.conversationId == null||_selectedUsers.first.conversationId =='')
                  //       ApiKeys.other_user_id: _selectedUsers.first.id
                  //     else
                  //       ApiKeys.conversation_id:
                  //       _selectedUsers.first.conversationId,
                  //     ApiKeys.message: "${widget.sharedText}",
                  //     ApiKeys.message_type: "text",
                  //   };
                  //   if (_selectedUsers.first.conversationId == null||_selectedUsers.first.conversationId =='') {
                  //     chatViewController.sendInitialMessage(data);
                  //   } else {
                  //     chatViewController.sendMessage(data);
                  //   }
                  // }
                  // chatViewController.openAnyOneChatFunction(
                  //   type: _selectedUsers.first.accountType,
                  //   isInitialMessage: true,
                  //   userId: _selectedUsers.first.id,
                  //   conversationId:
                  //   _selectedUsers.first.conversationId ?? '',
                  //   profileImage: _selectedUsers.first.profileImage,
                  //   contactName: _selectedUsers.first.name,
                  //   contactNo: _selectedUsers.first.contactNo,
                  //   isFromContactList: true,
                  // );
                }else{
                  if(chatViewController.selectedUserIds.isNotEmpty){
                    Map<String, dynamic> data = {
                      ApiKeys.forward_id:
                      chatThemeController.selectedMessageIds,
                      ApiKeys.forward_to_conversations:
                      chatViewController.selectedUserIds,
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
              }



            },
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
                    "${chatViewController.selectedUserIds.length} Forward",
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  SvgPicture.asset(
                      height: 18,
                      width: 18,
                      AppIconAssets.send_message_chat),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
