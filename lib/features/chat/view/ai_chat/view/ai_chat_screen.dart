

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../reminder_chat/reminder_chat_list.dart';
import '../../widget/component_widgets.dart';
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
        body:  Column(
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
                    type: widget.type,
                  ),
                  ReminderChatList(),
                  SizedBox(),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }


}
