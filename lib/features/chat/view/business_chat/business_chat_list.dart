import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../auth/controller/chat_flag_controller.dart';
import '../../auth/controller/chat_lock_controller.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../archive_chat/archive_chat_list.dart';
import '../flag_chat/business_flag_chat_list.dart';
import '../pin_chat/business_pin_chat_list.dart';
import '../reminder_chat/reminder_chat_list.dart';
import '../widget/component_widgets.dart';
import '../../../../widgets/glass_surface.dart';

/// Where a business-list row belongs:
///   [chats] — the main Chat tab (buyers, normal chats, groups)
///   [me]    — the seller/receiver's "Me" section (orders I own)
///   [skip]  — excluded entirely (not produced by the current rule; kept
///             so existing call-sites/switches stay valid)
enum ChatBucket { chats, me, skip }

/// Chat-card `message_type`s the ride/goods dispatch flow posts into a
/// conversation. A thread carrying any of them is a ride booking, whichever
/// route it was booked through (Discover transport, the Inquiry tab's rider
/// shortcut, a grocery/food order handed to a rider, or a fare call):
///   order_request — the booking request card
///   rider         — rider details + Track Order / Cancel Ride
///   rider_map     — the live-location card (suppressed inside the thread)
///   rider_otp     — the pickup / delivery handoff OTP card
const Set<String> _kRideDispatchMessageTypes = {
  'order_request',
  'rider',
  'rider_map',
  'rider_otp',
};

/// Conversations already identified as ride threads. A chat-list row only
/// carries its LAST message type, so once either party sends a plain message
/// the ride card scrolls out of that field — without this the thread would pop
/// back into the Inquiry tab. Seeded as rows arrive, so it costs nothing; it is
/// in-memory only, and a relaunch simply falls back to the last-message check.
final Set<String> _knownRideChats = <String>{};

/// True when [chat] is a ride booking (see [_kRideDispatchMessageTypes]).
bool isRideDispatchChat(ChatList chat) {
  final id = chat.conversationId ?? '';
  if (_kRideDispatchMessageTypes.contains(chat.lastMessageType)) {
    if (id.isNotEmpty) _knownRideChats.add(id);
    return true;
  }
  return id.isNotEmpty && _knownRideChats.contains(id);
}

/// Single source of truth for routing one order/enquiry row — the Dart twin
/// of the backend routing spec. An order/enquiry I *receive* (someone ordered
/// from / enquired to my business) goes to my "Me" section; one I *placed*
/// (I'm the buyer/enquirer) goes to the Chat/Inquiry tab.
///
///   is_order && I am the receiver  → [ChatBucket.me]    (seller/provider)
///   is_order && I am the sender    → [ChatBucket.chats]  (buyer/enquirer)
///   !is_order                      → [ChatBucket.chats]  (normal chat)
///
/// "Am I the receiver?" is decided from two signals, in priority order:
///   1. `business_owner_user_id == me` — authoritative, but the chat-list
///      socket rows leave it `null` (it only arrives on socket *update*
///      payloads), so it's used only when actually present.
///   2. `i_own_business == true` — the flag the chat-list rows DO carry:
///      `true` = someone ordered from / enquired to MY business (receiver),
///      `false` = I placed the order/enquiry (sender). This is the field the
///      real payload routes on.
///
/// `me` is the logged-in user's id (`userId`).
ChatBucket bucketChat(ChatList chat) {
  // A ride booking is just a grocery order with the rider as the shop: the
  // person who booked is the customer (buyer) and the rider fulfils it
  // (seller). The backend can't express that through `business_owner_user_id`
  // — a direct ride has no business behind it — so the rider side is decided
  // from the logged-in user's profession. On a rider's device the ride thread
  // is therefore an order (the "me" lane) and never shows up in their Inquiry
  // tab, which they don't use: riders work the ride out of their dispatch
  // screens, not chat. The customer's copy of the same thread is untouched and
  // stays in Inquiry next to their grocery / Discover orders.
  if (isRiderProfession(userProfessionGlobal) && isRideDispatchChat(chat)) {
    return ChatBucket.me;
  }

  final isOrder = chat.isOrder == true;
  if (!isOrder) return ChatBucket.chats;

  final ownerId = (chat.businessOwnerUserId ?? '').toString();
  final bool iAmReceiver = ownerId.isNotEmpty
      ? ownerId == userId.toString()
      : chat.iOwnBusiness == true;

  // I received this order/enquiry → my "Me" section; otherwise I placed it →
  // the Chat/Inquiry tab.
  return iAmReceiver ? ChatBucket.me : ChatBucket.chats;
}

/// Inquiry chats whose LAST MESSAGE landed inside [window], newest first.
///
/// "Ordering something" in this app is a conversation: the order/enquiry card
/// is posted into a chat, so a recent order is exactly a recent inquiry chat.
/// [bucketChat] keeps it to the ones the user PLACED ([ChatBucket.chats]) —
/// orders they received as a seller belong to the Me section and are not the
/// user's own shopping.
///
/// Pass [bucket] to slice the other side instead: [ChatBucket.me] is the
/// incoming-orders lane the Connect "Order" tab renders (see
/// [recentReceivedOrderChats]).
///
/// Shared so the Discover "Orders in N Hrs." rail and the multi-shop pickup
/// selection screen can never disagree about which orders are recent.
List<ChatList> recentInquiryChats(
  List<ChatList?>? all, {
  Duration window = const Duration(hours: 12),
  ChatBucket bucket = ChatBucket.chats,
}) {
  if (all == null || all.isEmpty) return const [];
  final cutoff = DateTime.now().subtract(window);
  final result = <ChatList>[];
  for (final chat in all) {
    if (chat == null) continue;
    if (bucketChat(chat) != bucket) continue;
    // `updatedAt` is the last-message time; `createdAt` only covers rows the
    // server sent before the conversation had one.
    final raw =
        (chat.updatedAt?.isNotEmpty ?? false) ? chat.updatedAt : chat.createdAt;
    if (raw == null || raw.isEmpty) continue;
    final DateTime at;
    try {
      at = DateTime.parse(raw).toLocal();
    } catch (_) {
      continue; // unparseable timestamp — can't claim it's recent
    }
    if (at.isAfter(cutoff)) result.add(chat);
  }
  result.sort((a, b) => (b.updatedAt ?? '').compareTo(a.updatedAt ?? ''));
  return result;
}

/// Orders the user RECEIVED as a seller whose last message landed inside
/// [window], newest first — the recent slice of the same [ChatBucket.me] lane
/// the Connect screen's "Order" tab renders (`BusinessChatsList` with
/// `excludeSenderId`, via `OrdersTabBody`).
List<ChatList> recentReceivedOrderChats(
  List<ChatList?>? all, {
  Duration window = const Duration(hours: 12),
}) =>
    recentInquiryChats(all, window: window, bucket: ChatBucket.me);

/// Date-range presets surfaced as filter chips above the list when
/// [BusinessChatsList.showDateFilter] is set (the provider/seller "order"
/// tabs that absorbed the old `OrdersTabView`). Resolved against
/// `chat.createdAt` (falling back to `updatedAt` when missing) by
/// `_BusinessChatsListState._matchesDateFilter`.
enum _OrderDateFilter { all, today, yesterday, last7Days, last30Days, custom }

extension _OrderDateFilterLabel on _OrderDateFilter {
  String get label {
    switch (this) {
      case _OrderDateFilter.all:
        return AppStrings.all.tr;
      case _OrderDateFilter.today:
        return AppStrings.todayLabel.tr;
      case _OrderDateFilter.yesterday:
        return AppStrings.yesterdayLabel.tr;
      case _OrderDateFilter.last7Days:
        return AppStrings.last7Days.tr;
      case _OrderDateFilter.last30Days:
        return AppStrings.last30Days.tr;
      case _OrderDateFilter.custom:
        return AppStrings.customLabel.tr;
    }
  }
}

class BusinessChatsList extends StatefulWidget {
  const BusinessChatsList({
    super.key,
    this.isForwardUI,
    this.isNewGroupUI,
    this.excludeSenderId,
    this.onlySenderId,
    this.isInParentScroll = false,
    this.showNewIfRecentlyCreated = false,
    this.showEmptyState = false,
    this.listTitle,
  });
  final bool? isForwardUI;
  final bool? isNewGroupUI;

  /// When `true`, a truly-empty list renders the shared [noChatsFound]
  /// placeholder instead of a zero-row `ListView`. Mirrors what
  /// `PersonalChatsList` already does on the Chat tab. Opt-in because the
  /// forward / group-add pickers and the Me-side order cards have their own
  /// empty handling and must keep rendering their chrome.
  final bool showEmptyState;

  /// Header title shown at the top of the white list card (e.g. "Orders" on
  /// the seller order tabs, "Inquiry" on the service inquiry tabs). When set,
  /// the header — title on the left, date-filter dropdown on the right — is
  /// rendered on every render, whether the list has rows or not. Null on the
  /// forward / group-add pickers (which keep the flat, card-less list).
  final String? listTitle;

  /// When `true`, each chat row shows a "New" label below the time if the
  /// conversation was created within the last 4 hours. Enabled by the Connect
  /// screen's Inquiry tab; defaults to `false` elsewhere.
  final bool showNewIfRecentlyCreated;

  /// Hides chats whose `lastMessageSenderId` equals this value — used
  /// by the self-employed / professionals "Order" tabs to surface only
  /// incoming inquiries (where the *other* party sent the latest msg).
  /// Null = no exclusion.
  final String? excludeSenderId;

  /// Mirror of [excludeSenderId] — keeps only chats whose
  /// `lastMessageSenderId` matches. Used by the Connect screen's
  /// Inquiry tab so the user sees only their own outgoing inquiries.
  /// Null = no inclusion filter.
  final String? onlySenderId;

  /// Embed-in-parent-scroll mode. When `true`, the inner chat list is
  /// not wrapped in `Expanded` and its `ListView` switches to
  /// `NeverScrollableScrollPhysics`, so the widget sizes to its
  /// content under an unbounded sliver/nested scroll surface (the
  /// self-employed / professionals "Order" tab). Defaults to `false`
  /// — the Connect screen and forward / group-add flows continue to
  /// rely on the bounded `Expanded` layout, unchanged.
  final bool isInParentScroll;

  @override
  State<BusinessChatsList> createState() => _BusinessChatsListState();
}

class _BusinessChatsListState extends State<BusinessChatsList> {
  // Use getOrPut (not Get.find) so this list works even when reached on a path
  // where ChatViewController isn't already live — e.g. the medical/provider
  // home embeds it outside the bottom-nav tab tree. Matches the dominant
  // pattern used by the other chat lists (personal_chat_list, group_chat_screen).
  final chatViewController = getOrPut(() => ChatViewController());
  late final ChatPinArchiveController pinArchiveController;
  late final ChatLockController lockController;

  // Date-range filter state — only surfaced when [widget.showDateFilter]
  // is true (provider/seller order tabs). `_selectedDateFilter` drives the
  // chip row; `_customRange` holds the calendar picker result for `custom`.
  _OrderDateFilter _selectedDateFilter = _OrderDateFilter.all;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();

    pinArchiveController =getOrPut(() => ChatPinArchiveController());
    lockController = getOrPut(() => ChatLockController());
    // The full chrome's sub-tabs Get.find these controllers (Flagged →
    // ChatFlagController, Reminder → ChatThemeController). Register them here
    // so BusinessChatsList is self-sufficient on the provider/seller screens,
    // which previously relied on ConnectMainPage having pre-registered them.
    getOrPut(() => ChatFlagController());
    getOrPut(() => ChatThemeController());
    if (chatViewController.canPopBusiness.value) {
      chatViewController.canPopBusiness.value = false;
    }
    Future.delayed(Duration(milliseconds: 800),(){
      chatViewController.emitEvent(
        ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.business_Chat_Type},
      );
    });

    // The All tab now renders the History bucket beneath the live chats, so
    // prefetch it here (the live Business emit never carries history rows, and
    // it was previously only fetched when the History tab was tapped). Skip for
    // pickers, which keep the flat list with no history section.
    final isPicker =
        (widget.isForwardUI ?? false) || (widget.isNewGroupUI ?? false);
    if (!isPicker) {
      chatViewController.emitEvent(ChatEmitEvents.ChatList,
          {ApiKeys.type: AppConstants.history_Chat_Type});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (chatViewController.businessChatListResponse.value.status ==
          Status.COMPLETE) {
        GetChatListModel? data =
            chatViewController.getBusinessChatListModel?.value;
        return RefreshIndicator(
          onRefresh: () async {
            chatViewController.emitEvent(
                ChatEmitEvents.ChatList, {ApiKeys.type: "business"});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // if (!widget.isInParentScroll) const SizedBox(height: 10),
           /*   HorizontalTabSelector(
                horizontalMargin: 14,
                horizontalPadding: 10,
                verticalMargin: widget.isInParentScroll ? 0 : null,
                tabs: [
                  AppStrings.allTab.tr,
                  AppStrings.pinnedTab.tr,
                  AppStrings.reminderTab.tr,
                  AppStrings.flaggedTab.tr,
                  AppStrings.recordsTab.tr,
                  AppStrings.historyTab.tr,
                ],
                selectedIndex:
                chatViewController.businessChatTabSelectedIndex.value,
                onTabSelected: (index, val) {
                  chatViewController.businessChatTabSelectedIndex.value = index;
                  // History is a separate server bucket — fetch it on demand
                  // when the tab is opened (the Business tab's own emit never
                  // carries `history` rows). Index 5 == History.
                  if (index == 5) {
                    chatViewController.emitEvent(ChatEmitEvents.ChatList,
                        {ApiKeys.type: AppConstants.history_Chat_Type});
                  }
                },
                labelBuilder: (value) => value,
              ),*/
              const SizedBox(height: 8),
              _sheeted(_buildActiveTabBody(data, theme)),
            ],
          ),
        );
      } else if (chatViewController.businessChatListResponse.value.status ==
          Status.INITIAL) {
        return SizedBox();
      } else {
        return Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size70),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.chat,
                  imgColor: Colors.black,
                  height: 70,
                  width: 70,
                ),
                const SizedBox(height: 14),
                CustomText(
                  AppStrings.noChatsFound.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 6),
                CustomText(AppStrings.goToContactsAndStartNewConversation.tr),
              ],
            ),
          ),
        );
      }
    });
  }

  /// The Business "History" sub-tab. Renders the `type:"history"` bucket —
  /// business conversations the server has aged out (12h after creation) —
  /// using the same [ChatListTile] rows as the main list. No AI/Records top
  /// rows: History is a flat archive of past order/business threads. Tapping a
  /// row opens the conversation normally (replies stay in History; the backend
  /// never resurfaces it into Business).
  /// Filtered History bucket — archived + PIN-locked dropped, then the same
  /// buyer/seller bucketing as the Business list (consumer sees buyer-side
  /// history; provider `excludeSenderId` sees the seller's "me" history;
  /// pickers see everything). Shared by the History sub-tab and the All tab's
  /// inline History section.
  List<ChatList?> _filteredHistoryList() {
    List<ChatList?> chatList =
        chatViewController.getHistoryChatListModel?.value.chatList ?? [];

    final archivedIds = pinArchiveController.businessArchivedIds;
    final lockedIds = lockController.businessLockedIds;

    chatList = chatList
        .where((chat) =>
            chat == null || !archivedIds.contains(chat.conversationId))
        .where((chat) =>
            chat == null || !lockedIds.contains(chat.conversationId))
        .toList();

    final isPicker =
        (widget.isForwardUI ?? false) || (widget.isNewGroupUI ?? false);
    if (widget.onlySenderId != null) {
      chatList = chatList
          .where((c) => (c?.lastMessageSenderId ?? '') == widget.onlySenderId)
          .toList();
    } else if (widget.excludeSenderId != null) {
      chatList = chatList
          .where((c) => c != null && bucketChat(c) == ChatBucket.me)
          .toList();
    } else if (!isPicker) {
      chatList = chatList
          .where((c) => c != null && bucketChat(c) == ChatBucket.chats)
          .toList();
    }
    return chatList;
  }

  Widget _historyChatListWidget(ThemeData theme) {
    return Obx(() {
      final status = chatViewController.historyChatListResponse.value.status;

      List<ChatList?> chatList = _filteredHistoryList();

      // First open with nothing cached yet → spinner while the socket replies.
      if (chatList.isEmpty && status != Status.COMPLETE) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 38),
          child: Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (chatList.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 38),
          child: Center(
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
          ),
        );
      }

      final listBody = Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size70),
        child: ListView.builder(
          itemCount: chatList.length,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: widget.isInParentScroll
              ? const NeverScrollableScrollPhysics()
              : null,
          itemBuilder: (context, index) {
            return _buildHistoryChatTile(chatList[index], index, theme);
          },
        ),
      );

      // Pull-to-refresh re-fetches the history bucket. Skip the RefreshIndicator
      // in parent-scroll mode (the outer scrollable owns the gesture there).
      if (widget.isInParentScroll) return listBody;
      return RefreshIndicator(
        onRefresh: () async {
          chatViewController.emitEvent(ChatEmitEvents.ChatList,
              {ApiKeys.type: AppConstants.history_Chat_Type});
        },
        child: listBody,
      );
    });
  }

  Widget _buildArchiveTab() {
    final column = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Get.to(() => const ArchiveChatListPage(isBusiness: true)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                final count =
                    pinArchiveController.businessArchivedIds.length;
                return Row(
                  children: [
                    Icon(Icons.archive_outlined,
                        color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.recordsCountFmt.trParams({'count': '$count'}),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey.shade400),
                  ],
                );
              }),
            ),
          ),
        ],
      );

    return widget.isInParentScroll ? column : Expanded(child: column);
  }

  Widget _businessChatListWidget(GetChatListModel? data, ThemeData theme) {
    List<ChatList?> chatList = data?.chatList ?? [];
    final archivedIds = pinArchiveController.businessArchivedIds;
    final pinnedIds = pinArchiveController.businessPinnedIds;
    final lockedIds = lockController.businessLockedIds;

    // Filter out archived
    chatList = chatList.where((chat) {
      return chat == null || !archivedIds.contains(chat.conversationId);
    }).toList();

    // Locked chats live behind the PIN-gated Locked Chats screen, so they
    // must not appear in the main list (WhatsApp-style Chat Lock).
    chatList = chatList.where((chat) {
      return chat == null || !lockedIds.contains(chat.conversationId);
    }).toList();

    // B2B routing — split the business list into "chats" vs the seller's
    // "me" (my customers) section via [bucketChat]. The Order tabs that
    // surface incoming customers pass [excludeSenderId] → render the "me"
    // bucket; everything else is the main chat list, which hides stranger
    // customers (they live in the seller's "me" section). Forward / group-
    // add pickers must show everything, so they skip bucketing.
    //
    // The Connect "my inquiries" tab keeps its legacy [onlySenderId] filter
    // (outgoing-only), which is an orthogonal slice of the chats bucket.
    final isPicker =
        (widget.isForwardUI ?? false) || (widget.isNewGroupUI ?? false);
    if (widget.onlySenderId != null) {
      chatList = chatList
          .where((c) =>
              (c?.lastMessageSenderId ?? '') == widget.onlySenderId)
          .toList();
    } else if (widget.excludeSenderId != null) {
      chatList = chatList
          .where((c) => c != null && bucketChat(c) == ChatBucket.me)
          .toList();
    } else if (!isPicker) {
      chatList = chatList
          .where((c) => c != null && bucketChat(c) == ChatBucket.chats)
          .toList();
    }

    // Date-range filter (provider/seller order tabs only). No-op when the
    // filter row isn't shown, since `_selectedDateFilter` stays `all`.
      chatList = chatList.where(_matchesDateFilter).toList();

    // Sort pinned to top
    chatList.sort((a, b) {
      final aPinned = pinnedIds.contains(a?.conversationId);
      final bPinned = pinnedIds.contains(b?.conversationId);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final hasArchived = archivedIds.isNotEmpty;

    // Top rows: Records only. The "Ask BlueEra Ai" row was removed from every
    // chat list — the server-side copy is stripped in
    // `ChatViewController.loadChatListWithType`, so it can't come back via the
    // socket either. `recordsOffset` is 0 or 1: the Records shortcut only
    // exists once at least one conversation has been archived, and the builder
    // subtracts it before indexing into `chatList` / `historyList`.
    final recordsOffset = hasArchived ? 1 : 0;
    final topRowCount = recordsOffset;

    // Merge the History bucket into the All tab: the live chats render under a
    // "Today" heading, followed by the aged-out conversations (the History
    // sub-tab's list) under a "History" heading. Pickers (forward / group-add)
    // keep the flat list — no section headers and no history.
    final showSections = !isPicker;
    final List<ChatList?> historyList =
        showSections ? _filteredHistoryList() : const <ChatList?>[];
    final showTodayHeader = showSections && chatList.isNotEmpty;
    final showHistoryHeader = showSections && historyList.isNotEmpty;

    final itemCount = topRowCount +
        (showTodayHeader ? 1 : 0) +
        chatList.length +
        (showHistoryHeader ? 1 : 0) +
        historyList.length;

    // Nothing at all to show — no live chats, no history, and no Records row.
    // Render the shared empty placeholder rather than a blank zero-row list.
    // The Records row is deliberately part of the test: when something has
    // been archived the list isn't really empty, so that shortcut must stay
    // reachable.
    if (widget.showEmptyState && itemCount == 0) {
      return Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size70),
        child: noChatsFound(),
      );
    }

    final listView = ListView.builder(
        itemCount: itemCount,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: widget.isInParentScroll
            ? const NeverScrollableScrollPhysics()
            : null,
        itemBuilder: (context, index) {
          // Records row at very top
          if (hasArchived && index == 0) {
            return _buildRecordsRow();
          }

          // Past the Records row — `i` now indexes into the real content:
          // [Today?, current…, History?, history…]
          int i = index - recordsOffset;

          // "Today" heading above the live chat list.
          if (showTodayHeader) {
            if (i == 0) return _buildSectionHeader(AppStrings.todayLabel.tr);
            i -= 1;
          }

          // Live (current) chats.
          if (i < chatList.length) {
            return _buildCurrentChatTile(chatList[i], i, theme);
          }
          i -= chatList.length;

          // "History" heading above the aged-out conversations.
          if (showHistoryHeader) {
            if (i == 0) return _buildSectionHeader(AppStrings.historyTab.tr);
            i -= 1;
          }

          // Aged-out (History bucket) chats.
          return _buildHistoryChatTile(historyList[i], i, theme);
        },
      );

    // Only the seller's "Me" tabs (which pass [excludeSenderId]) get the
    // bordered card with the title + date-filter header. The Chat side
    // (Connect / inquiry) and the forward / group-add pickers keep the
    // original flat list — no card, no outer border — unchanged.
    final bool isMeSide = widget.excludeSenderId != null;
    if (isPicker || !isMeSide) {
      return Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size70),
        child: listView,
      );
    }

    // Me-side card. The header (title + date-filter dropdown) shows on every
    // render — empty or not — so the title and the filter never vanish out
    // from under the user (e.g. when a date window narrows the list to zero).
    return _wrapInListCard(
      header: _listCardHeader(),
      list: listView,
    );
  }

  /// Header row at the top of the list card: the section title
  /// ([BusinessChatsList.listTitle] — "Orders" / "Inquiry") on the left and the
  /// date-range filter on the right. Rendered whenever either is configured,
  /// independent of whether the list currently has any rows.
  Widget _listCardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: widget.listTitle != null
                ? CustomText(
                    widget.listTitle!,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  )
                : const SizedBox.shrink(),
          ),
          _dateFilterControl(),
        ],
      ),
    );
  }

  /// Wraps the chat list in the white, rounded "card" surface used on the
  /// Me-side order tabs and the Chat/Connect page. A single [Divider] sits
  /// between the (optional) [header] and the list — the one separator the
  /// design calls for. Adapts to both layout modes: under a bounded parent
  /// the list is [Expanded] to fill the card; in parent-scroll mode it
  /// shrink-wraps so the card sizes to its content.
  Widget _wrapInListCard({Widget? header, required Widget list}) {
    // Under a [GlassScope] this card IS the chat sheet (docs/chat_new.jpeg) —
    // same frosted surface, just keeping its own card geometry (all four
    // corners rounded, margins on every side) because here it sits inside a
    // scrolling tab with other cards above it rather than running off the
    // bottom of the screen.
    final bool glass = GlassScope.isActive(context);
    return Container(
      margin: EdgeInsets.only(
        left: SizeConfig.size12,
        right: SizeConfig.size12,
        bottom: SizeConfig.size70,
      ),
      decoration: glass
          ? glassSheetDecoration(
              borderRadius: BorderRadius.circular(SizeConfig.size16))
          : BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size16),
              border: Border.all(color: AppColors.greyE6),
            ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize:
            widget.isInParentScroll ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            header
          else
            SizedBox(height: SizeConfig.size8),
          Divider(
              height: 1,
              thickness: 1,
              color: glass ? kGlassDivider : AppColors.greyE6),
          widget.isInParentScroll ? list : Expanded(child: list),
        ],
      ),
    );
  }

  /// Returns true when [chat]'s timestamp falls inside the selected date
  /// window. `createdAt` is preferred (order-placed moment); falls back to
  /// `updatedAt`. Unparseable / missing dates are dropped for any non-`all`
  /// filter so they don't leak into narrow windows. Ported from the merged
  /// `OrdersTabView`.
  bool _matchesDateFilter(ChatList? chat) {
    if (_selectedDateFilter == _OrderDateFilter.all) return true;

    final raw = (chat?.createdAt?.isNotEmpty ?? false)
        ? chat!.createdAt
        : chat?.updatedAt;
    if (raw == null || raw.isEmpty) return false;

    DateTime date;
    try {
      date = DateTime.parse(raw).toLocal();
    } catch (_) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateFilter) {
      case _OrderDateFilter.today:
        final tomorrow = today.add(const Duration(days: 1));
        return !date.isBefore(today) && date.isBefore(tomorrow);
      case _OrderDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return !date.isBefore(yesterday) && date.isBefore(today);
      case _OrderDateFilter.last7Days:
        // Inclusive of today + previous 6 days = 7-day rolling window.
        final start = today.subtract(const Duration(days: 6));
        return !date.isBefore(start);
      case _OrderDateFilter.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return !date.isBefore(start);
      case _OrderDateFilter.custom:
        if (_customRange == null) return true;
        final start = DateTime(_customRange!.start.year,
            _customRange!.start.month, _customRange!.start.day);
        // End is inclusive of the picked day, so add one full day to make
        // the upper bound exclusive against the local timestamp.
        final endExclusive = DateTime(_customRange!.end.year,
                _customRange!.end.month, _customRange!.end.day)
            .add(const Duration(days: 1));
        return !date.isBefore(start) && date.isBefore(endExclusive);
      case _OrderDateFilter.all:
        return true;
    }
  }

  /// Opens the system date-range picker for `_OrderDateFilter.custom`.
  /// Cancelling leaves the previous filter in place. Ported from the merged
  /// `OrdersTabView`.
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
      helpText: AppStrings.filterOrdersByDate.tr,
      saveText: AppStrings.applyLabel.tr,
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _selectedDateFilter = _OrderDateFilter.custom;
    });
  }

  String _formatRange(DateTimeRange r) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = r.start, e = r.end;
    final sameYear = s.year == e.year;
    final left = '${two(s.day)}/${two(s.month)}'
        '${sameYear ? '' : '/${s.year}'}';
    final right = '${two(e.day)}/${two(e.month)}/${e.year}';
    return '$left – $right';
  }

  /// Compact date-range dropdown. Deliberately styled as a single trigger +
  /// popup menu — NOT a pill strip — so it reads as a distinct control and
  /// doesn't visually echo the `All / Pinned / …` tab selector directly
  /// above it. A non-`all` selection tints the trigger and exposes a clear
  /// (✕) affordance. "Custom" launches the system date-range picker.
  Widget _dateFilterControl() {
    const presets = [
      _OrderDateFilter.all,
      _OrderDateFilter.today,
      _OrderDateFilter.yesterday,
      _OrderDateFilter.last7Days,
      _OrderDateFilter.last30Days,
      _OrderDateFilter.custom,
    ];

    final isFiltered = _selectedDateFilter != _OrderDateFilter.all;
    final triggerLabel =
        (_selectedDateFilter == _OrderDateFilter.custom && _customRange != null)
            ? _formatRange(_customRange!)
            : _selectedDateFilter.label;

    return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<_OrderDateFilter>(
            offset: const Offset(0, 42),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (f) {
              if (f == _OrderDateFilter.custom) {
                _pickCustomRange();
              } else {
                setState(() => _selectedDateFilter = f);
              }
            },
            itemBuilder: (_) => [
              for (final f in presets)
                PopupMenuItem<_OrderDateFilter>(
                  value: f,
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        f == _OrderDateFilter.custom
                            ? Icons.date_range
                            : Icons.event_note_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomText(f.label, fontSize: 14),
                      ),
                      if (_selectedDateFilter == f)
                        const Icon(Icons.check,
                            size: 16, color: AppColors.primaryColor),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isFiltered ? AppColors.buttonLiteBlue : Colors.white,
                border: Border.all(
                  color: isFiltered
                      ? AppColors.primaryColor
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 13,
                    color:
                        isFiltered ? AppColors.primaryColor : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  CustomText(
                    triggerLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isFiltered ? AppColors.primaryColor : Colors.black87,
                  ),
                  const SizedBox(width: 1),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 15,
                    color:
                        isFiltered ? AppColors.primaryColor : Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() {
                _selectedDateFilter = _OrderDateFilter.all;
                _customRange = null;
              }),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
              ),
            ),
          ],
        ],
      );
  }

  /// Section heading ("Today" / "History") shown inside the All tab's merged
  /// list to separate the live chats from the aged-out History bucket.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: CustomText(
        title,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
    );
  }

  /// The body under the filter chips for whichever sub-tab is selected. Lifted
  /// out of the build's collection-if chain so [_sheeted] has a single widget to
  /// wrap — the chain itself is unchanged.
  Widget _buildActiveTabBody(GetChatListModel? data, ThemeData theme) {
    switch (chatViewController.businessChatTabSelectedIndex.value) {
      case 1:
        return BusinessPinChatList(isInParentScroll: widget.isInParentScroll);
      case 2:
        return ReminderChatList(isInParentScroll: widget.isInParentScroll);
      case 3:
        return BusinessFlagChatList(isInParentScroll: widget.isInParentScroll);
      case 4:
        return _buildArchiveTab();
      case 5:
        return widget.isInParentScroll
            ? _historyChatListWidget(theme)
            : Expanded(child: _historyChatListWidget(theme));
      case 0:
      default:
        return widget.isInParentScroll
            ? _businessChatListWidget(data, theme)
            : Expanded(child: _businessChatListWidget(data, theme));
    }
  }

  /// Drops the list body onto the frosted sheet when this list is rendering on
  /// the Connect tab — its top edge lands directly under the filter chips above
  /// it (docs/chat_new.jpeg). Embedded anywhere else (the merchant dashboards
  /// pass `isInParentScroll`), the body is returned untouched.
  ///
  /// The body is an [Expanded] on most branches, and an Expanded has to stay a
  /// direct child of the Column — so the sheet is slipped INSIDE it rather than
  /// wrapped around it, which would put an Expanded under a non-Flex parent and
  /// throw.
  Widget _sheeted(Widget body) {
    if (!GlassScope.isActive(context)) return body;
    // Me-side lists (the provider dashboards, which pass excludeSenderId)
    // already render their own card, and [_wrapInListCard] turns THAT into the
    // sheet. Wrapping again would put a sheet inside a sheet — two stacked
    // translucencies reading as an opaque white slab.
    if (widget.excludeSenderId != null) return body;
    if (body is Expanded) {
      return Expanded(flex: body.flex, child: GlassSheet(child: body.child));
    }
    return GlassSheet(child: body);
  }

  /// A live ("Today") chat row — carries the pinned highlight and the optional
  /// "New" badge, matching the original All-tab list behaviour.
  Widget _buildCurrentChatTile(ChatList? chat, int chatIndex, ThemeData theme) {
    final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
    final isChatSelected = chatViewController.selectedConversationIds
        .contains(chat?.conversationId ?? '');
    final isPinned =
        pinArchiveController.businessPinnedIds.contains(chat?.conversationId);

    return _withGlassDivider(ChatListTile(
      isFromGroupSelect: widget.isNewGroupUI,
      onLongPress: () {
        if (!isInSelectionMode) {
          chatViewController.isChatListSelectionMode.value = true;
          chatViewController.toggleChatListSelection(chat);
          setState(() {});
        }
      },
      isChatListSelected: isChatSelected,
      isPinned: isPinned,
      onSelect: () => setState(() {}),
      type: chat?.sender?.accountType ?? AppConstants.business,
      index: chatIndex,
      chatViewController: chatViewController,
      chat: chat,
      theme: theme,
      isForwardUI: widget.isForwardUI,
      showFlagBadge: true,
      showNewIfRecentlyCreated: widget.showNewIfRecentlyCreated,
      context: context,
    ));
  }

  /// Adds the separator under a row when this list is rendering its glass
  /// variant (the Connect tab). The frosted sheet has no per-row edge, so
  /// without a rule the entries run together into one column of text; the inset
  /// clears the avatar so the line separates entries rather than cutting across
  /// the sheet. Outside the scope the row is returned untouched.
  Widget _withGlassDivider(Widget tile) {
    if (!GlassScope.isActive(context)) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        const Padding(
          padding: EdgeInsets.only(left: 78, right: 16),
          child: Divider(height: 1, thickness: 1, color: kGlassDivider),
        ),
      ],
    );
  }

  /// A History ("aged-out") chat row — same tile as the live list minus the
  /// pinned / "New" affordances (history is a flat archive). Shared by the
  /// History sub-tab and the All tab's inline History section.
  Widget _buildHistoryChatTile(ChatList? chat, int index, ThemeData theme) {
    final isInSelectionMode = chatViewController.isChatListSelectionMode.value;
    final isChatSelected = chatViewController.selectedConversationIds
        .contains(chat?.conversationId ?? '');

    return _withGlassDivider(ChatListTile(
      isFromGroupSelect: widget.isNewGroupUI,
      onLongPress: () {
        if (!isInSelectionMode) {
          chatViewController.isChatListSelectionMode.value = true;
          chatViewController.toggleChatListSelection(chat);
          setState(() {});
        }
      },
      isChatListSelected: isChatSelected,
      onSelect: () => setState(() {}),
      type: chat?.sender?.accountType ?? AppConstants.business,
      index: index,
      chatViewController: chatViewController,
      chat: chat,
      theme: theme,
      isForwardUI: widget.isForwardUI,
      showFlagBadge: true,
      context: context,
    ));
  }

  Widget _buildRecordsRow() {
    return Obx(() {
      final count = pinArchiveController.businessArchivedIds.length;
      if (count == 0) return const SizedBox.shrink();
      return InkWell(
        onTap: () => Get.to(() => const ArchiveChatListPage(isBusiness: true)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.archive_outlined,
                    color: Colors.grey.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.recordsLabel.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    });
  }
}
