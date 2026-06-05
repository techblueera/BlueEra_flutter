import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/cached_avatar_widget.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/starred_message_controller.dart';
import '../../auth/model/starred_message_model.dart';
import '../widget/message_card.dart';

/// Full-screen list of every message the user has starred across all chats.
/// Opened from the "Starred Messages" item in the ConnectMainPage drawer.
/// Each entry renders a WhatsApp-style header ("Sender ▸ Chat" + date) with
/// the real [MessageCard] bubble below it. Data is local-only (see
/// [StarredMessageController]).
class StarredMessagesScreen extends StatelessWidget {
  const StarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => StarredMessageController());
    // MessageCard depends on these via Get.find — make sure they exist even
    // when the screen is opened without ever entering a chat first.
    getOrPut(() => ChatViewController());
    getOrPut(() => ChatThemeController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: CustomText(
          AppStrings.starredMessagesLabel.tr,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        actions: [
          Obx(() => controller.starredMessages.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear all',
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.black54),
                  onPressed: () => _confirmClearAll(context, controller),
                )),
        ],
      ),
      body: Obx(() {
        final items = controller.starredMessages;
        if (items.isEmpty) {
          return _emptyState();
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 6,
            color: Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final starred = items[index];
            return _StarredMessageTile(
              starred: starred,
              onUnstar: () => controller.removeStar(starred),
            );
          },
        );
      }),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          CustomText(
            AppStrings.noStarredMessages.tr,
            fontSize: 15,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(
      BuildContext context, StarredMessageController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText(
          "Clear starred messages",
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        content: const CustomText(
          "Remove all starred messages? This can't be undone.",
          fontSize: 14,
          color: Colors.black87,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const CustomText("Cancel",
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () {
              controller.clearAll();
              Navigator.pop(ctx);
            },
            child: const CustomText("Clear",
                color: AppColors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StarredMessageTile extends StatelessWidget {
  final StarredMessage starred;
  final VoidCallback onUnstar;

  const _StarredMessageTile({
    required this.starred,
    required this.onUnstar,
  });

  @override
  Widget build(BuildContext context) {
    final message = starred.message;
    final bool isMine = message.myMessage ?? false;

    // 1-on-1 chats carry the partner's name as the conversation name, so when
    // the sender equals the conversation name we treat the recipient as "You".
    final String senderName = isMine
        ? 'You'
        : (message.sender?.name?.trim().isNotEmpty ?? false)
            ? message.sender!.name!
            : (starred.conversationName?.trim().isNotEmpty ?? false)
                ? starred.conversationName!
                : AppStrings.unknownLabel.tr;

    final String chatName = isMine
        ? (starred.conversationName?.trim().isNotEmpty ?? false)
            ? starred.conversationName!
            : AppStrings.unknownLabel.tr
        : (senderName == starred.conversationName)
            ? 'You'
            : (starred.conversationName?.trim().isNotEmpty ?? false)
                ? starred.conversationName!
                : 'You';

    final String? senderImage = isMine
        ? message.sender?.profileImage
        : (message.sender?.profileImage ?? starred.conversationProfileImage);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: sender avatar + "Sender ▸ Chat" on the left, date on right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CachedAvatarWidget(
                imageUrl: senderImage,
                size: 32,
                borderRadius: 16,
                showProfileOnFullScreen: false,
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.play_arrow_rounded,
                              size: 16, color: Colors.grey),
                        ),
                      ),
                      TextSpan(
                        text: chatName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                _formatDate(message.createdAt),
                fontSize: 11.5,
                color: Colors.grey.shade500,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          // The real message bubble — rendered exactly as in chat so the full
          // content shows (tap "Read more" on long text, open media, links,
          // etc.). MessageCard already receives every id it needs as explicit
          // params, so its taps work in this detached context too.
          MessageCard(
            message: message,
            isInitialMessage: false,
            conversationId: starred.conversationId ?? message.conversationId,
            userId: message.sender?.id,
            name: message.sender?.name,
            contactNo: message.sender?.contactNo,
            profileImage: message.sender?.profileImage,
            conversationUserId: starred.userId,
            conversationName: starred.conversationName,
            conversationProfileImage: starred.conversationProfileImage,
          ),
          SizedBox(height: SizeConfig.size4),
          // Star (tap to un-star) + starred time, aligned to the bubble side.
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: InkWell(
              onTap: onUnstar,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFE8B100), size: 16),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      _formatTime(message.createdAt),
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('d/M/yy').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }
}