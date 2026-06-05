import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/cached_avatar_widget.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import 'phone_user_bottom_sheet.dart';

/// Inline preview for a phone number found inside a chat message.
///
/// On first build it fires a one-off BlueEra lookup (cached in
/// [ChatViewController.phoneUserCache]). While unresolved — or when the number
/// has no BlueEra account — it renders the plain tappable underlined number,
/// exactly as before. When a BlueEra user is found it upgrades to a compact
/// chip showing the user's DP + name, tapping which opens their details sheet.
class PhoneUserPreview extends StatefulWidget {
  /// The raw matched number as it appears in the message (may carry +91 /
  /// spaces / dashes). Shown verbatim in the plain fallback.
  final String rawPhone;

  /// Base text style used for the plain-number fallback.
  final TextStyle baseStyle;

  const PhoneUserPreview({
    super.key,
    required this.rawPhone,
    required this.baseStyle,
  });

  @override
  State<PhoneUserPreview> createState() => _PhoneUserPreviewState();
}

class _PhoneUserPreviewState extends State<PhoneUserPreview> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    super.initState();
    // Resolve after the first frame so we never trigger setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatViewController.ensurePhoneUserLoaded(widget.rawPhone);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = chatViewController.cachedPhoneUser(widget.rawPhone);
      if (user == null) {
        // Not yet checked, or checked and not a BlueEra user → plain number.
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            chatViewController.openUserDetailsByPhone(widget.rawPhone);
          },
          child: Text(
            widget.rawPhone,
            style: widget.baseStyle.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }

      // BlueEra user found → DP + name chip.
      final name = user.name.trim().isNotEmpty ? user.name : widget.rawPhone;
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          showUserByPhoneBottomSheet(user);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedAvatarWidget(
                imageUrl: user.profileImage,
                size: 28,
                borderRadius: 14,
                showProfileOnFullScreen: false,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CustomText(
                      widget.rawPhone,
                      fontSize: 11,
                      color: Colors.black54,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
