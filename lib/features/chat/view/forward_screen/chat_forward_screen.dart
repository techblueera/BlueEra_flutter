import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../personal_chat/personal_chat_list.dart';

class ChatForwardScreen extends StatefulWidget {
  const ChatForwardScreen({super.key});

  @override
  State<ChatForwardScreen> createState() => _ChatForwardScreenState();
}

class _ChatForwardScreenState extends State<ChatForwardScreen> {
  final chatViewController = getOrPut(() => ChatViewController());
  final chatThemeController = getOrPut(() => ChatThemeController());

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
            child: ListView(
              children: [
                _topOptions(),
                _sectionTitle("Recent chats"),
                PersonalChatsList(isForwardUI: true),
              ],
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
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
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
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
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
            value: false,
            onChanged: (_) => (),
          ),
        ),
      ),
      onTap: () {
        // select logic here
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
              if(chatViewController.selectedUserIds.isNotEmpty){
                Map<String, dynamic> data = {
                  ApiKeys.forward_id:
                  chatThemeController.selectedId,
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
