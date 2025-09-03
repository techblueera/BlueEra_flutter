import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';
class BusinessChatsList extends StatefulWidget {
  const BusinessChatsList({super.key, this.isForwardUI, this.isNewGroupUI});
  final bool? isForwardUI;
  final bool? isNewGroupUI;
  @override
  State<BusinessChatsList> createState() => _BusinessChatsListState();
}

class _BusinessChatsListState extends State<BusinessChatsList> {
  final chatViewController = Get.find<ChatViewController>();
  final groupChatViewController = Get.find<GroupChatViewController>();


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.businessChatListResponse.value.status == Status.COMPLETE) {
        GetChatListModel? data = chatViewController.getBusinessChatListModel?.value;

        return RefreshIndicator(
          onRefresh: () async{
            chatViewController.emitEvent("ChatList", {
              ApiKeys.type:"business"
            });
          },
          child:Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size70),
            child: (data?.chatList?.isEmpty??true)?noChatsFound(): ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: data?.chatList?.length,
              itemBuilder: (context, index) {
                return ChatListTile(
                    isFromGroupSelect: widget.isNewGroupUI,
                    groupChatViewController: (widget.isNewGroupUI!=null&&widget.isNewGroupUI==true)?groupChatViewController:null,
                    onSelect: (){
                  setState(() {

                  });
                },type: "business",index: index, chatViewController: chatViewController,  chat: data?.chatList?[index], theme: theme, isForwardUI: widget.isForwardUI, context: context);
              }
            ),
          ),
        );

      } else if(chatViewController.personalChatListResponse.value.status == Status.INITIAL){
        return SizedBox();
      }else{
        return Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(AppIconAssets.chat,color: Colors.black,
                  height: 70,
                  width: 70,),
                const SizedBox(height: 14,),
                CustomText("No Chats Found",fontSize: 16,fontWeight: FontWeight.w600,),
                const SizedBox(height: 6,),
                CustomText("Go to contacts and start new conversation"),
              ],
            ),
          ),
        );
      }
    });
  }


}