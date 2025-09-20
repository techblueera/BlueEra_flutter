import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/group_chat/view_group_members.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../chat_screen.dart';
import '../widget/group_chat_input_box.dart';
import '../widget/group_message_card.dart';
import '../widget/message_card.dart';

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
  String _selectedDuration = "ONE_DAY";
  final Color backgroundColor = Color(0xFFF5F5F5);
  final chatViewController = Get.find<GroupChatViewController>();
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
          appBar: (chatThemeController.isMessageSelectionActive.value)
              ? PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leadingWidth: 38,
              leading: InkWell(
                onTap: () {
                  chatThemeController.resetSelection();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 18.0),
                  child: Icon(Icons.arrow_back_ios, color:AppColors.chat_input_icon_color),
                ),
              ),
              titleSpacing: 8,
              title: CustomText(
                "${chatThemeController.selectedId.length}",
                // or make dynamic
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.chat_input_icon_color),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: CustomText("Are you sure you want to delete?", color: Colors.black),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                Map<String, dynamic> data = {
                                  ApiKeys.conversation_id: "${widget.conversationId}",
                                  ApiKeys.delete_from_every_one: false,
                                  ApiKeys.message_id_list: chatThemeController.selectedId
                                };
                                await chatViewController.deleteChatMessage(data,'');
                                chatThemeController.resetSelection();
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "Delete for me",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                Map<String, dynamic> data = {
                                  ApiKeys.conversation_id: "${widget.conversationId}",
                                  ApiKeys.delete_from_every_one: true,
                                  ApiKeys.message_id_list: chatThemeController.selectedId
                                };
                                await chatViewController.deleteChatMessage(data, '');
                                chatThemeController.resetSelection();
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    "Delete for everyone",
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                (chatThemeController.selectedId.length==1&&chatThemeController.selectedFirstMessage?.value?.messageType=="text")?
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.chat_input_icon_color,size: 22,),
                  onPressed: (){
                    editingController.text=chatThemeController.selectedFirstMessage?.value?.message??'';
                    showMessageEditDialog();
                  },
                ):SizedBox(),
                // IconButton(
                //   icon:  Icon(Icons.push_pin_outlined,color: AppColors.chat_input_icon_color,size: 22,),
                //   onPressed: _showPinDialog,
                // ),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatMainScreen(isForwardUI: true,message: chatThemeController.selectedFirstMessage?.value,forwardId: chatThemeController.selectedFirstMessage?.value?.id??'',)));
                    },
                    child: SvgPicture.asset(
                      AppIconAssets.chat_media_forward, height: 24, width: 24,),
                  ),
                ),


                /// 🔽 Three Dots Menu (Edit option)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.chat_input_icon_color),
                  offset: const Offset(20, 60), // 👈 shift menu 40 pixels downward
                  onSelected: (value) {
                    if (value == 'edit') {
                      print("Edit selected");
                      // Handle your edit logic
                    }
                  },
                  itemBuilder: (context) => [

                  ],
                ),


                const SizedBox(width: 8),
              ],

            ),
          )
              : AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leadingWidth: 38,
            leading: InkWell(
              onTap: () {
                Navigator.pop(context);
                chatViewController.emitEvent(
                    "ChatList", {ApiKeys.type: "group"}, true);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0),
                // Reduce touch padding if needed
                child: Icon(Icons.arrow_back_ios, color: Colors.black),
              ),
            ),
            titleSpacing: 0,
            title: InkWell(
              onTap: (){
                _navigateToProfile(authorId: '');
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 18,
                    backgroundImage: widget.profileImage != null
                        ?  ((widget.profileImage!.contains('http'))
                        ? NetworkImage(widget.profileImage??"")
                        : FileImage(File(widget.profileImage??'')) as ImageProvider)
                        : null,
                    child: (widget.profileImage != null)
                        ? null
                        :(widget.name!=null)?
                    Center(child: CustomText("${widget.name?.split('')[0].capitalize}",color: Colors.white,fontWeight: FontWeight.w800,fontSize: 18,))
                        :Center(
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.surface,
                      ),
                    )
                    ,
                  ),
                  SizedBox(width: 6), // Slightly smaller spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        child: CustomText(
                          '${widget.name?.capitalize}',
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
            actions: [
              const SizedBox(width: 8),
              // InkWell(
              //     onTap: (){
              //       launchDialPad(widget.contactNo??'');
              //     },
              //     child: SvgPicture.asset(AppIconAssets.chat_call)),
              // const SizedBox(width: 12),
              // SvgPicture.asset(AppIconAssets.chat_video_call),
              // const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: SvgPicture.asset(AppIconAssets.chat_info_pop),
                onSelected: (value) {
                  if (value == "group_info") {

                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewGroupMembers(
                      conversationId: widget.conversationId,
                      type: widget.type,
                      name: widget.name,
                      profileImage: widget.profileImage,
                    )));
                  }

                },
                itemBuilder: (context) => [
                  // PopupMenuItem(
                  //   value: "group_members",
                  //   child: Text("Group Members"),
                  // ),
                  PopupMenuItem(
                    onTap:() {
                      
                    } ,
                    value: "group_info",
                    child: Text("Group Info"),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
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
  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      "Choose how long your pin lasts",
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    const CustomText(
                      "You can unpin at any time",
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),

                    RadioListTile(
                      value: "ONE_DAY",
                      groupValue: _selectedDuration,
                      onChanged: (value) {
                        setState(() {
                          _selectedDuration = value!;
                        });
                      },
                      title: const CustomText("24 Hours"),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioTheme(
                      data: RadioThemeData(
                        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue; // Selected radio circle color
                          }
                          return Colors.grey; // Unselected circle fill color
                        }),
                      ),
                      child: RadioListTile<String>(
                        value: "SEVEN_DAYS",
                        groupValue: _selectedDuration,
                        onChanged: (value) {
                          setState(() {
                            _selectedDuration = value!;
                          });
                        },
                        title: const CustomText("30 Days"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    RadioTheme(
                      data: RadioThemeData(
                        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue; // Selected radio circle color
                          }
                          return Colors.grey; // Unselected circle fill color
                        }),
                      ),
                      child: RadioListTile<String>(
                        value: "THIRTY_DAYS",
                        groupValue: _selectedDuration,
                        onChanged: (value) {
                          setState(() {
                            _selectedDuration = value!;
                          });
                        },
                        title: const CustomText("30 Days"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),


                    const SizedBox(height: 16),

                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const CustomText("Cancel"),
                        ),
                        const SizedBox(width: 8),

                        InkWell(
                            onTap: (){
                              Map<String, dynamic> data = {
                                ApiKeys.message_id: chatThemeController.selectedId,
                                ApiKeys.conversation_id: widget.conversationId,
                                ApiKeys.duration: _selectedDuration,
                                ApiKeys.remove_from_pin: true,
                              };
                              print(data); // your logic
                              chatViewController.addToPinMessage(data);
                              Navigator.pop(context);
                            },
                            child: CustomText("Pin",color: Colors.blue,fontSize: 16,fontWeight: FontWeight.w600,)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
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


