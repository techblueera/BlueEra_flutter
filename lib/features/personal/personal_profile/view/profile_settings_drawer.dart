import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ProfileSettingsDrawer extends StatelessWidget {
  const ProfileSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Profile setting",
        isLeading: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: 12,
        ),
        children: [
          _buildSettingCard(
            icon: AppIconAssets.app_setting_edit_profile,
            title: "Edit Profile",
            onTap: () {},
          ),
          _buildSettingCard(
            icon: AppIconAssets.editIcon,
            title: "Edit Category",
            onTap: () {},
          ),
          _buildSettingCard(
            icon: AppIconAssets.app_setting_change_phone_number,
            title: "Change Phone number",
            onTap: () {},
          ),
          _buildSettingCard(
            icon: AppIconAssets.email,
            title: "Change Your Email",
            onTap: () {},
          ),
          _buildSettingCard(
            icon: AppIconAssets.verifiedIcon,
            title: "Email Verification",
            onTap: () {},
            statusWidget: _statusChip("Verified", isGreen: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String icon,
    required String title,
    required VoidCallback onTap,
    Widget? statusWidget,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size18,
            vertical: SizeConfig.size18,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.whiteE5,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              LocalAssets(
                imagePath: icon,
                height: 20,
                width: 20,
                boxFix: BoxFit.cover,
                imgColor: AppColors.secondaryTextColor,
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (statusWidget != null) statusWidget,
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String text, {bool isGreen = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: isGreen ? AppColors.green4F : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.size10,
        color: isGreen ? Colors.white : AppColors.mainTextColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}