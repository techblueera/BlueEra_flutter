import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../chat_screen_new.dart';
import '../widget/component_widgets.dart';
import '../widget/message_card.dart';
class OrderChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? type;
  final String? name;
  final String? contactNo;
  OrderChatScreen(
      {
        required this.conversationId,
        required this.type,
        required this.userId,
        required this.profileImage,
        this.name,
        this.contactNo,
      });
  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final Color sentMessageColor = Color(0xFF007AFF);

  final Color receivedMessageColor = Color(0xFFECECEC);

  final Color backgroundColor = Color(0xFFF5F5F5);

  final chatViewController = Get.find<ChatViewController>();

  final chatThemeController = Get.find<ChatThemeController>();

  final TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatViewController.getLocalConversation(
      widget.conversationId??'',
      widget.userId??'',

    );

    chatThemeController.resetSelection();

    checkPendingMessages();
    super.initState();
  }

  Future<void> checkPendingMessages() async {
    final connectivityResult = await NetworkUtils.isConnected();
    if (!connectivityResult) {
      chatViewController.sendOfflineMessage(widget.conversationId ?? "");
    }
  }

  @override
  void dispose() {
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        chatViewController.emitEvent(
            ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type}, true);
        chatViewController.emitEvent(
            ChatEmitEvents.newMessageReceived, {ApiKeys.type: AppConstants.personal_Chat_Type}, true);

        return true;
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: (chatThemeController.isMessageSelectionActive.value &&
              widget.type != "Admin")
              ? getChatOptionsAppBar(context,
              profileImage: widget.profileImage,
              editingController: editingController,
              conversationId: widget.conversationId,
              userId: widget.userId,
              type: widget.type,
              name: widget.name,
              contactNo: widget.contactNo)
              : getChatTitleAppBar(socketType: "personal",
              context,

              userId: widget.userId,
              type: widget.type,
              name: widget.name,
              profileImage: widget.profileImage,
              contactNo: widget.contactNo, conversationId: widget.conversationId),
          body: Obx(() {

            if (chatViewController.getListOfMessageResponse.value.status ==
                Status.COMPLETE) {
              List<Messages> messages =
                  chatViewController.getListOfMessageData ?? [];
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
                          child: (messages.isEmpty)
                              ? Center(
                            child: InkWell(
                              onTap: () {
                                Map<String, dynamic> data = {
                                  ApiKeys.other_user_id: widget.userId,
                                  ApiKeys.message: "Namaste 🙏",
                                  ApiKeys.message_type: "text",
                                };
                                chatViewController
                                    .sendInitialMessage(data);
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
                                        text: AppStrings.noConversationYet.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: AppStrings.sayNamaste.tr,
                                        style: TextStyle(
                                          color:AppColors.primaryColor, // blue from theme
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
                                      reverse: (widget.type == "Admin")
                                          ? false
                                          : true,
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.end,
                                        children: messages.map((message) {
                                          return MessageCard(
                                            isFromOrderTab: true,
                                            message: message,
                                            isInitialMessage:
                                           false,
                                            conversationId:
                                            widget.conversationId,
                                            userId: widget.userId,
                                            name: widget.name,
                                            contactNo: widget.contactNo,
                                            profileImage:
                                            widget.profileImage,
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
}






//
class ReactionInfoWidget extends StatefulWidget {
  const ReactionInfoWidget({super.key,required this.time,required this.userId,required this.conversation, required this.message});
  final String time;
  final String userId;
  final String conversation;
  final Messages message;

  @override
  State<ReactionInfoWidget> createState() => _ReactionInfoWidgetState();
}

class _ReactionInfoWidgetState extends State<ReactionInfoWidget> {
  final chatThemeController = Get.find<ChatThemeController>();
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      padding: EdgeInsets.only(left: 8,right: 8, top: 8,bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
      ),

      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                  onTap: (){
                    Map<String,dynamic> data={
                      ApiKeys.message_id: "${widget.message.id}",
                      ApiKeys.type: "Code1"
                    };
                    chatViewController.likeAndUnlikeMessage(data,widget.userId,widget.conversation);
                  },
                  child: _iconText(widget.userId,widget.conversation,AppIconAssets.chat_smile, "${(widget.message.likes_count=='null')?0:widget.message.likes_count??0}",context,chatThemeController,widget.message.is_liked)),
              _verticalDivider(),
              _iconText(widget.userId,widget.conversation,AppIconAssets.chat_cmd, "${(widget.message.replies_count=='null')?"0":widget.message.replies_count??0}",context,chatThemeController),
              _verticalDivider(),
              InkWell(
                  onTap: (){
                    chatThemeController.selectedId.add(widget.message.id??'');
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>NewChatMainScreen(isForwardUI: true,message: widget.message,forwardId: widget.message.id??'',)));
                  },
                  child: _iconText(widget.userId,widget.conversation,AppIconAssets.chat_share_icon, "${(widget.message.forwards_count=="null")?"0":widget.message.forwards_count??0}",context,chatThemeController)),
            ],
          ),
          timeAndReadInfoWidget(message: widget.message,isMyMessage: widget.message.myMessage??false,time: widget.time,timeColor: AppColors.black,indicateColor: widget.message.messageRead==1?Colors.blue:Colors.grey)
        ],
      ),
    );
  }

  Widget _iconText(String userId,String conversationId,String icon, String count,BuildContext context,ChatThemeController chatThemeController,[bool? isLiked]) {
    return Row(
      children: [
        (isLiked!=null&&isLiked==true&&icon==AppIconAssets.chat_smile)?Icon(Icons.favorite,color:chatThemeController.myMessageBgColor.value ,size: 20,):(icon==AppIconAssets.chat_smile)?Icon(Icons.favorite_border,color:chatThemeController.myMessageBgColor.value ,size: 20,):SvgPicture.asset(icon,color: chatThemeController.myMessageBgColor.value,),
        SizedBox(width: 1),
        CustomText(
          "${count}",
            color:chatThemeController.myMessageBgColor.value,
            fontSize: 14,
            fontWeight: FontWeight.w500,
        )
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 4),
      color:chatThemeController.myMessageBgColor.value,
    );
  }
}

