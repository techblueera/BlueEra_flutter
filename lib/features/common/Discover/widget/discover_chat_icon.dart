import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DiscoverChatIcon extends StatelessWidget {
  final String userId;
  final String? name;
  final String? profile;
  final double size;

  /// When set, a fire-and-forget chat-click event is recorded against
  /// this business id every time the user taps the icon. See
  /// [ChatClickTracker] for behaviour.
  final String? businessId;
  final ChatClickSource trackingSource;
  final Map<String, dynamic>? trackingMetadata;

  /// Conversation lane this chat opens into. Discover is a marketplace/
  /// discovery surface, so it defaults to the `discover` (business) lane —
  /// the chat always opens the business thread, even if a personal one
  /// already exists with this user.
  final String route;

  const DiscoverChatIcon({
    super.key,
    required this.userId,
    this.name,
    this.profile,
    this.size = 18,
    this.businessId,
    this.trackingSource = ChatClickSource.other,
    this.trackingMetadata,
    this.route = AppConstants.route_discover,
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
        final bId = businessId?.trim();
        if (bId != null && bId.isNotEmpty) {
          ChatClickTracker.track(
            businessId: bId,
            source: trackingSource,
            metadata: trackingMetadata,
          );
        }
        final chatViewController = getOrPut(() => ChatViewController());
        chatViewController.checkChatConnectionAndOpenChat(
          userId: userId,
          name: name,
          profile: profile,
          route: route,
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
