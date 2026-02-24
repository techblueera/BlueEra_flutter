import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../ai_chat/view/ai_chat_screen.dart';
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

@override
  void initState() {
    // TODO: implement initState
    if(chatViewController.canPopBusiness.value){
      chatViewController.canPopBusiness.value=false;
    }

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.businessChatListResponse.value.status == Status.COMPLETE) {
        GetChatListModel? data = chatViewController.getBusinessChatListModel?.value;
        return RefreshIndicator(
          onRefresh: () async{
            chatViewController.emitEvent(ChatEmitEvents.ChatList, {
              ApiKeys.type:"business"
            });
          },
          child:Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16,),
              HorizontalTabSelector(horizontalMargin: 14,
                  horizontalPadding: 10,
                  tabs: ['All',"Selling","Buying"],
                  selectedIndex: 0,
                  onTabSelected: (index,val){

                  },
                  labelBuilder: (value)=>value),
              SizedBox(height: 12,),
              Container(
                margin: EdgeInsets.only(bottom: SizeConfig.size70),
                child: (data?.chatList?.isEmpty??true)?noChatsFound(): ListView.builder(
                    shrinkWrap: true,
                  itemCount:  (data?.chatList?.length ?? 0) + 1,
                  itemBuilder: (context, index) {
                    final chat =(index == 0)? ChatViewController.businessAiChatModule:data?.chatList?[index - 1];
                    return ChatListTile(onTab: (index == 0)?(){
                      Get.to(()=> AiChatScreen(
                        profileImage: chat?.sender?.profileImage,
                        name: chat?.sender?.name,
                        contactNo: chat?.sender?.contactNo,
                        conversationId: '',
                        userId: '',
                        businessId: '',
                        type: chat?.sender?.accountType,
                        isInitialMessage: false,));
                    }:null,
                        isFromGroupSelect: widget.isNewGroupUI,
                        onSelect: (){
                      setState(() {

                      });
                    },type: "business",
                        index: index,
                        chatViewController: chatViewController,
                        chat: chat,
                        theme: theme,
                        isForwardUI: widget.isForwardUI,
                        context: context);
                  }
                ),
              ),
            ],
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