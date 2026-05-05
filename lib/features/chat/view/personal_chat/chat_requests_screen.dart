import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/ChatRequestsListModel.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lists symbol-reply chat requests returned by
/// `GET chat-service/chat/requests`. Tapping a row opens the existing
/// conversation in [PersonalChatScreen].
class ChatRequestsScreen extends StatefulWidget {
  const ChatRequestsScreen({super.key});

  @override
  State<ChatRequestsScreen> createState() => _ChatRequestsScreenState();
}

class _ChatRequestsScreenState extends State<ChatRequestsScreen> {
  final ChatViewController _controller = getOrPut(() => ChatViewController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getChatRequestsList();
    });
  }

  void _openChat(ChatRequest req) {
    final convId = req.conversationId;
    if (convId == null || convId.isEmpty) return;
    Get.to(() => PersonalChatScreen(
          conversationId: convId,
          userId: req.initiator?.id,
          name: req.initiator?.name,
          contactNo: req.initiator?.contact,
          profileImage: req.initiator?.profileImage,
          type: AppConstants.personal_Chat_Type,
          isInitialMessage: false,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonBackAppBar(
        title: 'Requests',
        showElevation: 0,
        isLeading: true,
        isMore: false,
        isSearch: false,
        isProfile: false,
        isNotification: false,
        isGuestLogout: false,
      ),
      body: Obx(() {
        final status = _controller.chatRequestsListResponse.value.status;
        final items = _controller.chatRequestsListModel.value.data ?? [];

        if (status == Status.LOADING && items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (status == Status.ERROR && items.isEmpty) {
          return const Center(
            child: CustomText('Could not load requests',
                color: Colors.black54, fontSize: 14),
          );
        }
        if (items.isEmpty) {
          return const Center(
            child: CustomText('No requests yet',
                color: Colors.black54, fontSize: 14),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _controller.getChatRequestsList(),
          color: AppColors.primaryColor,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 76, endIndent: 16),
            itemBuilder: (context, i) =>
                _RequestRow(item: items[i], onTap: () => _openChat(items[i])),
          ),
        );
      }),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final ChatRequest item;
  final VoidCallback onTap;

  const _RequestRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initiator = item.initiator;
    final name = (initiator?.name?.isNotEmpty ?? false)
        ? initiator!.name!
        : (initiator?.contact ?? 'Unknown');
    final preview = (item.lastMessage?.isNotEmpty ?? false)
        ? item.lastMessage!
        : (item.lastMessageType == 'reply_to_symbol'
            ? 'Replied to your symbol'
            : '');
    final timestamp = _formatTimestamp(item.requestedAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CachedAvatarWidget(
              imageUrl: initiator?.profileImage ?? '',
              size: 48,
              borderRadius: 24,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          name,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        CustomText(
                          timestamp,
                          fontSize: 11.5,
                          color: Colors.black45,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          preview,
                          fontSize: 13,
                          color: Colors.black54,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((item.status ?? '').isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatusPill(status: item.status!.toLowerCase()),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final isSameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isSameDay) {
      final h = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final m = local.minute.toString().padLeft(2, '0');
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    return '${local.day}/${local.month}/${local.year % 100}';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomText(
        status,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    );
  }

  (Color, Color) _palette(String s) {
    switch (s) {
      case 'accepted':
        return (const Color(0xFFE6F9F1), const Color(0xFF2BB67F));
      case 'rejected':
      case 'declined':
        return (const Color(0xFFFFEBEE), const Color(0xFFD94A42));
      default:
        return (const Color(0xFFFFF3E0), const Color(0xFFE88D1A));
    }
  }
}
