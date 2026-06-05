import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../auth/controller/chat_flag_controller.dart';
import '../../auth/controller/chat_lock_controller.dart';
import '../../auth/controller/chat_pin_archive_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../ai_chat/view/ai_chat_screen.dart';
import '../archive_chat/archive_chat_list.dart';
import '../flag_chat/business_flag_chat_list.dart';
import '../pin_chat/business_pin_chat_list.dart';
import '../reminder_chat/reminder_chat_list.dart';
import '../widget/component_widgets.dart';

/// Where a business-list row belongs:
///   [chats] — the main chat list (buyer side, friends, groups)
///   [me]    — the seller's "my customers" section (stranger orders)
///   [skip]  — excluded entirely
enum ChatBucket { chats, me, skip }

/// Single source of truth for routing one chat row — the Dart twin of the
/// backend `bucketChat` spec. Call once per row.
///
/// Priority (mirrors the backend `bucketChat`):
///   1. Group rows always go to [ChatBucket.chats].
///   2. Non-business conversation types → [ChatBucket.chats] by default,
///      or [ChatBucket.skip] when [includeNonBusinessInChats] is false.
///   3. Seller side (`i_own_business`) — friend orders stay in chats,
///      stranger customers go to [ChatBucket.me].
///   4. Buyer side (I ordered from someone else's business) → chats.
///
/// `i_own_business` is read straight from the row; when the server hasn't
/// sent it (legacy payload) we fall back to *my own* account type — if I'm
/// logged in as a business (`accountTypeGlobal == BUSINESS`) then in a
/// business conversation I'm the seller side. `is_friend` falls back to
/// false. (We use `accountTypeGlobal`, the current user's account type,
/// not `businessTypeGlobal`, which holds the business *category* like
/// Food / Grocery / OTHER.)
///
/// The conversation `type` is null-tolerant: legacy payloads that omit it
/// fall straight through to the seller/buyer logic (this widget is fed by
/// the business endpoint, so an absent type means "business").
ChatBucket bucketChat(ChatList chat, {bool includeNonBusinessInChats = true}) {
  // Group rows always live in the chat list.
  if (chat.isGroup == true || chat.type == AppConstants.group_Chat_Type) {
    return ChatBucket.chats;
  }

  // Known non-business conversation type → chats (or skip when opted out).
  if (chat.type != null && chat.type != AppConstants.business_Chat_Type) {
    return includeNonBusinessInChats ? ChatBucket.chats : ChatBucket.skip;
  }

  final iOwnBusiness =
      chat.iOwnBusiness ?? (accountTypeGlobal == AppConstants.business);

  // Business convo — seller side.
  if (iOwnBusiness) {
    // Friend override — a friend ordering from my business → chat list.
    if (chat.isFriend == true) return ChatBucket.chats;
    // Stranger customer → "me" section.
    return ChatBucket.me;
  }

  // Business convo — buyer side (I ordered from someone else's business).
  return ChatBucket.chats;
}

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
    this.showDateFilter = false,
    this.showNewIfRecentlyCreated = false,
  });
  final bool? isForwardUI;
  final bool? isNewGroupUI;

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

  /// Surfaces the date-range filter chip row above the "All" list — the
  /// feature carried over from the merged-in `OrdersTabView`. Used by the
  /// provider/seller order tabs (food / grocery / product / manufacturer)
  /// so a merchant can narrow incoming orders by date. Defaults to `false`
  /// — the Connect / forward / group-add flows render no date filter,
  /// unchanged.
  final bool showDateFilter;

  @override
  State<BusinessChatsList> createState() => _BusinessChatsListState();
}

class _BusinessChatsListState extends State<BusinessChatsList> {
  final chatViewController = Get.find<ChatViewController>();
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
              HorizontalTabSelector(
                horizontalMargin: 14,
                horizontalPadding: 10,
                verticalMargin: widget.isInParentScroll ? 0 : null,
                tabs: [
                  AppStrings.allTab.tr,
                  AppStrings.pinnedTab.tr,
                  AppStrings.reminderTab.tr,
                  AppStrings.flaggedTab.tr,
                  AppStrings.recordsTab.tr,
                ],
                selectedIndex:
                chatViewController.businessChatTabSelectedIndex.value,
                onTabSelected: (index, val) {
                  chatViewController.businessChatTabSelectedIndex.value = index;
                },
                labelBuilder: (value) => value,
              ),
              const SizedBox(height: 8),
              if (chatViewController.businessChatTabSelectedIndex.value == 0)
                widget.isInParentScroll
                    ? _businessChatListWidget(data, theme)
                    : Expanded(child: _businessChatListWidget(data, theme))
              else if (chatViewController.businessChatTabSelectedIndex.value == 1)
                BusinessPinChatList(isInParentScroll: widget.isInParentScroll)
              else if (chatViewController.businessChatTabSelectedIndex.value == 2)
                  ReminderChatList(isInParentScroll: widget.isInParentScroll)
                else if (chatViewController.businessChatTabSelectedIndex.value == 3)
                    BusinessFlagChatList(
                        isInParentScroll: widget.isInParentScroll)
                  else if (chatViewController.businessChatTabSelectedIndex.value == 4)
                      _buildArchiveTab(),
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
                SvgPicture.asset(
                  AppIconAssets.chat,
                  color: Colors.black,
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
    if (widget.showDateFilter) {
      chatList = chatList.where(_matchesDateFilter).toList();
    }

    // Sort pinned to top
    chatList.sort((a, b) {
      final aPinned = pinnedIds.contains(a?.conversationId);
      final bPinned = pinnedIds.contains(b?.conversationId);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final hasArchived = archivedIds.isNotEmpty;

    // Top rows: Records + AI chat
    final recordsOffset = hasArchived ? 1 : 0;
    final aiOffset = 1; // always show AI chat
    final topRowCount = recordsOffset + aiOffset;

    final listBody = Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size70),
      child:  ListView.builder(
        itemCount: chatList.length + topRowCount,
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

          // AI chat right after Records row
          if (index == recordsOffset) {
            final chat = ChatViewController.businessAiChatModule;
            final isInSelectionMode =
                chatViewController.isChatListSelectionMode.value;
            final isChatSelected = chatViewController
                .selectedConversationIds
                .contains(chat?.conversationId ?? '');

            return ChatListTile(
              onTab: () {
                if (isInSelectionMode) {
                  chatViewController.toggleChatListSelection(chat);
                  setState(() {});
                  return;
                }
                Get.to(() => AiChatScreen(
                  profileImage: chat?.sender?.profileImage,
                  name: chat?.sender?.name,
                  type: chat?.sender?.accountType,
                ));
              },
              isFromGroupSelect: widget.isNewGroupUI,
              onLongPress: () {
                if (!isInSelectionMode) {
                  chatViewController.isChatListSelectionMode.value =
                  true;
                  chatViewController.toggleChatListSelection(chat);
                  setState(() {});
                }
              },
              isChatListSelected: isChatSelected,
              onSelect: () => setState(() {}),
              type:
              chat?.sender?.accountType ?? AppConstants.business,
              index: -1,
              chatViewController: chatViewController,
              chat: chat,
              theme: theme,
              isForwardUI: widget.isForwardUI,
              showFlagBadge: true,
              context: context,
            );
          }

          final chatIndex = index - topRowCount;
          final chat = chatList[chatIndex];
          final isInSelectionMode =
              chatViewController.isChatListSelectionMode.value;
          final isChatSelected = chatViewController
              .selectedConversationIds
              .contains(chat?.conversationId ?? '');
          final isPinned =
          pinnedIds.contains(chat?.conversationId);

          return ChatListTile(
            isFromGroupSelect: widget.isNewGroupUI,
            onLongPress: () {
              if (!isInSelectionMode) {
                chatViewController.isChatListSelectionMode.value =
                true;
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
          );
        },
      ),
    );

    // Without the date filter the list body is returned as-is — the All-tab
    // branch in `build` handles the Expanded/parent-scroll wrapping. With the
    // filter on, prepend the chip row and re-apply that same wrapping here so
    // the bounded (Connect) and parent-scroll (provider) layouts both hold.
    if (!widget.showDateFilter) return listBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateFilterRow(),
        const SizedBox(height: 8),
        widget.isInParentScroll ? listBody : Expanded(child: listBody),
      ],
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
  Widget _buildDateFilterRow() {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFiltered ? AppColors.buttonLiteBlue : Colors.white,
                border: Border.all(
                  color: isFiltered
                      ? AppColors.primaryColor
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color:
                        isFiltered ? AppColors.primaryColor : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  CustomText(
                    triggerLabel,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color:
                        isFiltered ? AppColors.primaryColor : Colors.black87,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
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
      ),
    );
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
