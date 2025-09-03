import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../chat_screen.dart';
import 'component_widgets.dart';
class GroupReactionInfoWidget extends StatefulWidget {
  const GroupReactionInfoWidget({super.key,required this.time,required this.userId,required this.conversation, required this.message});
  final String time;
  final String userId;
  final String conversation;
  final Messages message;

  @override
  State<GroupReactionInfoWidget> createState() => _GroupReactionInfoWidgetState();
}

class _GroupReactionInfoWidgetState extends State<GroupReactionInfoWidget> {
  final chatThemeController = Get.find<ChatThemeController>();
  final chatViewController = Get.find<GroupChatViewController>();

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
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatMainScreen(isForwardUI: true,message: widget.message,forwardId: widget.message.id??'',)));
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
