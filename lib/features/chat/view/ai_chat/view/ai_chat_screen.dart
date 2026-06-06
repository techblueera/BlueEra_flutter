

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/controller/ai_chat_profile_controller.dart';
import '../../widget/common_ai_chat_topics.dart';
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

  /// Opens the AI topics / quick-start dialog.
  void _openTopicsDialog() {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: Colors.black.withValues(alpha: 0.2),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () {},
                child: InitialMessageOptionDialog(
                  userName: userNameGlobal,
                  topics: AppConstants.aiChatTopics,
                  onSend: (message, tag) {
                    chatViewController.sendMessageToAiSocket(
                      type: widget.type ?? '',
                      tag: tag,
                      message: message,
                    );
                    Get.back();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// "New" option shown at the top of the chat screen — opens the topics
  /// quick-start dialog.
  Widget _newOption() {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: _openTopicsDialog,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primaryColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: CustomText(
            AppStrings.newTag.tr,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
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
        body: Column(
          children: [
            _newOption(),
            Expanded(
              child: AiChatMessageViewScreen(
                type: widget.type,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
