import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DiscoverChatIcon extends StatelessWidget {
  final String userId;
  final String? name;
  final String? profile;
  final double size;

  const DiscoverChatIcon({
    super.key,
    required this.userId,
    this.name,
    this.profile,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = userId.trim().isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (!enabled) return;
        if (isGuestUser()) {
          createProfileScreen();
          return;
        }
        final chatViewController = getOrPut(() => ChatViewController());
        chatViewController.checkChatConnectionAndOpenChat(
          userId: userId,
          name: name,
          profile: profile,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primaryColor, width: 0.5),
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.chat,
          height: size,
          width: size,
          imgColor: AppColors.primaryColor,
        ),
      ),
    );
  }
}
