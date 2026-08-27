import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/business_chat_products.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../core/services/notification_utils.dart';
import '../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../widget/chat_input_box.dart';
import '../widget/component_widgets.dart';
import '../widget/call_customer_button.dart';
import '../widget/message_card.dart';
import 'package:BlueEra/features/chat/view/widget/order_card_dedupe.dart';
import 'widgets/payment_qr_bottom_sheet.dart';

class BusinessChatScreenUpdated extends StatefulWidget {
  BusinessChatScreenUpdated(
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
  final String? type;
  final bool isInitialMessage;
  final String? contactNo;
  /// Optional intro text seeded into the input field on first open. Applied
  /// inside the post-frame callback so it survives the `clear()` there.
  final String? prefilledMessage;

  @override
  State<BusinessChatScreenUpdated> createState() =>
      _BusinessChatScreenUpdatedState();
}

class _BusinessChatScreenUpdatedState extends State<BusinessChatScreenUpdated>
    with WidgetsBindingObserver {
  final chatViewController = getOrPut(() => ChatViewController());
  final bottomBarController = getOrPut(() => BottomBarController());
  final chatThemeController = getOrPut(() => ChatThemeController());

  final TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    // This screen is the business/discovery lane (it also hosts former order
    // threads now that `order` is merged into `business`): tag outgoing sends
    // with the `discover` route so a first message looks up / creates the
    // business conversation.
    chatViewController.activeRoute = AppConstants.route_discover;

    WidgetsBinding.instance.addPostFrameCallback((value){
      chatViewController.isChatFromBusinessProfile(true);
      chatViewController.sendMessageController.value.clear();
      chatViewController.isTextFieldEmpty.value = false;
      final prefill = widget.prefilledMessage;
      if (prefill != null && prefill.isNotEmpty) {
        chatViewController.sendMessageController.value.text = prefill;
        // `isTextFieldEmpty` is inverted in this codebase: `true` means the
        // field HAS text, which is what flips the mic icon to send.
        chatViewController.isTextFieldEmpty.value = true;
      }
      chatViewController.listenUserNewMessages(
          userId: widget.userId ?? "",
          conversationId: widget.conversationId ?? '');
      chatThemeController.resetSelection();

      // Bump the message page size by 30 whenever the user scrolls to the top
      // of the (reverse:true) list so older history streams in on demand.
      chatViewController.scrollController.addListener(_onScroll);

      checkPendingMessages();
    });

    // On Android, CallActivity runs in a separate task and pauses the chat's
    // Flutter engine. Once the user returns, pull the latest messages so the
    // just-created call record shows up without the user having to leave and
    // re-open the chat.
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-read `/actions` for every order card on screen. A socket event
      // missed while backgrounded is the difference between a shop staring at
      // a stale "Accept" button and a shop that knows the order was
      // auto-cancelled ten minutes ago (guide §5.2).
      chatViewController.refreshVisibleOrderActions();

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
    if (!controller.hasClients) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 80) {
      chatViewController.loadMoreMessages();
    }
  }

  Future<void> checkPendingMessages() async {
    final connectivityResult = await NetworkUtils.isConnected();
    if (!connectivityResult) {
      chatViewController.sendOfflineMessage(widget.conversationId ?? "");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chatViewController.scrollController.removeListener(_onScroll);
    NetworkUtils.removeListener((connected) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (val)  {
        chatViewController.leaveConversation();
        if (chatViewController.canPopBusiness.value) {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "business"},);
        } else {
          chatViewController.emitEvent(
              ChatEmitEvents.ChatList, {ApiKeys.type: "business"},);
        }
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: Color(0xFFF5F5F5),
          appBar: (chatThemeController.isMessageSelectionActive.value &&
                  widget.type != "Admin")
              ? getChatOptionsAppBar(
                  context,
                  profileImage: widget.profileImage,
                  editingController: editingController,
                  conversationId: widget.conversationId,
                  userId: widget.userId,
                  // Inquiry lane: messages younger than 48h can't be deleted.
                  restrictDeleteWithin48h: true,
                )
              : getChatTitleAppBar(
                  socketType: "business",
                  context,
                  userId: widget.userId,
                  type: widget.type,
                  name: widget.name,
                  contactNo: widget.contactNo,
                  profileImage: widget.profileImage,
                  conversationId: widget.conversationId,
                ),
          body: Obx(() {
            final _status =
                chatViewController.getListOfMessageResponse.value.status;
            List<Messages> messages =
                chatViewController.getListOfMessageData ?? [];
            // Show the body as soon as cached history is available; only fall
            // back to the spinner when there is truly nothing to paint yet.
            // This keeps the offline chat screen populated from Hive.
            if (messages.isNotEmpty || _status == Status.COMPLETE) {
              messages.sort((a, b) {
                final dateA = (a.createdAt != null && a.createdAt!.isNotEmpty)
                    ? DateTime.parse(a.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                final dateB = (b.createdAt != null && b.createdAt!.isNotEmpty)
                    ? DateTime.parse(b.createdAt!).toLocal()
                    : DateTime.fromMillisecondsSinceEpoch(0);

                return dateA.compareTo(dateB); // descending
              });
              // C12 — one card per order. A duplicate order (server-side) or a
              // replayed socket card would otherwise show the same order
              // twice; the newest `created_at` wins and the history list stays
              // untouched. See ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md §3.
              messages = OrderCardDedupe.apply(messages);
              return SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Obx(() => chatThemeController.chatBackground()),
                    Column(
                      children: [
                        Container(
                          height: 42,
                          padding: EdgeInsets.only(left: 10, right: 6),
                          margin: EdgeInsets.only(top: 8, bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: chatViewController.tabs.length,
                            separatorBuilder: (_, __) => SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              return Obx(() {
                                final selected = index ==
                                    chatViewController
                                        .businessTabIndexSelected.value;
                                return InkWell(
                                  onTap: () {
                                    chatViewController
                                        .changeBusinessInsideTab(index);
                                    // History is a separate server bucket —
                                    // fetch it; the History tab then opens that
                                    // aged-out conversation as a chat thread.
                                    if (index ==
                                        chatViewController.historyTabIndex) {
                                      chatViewController.emitEvent(
                                          ChatEmitEvents.ChatList, {
                                        ApiKeys.type:
                                            AppConstants.history_Chat_Type
                                      });
                                    } else if (index == 0) {
                                      // Back to the live Chat tab: restore the
                                      // discover send-route and reload the
                                      // current conversation (History may have
                                      // swapped the open conversation to an
                                      // aged-out thread).
                                      chatViewController.activeRoute =
                                          AppConstants.route_discover;
                                      final id = widget.conversationId ?? '';
                                      if (id.isNotEmpty &&
                                          chatViewController.userOpenConversationId
                                                  .value !=
                                              id) {
                                        chatViewController.listenUserNewMessages(
                                            userId: widget.userId ?? '',
                                            conversationId: id);
                                      }
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 3),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryColor
                                          : AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: selected
                                          ? null
                                          : Border.all(
                                              color: AppColors.borderBox
                                                  .withValues(alpha: 0.75)),
                                    ),
                                    child: Center(
                                      child: CustomText(
                                        chatViewController.tabs[index],
                                        color: selected
                                            ? AppColors.white
                                            : AppColors.grayText,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              });
                            },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (chatViewController.businessTabIndexSelected == 0)
                          Expanded(
                            // Hangs the "Call Customer" pill over the thread
                            // once a packing PDF has been sent in it.
                            child: CallCustomerOverlay(
                              conversationId: widget.conversationId,
                              child: (messages.isEmpty)
                                ? Center(
                                    child: InkWell(
                                      onTap: () {
                                        Map<String, dynamic> data = {
                                          ApiKeys.other_user_id: widget.userId,
                                          ApiKeys.message: "Namaste 🙏",
                                          ApiKeys.message_type: "text",
                                        };
                                        chatViewController
                                            .sendInitialMessage(data);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.5),
                                          // light color with 0.5 opacity
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:AppStrings.noConversationYet.tr,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              TextSpan(
                                                text: AppStrings.sayNamaste.tr,
                                                style: TextStyle(
                                                  color: Colors
                                                      .blue, // blue from theme
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: chatViewController.scrollController,
                                    reverse: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[messages.length - 1 - index];
                                      return MessageCard(
                                        message: message,
                                        isInitialMessage: widget.isInitialMessage,
                                        conversationId: widget.conversationId,
                                        userId: widget.userId,
                                        name: widget.name,
                                        contactNo: widget.contactNo,
                                        profileImage: widget.profileImage,
                                        conversationName: widget.name,
                                        conversationProfileImage: widget.profileImage,
                                      );
                                    },
                                  ),
                            ),
                          )
                        else if (chatViewController.businessTabIndexSelected ==
                            chatViewController.productsTabIndex)
                          Expanded(child:
                              LayoutBuilder(builder: (context, constraints) {
                            return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, right: 8, bottom: 0),
                                  child: BusinessChatProducts(
                                    conversationId: widget.conversationId ?? '',
                                    businessId: widget.userId ?? '',
                                  ),
                                ));
                          }))
                        else if (chatViewController.businessTabIndexSelected ==
                            chatViewController.paymentsTabIndex)
                          // Pay this business: their QR code, copyable UPI id +
                          // linked mobile number, Download-QR and Upload-payment-
                          // screenshot actions (shared with the payment sheet).
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: PaymentQrPanel(
                                embedded: true,
                                userId: widget.userId,
                                conversationId: widget.conversationId,
                                payeeName: widget.name ?? 'My Business',
                              ),
                            ),
                          )
                        else if (chatViewController.businessTabIndexSelected ==
                            chatViewController.historyTabIndex)
                          Expanded(
                              child: _buildHistoryThread(context, messages))
                        else if (chatViewController.businessTabIndexSelected ==
                            chatViewController.ourViewTabIndex)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 38.0),
                            child: Center(
                              child: CustomText("Coming Soon"),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 38.0),
                            child: Center(
                              child: CustomText("Coming Soon"),
                            ),
                          ),
                        // Input bar shows on the live Chat tab and on the
                        // History tab once its aged-out thread is loaded — so a
                        // reply lands back in that History conversation.
                        if (_showChatInput)
                          SizedBox(
                            height: SizeConfig.size6,
                          ),
                        if (_showChatInput)
                          ChatInputBar(
                            isInitialMessage:
                                _onHistoryThread ? false : widget.isInitialMessage,
                            userId: widget.userId ?? '',
                            conversationId: _onHistoryThread
                                ? (_historyConversationId() ?? '')
                                : (widget.conversationId ?? ''),
                          ),
                        if (_showChatInput)
                          SizedBox(height: SizeConfig.size14)
                        else
                          SizedBox(height: SizeConfig.size6)
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return SafeArea(
                  child: Stack(
                fit: StackFit.expand,
                children: [
                  Obx(() => chatThemeController.chatBackground()),
                  Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(),
                    ),
                  )
                ],
              ));
            }
          }),
        );
      }),
    );
  }

  /// Conversation id of the aged-out (`type:"history"`) thread with *this*
  /// business. History rows preserve the same participant fields as Business
  /// rows, so match on the other participant's id / businessId or the seller's
  /// owner id. Returns the most recent match (the list is already ordered by
  /// recency), or `null` when there is no history with this business yet.
  String? _historyConversationId() {
    final all =
        chatViewController.getHistoryChatListModel?.value.chatList ?? [];
    final businessId = widget.userId ?? '';
    for (final c in all) {
      if (c == null) continue;
      if (c.sender?.id == businessId ||
          c.sender?.businessId == businessId ||
          c.businessOwnerUserId == businessId) {
        final id = c.conversationId ?? '';
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  /// True when the History tab is selected AND its aged-out conversation has
  /// been loaded into the shared message Rx (so the thread + input render).
  bool get _onHistoryThread {
    if (chatViewController.businessTabIndexSelected.value !=
        chatViewController.historyTabIndex) {
      return false;
    }
    final histId = _historyConversationId();
    return histId != null &&
        histId.isNotEmpty &&
        chatViewController.userOpenConversationId.value == histId;
  }

  /// Whether to show the chat input bar — the live Chat tab, or the History
  /// tab once its thread is loaded.
  bool get _showChatInput =>
      chatViewController.businessTabIndexSelected.value == 0 ||
      _onHistoryThread;

  Widget _historyLoader() => const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _historyEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            CustomText(
              AppStrings.noHistoryChats.tr,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      );

  /// The "History" sub-tab — shows the aged-out (`type:"history"`) conversation
  /// with this business directly as a chat thread (not a list). The aged-out
  /// conversation is made the open conversation so its messages load into the
  /// shared message Rx, then rendered with [MessageCard] exactly like the live
  /// Chat tab. Replying (via the input bar) lands back in this History thread.
  Widget _buildHistoryThread(BuildContext context, List<Messages> messages) {
    return Obx(() {
      final status = chatViewController.historyChatListResponse.value.status;
      final histConvId = _historyConversationId();

      if (histConvId == null || histConvId.isEmpty) {
        return status != Status.COMPLETE ? _historyLoader() : _historyEmpty();
      }

      // Swap the open conversation to the history thread so its messages stream
      // into `getListOfMessageData` (the same source the Chat tab renders).
      if (chatViewController.userOpenConversationId.value != histConvId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (chatViewController.businessTabIndexSelected.value ==
                  chatViewController.historyTabIndex &&
              chatViewController.userOpenConversationId.value != histConvId) {
            // Reply into the existing thread — no discover/create route.
            chatViewController.activeRoute = null;
            chatViewController.listenUserNewMessages(
                userId: widget.userId ?? '', conversationId: histConvId);
            // Pull this thread's messages from the server (mirrors the
            // lifecycle-resume fetch), so the History thread populates even
            // when nothing is cached locally.
            chatViewController.emitEvent(ChatEmitEvents.messageReceived, {
              ApiKeys.conversation_id: histConvId,
              ApiKeys.page: 1,
              ApiKeys.is_online_user: chatViewController.userOpenUserId.value,
              ApiKeys.per_page_message: 30,
            });
          }
        });
        return _historyLoader();
      }

      if (messages.isEmpty) return _historyEmpty();

      return ListView.builder(
        controller: chatViewController.scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          return MessageCard(
            message: message,
            isInitialMessage: false,
            conversationId: histConvId,
            userId: widget.userId,
            name: widget.name,
            contactNo: widget.contactNo,
            profileImage: widget.profileImage,
            conversationName: widget.name,
            conversationProfileImage: widget.profileImage,
          );
        },
      );
    });
  }

}
