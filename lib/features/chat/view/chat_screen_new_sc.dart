import 'dart:developer';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/size_config.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/controller/chat_view_controller.dart';
import '../auth/controller/group_chat_view_controller.dart';
import '../auth/model/GetChatListModel.dart';
import '../contacts/auth/controller/secound_chat_view_controller.dart';
import '../contacts/view/contact_list_new_sc.dart';

class NewScChatListPage extends StatefulWidget {
  const NewScChatListPage({super.key, this.isForwardUI, this.isNewGroupUI});

  final bool? isForwardUI;
  final bool? isNewGroupUI;

  @override
  State<NewScChatListPage> createState() => _NewScChatListPageState();
}

class _NewScChatListPageState extends State<NewScChatListPage> {
  final chatViewController = Get.find<ChatViewController>();
  final groupChatViewController = Get.find<GroupChatViewController>();
  final secondChatViewController = Get.put(SecondChatViewController());
@override
  void initState() {
    // TODO: implement initState
  secondChatViewController.connectSocket();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Second Chat"),
      ),
      floatingActionButton: SafeArea(
        child: Padding(
            padding:
            const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
            child: FloatingActionButton(
              child: Icon(Icons.add),
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=> ContactsPageNew()));

              },
            )),
      ),
        body:Obx(() {
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
                return SizedBox();
              },
              
            ),
          ),
        );
      } else {
        return SizedBox();
      }
    }));
  }

  String formatTimeFromUtc(String utcString) {
    DateTime utcDate = DateTime.parse(utcString);
    DateTime localDate = utcDate.toLocal();
    String formattedTime = DateFormat.jm().format(localDate); // e.g. 9:52 PM
    return formattedTime;
  }
}
