import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class GuestDashBoardScreen extends StatefulWidget {
  const GuestDashBoardScreen({super.key});

  @override
  State<GuestDashBoardScreen> createState() => _GuestDashBoardScreenState();
}

class _GuestDashBoardScreenState extends State<GuestDashBoardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              "Guest User",
              fontSize: SizeConfig.size24,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(
              height: SizeConfig.size10,
            ),
            CustomText(
              "Create a account to access all features and enjoy the full experience!",
              fontSize: SizeConfig.size15,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: SizeConfig.size20,
            ),
            PositiveCustomBtn(
                onTap: () {
                  createProfileScreen();
                },
                title: "Create Profile")
          ],
        ),
      ),
    );
  }
}
