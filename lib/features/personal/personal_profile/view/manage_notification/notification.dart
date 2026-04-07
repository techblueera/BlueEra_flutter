import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
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
      appBar: const CommonBackAppBar(
        title: AppStrings.notificationSetting,
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
            children: [
              NotificationTile(title: AppStrings.comment),
              NotificationTile(title: AppStrings.post),
              NotificationTile(title: AppStrings.like),
              NotificationTile(title: AppStrings.tag),
              NotificationTile(title: AppStrings.followingNotification),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child:
                    PositiveCustomBtn(onTap: () {}, title: AppStrings.submit),
              ),
              SizedBox(
                height: 10,
              ),
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
              color: AppColors.mainTextColor,
            ),
            CustomSwitch(
              value: isEnabled,
              onChanged: (value) {
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
