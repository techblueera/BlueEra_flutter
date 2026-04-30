import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/local_assets.dart';
class ChatActionBar extends StatelessWidget {
  final VoidCallback onReminderTap;
  final VoidCallback onCopyTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onForwardTap;

  const ChatActionBar({
    super.key,
    required this.onReminderTap,
    required this.onCopyTap,
    required this.onDeleteTap,
    required this.onForwardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.lightBlueShade.withValues(alpha: 0.2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ChatActionButton(
            title: "Reminder",
            iconPath: AppIconAssets.clock_new,
            onTap: onReminderTap,
          ),
          ChatActionButton(
            title: "Copy",
            iconPath: AppIconAssets.clock_new,
            onTap: onCopyTap,
          ),
          ChatActionButton(
            title: "Delete",
            iconPath: AppIconAssets.deleteIcon,
            onTap: onDeleteTap,
          ),
          ChatActionButton(
            title: "Forward",
            iconPath: AppIconAssets.clock_new,
            onTap: onForwardTap,
          ),
        ],
      ),
    );
  }
}
class ChatActionButton extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback? onTap;

  const ChatActionButton({
    super.key,
    required this.title,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            LocalAssets(
              imagePath: iconPath,
              height: 14,
              width: 14,
            ),
            const SizedBox(width: 6),
            CustomText(
              title,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ],
        ),
      ),
    );
  }
}