import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_list.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Fullscreen WhatsApp-style search:
/// * Empty query → falls back to the regular `PersonalChatsList`.
/// * Non-empty query → custom two-section result list ("Chats" + "Messages").
///
/// Message search runs against locally cached Hive messages via
/// `LocalStorageHelper.getMessagesByConversationId` for every chat in the
/// snapshot. Async, debounced 250 ms, with sequence-guarded cancellation
/// so old searches can't overwrite newer results. The shared
/// `ChatViewController` state is never mutated, so the home tab stays put.
class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final List<ChatList?> _allChats;

  final RxString _query = ''.obs;
  final RxList<ChatList> _chatHits = <ChatList>[].obs;
  final RxList<_MessageHit> _messageHits = <_MessageHit>[].obs;
  final RxBool _searching = false.obs;

  Timer? _debounce;
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    final full = _chatViewController
            .getPersonalFilteredChatListModel?.value.chatList ??
        const <ChatList?>[];
    final displayed =
        _chatViewController.getPersonalChatListModel?.value.chatList ??
            const <ChatList?>[];
    final source = full.length >= displayed.length ? full : displayed;
    _allChats = List<ChatList?>.from(source);

    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onChanged() {
    if (!mounted) return;
    final q = _controller.text.trim().toLowerCase();
    _query.value = q;

    _debounce?.cancel();
    if (q.isEmpty) {
      _searchSeq++;
      _chatHits.clear();
      _messageHits.clear();
      _searching.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    final seq = ++_searchSeq;
    _searching.value = true;

    // 1) Chat list — name + phone match.
    final chats = _allChats
        .whereType<ChatList>()
        .where((c) {
          final name = c.sender?.name?.toLowerCase() ?? '';
          final phone = c.sender?.contactNo?.toLowerCase() ?? '';
          return name.contains(q) || phone.contains(q);
        })
        .toList();
    if (seq != _searchSeq || !mounted) return;
    _chatHits.assignAll(chats);

    // 2) Messages — scan locally cached Hive messages per conversation.
    final hits = <_MessageHit>[];
    for (final c in _allChats) {
      final convId = c?.conversationId;
      if (c == null || convId == null || convId.isEmpty) continue;
      try {
        final messages = await _chatViewController.localStorageHelper
            .getMessagesByConversationId(convId);
        if (seq != _searchSeq || !mounted) return;
        for (final m in messages) {
          final text = m.message?.toLowerCase();
          if (text == null || text.isEmpty) continue;
          if (text.contains(q)) {
            hits.add(_MessageHit(chat: c, message: m));
          }
        }
      } catch (_) {
        // Ignore per-conversation read failures so one bad box entry can't
        // tank the entire search.
      }
    }
    if (seq != _searchSeq || !mounted) return;
    _messageHits.assignAll(hits);
    _searching.value = false;
  }

  void _openChat(ChatList chat) {
    Get.to(() => PersonalChatScreen(
          type: chat.sender?.accountType,
          isInitialMessage: false,
          userId: chat.sender?.id,
          conversationId: chat.conversationId,
          profileImage: chat.sender?.profileImage,
          name: chat.sender?.name,
          contactNo: chat.sender?.contactNo,
        ));
  }

  @override
  void dispose() {
    _searchSeq++;
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Search chats and messages...',
            hintStyle: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryTextColor,
            ),
            border: InputBorder.none,
            isCollapsed: true,
          ),
        ),
        actions: [
          Obx(() {
            if (_query.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => _controller.clear(),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_query.value.isEmpty) {
          return PersonalChatsList(isForwardUI: false);
        }
        if (_searching.value &&
            _chatHits.isEmpty &&
            _messageHits.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (_chatHits.isEmpty && _messageHits.isEmpty) {
          return _buildNoResults();
        }
        return _buildResults();
      }),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_chatHits.isNotEmpty) ...[
          _sectionHeader('Chats', _chatHits.length),
          ..._chatHits.map(
            (c) => _ChatHitTile(
              chat: c,
              query: _query.value,
              onTap: () => _openChat(c),
            ),
          ),
        ],
        if (_messageHits.isNotEmpty) ...[
          _sectionHeader('Messages', _messageHits.length),
          ..._messageHits.map(
            (h) => _MessageHitTile(
              hit: h,
              query: _query.value,
              onTap: () => _openChat(h.chat),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      color: const Color(0xffF7F9FC),
      child: CustomText(
        '${label.toUpperCase()}  ·  $count',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.search_off,
                size: 32, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 14),
          const CustomText(
            'No chats or messages found',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          CustomText(
            'Try a different name, number, or keyword.',
            fontSize: 12,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _MessageHit {
  final ChatList chat;
  final Messages message;

  const _MessageHit({required this.chat, required this.message});
}

class _ChatHitTile extends StatelessWidget {
  final ChatList chat;
  final String query;
  final VoidCallback onTap;

  const _ChatHitTile({
    required this.chat,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = chat.sender?.name ?? 'Unknown';
    final phone = chat.sender?.contactNo ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: chat.sender?.profileImage ?? '',
              size: 44,
              borderRadius: 22,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlighted(name, query, baseStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  )),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _highlighted(phone, query, baseStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageHitTile extends StatelessWidget {
  final _MessageHit hit;
  final String query;
  final VoidCallback onTap;

  const _MessageHitTile({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chat = hit.chat;
    final name = chat.sender?.name ?? 'Unknown';
    final messageText = hit.message.message ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: chat.sender?.profileImage ?? '',
              size: 44,
              borderRadius: 22,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    name,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _highlighted(
                    messageText,
                    query,
                    baseStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryTextColor,
                    ),
                    maxLines: 2,
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

/// Renders [text] with every case-insensitive occurrence of [query] painted
/// in the brand primary colour.
Widget _highlighted(
  String text,
  String query, {
  required TextStyle baseStyle,
  int maxLines = 1,
}) {
  if (query.isEmpty || text.isEmpty) {
    return Text(
      text,
      style: baseStyle,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final spans = <TextSpan>[];
  int start = 0;
  while (start < text.length) {
    final idx = lowerText.indexOf(lowerQuery, start);
    if (idx < 0) {
      spans.add(TextSpan(text: text.substring(start)));
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx)));
    }
    spans.add(TextSpan(
      text: text.substring(idx, idx + lowerQuery.length),
      style: const TextStyle(
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w700,
      ),
    ));
    start = idx + lowerQuery.length;
  }
  return RichText(
    text: TextSpan(style: baseStyle, children: spans),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}
