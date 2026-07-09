import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/services/notification_utils.dart';
import '../../auth/controller/call_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/socket/chat_socket.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/broadcast_message_card.dart';
import '../widget/chat_input_box.dart';
import '../widget/component_widgets.dart';
import '../widget/message_card.dart';
import '../widget/ongoing_call_message_card.dart';

class PersonalChatScreen extends StatefulWidget {
  PersonalChatScreen(
      {required this.conversationId,
      required this.userId,
      this.profileImage,
      required this.type,
      this.name,
      this.contactNo,
      required this.isInitialMessage,
      this.prefilledMessage});

  final String? conversationId;
  final String? userId;
  final String? profileImage;
  final String? name;
  final String? contactNo;
  final String? type;
  final bool isInitialMessage;
  /// Optional intro text seeded into the input field on first open. Survives
  /// the in-init `clear()` because we apply it right after.
  final String? prefilledMessage;


  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen>
    with WidgetsBindingObserver {

  final chatViewController = Get.find<ChatViewController>();
  // Self-register so the personal chat screen works regardless of entry path
  // (e.g. opened from an order/inquiry deep-link) — the theme controller is
  // otherwise registered by the chat list/tab flows. Matches how the other
  // chat screens obtain it.
  final chatThemeController = getOrPut(() => ChatThemeController());
  final TextEditingController editingController = TextEditingController();

  // Whether a call for THIS conversation is currently live. Driven by a poll of
  // the cross-isolate active-call record (the call may run in Android's separate
  // CallActivity engine, so reactive controller state isn't reliable here).
  // When true, a synthetic `callongoing` message is injected at the bottom of
  // the thread.
  final RxBool _ongoingCallActive = false.obs;
  Timer? _ongoingCallPoll;

  @override
  void initState() {
    // This screen is the personal lane: tag outgoing sends with the `contact`
    // route so a first message looks up / creates the personal conversation.
    // Admin (system) chats opt out and keep legacy route-less behaviour.
    chatViewController.activeRoute =
        widget.type == "Admin" ? null : AppConstants.route_contact;
    chatViewController.sendMessageController.value.clear();
    chatViewController.isTextFieldEmpty.value = false;
    final prefill = widget.prefilledMessage;
    if (prefill != null && prefill.isNotEmpty) {
      chatViewController.sendMessageController.value.text = prefill;
      // `isTextFieldEmpty` has inverted semantics in this codebase — see
      // chat_input_box.dart onChanged: it's `true` when the field HAS text.
      // The send icon only shows in that state; otherwise the mic shows.
      chatViewController.isTextFieldEmpty.value = true;
    }
    chatViewController.listenUserNewMessages(
        userId: widget.userId ?? "",
        conversationId: widget.conversationId ?? '');
    chatThemeController.resetSelection();

    // Track scroll position for scroll-to-bottom FAB
    chatViewController.isUserScrolledUp.value = false;
    chatViewController.unreadNewMessageCount.value = 0;
    chatViewController.scrollController.addListener(_onScroll);

    // On Android, CallActivity runs in a separate task and pauses the chat's
    // Flutter engine. Once the user returns, pull the latest messages so the
    // just-created call record shows up without the user having to leave and
    // re-open the chat.
    WidgetsBinding.instance.addObserver(this);

    // Poll for a live call on this conversation so the in-chat "Ongoing call"
    // message appears/disappears without the user leaving the screen. Admin
    // (broadcast) threads never have calls, so skip the poll there.
    if (widget.type != "Admin") {
      _pollOngoingCall();
      _ongoingCallPoll = Timer.periodic(
          const Duration(seconds: 2), (_) => _pollOngoingCall());
    } else {
      // Admin (BlueEra broadcast) thread: always pull page-1 history from the
      // server on open. `listenUserNewMessages` only paints the Hive cache, so
      // when this screen is reached from a broadcast-notification tap (which may
      // not have pre-fetched via getLocalConversation) the thread would
      // otherwise show only the just-pushed message instead of the full
      // broadcast history. Mirrors the resume handler's fetch below.
      final id = widget.conversationId ?? '';
      if (id.isNotEmpty) {
        // When the app was backgrounded (e.g. this screen was reached from a
        // broadcast-notification tap), the chat socket may be sitting in its
        // 2s→4s→…→32s reconnect backoff. The messageReceived fetch below would
        // then be buffered on the dead socket and only flush after that
        // backoff — so the broadcast history takes seconds to appear. Force an
        // immediate reconnect first (a no-op when already connected) so the
        // fetch goes out right away and the message shows fast.
        ChatSocketService().reconnectNow();
        chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
          ApiKeys.conversation_id: id,
          ApiKeys.page: 1,
          ApiKeys.is_online_user: widget.userId,
          ApiKeys.per_page_message: 30,
        });
      }
    }

    // checkPendingMessages();
    super.initState();
  }

  Future<void> _pollOngoingCall() async {
    final session = await CallController.readActiveCallSession();
    final active = session != null &&
        OngoingCallMessageCard.sessionMatches(
          session,
          conversationId: widget.conversationId ?? '',
          userId: widget.userId,
        );
    if (!mounted) return;
    _ongoingCallActive.value = active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final id = widget.conversationId ?? '';
      if (id.isEmpty) return;
      chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id: id,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: chatViewController.userOpenUserId.value,
        ApiKeys.per_page_message: 30,
      });
    }
  }

  void _onScroll() {
    final controller = chatViewController.scrollController;
    final isUp = controller.offset > 150;
    if (isUp != chatViewController.isUserScrolledUp.value) {
      chatViewController.isUserScrolledUp.value = isUp;
      if (!isUp) {
        chatViewController.unreadNewMessageCount.value = 0;
      }
    }
    // The ListView is reverse:true, so the TOP of the chat is at the end of
    // the scroll range. When the user is within 80px of the top, ask the
    // server for the next 30-message window. loadMoreMessages is guarded so
    // repeated triggers don't pile up.
    if (controller.hasClients &&
        controller.position.pixels >=
            controller.position.maxScrollExtent - 80) {
      chatViewController.loadMoreMessages();
    }
  }

  // Future<void> checkPendingMessages() async {
  //   final connectivityResult = await NetworkUtils.isConnected();
  //   if (!connectivityResult) {
  //     chatViewController.sendOfflineMessage(widget.conversationId ?? "");
  //   }
  // }

  @override
  void dispose() {
    _ongoingCallPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    chatViewController.scrollController.removeListener(_onScroll);
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (val){
      // Tell server we left this conversation (screenRoom → "online")
      chatViewController.leaveConversation();
      // Refresh chat list only — do NOT emit newMessageReceived, it causes
      // the socket listener to re-add messages and create duplicates
      chatViewController.emitEvent(
        ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.personal_Chat_Type}, );

    },
      child: Scaffold(
        backgroundColor: AppColors.fillColor,
        // AppBar in its own Obx — only rebuilds when selection state changes
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            return (chatThemeController.isMessageSelectionActive.value &&
                    widget.type != "Admin")
                ? getChatOptionsAppBar(
                context,
                    profileImage: widget.profileImage,
                    editingController: editingController,
                    conversationId: widget.conversationId,
                    userId: widget.userId,
                    )
                : getChatTitleAppBar(socketType: AppConstants.personal,
                context,
                    userId: widget.userId,
                    type: widget.type,
                    name: widget.name,
                    profileImage: widget.profileImage,
                    contactNo: widget.contactNo, conversationId: widget.conversationId);
          }),
        ),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background in its own Obx — only rebuilds when theme changes
              Obx(() => chatThemeController.chatBackground()),
              Column(
                children: [
                  // Message list + scroll-to-bottom FAB
                  Expanded(
                    child: Stack(
                      children: [
                        // Message list
                        Obx(() {
                          final messages =
                              chatViewController.getListOfMessageData ?? [];
                          final status = chatViewController
                              .getListOfMessageResponse.value.status;
                          // Show cached history as soon as it's available.
                          // Only block with a spinner when there is nothing to
                          // paint yet AND the load hasn't settled — so offline
                          // users keep seeing their Hive-cached history.
                          if (messages.isEmpty && status != Status.COMPLETE) {
                            return const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (messages.isEmpty) {
                            return Center(
                              child: InkWell(
                                onTap: () {
                                  Map<String, dynamic> data = {
                                    ApiKeys.other_user_id: widget.userId,
                                    ApiKeys.message: "Namaste \u{1F64F}",
                                    ApiKeys.message_type: "text",
                                  };
                                  chatViewController.sendInitialMessage(data);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "No conversation yet. ",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Say Namaste \u{1F64F}",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Inject a synthetic "callongoing" message at the very
                          // bottom (newest slot) of the reversed list while a
                          // call for this conversation is live. It renders the
                          // OngoingCallMessageCard and self-hides when the call
                          // ends. Admin threads never have calls.
                          final showOngoing = widget.type != "Admin" &&
                              _ongoingCallActive.value;
                          return ListView.builder(
                            controller: chatViewController.scrollController,
                            // Reversed for every thread (incl. Admin/broadcast)
                            // so it opens anchored at the newest message at the
                            // bottom — same as a normal chat — and stays pinned
                            // there even as broadcast images / link previews load
                            // and change height.
                            reverse: true,
                            addAutomaticKeepAlives: true,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: messages.length + (showOngoing ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Reversed list → index 0 is the bottom row.
                              if (showOngoing && index == 0) {
                                return RepaintBoundary(
                                  key: const ValueKey('__ongoing_call__'),
                                  child: MessageCard(
                                    message: Messages(
                                      id: '__ongoing_call__',
                                      messageType: 'callongoing',
                                      conversationId: widget.conversationId,
                                    ),
                                    isInitialMessage: false,
                                    conversationId: widget.conversationId,
                                    conversationUserId: widget.userId,
                                  ),
                                );
                              }
                              final dataIndex = showOngoing ? index - 1 : index;
                              // Newest message at the bottom (index 0) for all
                              // threads now that the list is reversed.
                              final message =
                                  messages[messages.length - 1 - dataIndex];
                              // Broadcast (Admin) thread: render every message as
                              // the full-width notification-style card so it looks
                              // identical to the BlueEra notification screen. All
                              // other chats keep the standard MessageCard bubble.
                              return RepaintBoundary(
                                key: ValueKey(message.id ?? index),
                                child: widget.type == "Admin"
                                    ? BroadcastMessageCard(message: message)
                                    : MessageCard(
                                        message: message,
                                        isInitialMessage: false,
                                        conversationId: message.conversationId,
                                        userId: message.sender?.id,
                                        name: message.sender?.name,
                                        contactNo: message.sender?.contactNo,
                                        profileImage: message.sender?.profileImage,
                                        conversationUserId: widget.userId,
                                        conversationName: widget.name,
                                        conversationProfileImage: widget.profileImage,
                                      ),
                              );
                            },
                          );
                        }),

                        // Scroll-to-bottom FAB with unread badge
                        Positioned(
                          right: 12,
                          bottom: 8,
                          child: Obx(() {
                            if (!chatViewController.isUserScrolledUp.value) {
                              return const SizedBox.shrink();
                            }
                            final count = chatViewController.unreadNewMessageCount.value;
                            return GestureDetector(
                              onTap: () =>
                                  chatViewController.jumpToBottom(reversed: true),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.black54,
                                        size: 28,
                                      ),
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        top: -4,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(minWidth: 18),
                                          child: Text(
                                            count > 99 ? '99+' : '$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  (widget.type == "Admin")
                      ? const SizedBox()
                      : ChatInputBar(
                          isInitialMessage: widget.isInitialMessage,
                          userId: widget.userId ?? '',
                          conversationId: widget.conversationId ?? '',
                        ),
                  const SizedBox(height: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
