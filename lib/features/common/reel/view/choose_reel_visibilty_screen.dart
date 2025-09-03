import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/view/close_friend_screen.dart';
import 'package:BlueEra/features/common/reel/widget/custom_radio_option.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ChooseReelVisibilityScreen extends StatefulWidget {
  const ChooseReelVisibilityScreen({super.key});

  @override
  State<ChooseReelVisibilityScreen> createState() => _ChooseReelVisibilityScreenState();
}

class _ChooseReelVisibilityScreenState extends State<ChooseReelVisibilityScreen> {
  String selectedOption = 'followers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: "Choose visibility of your Video",
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: SizeConfig.size20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: SizeConfig.size20),
              CustomText(
                "Select who can see your video",
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(
                height: SizeConfig.size20,
              ),
              CustomRadioOption(
                value: 'followers',
                groupValue: selectedOption,
                title: "Your followers only",
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
              // SizedBox(
              //   height: SizeConfig.size5,
              // ),
              CustomRadioOption(
                value: 'close_friends',
                groupValue: selectedOption,
                title: "Only your close Friends",
                onChanged: (value) => setState(() => selectedOption = value!),
              ),
        
              TextButton(
                  onPressed: () {
                    navigatePushTo(context, CloseFriendsScreen());
                  },
              child: Row(
                children: [
                  CustomText(
                    "5 people",
                    fontSize: SizeConfig.medium,
                    color: AppColors.primaryColor
                  ),
                  Icon(Icons.chevron_right,
                      size: SizeConfig.size20,
                      color: AppColors.primaryColor)
                ],
              )
                            ),
              const Spacer(),
              CustomBtn(
                title: "Save",
                onTap: () {

                },
                isValidate: true,
              )
            ],
          ),
        ),
      ),
    );
  }
}
