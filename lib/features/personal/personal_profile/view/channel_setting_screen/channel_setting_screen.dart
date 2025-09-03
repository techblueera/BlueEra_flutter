import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'channel_setting_controller.dart';

class ChannelSettingScreen extends StatelessWidget {
  const ChannelSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChannelSettingController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonBackAppBar(
        title: 'Channel Setting',
        isLeading: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: Column(
              children: [
                // Hide or Show Mobile Number
                _buildSettingItem(
                  imagePath:"assets/icons/hide_icon.png",
                  title: 'Hide or Show Mobile Number',
                  control: _buildToggleSwitch(
                    value: controller.hideMobileNumber,
                    onChanged: controller.toggleHideMobileNumber,
                  ),
                ),
                _buildDivider(),

                // Comment Control
                _buildSettingItem(
                  imagePath: "assets/icons/comment_icon.png",
                  title: 'Comment Control',
                  control: _buildSegmentedControl(
                    options: ['Allow', 'Block'],
                    selectedValue: controller.commentControl,
                    onChanged: controller.setCommentControl,
                  ),
                ),
                _buildDivider(),

                // Video Quality
                _buildSettingItem(
                  imagePath: "assets/icons/video_quality_icon.png",
                  title: 'Video Quality',
                  control: _buildDropdown(
                    value: controller.videoQuality,
                    options: ['144p', '240p', '360p', '480p', '720p', '1080p', '1440p'],
                    onChanged: controller.setVideoQuality,
                  ),
                ),
                _buildDivider(),

                // Channel Verified Tag
                _buildSettingItem(
                  imagePath: "assets/icons/channel_icon.png",
                  title: 'Channel Verified Tag',
                  control: _buildVerifiedTag(controller.channelVerifiedTag),
                ),
                _buildDivider(),

                // Audio Control
                _buildSettingItem(
                  imagePath: "assets/icons/audio_icon.png",
                  title: 'Audio Control',
                  control: _buildSegmentedControl(
                    options: ['Mute', 'Auto Play'],
                    selectedValue: controller.audioControl,
                    onChanged: controller.setAudioControl,
                  ),
                ),
                _buildDivider(),

                // Video Control
                _buildSettingItem(
                  imagePath: "assets/icons/video_control_icon.png",
                  title: 'Video Control',
                  control: _buildSegmentedControl(
                    options: ['Stop', 'Auto Play'],
                    selectedValue: controller.videoControl,
                    onChanged: controller.setVideoControl,
                  ),
                ),
                _buildDivider(),

                // Under 18 Restriction
                _buildSettingItem(
                  imagePath: "assets/icons/shield_icon.png",
                  title: 'Under 18 Restriction',
                  control: _buildToggleSwitch(
                    value: controller.under18Restriction,
                    onChanged: controller.toggleUnder18Restriction,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String imagePath, // <-- Replace IconData with image path
    required String title,
    required Widget control,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
      child: Row(
        children: [
          // Image Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(8), // optional padding
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size12),

          // Title
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: SizeConfig.size12),

          // Control
          control,
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required RxBool value,
    required VoidCallback onChanged,
  }) {
    return Obx(() => Transform.scale(
      scale: 0.75, // Adjust scale to reduce size
      child: Switch(
        value: value.value,
        onChanged: (val) => onChanged(),
        activeColor: AppColors.primaryColor,
        activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
        inactiveTrackColor: Colors.grey[300],
        inactiveThumbColor: Colors.grey[400],
      ),
    ));
  }


  Widget _buildSegmentedControl({
    required List<String> options,
    required RxString selectedValue,
    required Function(String) onChanged,
  }) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          bool isSelected = selectedValue.value == option;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomText(
                option,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }

  Widget _buildDropdown({
    required RxString value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Obx(() => PopupMenuButton<String>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              value.value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            SizedBox(width: SizeConfig.size4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: CustomText(
            option,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );
      }).toList(),
      onSelected: onChanged,
    ));
  }

  Widget _buildVerifiedTag(RxBool value) {
    return Obx(() => Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: value.value ? AppColors.primaryColor : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: value.value
          ? Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    ));
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[200],
      height: 1,
      thickness: 0.5,
    );
  }
} 