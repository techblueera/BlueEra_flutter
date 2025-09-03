import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_image_assets.dart';
import '../../../../core/constants/size_config.dart';
import '../widget/chat_input_box.dart';

class BusinessChatScreen extends StatelessWidget {
  final List<String> tabs = ['Chat', 'Catalogs', 'Reviews', 'Products', 'Services'];

  final List<String> faqs = [
    "Are you hiring right now?",
    "What are the requirements to apply?",
    "How do I track my job application?",
    "Delivery & Takeaway?",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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
                  'Mc Donald’s',

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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Column(
              children: [

                Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final selected = index == 0;
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 1,vertical: 3),
                        padding: EdgeInsets.symmetric(horizontal: 12, ),
                        decoration: BoxDecoration(
                          color: selected ? Color.fromRGBO(217, 235, 255, 1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:  selected ?null:Border.all(color: Color.fromRGBO(153, 153, 153, 0.75)),
                        ),
                        child: Center(
                          child: CustomText(
                            tabs[index],
                              color: selected ? Color.fromRGBO(25, 26, 51, 1) : Color.fromRGBO(110, 109, 109, 1),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,

                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Chat Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/chat_bg.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    padding: EdgeInsets.all(12),
                    child: ListView(
                      children: [
                        // User message
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _userBubble("Holla Jane!", "17:00"),
                              SizedBox(height: 4),
                              _userBubble("A week back I started\nexploring UI/UX using Figma", "17:00"),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // FAQ Card
                        Container(
                          width: 270,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(242, 254, 254, 1), // light bluish background
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                              bottomLeft: Radius.circular(0),
                            ),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Menu & Orders?",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 12),
                              ...faqs.map(
                                    (q) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Text("• ", style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            text: q,
                                            style: TextStyle(
                                              color: Colors.black,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.black, // ✅ underline color
                                              decorationThickness: 1.2,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Suggestions
                        _suggestionCard("Offers & Loyalty?"),
                        SizedBox(height: 8),
                        _suggestionCard("Support & Feedback?"),
                      ],
                    ),
                  ),
                ),

                // Input Area
                ChatInputBar(conversationId: '',userId: '',isInitialMessage: false,),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userBubble(String text, String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor, // light bluish background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(0),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _suggestionCard(String label) {
    return Container(
      width: 270,
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(242, 254, 254, 1), // light bluish background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: Center(
        child: CustomText(
          label,
              fontWeight: FontWeight.w500
        ),
      ),
    );
  }
}
