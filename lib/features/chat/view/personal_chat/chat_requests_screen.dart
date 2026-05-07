import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/ChatRequestsListModel.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lists symbol-reply chat requests returned by
/// `GET chat-service/chat/requests`.
///
/// Two sub-tabs (per the v1.1 contract):
///   • **Incoming** — caller is the recipient. Each row exposes
///     Accept · Decline · Decline+Block buttons. Tapping the row also
///     opens the conversation so the recipient can preview the message
///     thread before deciding.
///   • **Sent** — caller is the initiator. Each row exposes a Cancel
///     button. Tapping the row opens the conversation in read mode so the
///     initiator can re-read what they sent (the chat service only allows
///     additional `reply_to_symbol` messages until the recipient accepts).
class ChatRequestsScreen extends StatefulWidget {
  const ChatRequestsScreen({super.key});

  @override
  State<ChatRequestsScreen> createState() => _ChatRequestsScreenState();
}

class _ChatRequestsScreenState extends State<ChatRequestsScreen>
    with SingleTickerProviderStateMixin {
  final ChatViewController _controller = getOrPut(() => ChatViewController());
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-warm both tabs so switching is instant.
      _controller.getChatRequestsList(role: 'incoming');
      _controller.getChatRequestsList(role: 'sent');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Opens the conversation. Works for both incoming and sent because
  /// `GET /chat/requests/:id` is now readable by either party — the chat
  /// screen itself fetches the message history.
  void _openChat(ChatRequest req, {required bool isSent}) {
    final convId = req.conversationId;
    if (convId == null || convId.isEmpty) return;
    final party = isSent ? req.recipient : req.initiator;
    Get.to(() => PersonalChatScreen(
          conversationId: convId,
          userId: party?.id,
          name: party?.name,
          contactNo: party?.contact,
          profileImage: party?.profileImage,
          type: AppConstants.personal_Chat_Type,
          isInitialMessage: false,
        ));
  }

  Future<void> _accept(ChatRequest req) async {
    final id = req.conversationId;
    if (id == null || id.isEmpty) return;
    final ok = await _controller.respondToChatRequest(
        conversationId: id, action: 'accept');
    if (ok) {
      commonSnackBar(message: 'Request accepted');
      // Open the chat so the user can immediately reply.
      _openChat(req, isSent: false);
    }
  }

  Future<void> _decline(ChatRequest req, {bool block = false}) async {
    final id = req.conversationId;
    if (id == null || id.isEmpty) return;
    if (block) {
      final confirmed = await _confirm(
        title: 'Decline & block sender?',
        body:
            'This will permanently silence future requests from this user. Continue?',
        confirmLabel: 'Decline & block',
      );
      if (confirmed != true) return;
    }
    final ok = await _controller.respondToChatRequest(
        conversationId: id, action: 'decline', blockInitiator: block);
    if (ok) {
      commonSnackBar(message: block ? 'Declined & blocked' : 'Request declined');
    }
  }

  Future<void> _cancel(ChatRequest req) async {
    final id = req.conversationId;
    if (id == null || id.isEmpty) return;
    final confirmed = await _confirm(
      title: 'Cancel request?',
      body: 'The recipient will no longer see this request.',
      confirmLabel: 'Cancel request',
    );
    if (confirmed != true) return;
    final ok = await _controller.cancelChatRequest(id);
    if (ok) {
      commonSnackBar(message: 'Request cancelled');
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(title,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
        content: CustomText(body, fontSize: 13.5, color: Colors.black54),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const CustomText('Keep',
                fontSize: 13.5, color: Colors.black54),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText(confirmLabel,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD94A42)),
          ),
        ],
      ),
    );
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 2.5,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Requests'),
                Tab(text: 'Replied'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IncomingList(
                  controller: _controller,
                  onRowTap: (req) => _openChat(req, isSent: false),
                  onAccept: _accept,
                  onDecline: (req) => _decline(req),
                  onDeclineBlock: (req) => _decline(req, block: true),
                ),
                _SentList(
                  controller: _controller,
                  onRowTap: (req) => _openChat(req, isSent: true),
                  onCancel: _cancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Incoming (recipient's view) ───────────────────────────────────────────

class _IncomingList extends StatelessWidget {
  final ChatViewController controller;
  final ValueChanged<ChatRequest> onRowTap;
  final ValueChanged<ChatRequest> onAccept;
  final ValueChanged<ChatRequest> onDecline;
  final ValueChanged<ChatRequest> onDeclineBlock;

  const _IncomingList({
    required this.controller,
    required this.onRowTap,
    required this.onAccept,
    required this.onDecline,
    required this.onDeclineBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.chatRequestsListResponse.value.status;
      final items = controller.chatRequestsListModel.value.data ?? [];
      return _ListShell(
        status: status,
        emptyLabel: 'No incoming requests',
        items: items,
        onRefresh: () =>
            controller.getChatRequestsList(role: 'incoming'),
        rowBuilder: (req) => _RequestRow(
          item: req,
          isSent: false,
          onTap: () => onRowTap(req),
          actions: _IncomingActions(
            onAccept: () => onAccept(req),
            onDecline: () => onDecline(req),
            onDeclineBlock: () => onDeclineBlock(req),
          ),
        ),
      );
    });
  }
}

class _IncomingActions extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDeclineBlock;

  const _IncomingActions({
    required this.onAccept,
    required this.onDecline,
    required this.onDeclineBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Accept',
            background: AppColors.primaryColor,
            foreground: Colors.white,
            onTap: onAccept,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PillButton(
            label: 'Decline',
            background: const Color(0xFFF2F3F5),
            foreground: Colors.black87,
            onTap: onDecline,
          ),
        ),
        const SizedBox(width: 8),
        _IconPillButton(
          icon: Icons.block,
          tooltip: 'Decline & block',
          onTap: onDeclineBlock,
        ),
      ],
    );
  }
}

// ─── Sent (initiator's view) ───────────────────────────────────────────────

class _SentList extends StatelessWidget {
  final ChatViewController controller;
  final ValueChanged<ChatRequest> onRowTap;
  final ValueChanged<ChatRequest> onCancel;

  const _SentList({
    required this.controller,
    required this.onRowTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.sentChatRequestsListResponse.value.status;
      final items = controller.sentChatRequestsListModel.value.data ?? [];
      return _ListShell(
        status: status,
        emptyLabel: 'No outgoing requests',
        items: items,
        onRefresh: () => controller.getChatRequestsList(role: 'sent'),
        rowBuilder: (req) => _RequestRow(
          item: req,
          isSent: true,
          onTap: () => onRowTap(req),
          actions: _SentActions(onCancel: () => onCancel(req)),
        ),
      );
    });
  }
}

class _SentActions extends StatelessWidget {
  final VoidCallback onCancel;
  const _SentActions({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Cancel request',
            background: const Color(0xFFFFEBEE),
            foreground: const Color(0xFFD94A42),
            onTap: onCancel,
          ),
        ),
      ],
    );
  }
}

// ─── Shared list shell + row ───────────────────────────────────────────────

class _ListShell extends StatelessWidget {
  final Status? status;
  final String emptyLabel;
  final List<ChatRequest> items;
  final Future<void> Function() onRefresh;
  final Widget Function(ChatRequest req) rowBuilder;

  const _ListShell({
    required this.status,
    required this.emptyLabel,
    required this.items,
    required this.onRefresh,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (status == Status.LOADING && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    if (status == Status.ERROR && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomText('Could not load requests',
                color: Colors.black54, fontSize: 14),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRefresh,
              child: const CustomText('Retry',
                  color: AppColors.primaryColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: CustomText(emptyLabel,
                  color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 76, endIndent: 16),
        itemBuilder: (context, i) => rowBuilder(items[i]),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final ChatRequest item;
  final bool isSent;
  final VoidCallback onTap;
  final Widget actions;

  const _RequestRow({
    required this.item,
    required this.isSent,
    required this.onTap,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // For Sent rows the counterparty is `recipient`; for Incoming it's
    // `initiator`. `counterparty` on the model resolves the right one.
    final party = isSent ? item.recipient : item.initiator;
    final name = (party?.name?.isNotEmpty ?? false)
        ? party!.name!
        : (party?.contact ?? 'Unknown user');
    final preview = (item.lastMessage?.isNotEmpty ?? false)
        ? item.lastMessage!
        : (item.lastMessageType == 'reply_to_symbol'
            ? (isSent ? 'Replied to their symbol' : 'Replied to your symbol')
            : '');
    final timestamp = _formatTimestamp(item.requestedAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CachedAvatarWidget(
                  imageUrl: party?.profileImage ?? '',
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
            const SizedBox(height: 10),
            // Action row aligned under the text column for visual balance.
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: actions,
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

// ─── Small UI primitives ───────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Center(
            child: CustomText(
              label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPillButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconPillButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Icon(Icons.block, size: 18, color: Color(0xFFD94A42)),
          ),
        ),
      ),
    );
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
