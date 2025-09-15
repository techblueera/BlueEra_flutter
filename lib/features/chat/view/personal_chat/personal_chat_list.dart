import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';

class PersonalChatsList extends StatefulWidget {
  const PersonalChatsList({super.key, this.isForwardUI, this.isNewGroupUI});

  final bool? isForwardUI;
  final bool? isNewGroupUI;

  @override
  State<PersonalChatsList> createState() => _PersonalChatsListState();
}

class _PersonalChatsListState extends State<PersonalChatsList> {
  final chatViewController = Get.find<ChatViewController>();
  final groupChatViewController = Get.find<GroupChatViewController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.personalChatListResponse.value.status ==
          Status.COMPLETE) {
        GetChatListModel? data =
            chatViewController.getPersonalChatListModel?.value;
        return RefreshIndicator(
          onRefresh: () async {
            chatViewController.emitEvent(
                "ChatList", {ApiKeys.type: "personal"}, true);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: (data?.chatList?.isEmpty ?? true)
                ? noChatsFound()
                : ListView.builder(
                    itemCount: data?.chatList?.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return ChatListTile(
                          isFromGroupSelect: widget.isNewGroupUI,
                          groupChatViewController:
                              (widget.isNewGroupUI != null &&
                                      widget.isNewGroupUI == true)
                                  ? groupChatViewController
                                  : null,
                          onSelect: () {
                            setState(() {});
                          },
                          type: data?.chatList?[index]?.sender?.accountType ??
                              AppConstants.individual,
                          index: index,
                          chatViewController: chatViewController,
                          chat: data?.chatList?[index],
                          theme: theme,
                          isForwardUI: widget.isForwardUI,
                          context: context);
                    },
                  ),
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }

  String formatTimeFromUtc(String utcString) {
    DateTime utcDate = DateTime.parse(utcString);
    DateTime localDate = utcDate.toLocal();
    String formattedTime = DateFormat.jm().format(localDate); // e.g. 9:52 PM
    return formattedTime;
  }
}
