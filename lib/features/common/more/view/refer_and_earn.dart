import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/common_back_app_bar.dart';

const appBarTitle = "Refer And Earn";
const inviteTitle = "Invite & Earn Upto 100 Coins";
const coinsValue = "100 Coins = ₹10";
const totalEarnLabel = "Total Earn";
const totalEarnValue = "₹ 10,000";
const copyCodeLabel = "Copy Your Code:";
const referralCode = "adf8zd";
const shareLabel = "Share Your Referral Code Via";

class ReferAndEarnScreen extends StatefulWidget {
  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreen();
}

class _ReferAndEarnScreen extends State<ReferAndEarnScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: appBarTitle,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferralBanner(),
            Container(
              margin: EdgeInsets.only(
                left: SizeConfig.paddingS,
                right: SizeConfig.paddingS,
                top: SizeConfig.size20,
              ),
              width: double.infinity,
              padding: EdgeInsets.all(SizeConfig.paddingS),
              decoration: BoxDecoration(
                color: AppColors.blue2A,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    totalEarnValue,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w500,
                  ),
                  CustomText(
                    totalEarnLabel,
                    fontSize: SizeConfig.size20,
                    fontWeight: FontWeight.w700,
                  )
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.size10,
            ),
            Container(
              margin: EdgeInsets.only(
                left: SizeConfig.paddingS,
                right: SizeConfig.paddingS,
              ),
              width: double.infinity,
              padding: EdgeInsets.all(SizeConfig.paddingS),
              decoration: BoxDecoration(
                color: AppColors.blue2A,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        copyCodeLabel,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w400,
                        color: AppColors.greyCA,
                      ),
                      CustomText(
                        referralCode,
                        fontSize: SizeConfig.size20,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: LocalAssets(imagePath: AppIconAssets.copyIcon),
                  )
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.size20,
            ),
            CustomText(
              shareLabel,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(
              height: SizeConfig.size10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlowingIconCircle(
                    glowColor: AppColors.pinkE2,
                    iconPath: AppIconAssets.instaIcon,
                    onTap: () {}),
                SizedBox(
                  width: SizeConfig.size10,
                ),
                GlowingIconCircle(
                  onTap: () {},
                  glowColor: AppColors.greenLight,
                  iconPath: AppIconAssets.whatsappIcon,
                ),
                SizedBox(
                  width: SizeConfig.size10,
                ),
                GlowingIconCircle(
                  onTap: () {},
                  glowColor: AppColors.white99,
                  iconPath: AppIconAssets.gradientMsg,
                ),
                SizedBox(
                  width: SizeConfig.size10,
                ),
                InkWell(
                    onTap: () {},
                    child: LocalAssets(
                        imagePath: AppIconAssets.horizontalThreeDots)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

//GlowingIconCircle
class GlowingIconCircle extends StatelessWidget {
  final Color glowColor;
  final String iconPath;
  final double? size;
  final double glowSize;
  final Color backgroundColor;
  final VoidCallback onTap;

  GlowingIconCircle({
    Key? key,
    required this.glowColor,
    required this.iconPath,
    required this.onTap,
    this.size,
    this.glowSize = 30,
    this.backgroundColor = AppColors.blue2A, // Default dark background
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      radius: SizeConfig.size50,
      // customBorder: CircleBorder(),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: SizeConfig.size50,
            height: SizeConfig.size50,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: glowSize,
            height: glowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 5,
                  spreadRadius: 0,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          LocalAssets(height: size, width: size, imagePath: iconPath),
        ],
      ),
    );
  }
}

//Referral Banner
class ReferralBanner extends StatelessWidget {
  const ReferralBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.screenHeight * 0.42,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            AppColors.blue3F,
            AppColors.darkBlue25,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: const Border(
          bottom: BorderSide(
            color: Colors.white,
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: SizeConfig.size8,
            child: LocalAssets(
              height: SizeConfig.screenWidth * 0.7,
              width: SizeConfig.screenWidth * 0.7,
              imagePath: AppImageAssets.refer_earn_bg,
            ),
          ),
          Positioned(
            top: SizeConfig.screenHeight * 0.31,
            left: SizeConfig.size50,
            right: SizeConfig.size50,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size14,
                horizontal: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.white0D,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  CustomText(
                    inviteTitle,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                  ),
                  CustomText(
                    coinsValue,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
