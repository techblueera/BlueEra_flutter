

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/controller/ai_chat_profile_controller.dart';
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

class _AiChatScreenState extends State<AiChatScreen> {
  final chatViewController = Get.find<ChatViewController>();
  final chatThemeController = Get.find<ChatThemeController>();
  final aiChatProfileController = Get.isRegistered<AiChatProfileController>()
      ? Get.find<AiChatProfileController>()
      : Get.put(AiChatProfileController());

  @override
  void initState() {
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    chatThemeController.resetSelection();
    // Load locally-saved name/image/mute for this AI chat so the appbar shows
    // the personalized values.
    aiChatProfileController.loadForType(widget.type ?? '');
    chatViewController.connectAiSocket(widget.type ?? '');
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
        body: AiChatMessageViewScreen(
          type: widget.type,
        ),
      ),
    );
  }
}
