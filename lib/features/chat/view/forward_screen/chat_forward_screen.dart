import 'dart:convert';
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

import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../add_symbol/add_symbol_screen.dart';
import '../personal_chat/personal_chat_list.dart';

class ChatForwardScreen extends StatefulWidget {
  const ChatForwardScreen({super.key, this.sharedText, this.sharedFiles, this.maxSelectionCount, this.stopChatNav});
  final String? sharedText;
  final List<SharedAttachment?>? sharedFiles;
  final int? maxSelectionCount;
  final bool? stopChatNav;

  @override
  State<ChatForwardScreen> createState() => _ChatForwardScreenState();
}

class _ChatForwardScreenState extends State<ChatForwardScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());
 bool symbolSelected=false;
 bool _isSending = false;
  final bottomBarController = getOrPut(() => BottomBarController());

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
                  PersonalChatsList(isForwardUI: true,hideAiChats: true,),
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
              if (_isSending) return; // prevent double-tap
              _isSending = true;
              // Forward to selected contacts first (if any)
              if(chatViewController.selectedUserIds.isNotEmpty){
                if(widget.sharedFiles!=null||widget.sharedText!=null){
                  if (widget.sharedText != null) {
                    List<String?> userIds= chatViewController.selectedChatList.map((e)=>e?.sender?.id).toList();
                    Map<String, dynamic> data = {
                      ApiKeys.other_user_id: jsonEncode(userIds),
                      ApiKeys.message: "${widget.sharedText}",
                      ApiKeys.message_type: "text",
                    };
                      await chatViewController.sendMessage(data);
                    chatViewController.emitEvent(
                        ChatEmitEvents.ChatList,
                        {ApiKeys.type: AppConstants.personal_Chat_Type});
                  }

                  if (widget.sharedFiles != null) {
                    List<String?> userIds= chatViewController.selectedChatList.map((e)=>e?.sender?.id).toList();
                    List<File> selectedFiles = [];
                    List<SharedAttachment?>? sharedList =
                        widget.sharedFiles;

                    if (sharedList != null && sharedList.isNotEmpty) {
                      selectedFiles = sharedList
                          .where((e) =>
                      e?.path != null && e!.path.isNotEmpty)
                          .map((e) => File(e!.path))
                          .toList();
                    }

                    List<String?> fileNames = [];
                    List<String?> fileTypes = [];
                    for (var file in selectedFiles) {
                      Map<String, String?> fileInfo = getFileInfo(file);
                      fileNames.add(fileInfo['fileName']);
                      fileTypes.add(fileInfo['mimeType']);
                    }

                    String firstFileExtension = selectedFiles.first.path
                        .split('.')
                        .last
                        .toLowerCase();
                    String messageType = ['mp4', 'mov', 'avi', 'mkv']
                        .contains(firstFileExtension)
                        ? 'video'
                        : 'image';

                    final uploadParams = {
                      ApiKeys.fileName: fileNames,
                      ApiKeys.fileType: fileTypes,
                    };

                    await chatViewController.generateUploadUrlsApi(
                      params: uploadParams,
                      listFile: selectedFiles,
                      userId: userIds,
                      messageType: messageType,
                    );
                    chatViewController.emitEvent(
                        ChatEmitEvents.ChatList,
                        {ApiKeys.type: AppConstants.personal_Chat_Type});
                  }
                }else{
                  // Forward existing messages to selected contacts
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
                    chatThemeController.selectedMessageIds.clear();
                    chatThemeController.isMessageSelectionActive.value=false;
                  }
                }
              }

              // Navigate to symbol screen if symbol selected
              if(symbolSelected==true){
                Get.off(()=>AddChatSymbolScreen(
                  sharedText: widget.sharedText,
                  sharedFiles: widget.sharedFiles,
                ));
              }else{
                if(widget.stopChatNav!=true){
                  bottomBarController.onChangeIndex(3);
                }
                // For share-intent flows (sharedFiles/sharedText), only pop
                // once since there's no underlying chat screen to return to.
                // For normal message forwarding, pop the forward screen first,
                // then pop the message-selection screen.
                Get.back();
                if(widget.sharedFiles==null && widget.sharedText==null){
                  // Small delay to let the first pop finish so we don't
                  // accidentally pop an unrelated screen.
                  await Future.delayed(const Duration(milliseconds: 100));
                  if(Navigator.of(context).canPop()) {
                    Get.back();
                  }
                }
              }

              _isSending = false;
            },
            child: Container(
              padding: EdgeInsets.all(14),
              margin: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: (chatViewController.selectedUserIds.isNotEmpty||symbolSelected)
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
