import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/user_by_phone_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet shown after a phone number tapped inside a chat message is
/// resolved to a BlueEra user via `user-service/user/by-phone/{phone}`.
/// The "Chat" button opens (or creates) a personal conversation with them.
void showUserByPhoneBottomSheet(UserByPhoneModel user) {
  Get.bottomSheet(
    _PhoneUserSheet(user: user),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
}

class _PhoneUserSheet extends StatelessWidget {
  const _PhoneUserSheet({required this.user});

  final UserByPhoneModel user;

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        user.profileImage != null && user.profileImage!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header: avatar + name + username
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.fillColor,
                  backgroundImage:
                      hasImage ? NetworkImage(user.profileImage!) : null,
                  child: hasImage
                      ? null
                      : const Icon(Icons.person,
                          size: 34, color: AppColors.grayText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        user.name.isEmpty ? 'User' : user.name,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((user.username ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          '@${user.username}',
                          fontSize: 13,
                          color: AppColors.grayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if ((user.contactNo ?? '').isNotEmpty)
              _infoRow(Icons.phone_outlined, user.contactNo!),
            if ((user.location ?? '').isNotEmpty)
              _infoRow(Icons.location_on_outlined, user.location!),
            if ((user.bio ?? '').isNotEmpty)
              _infoRow(Icons.info_outline, user.bio!),
            const SizedBox(height: 22),
            CustomBtn(
              title: 'Chat',
              bgColor: AppColors.primaryColor,
              onTap: () {
                // Close the sheet, then open / create the personal thread.
                Get.back();
                Get.find<ChatViewController>().checkChatConnectionAndOpenChat(
                  userId: user.id,
                  name: user.name,
                  conductNo: user.contactNo,
                  profile: user.profileImage,
                  route: AppConstants.route_contact,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.grayText),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              value,
              fontSize: 14,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
