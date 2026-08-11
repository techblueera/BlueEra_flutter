import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/user_by_phone_model.dart';
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

  /// BlueEra user resolved from a typed 10-digit mobile number via
  /// `user/by-phone` (same lookup the shared-contact card uses). Null when the
  /// query isn't a phone number, the lookup is still running, or the number has
  /// no BlueEra account.
  final Rxn<UserByPhoneModel> _phoneUser = Rxn<UserByPhoneModel>();

  /// True while the by-phone lookup for the current query is on the wire.
  final RxBool _phoneLookingUp = false.obs;

  /// True once the lookup for the current query finished (found or not), so the
  /// UI can tell "still checking" from "checked, not on BlueEra".
  final RxBool _phoneChecked = false.obs;

  Timer? _debounce;
  int _searchSeq = 0;

  /// Only digits / phone punctuation — a name query never triggers a lookup.
  static final RegExp _phoneLike = RegExp(r'^[0-9+\-\s()]+$');

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
      _resetPhoneLookup();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _runSearch(q);
    });
  }

  void _resetPhoneLookup() {
    _phoneUser.value = null;
    _phoneLookingUp.value = false;
    _phoneChecked.value = false;
  }

  /// The 10-digit national number [q] represents, or null when it isn't a plain
  /// mobile number the `user/by-phone` API can be asked about.
  String? _phoneDigitsOf(String q) {
    if (!_phoneLike.hasMatch(q)) return null;
    return _chatViewController.normalizePhone(q);
  }

  /// Resolve a typed mobile number to a BlueEra account so a number with no
  /// existing thread can still be opened as a chat. Cache-first inside the
  /// controller, so retyping the same number costs nothing.
  Future<void> _runPhoneLookup(String digits, int seq) async {
    _phoneLookingUp.value = true;
    _phoneChecked.value = false;
    try {
      final user = await _chatViewController.resolveBlueEraUserByPhone(digits);
      if (seq != _searchSeq || !mounted) return;
      _phoneUser.value = (user != null && user.id.isNotEmpty) ? user : null;
    } catch (_) {
      if (seq != _searchSeq || !mounted) return;
      _phoneUser.value = null;
    }
    if (seq != _searchSeq || !mounted) return;
    _phoneLookingUp.value = false;
    _phoneChecked.value = true;
  }

  Future<void> _runSearch(String q) async {
    final seq = ++_searchSeq;
    _searching.value = true;

    // 0) A full 10-digit number also gets looked up on BlueEra, in parallel
    // with the local scan below so the API round-trip doesn't delay results.
    final digits = _phoneDigitsOf(q);
    if (digits == null) {
      _resetPhoneLookup();
    } else {
      unawaited(_runPhoneLookup(digits, seq));
    }

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

  /// Open (or create) the personal thread with a user found by phone number.
  /// Goes through `checkChatConnectionAndOpenChat` so a first-time number gets
  /// its conversation resolved/created exactly like a contact-list tap.
  void _openPhoneUserChat(UserByPhoneModel user) {
    _focusNode.unfocus();
    _chatViewController.checkChatConnectionAndOpenChat(
      userId: user.id,
      name: user.name,
      conductNo: user.contactNo,
      profile: user.profileImage,
      route: AppConstants.route_contact,
    );
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  splashRadius: 22,
                  icon: const Icon(Icons.arrow_back,
                      size: 22, color: Colors.black87),
                  onPressed: () => Get.back(),
                ),
                Expanded(child: _buildSearchField()),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (_query.value.isEmpty) {
          return PersonalChatsList(isForwardUI: false);
        }
        final hasAnything = _chatHits.isNotEmpty ||
            _messageHits.isNotEmpty ||
            _phoneUser.value != null ||
            _phoneLookingUp.value;
        if (_searching.value && !hasAnything) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (!hasAnything) {
          return _buildNoResults();
        }
        return _buildResults();
      }),
    );
  }

  /// Rounded pill field: search glyph, text, and a clear button that only
  /// appears once there is something to clear. Fixed 44 px height so the
  /// glyph, text and clear button stay vertically centred together.
  Widget _buildSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF2F4F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE4E8EF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search,
              size: 20, color: AppColors.secondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: AppColors.primaryColor,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                height: 1.2,
              ),
              decoration: const InputDecoration(
                hintText: 'Search name, number or message',
                hintStyle: TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  color: AppColors.secondaryTextColor,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Obx(() {
            if (_query.value.isEmpty) return const SizedBox(width: 4);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controller.clear(),
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.close,
                    size: 18, color: AppColors.secondaryTextColor),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // A number that already has a thread is shown once, as the chat row.
    final phoneUser = _phoneUser.value;
    final alreadyInChats = phoneUser != null &&
        _chatHits.any((c) => c.sender?.id == phoneUser.id);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_phoneLookingUp.value) ...[
          _sectionHeader('On BlueEra', null),
          const _PhoneLookupLoadingTile(),
        ] else if (phoneUser != null && !alreadyInChats) ...[
          _sectionHeader('On BlueEra', 1),
          _PhoneUserTile(
            user: phoneUser,
            query: _query.value,
            onTap: () => _openPhoneUserChat(phoneUser),
          ),
        ],
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

  Widget _sectionHeader(String label, int? count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      color: const Color(0xffF7F9FC),
      child: CustomText(
        count == null ? label.toUpperCase() : '${label.toUpperCase()}  ·  $count',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _buildNoResults() {
    // A typed number that was checked and isn't on BlueEra gets its own copy,
    // so the user knows the lookup ran rather than that search simply missed.
    final isCheckedPhone =
        _phoneChecked.value && _phoneDigitsOf(_query.value) != null;
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
          CustomText(
            isCheckedPhone
                ? 'This number is not on BlueEra'
                : 'No chats or messages found',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: CustomText(
              isCheckedPhone
                  ? 'No BlueEra account is registered with this mobile number.'
                  : 'Try a different name, number, or keyword.',
              fontSize: 12,
              textAlign: TextAlign.center,
              color: AppColors.secondaryTextColor,
            ),
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

/// Placeholder row shown while the typed number is being looked up on BlueEra,
/// so the section doesn't pop in from nothing.
class _PhoneLookupLoadingTile extends StatelessWidget {
  const _PhoneLookupLoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 14),
          CustomText(
            'Checking this number on BlueEra…',
            fontSize: 13,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

/// Chat-list-styled row for a user resolved from a typed mobile number. Tapping
/// it opens (or starts) the personal chat with them.
class _PhoneUserTile extends StatelessWidget {
  final UserByPhoneModel user;
  final String query;
  final VoidCallback onTap;

  const _PhoneUserTile({
    required this.user,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim().isNotEmpty ? user.name : 'BlueEra user';
    final phone = user.contactNo ?? '';
    final subtitle = user.subtitle;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: user.profileImage ?? '',
              size: 46,
              borderRadius: 23,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 14),
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
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _highlighted(
                      phone,
                      query,
                      baseStyle: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle!,
                      fontSize: 11.5,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CustomText(
                'Chat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CachedAvatarWidget(
              imageUrl: chat.sender?.profileImage ?? '',
              size: 46,
              borderRadius: 23,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 14),
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
                    const SizedBox(height: 3),
                    _highlighted(phone, query, baseStyle: const TextStyle(
                      fontSize: 12.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedAvatarWidget(
              imageUrl: chat.sender?.profileImage ?? '',
              size: 46,
              borderRadius: 23,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
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
