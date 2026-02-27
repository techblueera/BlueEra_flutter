
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/common_methods.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../reminder_chat/reminder_chat_list.dart';
import '../../widget/component_widgets.dart';
import '../../widget/picked_media_preview.dart';
import 'ai_chat_message_view_screen.dart';

class AiChatScreen extends StatefulWidget {
  AiChatScreen(
      {
        this.profileImage,
        required this.type,
        this.name,
        });
  final String? profileImage;
  final String? name;
  final String? type;


  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with SingleTickerProviderStateMixin {
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final TextEditingController editingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  final _scrollController = ScrollController();
  TabController? aiChatTapbarController;

  @override
  void initState() {
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatThemeController.resetSelection();
    chatViewController.connectAiSocket(widget.type ?? '');
    aiChatTapbarController=TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    chatViewController.disposeAiSocket();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.fillColor,
        appBar: getChatTitleAppBar(
          socketType: "personal",
          context,
          isFromAiChat: true,
          type: widget.type,
          name: widget.name,
          profileImage: widget.profileImage,
        ),
        body: Obx(() {

          if (chatViewController.getListOfAiMessageResponse.value.status ==
              Status.COMPLETE) {
            List<Messages> messages =
                chatViewController.getListOfAiMessageData ?? [];

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
                      Container(
                        color: AppColors.white,
                        child: TabBar(
                          dividerColor: AppColors.primaryColor.withOpacity(0.4),
                          onTap: (index) {
                            setState(() {

                            });

                          },
                          controller: aiChatTapbarController,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.black54,
                          indicatorColor: Colors.lightBlue,
                          tabs:  [
                            Tab(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LocalAssets(imagePath: AppImageAssets.chat_tab_view,height: 18,width: 18,),
                                  SizedBox(width: 12,),
                                  CustomText("New Chat",fontSize: 14,
                                    fontWeight: FontWeight.w500,),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LocalAssets(imagePath: AppIconAssets.clock_new,height: 18,width: 18,),
                                  SizedBox(width: 12,),
                                  CustomText("Reminder",fontSize: 14,
                                    fontWeight: FontWeight.w500,),
                                ],
                              ),
                            ),   Tab(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LocalAssets(imagePath: AppImageAssets.chat_tab_to_do,height: 18,width: 18,),
                                  SizedBox(width: 12,),
                                  CustomText("To Do List",fontSize: 14,
                                    fontWeight: FontWeight.w500,),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: aiChatTapbarController,
                          children: [

                            AiChatMessageViewScreen(
                              messages: messages,
                              type: widget.type,
                            ),
                            ReminderChatList(),
                            SizedBox(),
                          ],
                        ),
                      ),

                     if(aiChatTapbarController?.index==0)
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
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
                                                   height: 22,
                                                   width: 22,
                                                   imagePath: AppIconAssets.chat_box_smile,
                                                   imgColor: AppColors.chat_input_icon_color,),
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

                                         ( chatViewController.isTextFieldEmpty.value)?SizedBox():SizedBox(width: 8),
                                         ( chatViewController.isTextFieldEmpty.value)?SizedBox():Material(
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
                                               .sendMessageToAiSocket(
                                               type: widget.type ?? '',
                                               message: chatViewController
                                                   .sendMessageController.value
                                                   .text
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
                  // if(messages.isEmpty&&aiChatTapbarController?.index==0)
                  // Positioned(
                  //     left: 10,
                  //     top: 70,
                  //     child:  Container(
                  //   width: 340,
                  //   decoration: BoxDecoration(
                  //     color: Colors.transparent,
                  //   ),
                  //   child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //
                  //       /// Title
                  //        Container(
                  //          width: 270,
                  //          decoration: BoxDecoration(
                  //            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10),bottomRight: Radius.circular(10),)
                  //          ,
                  //            color: AppColors.white
                  //          ),
                  //          padding: EdgeInsets.symmetric(horizontal: 24,vertical: 10),
                  //          child: Row(
                  //            children: [
                  //              CustomText(
                  //               "Hi ${userNameGlobal} Choose Your Topic",
                  //                 fontSize: 14,
                  //                 fontWeight: FontWeight.w400,
                  //                 color: Colors.black,
                  //               textAlign: TextAlign.center,
                  //                                        ),
                  //            ],
                  //          ),
                  //        ),
                  //
                  //       const SizedBox(height: 6),
                  //
                  //       /// Grid Topics
                  //       Container(
                  //         decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10),bottomRight: Radius.circular(10),)
                  //             ,
                  //             color: AppColors.white
                  //         ),
                  //         width: 270,
                  //         padding: EdgeInsets.all(10),
                  //         child:GridView.builder(
                  //           shrinkWrap: true,
                  //           physics: const NeverScrollableScrollPhysics(),
                  //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //             crossAxisCount: 2,
                  //             crossAxisSpacing: 12,
                  //             mainAxisSpacing: 12,
                  //             childAspectRatio: 3,
                  //           ),
                  //           itemCount: topics.length,
                  //           itemBuilder: (context, index) {
                  //             final topic = topics[index];
                  //
                  //             return TopicButton(
                  //               title: topic["title"]!,
                  //               onTab: () {
                  //                 SendMessageToAI(
                  //                   message: topic["title"]!,
                  //                   tag: topic["tag"]!,
                  //                 );
                  //               },
                  //             );
                  //           },
                  //         ),
                  //       ),
                  //       const SizedBox(height: 6),
                  //
                  //       Container(
                  //         width: 270,
                  //         decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10),bottomRight: Radius.circular(10),)
                  //             ,
                  //             color: AppColors.white
                  //         ),
                  //         padding: EdgeInsets.symmetric(horizontal: 24,vertical: 10),
                  //         child: CustomText(
                  //           "Or How Can I Help You?",
                  //           fontSize: 14,
                  //           fontWeight: FontWeight.w400,
                  //           color: Colors.black,
                  //           textAlign: TextAlign.center,
                  //         ),
                  //       ),
                  //
                  //       const SizedBox(height: 6),
                  //       Container(
                  //         width: 270,
                  //         decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10),bottomRight: Radius.circular(10),)
                  //             ,
                  //             color: AppColors.white
                  //         ),
                  //         padding: EdgeInsets.all(10),
                  //         child:  Row(
                  //           children:  [
                  //             Expanded(child: TopicButton(title: "Create Reply", onTab: () {
                  //               SendMessageToAI(message: "Create Reply",tag: "create reply");
                  //             },)),
                  //             SizedBox(width: 12),
                  //             Expanded(child: TopicButton(title: "Draft Email", onTab: () {
                  //               SendMessageToAI(message: "Draft Email",tag: "draft email");
                  //             },)),
                  //           ],
                  //         ),
                  //       ),
                  //       /// Bottom Buttons
                  //
                  //     ],
                  //   ),
                  // ))
                ],
              ),
            );
          } else {
            return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LocalAssets(
                      imagePath: AppImageAssets.chating_bg,
                      boxFix: BoxFit.cover,
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
      ),
    );
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



                },
              ),
        ),
      );
    }
  }
}
