import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/services/chat_media_storage_service.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../forward_screen/chat_forward_screen.dart';
import 'common_delete_message.dart';
import 'reminder_sheet.dart';

/// Shows an iOS iMessage-style context menu above the long-pressed message.
void showMessageContextMenu({
  required BuildContext context,
  required Messages message,
  required GlobalKey messageKey,
  required bool isReceive,
  required Widget messageWidget,
  String? conversationId,
  String? userId,
  String? name,
  String? profileImage,
}) {
  final renderBox =
      messageKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  HapticFeedback.mediumImpact();

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => _MessageContextMenuOverlay(
        messagePosition: position,
        messageSize: size,
        isReceive: isReceive,
        messageWidget: messageWidget,
        message: message,
        conversationId: conversationId,
        userId: userId,
        name: name,
        profileImage: profileImage,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
    ),
  );
}

class _MessageContextMenuOverlay extends StatelessWidget {
  final Offset messagePosition;
  final Size messageSize;
  final bool isReceive;
  final Widget messageWidget;
  final Messages message;
  final String? conversationId;
  final String? userId;
  final String? name;
  final String? profileImage;

  const _MessageContextMenuOverlay({
    required this.messagePosition,
    required this.messageSize,
    required this.isReceive,
    required this.messageWidget,
    required this.message,
    this.conversationId,
    this.userId,
    this.name,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Total height: emoji row (~52) + gap (8) + menu (~310)
    final totalMenuHeight = 370.0;

    final spaceAbove = messagePosition.dy - padding.top;
    final spaceBelow =
        screenSize.height - messagePosition.dy - messageSize.height - padding.bottom;
    final showAbove = spaceAbove > totalMenuHeight || spaceAbove > spaceBelow;

    double menuTop;
    if (showAbove) {
      menuTop = messagePosition.dy - totalMenuHeight - 8;
      if (menuTop < padding.top + 8) menuTop = padding.top + 8;
    } else {
      menuTop = messagePosition.dy + messageSize.height + 8;
    }

    final menuWidth = 220.0;
    final menuLeft = isReceive ? 16.0 : screenSize.width - menuWidth - 16;
    final clampedLeft = menuLeft.clamp(12.0, screenSize.width - menuWidth - 12);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),

            // The message itself (snapshot)
            Positioned(
              left: messagePosition.dx,
              top: messagePosition.dy,
              width: messageSize.width,
              height: messageSize.height,
              child: IgnorePointer(
                child: messageWidget,
              ),
            ),

            // Emoji row + Context menu
            Positioned(
              left: clampedLeft,
              top: menuTop,
              child: Column(
                crossAxisAlignment:
                    isReceive ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  _ContextMenuCard(
                    message: message,
                    conversationId: conversationId,
                    userId: userId,
                    name: name,
                    profileImage: profileImage,
                  ),
                  const SizedBox(height: 8),
                  _EmojiReactionRow(
                    message: message,
                    conversationId: conversationId,
                    onReact: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiReactionRow extends StatelessWidget {
  final Messages message;
  final String? conversationId;
  final VoidCallback onReact;

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥'];

  const _EmojiReactionRow({
    required this.message,
    this.conversationId,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _emojis.map((emoji) {
          return GestureDetector(
            onTap: () {
              // TODO: Emit reaction via socket when backend is ready
              onReact();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ContextMenuCard extends StatelessWidget {
  final Messages message;
  final String? conversationId;
  final String? userId;
  final String? name;
  final String? profileImage;

  const _ContextMenuCard({
    required this.message,
    this.conversationId,
    this.userId,
    this.name,
    this.profileImage,
  });

  /// Whether this message has downloadable media (image, video, audio, document).
  bool get _isMediaMessage {
    final type = message.messageType?.toLowerCase() ?? '';
    return ['image', 'video', 'audio', 'document'].contains(type) &&
        message.url != null &&
        message.url!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final chatViewController = Get.find<ChatViewController>();
    final chatThemeController = Get.find<ChatThemeController>();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              icon: Icons.reply_rounded,
              label: "Reply",
              onTap: () {
                Navigator.of(context).pop();
                chatViewController.setReplyMessage(message);
              },
            ),
            _divider(),
            _menuItem(
              icon: Icons.copy_rounded,
              label: "Copy",
              onTap: () {
                Navigator.of(context).pop();
                if (message.message != null) {
                  Clipboard.setData(ClipboardData(text: message.message!));
                  Get.snackbar("Copied", "Message copied to clipboard",
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 1));
                }
              },
            ),
            _divider(),
            _menuItem(
              icon: Icons.shortcut_rounded,
              label: "Forward",
              onTap: () {
                Navigator.of(context).pop();
                chatThemeController.activateSelection(message);
                Get.to(() => ChatForwardScreen());
              },
            ),

            // Download option — only for media messages
            if (_isMediaMessage) ...[
              _divider(),
              _menuItem(
                icon: Icons.download_rounded,
                label: "Download",
                onTap: () {
                  Navigator.of(context).pop();
                  _downloadMedia(context, message);
                },
              ),
            ],

            _divider(),
            _menuItem(
              icon: Icons.alarm_rounded,
              label: "Reminder",
              onTap: () {
                Navigator.of(context).pop();
                chatThemeController.activateSelection(message);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => ReminderBottomSheet(
                    name: name,
                    conversationId: conversationId,
                    profileImagePath: profileImage,
                  ),
                );
              },
            ),
            _divider(),
            _menuItem(
              icon: Icons.check_circle_outline_rounded,
              label: "Select",
              onTap: () {
                Navigator.of(context).pop();
                chatThemeController.activateSelection(message);
              },
            ),
            _divider(),
            _menuItem(
              icon: Icons.delete_outline_rounded,
              label: "Delete",
              color: Colors.red,
              onTap: () {
                Navigator.of(context).pop();
                chatThemeController.activateSelection(message);
                showDialog(
                  context: context,
                  builder: (_) => CommonDeleteDialog(
                    showDeleteForEveryone: message.myMessage == true,
                    showDeleteFromDevice: _isMediaMessage,
                    onDeleteForMe: () async {
                      Map<String, dynamic> data = {
                        ApiKeys.conversation_id: "$conversationId",
                        ApiKeys.delete_from_every_one: false,
                        ApiKeys.message_id_list:
                            chatThemeController.selectedMessageIds,
                      };
                      await chatViewController.deleteChatMessage(
                          data, userId ?? '');
                      chatThemeController.resetSelection();
                      chatThemeController.deActivateSelection();
                      Navigator.pop(context);
                    },
                    onDeleteForEveryone: () async {
                      // Delete from server
                      Map<String, dynamic> data = {
                        ApiKeys.conversation_id: "$conversationId",
                        ApiKeys.delete_from_every_one: true,
                        ApiKeys.message_id_list:
                            chatThemeController.selectedMessageIds,
                      };
                      await chatViewController.deleteChatMessage(
                          data, userId ?? '');

                      // Also delete from device storage
                      _deleteMediaFromDevice(message);

                      chatThemeController.resetSelection();
                      chatThemeController.deActivateSelection();
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Downloads all media files from the message to BlueEra folder.
  static void _downloadMedia(BuildContext context, Messages message) async {
    final type = message.messageType ?? 'image';
    final urls = message.url ?? [];
    if (urls.isEmpty) return;

    Get.snackbar(
      "Downloading",
      "Saving to BlueEra/${type == 'document' ? 'Documents' : '${type[0].toUpperCase()}${type.substring(1)}'}...",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.download_rounded, color: Colors.white),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );

    int saved = 0;
    for (final media in urls) {
      if (media.url == null || media.url!.isEmpty) continue;
      final file = await ChatMediaStorageService.downloadAndSave(
        url: media.url!,
        messageType: type,
        fileName: media.name,
      );
      if (file != null) saved++;
    }

    Get.snackbar(
      saved > 0 ? "Saved" : "Failed",
      saved > 0
          ? "$saved file${saved > 1 ? 's' : ''} saved to BlueEra folder"
          : "Could not save files. Check permissions.",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      icon: Icon(
        saved > 0 ? Icons.check_circle_rounded : Icons.error_outline,
        color: Colors.white,
      ),
      backgroundColor: saved > 0 ? Colors.green.shade700 : Colors.red.shade700,
      colorText: Colors.white,
    );
  }

  /// Deletes saved media files from the device when "Delete for everyone" is used.
  static void _deleteMediaFromDevice(Messages message) {
    final type = message.messageType ?? 'image';
    final urls = message.url ?? [];
    if (urls.isEmpty) return;

    final urlStrings = urls
        .where((m) => m.url != null && m.url!.isNotEmpty)
        .map((m) => m.url!)
        .toList();

    ChatMediaStorageService.deleteMediaFiles(urlStrings, messageType: type);
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 0.5, thickness: 0.5, color: Colors.grey.shade200);
  }
}
