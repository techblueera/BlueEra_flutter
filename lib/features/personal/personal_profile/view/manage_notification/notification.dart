import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import '../../../../../widgets/custom_switch_widget.dart';

class NotificationSettingScreen extends StatelessWidget {
  const NotificationSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2), // exact light grey bg
      appBar: const CommonBackAppBar(
        title: "Notification Setting",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              NotificationTile(title: "Chat Notification"),
              NotificationTile(title: "Post Notification"),
              NotificationTile(title: "Lorem ipsum Dolor"),
              NotificationTile(title: "Lorem ipsum Dolor"),
              NotificationTile(title: "Lorem ipsum Dolor"),
              NotificationTile(title: "Lorem ipsum Dolor"),
            ],
          ),
        ),
      ),
    );
  }
}
class NotificationTile extends StatefulWidget {
  final String title;

  const NotificationTile({super.key, required this.title});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(


        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.greyE5, // thin grey border like image
            width: 0.5,
          ),
        ),
        child: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            CustomText(
              widget.title,
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
            CustomSwitch(
              value: isEnabled,
              onChanged: (value){
                setState(() {
                  isEnabled = value;
                });
              },
              containerHeight: SizeConfig.size24,
              containerWidth: SizeConfig.size44,
              circleSize: SizeConfig.size16,
            ),


          ],
        ),
      ),
    );
  }
}