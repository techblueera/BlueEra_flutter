import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../chat_screen.dart';
import '../widget/component_widgets.dart';
class OrderChatScreen extends StatelessWidget {
  final Color sentMessageColor = Color(0xFF007AFF);
  final Color receivedMessageColor = Color(0xFFECECEC);
  final Color backgroundColor = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading:InkWell(
            onTap: (){
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios, color: Colors.black)),
        titleSpacing: 0, // removes default space between leading and title
        title: Row(
          children: [
            SizedBox(width: 4),
            CircleAvatar(
              radius: 18,
              child: CustomText(
                  "BE",
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'McDonalds',

                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,

                ),
                CustomText(
                  'Offline',

                    color: Colors.grey.shade600,
                    fontSize: 12,

                ),
              ],
            ),
          ],
        ),
        actions: [
          SvgPicture.asset(AppIconAssets.chat_video_call),
          const SizedBox(width: 12),
          SvgPicture.asset(AppIconAssets.chat_info_pop),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
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
              McDonaldsWidget(),
              Spacer(),

              // Expanded(
              //   child: ListView(
              //     padding: EdgeInsets.all(10),
              //     children: [
              //       _buildReceivedMessage("Holla Jane!", "17:00",false),
              //       _buildReceivedMessage("A week back I started\nexploring UI/UX using Figma", "17:00",false),
              //       _buildReceivedMessage("A week back I started\nexploring UI/UX using Figma", "17:00",true),
              //       _buildDateDivider("Today"),
              //       _buildImageMessage(
              //         "assets/images/camera_girl.png",
              //         "17:00",
              //         views: 10,
              //         comments: 10,
              //         likes: 20,
              //       ),
              //     ],
              //   ),
              // ),
              // ChatInputBar(),
            ],
          ),
        ],
      ),
    );
  }







}

class ReactionInfoWidget extends StatefulWidget {
  const ReactionInfoWidget({super.key,required this.time,required this.userId,required this.conversation, required this.message});
  final String time;
  final String userId;
  final String conversation;
  final Messages message;

  @override
  State<ReactionInfoWidget> createState() => _ReactionInfoWidgetState();
}

class _ReactionInfoWidgetState extends State<ReactionInfoWidget> {
  final chatThemeController = Get.find<ChatThemeController>();
  final chatViewController = Get.find<ChatViewController>();

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


class McDonaldsWidget extends StatelessWidget {
  const McDonaldsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 16,bottom: 16,left: 16,right: 90),
      color: Colors.white,
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red Header with logo and text
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD6001C), // McD red
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                // Image.asset(
                //   'assets/mcd_logo.png', // Replace with your asset
                //   height: 50,
                // ),
                SizedBox(
                  height: 50,
                ),
                const SizedBox(height: 10),
                const CustomText(
                  "McDonald's Logo Meaning",

                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,

                ),
                const SizedBox(height: 4),
                const CustomText(
                  'SYMBOL, HISTORY & BRAND REVIEW',
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1,
                ),
              ],
            ),
          ),

          // Message content
          Container(
            padding: const EdgeInsets.all(16),
            color: Color.fromRGBO(242, 254, 254, 1),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: const [
                  TextSpan(
                    text: "Hello There,\n\nThanks for checking out our new Pizza Menu – fresh out… ",
                  ),
                  TextSpan(
                    text: "read more",
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),


          // Bottom buttons
          const Divider(height: 1,color: Colors.grey,),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close, color: Colors.red,),
                  label:  CustomText(
                    'Cancel',
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const VerticalDivider(width: 1,color: Colors.grey,),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: SvgPicture.asset(AppIconAssets.carbon_delivery),
                  label:   CustomText(
                    'Tracking',
                    color: Colors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
