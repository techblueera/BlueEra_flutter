import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/inventory_ask_ai_model.dart';
import 'package:BlueEra/features/chat/view/ai_chat/widget/ask_inventory_msg_card.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/chat/view/widget/message_bubble.dart';
import 'package:BlueEra/features/chat/view/widget/picked_media_preview.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AiInventoryScreen extends StatefulWidget {
  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? businessId;
  final String? name;
  final String? contactNo;
  final String? type;
  final bool isInitialMessage;

  const AiInventoryScreen({super.key,
    required this.conversationId,
    required this.userId,
    required this.businessId,
    this.profileImage,
    required this.type,
    this.name,
    this.contactNo,
    required this.isInitialMessage,
  });

  @override
  State<AiInventoryScreen> createState() => _AiInventoryScreenState();
}

class _AiInventoryScreenState extends State<AiInventoryScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());
  final TextEditingController editingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  final _scrollController = ScrollController();

  @override
  initState(){
    chatViewController.connectInventoryAiSocket(AppConstants.askInventory_Chat_Type);
    super.initState();
  }

  @override
  void dispose() {
    chatViewController.disposeAiSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: (chatThemeController.isMessageSelectionActive.value &&
          widget.type != AppStrings.Admin)
          ? getChatOptionsAppBar(
          context,
          profileImage: widget.profileImage,
          editingController: editingController,
          conversationId: widget.conversationId,
          userId: widget.userId,
          type: widget.type,
          name: widget.name,
          contactNo: widget.contactNo)
          : getChatTitleAppBar(
          socketType: "personal",
          context,
          userId: widget.userId,
          type: widget.type,
          name: widget.name,
          profileImage: widget.profileImage,
          contactNo: widget.contactNo, conversationId: widget.conversationId),
      body: Obx(()=> _AskInventoryAiWidget()),
    );

  }

  Widget _AskInventoryAiWidget(){
    // if (chatViewController.getListOfInventoryAiMessageResponse.value.status ==
    //     Status.COMPLETE) {
    List<InventoryAskAiModel> messages =
        chatViewController.getListOfInventoryAiMessages;

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
                child: (messages.isEmpty)
                    ? Center(
                  child: InkWell(
                    onTap: () {

                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.5), // light color with 0.5 opacity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "No conversation yet. Please search for Products",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    : LayoutBuilder(
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
                            controller: chatViewController
                                .scrollController,
                            reverse: (widget.type == AppStrings.Admin)
                                ? false
                                : true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: messages.map((message) {
                                switch (message.role) {
                                  case "model":
                                    return AskInventoryMsgCard(response: message);

                                  case "user":
                                    return MessageBubble(
                                      messages: Messages(),
                                      message: message.reply??"",
                                      time: message.timestamp ?? '',
                                      isReceiveMsg: false,
                                    ); // or your reply widget
                                }

                                // Fallback widget to avoid returning null
                                return const SizedBox();
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),


              (chatViewController.chatBotReading.value==true)
                  ? staggeredDotsWaveLoading(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                  color: AppColors.grayText
              ) : SizedBox(
                height: SizeConfig.size6,
              ),

              Container(
                // padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  // color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:  Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              )
                            ],
                          ),
                          child:
                          Row(crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                        (states) {
                                      if (states.contains(WidgetState.pressed)) {
                                        return Colors.grey..withValues(alpha: 0.4); // pressed
                                      }
                                      if (states.contains(WidgetState.hovered)) {
                                        return Colors.grey.withValues(alpha: 0.2); // hover
                                      }
                                      return null;
                                    },
                                  ),

                                  onTap: _toggleEmojiKeyboard,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 3.0),
                                      child: LocalAssets(
                                          height: 22, width: 22,
                                          imagePath: AppIconAssets.chat_box_smile,
                                          imgColor: AppColors.chat_input_icon_color),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  scrollController: _scrollController,
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.sentences,
                                  controller: chatViewController.sendMessageController
                                      .value,
                                  minLines: 1,
                                  maxLines: 5,
                                  onChanged: (value) {
                                    if (!value.isEmpty) {
                                      chatViewController.isTextFieldEmpty.value =
                                      true;
                                    } else {
                                      chatViewController.isTextFieldEmpty.value =
                                      false;
                                    }
                                  },
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: "Type Message...",
                                    hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500
                                    ),
                                    contentPadding: EdgeInsets.only(left: 6,bottom: 10,top: 8),
                                    fillColor: Colors.transparent,
                                    filled: true,
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,

                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a URL';
                                    }
                                    final httpsUrlRegex = RegExp('r^https:\/\/[a-zA-Z0-9\-._~:\/?#\[\]@!\$&\'()*+,;=%]+\$');
                                    if (!httpsUrlRegex.hasMatch(value)) {
                                      return 'Only HTTPS URLs are allowed';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              (chatViewController.isTextFieldEmpty.value)?SizedBox():SizedBox(width: 8),
                              (chatViewController.isTextFieldEmpty.value)?SizedBox():Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _pickFromCamera();
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                        (states) {
                                      if (states.contains(WidgetState.pressed)) {
                                        return Colors.grey..withValues(alpha: 0.4); // pressed
                                      }
                                      if (states.contains(WidgetState.hovered)) {
                                        return Colors.grey.withValues(alpha: 0.2); // hover
                                      }
                                      return null;
                                    },
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      // background if you want
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                    child: Icon(Icons.camera_alt_outlined,
                                        color: AppColors.chat_input_icon_color,
                                        size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Obx(() {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                  (states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return Colors.grey.withValues(alpha: 0.4); // pressed
                                }
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.grey.withValues(alpha: 0.2); // hover
                                }
                                return null;
                              },
                            ),
                            onTap: () async {
                              if(chatViewController.sendMessageController.value.text.isNotEmpty){
                                chatViewController
                                    .sendInventoryMessageToAiSocket(
                                    type: AppConstants.askInventory_Chat_Type,
                                    message: chatViewController
                                        .sendMessageController.value
                                        .text.trim()
                                );
                              }
                            },
                            child: Center(
                              child: Ink(
                                decoration: BoxDecoration(
                                  color:
                                  chatThemeController.myMessageBgColor.value,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(14),
                                child: LocalAssets(
                                  imagePath: AppIconAssets.send_message_chat,
                                  height: 21,
                                  width: 21,
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          )
        ],
      ),
    );
    // } else {
    //   return SafeArea(
    //       child: Stack(
    //         fit: StackFit.expand,
    //         children: [
    //           Image.asset(
    //             AppImageAssets.chating_bg,
    //             fit: BoxFit.cover,
    //             width: SizeConfig.screenWidth,
    //             height: SizeConfig.screenHeight,
    //           ),
    //           Center(
    //             child: SizedBox(
    //               height: 22,
    //               width: 22,
    //               child: CircularProgressIndicator(),
    //             ),
    //           )
    //         ],
    //       ));
    // }
  }

  void _toggleEmojiKeyboard() {
    if (_isEmojiVisible) {
      _focusNode.requestFocus();
      setState(() => _isEmojiVisible = false);
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => _isEmojiVisible = true);
      });
    }
  }
  Future<void> _pickFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MultiImagePreviewPage(
                mediaFiles: [File(pickedFile.path)],
                onSend: (val, String? commands) async {
                  Navigator.pop(context);
                  String? imagePath = File(pickedFile.path).path;
                  String fileName = imagePath
                      .split('/')
                      .last;
                  String fileExtension = fileName
                      .split('.')
                      .last
                      .toLowerCase();
                  String messageType = ['mp4', 'mov', 'avi', 'mkv'].contains(
                      fileExtension)
                      ? 'video'
                      : 'image';

                  dio.MultipartFile? imageByPart = await dio.MultipartFile
                      .fromFile(
                    imagePath,
                    filename: fileName,
                  );

                  // Map<String, dynamic> data = {
                  //   if(isInitialFlow)
                  //     ApiKeys.other_user_id: widget.userId
                  //   else
                  //     ApiKeys.conversation_id: widget.conversationId,
                  //   if(commands != null)
                  //     ApiKeys.message: commands,
                  //   ApiKeys.message_type: messageType,
                  //   ApiKeys.files: imageByPart,
                  // };
                  // print('SEND PAYLOAD (camera ${messageType}): '+data.toString());
                  // sendMessageToUser(
                  //     data: data, isInitial: isInitialFlow);
                },
              ),
        ),
      );
    }
  }

}
