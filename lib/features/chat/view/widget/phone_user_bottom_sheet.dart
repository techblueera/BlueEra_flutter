import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/user_by_phone_model.dart';
import 'package:BlueEra/features/chat/auth/service/call_activity_service.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

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
                      if ((user.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        CustomText(
                          user.subtitle!,
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
            const SizedBox(height: 18),
            // Quick actions — in-app Chat / Audio call / Video call to this
            // BlueEra user (call flow mirrors the chat appbar in
            // component_widgets.dart).
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.fillColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _quickAction(
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.primaryColor,
                    label: 'Chat',
                    onTap: () {
                      // Close the sheet, then open / create the personal thread.
                      Get.back();
                      Get.find<ChatViewController>()
                          .checkChatConnectionAndOpenChat(
                        userId: user.id,
                        name: user.name,
                        conductNo: user.contactNo,
                        profile: user.profileImage,
                        route: AppConstants.route_contact,
                      );
                    },
                  ),
                  _quickAction(
                    icon: Icons.call,
                    color: Colors.green,
                    label: 'Audio',
                    onTap: () {
                      Get.back();
                      _startBlueEraCall(user, CallType.audio);
                    },
                  ),
                  _quickAction(
                    icon: Icons.videocam,
                    color: Colors.blue,
                    label: 'Video',
                    onTap: () {
                      Get.back();
                      _startBlueEraCall(user, CallType.video);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    title: 'View Profile',
                    bgColor: Colors.white,
                    textColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                    onTap: _onViewProfile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomBtn(
                    title: 'Add to contact',
                    bgColor: AppColors.primaryColor,
                    onTap: () {
                      Get.back();
                      _saveContactWithEditor(
                        name: user.name,
                        phone: user.contactNo ?? '',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 6),
              CustomText(
                label,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: wire up to the real profile screen once available.
  // Dummy handler for now — closes the sheet and shows a placeholder.
  void _onViewProfile() {
    Get.back();
    commonSnackBar(message: 'View Profile coming soon');
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

/// Bottom sheet shown when a tapped phone number is NOT a BlueEra user
/// (API returns `{"status":false,"message":"User not found"}`). Offers to
/// save the number as a new contact via the native contact editor.
void showAddNewContactBottomSheet(String phone) {
  Get.bottomSheet(
    _AddNewContactSheet(phone: phone),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
}

class _AddNewContactSheet extends StatelessWidget {
  const _AddNewContactSheet({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.fillColor,
                  child: const Icon(Icons.person_off_outlined,
                      size: 32, color: AppColors.grayText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        'No BlueEra user found',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        phone,
                        fontSize: 14,
                        color: AppColors.grayText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            CustomBtn(
              title: 'Add New Contact',
              bgColor: AppColors.primaryColor,
              onTap: () {
                Get.back();
                _saveContactWithEditor(phone: phone);
              },
            ),
            const SizedBox(height: 12),
            CustomBtn(
              title: 'Invite to BlueEra',
              bgColor: Colors.white,
              textColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
              onTap: () {
                Get.back();
                _inviteToBlueEra();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the OS share sheet with the standard BlueEra invite message.
  Future<void> _inviteToBlueEra() async {
    await SharePlus.instance.share(
      ShareParams(
        text: AppConstants.shareAppMsg,
        subject: AppConstants.shareAppMsg,
      ),
    );
  }
}

/// Format a raw phone string to Indian E.164 (`+91XXXXXXXXXX`) so the contact
/// is saved with the country code.
String _toIndianNumber(String raw) {
  String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return raw;
  if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
  if (digits.length == 10) return '+91$digits';
  if (digits.length > 10) return '+91${digits.substring(digits.length - 10)}';
  return raw;
}

/// Opens the native contact editor prefilled with [name] / [phone] so the user
/// can review/edit before saving. Shared by the BlueEra-user sheet (where a
/// name is known) and the "no user found" sheet (number only).
Future<void> _saveContactWithEditor({String? name, required String phone}) async {
  final permissionStatus = await Permission.contacts.request();
  if (permissionStatus.isGranted) {
    final contact = Contact()..phones = [Phone(_toIndianNumber(phone))];
    if (name != null && name.trim().isNotEmpty) {
      contact.name = Name(first: name.trim());
    }
    await FlutterContacts.openExternalInsert(contact);
  } else {
    commonSnackBar(message: 'Contact permission denied');
  }
}

/// Place an in-app BlueEra call ([CallType.audio] / [CallType.video]) to a
/// number-resolved user. On Android the call runs in the native CallActivity
/// (WhatsApp-style separate task) with an in-app fallback if it can't launch;
/// elsewhere it goes straight to the in-app CallRoomScreen. Mirrors the call
/// flow used by the chat appbar in component_widgets.dart.
void _startBlueEraCall(UserByPhoneModel user, CallType type) {
  final targetUserId = user.id;
  if (targetUserId.isEmpty) return;
  final targetUserName = user.name.isNotEmpty ? user.name : 'User';
  final targetUserImage = user.profileImage ?? '';

  if (Platform.isAndroid) {
    CallController.isCallActivityActive = true;
    CallActivityService.launchCallActivity(
      callId: '',
      roomId: '',
      conversationId: '',
      callType: type == CallType.video ? 'video' : 'audio',
      callerName: targetUserName,
      callerImage: targetUserImage,
      remoteUserId: targetUserId,
      remoteUserName: targetUserName,
      remoteUserImage: targetUserImage,
      isCaller: true,
    ).then((launched) {
      if (!launched) {
        CallController.isCallActivityActive = false;
        _startBlueEraCallInApp(
            targetUserId, targetUserName, targetUserImage, type);
      }
    });
    return;
  }

  _startBlueEraCallInApp(targetUserId, targetUserName, targetUserImage, type);
}

void _startBlueEraCallInApp(
    String otherUserId, String userName, String userImage, CallType type) async {
  if (!Get.isRegistered<CallController>()) {
    Get.put(CallController());
  }
  final callController = Get.find<CallController>();
  final success = await callController.initiateCall(
    type: type,
    otherUserId: otherUserId,
    userName: userName,
    userImage: userImage,
  );
  if (success) {
    Get.toNamed('/CallRoomScreen');
  }
}
