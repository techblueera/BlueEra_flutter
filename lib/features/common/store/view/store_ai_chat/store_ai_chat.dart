import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/store_ai_chat/widget/store_message_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/common_methods.dart';
import '../../../../../core/constants/size_config.dart';


class StoreAiChatScreen extends StatefulWidget {
  StoreAiChatScreen(
      {
        this.profileImage,
        this.name,
        this.contactNo,
      });

  final String? profileImage;
  final String? name;
  final String? contactNo;


  @override
  State<StoreAiChatScreen> createState() => _StoreAiChatScreenState();
}

class _StoreAiChatScreenState extends State<StoreAiChatScreen> {
  final TextEditingController editingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  final controller = getOrPut(() => NewStoreController());
  final chatThemeController = getOrPut(() => ChatThemeController());
  String? name, contactNo, profileImage;

  @override
  void initState() {
    name = widget.name;
    contactNo = widget.contactNo;
    profileImage = widget.profileImage;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
          onPopInvokedWithResult: (didPop, result){
              if(didPop) return;
          },
      child: Scaffold(
          backgroundColor: AppColors.fillColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leadingWidth: 38,
            leading: InkWell(
              onTap: () {
                Get.back();
              },
              child: Padding(
                padding: EdgeInsets.only(left: SizeConfig.size18),
                // Reduce touch padding if needed
                child: Icon(Icons.arrow_back_ios, color: Colors.black),
              ),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  radius: SizeConfig.size18,
                  backgroundImage:
                  profileImage !=null ? NetworkImage(
                      profileImage!,
                    // Icon(
                    //   Icons.person,
                    //   color: theme.colorScheme.surface,
                    // ),
                  ) : null,
                  child: (profileImage == 'null') ? CustomText(
                    "${name!.split('')[0]}",
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: SizeConfig.size18,
                  ) : (profileImage != null)
                      ? null
                      : (name != null)
                      ? Center(
                      child: CustomText(
                        name?.isNotEmpty ?? false ? "${name?.split('')[0]}" : "U",
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: SizeConfig.size18,
                      ))
                      : Center(
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size6), // Slightly smaller spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: SizeConfig.size160,
                      child: CustomText(
                        name,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: SizeConfig.size16,
                      ),
                    ),
                    CustomText(
                      "BlueCs Limited",
                      color: AppColors.grayText,

                      fontSize: SizeConfig.size12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Obx(() {

            // if (controller.getListOfAiMessageResponse.value.status ==
            //     Status.COMPLETE) {
              // List<Messages> messages = chatViewController.getListOfAiMessageData ?? [];
              List<Messages> messages =  [];

              // messages.sort((a, b) {
              //   final dateA = (a.createdAt != null && a.createdAt!.isNotEmpty)
              //       ? DateTime.parse(a.createdAt!).toLocal()
              //       : DateTime.fromMillisecondsSinceEpoch(0);
              //
              //   final dateB = (b.createdAt != null && b.createdAt!.isNotEmpty)
              //       ? DateTime.parse(b.createdAt!).toLocal()
              //       : DateTime.fromMillisecondsSinceEpoch(0);
              //
              //   return dateA.compareTo(dateB); // descending
              // });
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
                                Map<String, dynamic> data = {
                                  // ApiKeys.other_user_id: widget.userId,
                                  ApiKeys.message: "Namaste 🙏",
                                  ApiKeys.message_type: "text",
                                };
                                // chatViewController.sendInitialMessage(data);
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
                                          color: Colors
                                              .blue, // blue from theme
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
                                      controller: controller
                                          .aiChatScrollController,
                                      // reverse: (widget.type == AppStrings.Admin)
                                      //     ? false
                                      //     : true,
                                      reverse: true,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: messages.map((message) {
                                          return StoreMessageCard(
                                            message: message,
                                            name: widget.name,
                                            contactNo: widget.contactNo,
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
                        (controller.chatBotReading.value==true)? const SizedBox(
                          height: 6,
                        ) : SizedBox(),
                        (controller.chatBotReading.value==true)? staggeredDotsWaveLoading(padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                            color: AppColors.grayText
                        ) : SizedBox(),
                        const SizedBox(
                          height: 6,
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
                                                  imgColor: AppColors.chat_input_icon_color
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            keyboardType: TextInputType.text,
                                            textCapitalization: TextCapitalization.sentences,
                                            controller: controller.sendMessageController,
                                            minLines: 1,
                                            maxLines: 5,
                                            onChanged: (value) {
                                              if (!value.isEmpty) {
                                                controller.isTextFieldEmpty.value =
                                                true;
                                              } else {
                                                controller.isTextFieldEmpty.value =
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

                                        (controller.isTextFieldEmpty.value)?SizedBox():SizedBox(width: 8),
                                        (controller.isTextFieldEmpty.value)?SizedBox():Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              // _pickFromCamera();
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
                                        if(controller.sendMessageController.value.text.isNotEmpty){
                                          controller.askAiInventory(
                                              message: controller.sendMessageController.value.text
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
                                          child: SvgPicture.asset(
                                            AppIconAssets.send_message_chat,
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
                    ),
                  ],
                ),
              );
            // }
            // else {
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
          }),
        )

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

  // Future<void> _pickFromCamera() async {
  //   final pickedFile = await ImagePicker().pickImage(
  //     source: ImageSource.camera,
  //   );
  //   if (pickedFile != null) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) =>
  //             MultiImagePreviewPage(
  //               mediaFiles: [File(pickedFile.path)],
  //               onSend: (val, String? commands) async {
  //                 Navigator.pop(context);
  //                 String? imagePath = File(pickedFile.path).path;
  //                 String fileName = imagePath
  //                     .split('/')
  //                     .last;
  //                 String fileExtension = fileName
  //                     .split('.')
  //                     .last
  //                     .toLowerCase();
  //                 String messageType = ['mp4', 'mov', 'avi', 'mkv'].contains(
  //                     fileExtension)
  //                     ? 'video'
  //                     : 'image';
  //
  //                 dio.MultipartFile? imageByPart = await dio.MultipartFile
  //                     .fromFile(
  //                   imagePath,
  //                   filename: fileName,
  //                 );
  //
  //                 // Map<String, dynamic> data = {
  //                 //   if(isInitialFlow)
  //                 //     ApiKeys.other_user_id: widget.userId
  //                 //   else
  //                 //     ApiKeys.conversation_id: widget.conversationId,
  //                 //   if(commands != null)
  //                 //     ApiKeys.message: commands,
  //                 //   ApiKeys.message_type: messageType,
  //                 //   ApiKeys.files: imageByPart,
  //                 // };
  //                 // print('SEND PAYLOAD (camera ${messageType}): '+data.toString());
  //                 // sendMessageToUser(
  //                 //     data: data, isInitial: isInitialFlow);
  //               },
  //             ),
  //       ),
  //     );
  //   }
  // }
}
