
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';
import 'order_chat_screen.dart';

/// Date-range presets surfaced as filter chips above the orders list.
/// Resolved against `chat.createdAt` (falling back to `updatedAt` when
/// missing) by `_OrdersTabViewState._matchesDateFilter`.
enum _OrderDateFilter { all, today, yesterday, last7Days, last30Days, custom }

extension _OrderDateFilterLabel on _OrderDateFilter {
  String get label {
    switch (this) {
      case _OrderDateFilter.all:
        return 'All';
      case _OrderDateFilter.today:
        return 'Today';
      case _OrderDateFilter.yesterday:
        return 'Yesterday';
      case _OrderDateFilter.last7Days:
        return 'Last 7 days';
      case _OrderDateFilter.last30Days:
        return 'Last 30 days';
      case _OrderDateFilter.custom:
        return 'Custom';
    }
  }
}

class OrdersTabView extends StatefulWidget {
  /// Hides chats whose `lastMessageSenderId` equals this value — i.e.
  /// drops conversations where the most recent message was authored by
  /// the caller. When `null`, no exclusion is applied. The Grocery
  /// profile screen passes the logged-in user's id so the owner only
  /// sees orders where the *last message* came from someone else (an
  /// actual incoming order ping).
  final String? excludeSenderId;

  /// Mirror of [excludeSenderId] — when set, *only* chats whose
  /// `lastMessageSenderId` matches this value are shown. Used by the
  /// Connect screen's Order tab so the user sees nothing but their own
  /// outgoing self-orders. Mutually exclusive with [excludeSenderId];
  /// if both are provided, both predicates apply.
  final String? onlySenderId;

  /// Embed-in-parent-scroll mode. When `true`, the inner orders list is
  /// not wrapped in `Expanded` and its `ListView` switches to
  /// `NeverScrollableScrollPhysics`, so the widget sizes to its
  /// content under an unbounded sliver/nested scroll surface (the
  /// grocery / food / inventory "Order" tabs). Defaults to `false` —
  /// the Connect screen continues to rely on the bounded `Expanded`
  /// layout, unchanged.
  final bool isInParentScroll;

  const OrdersTabView({
    super.key,
    this.excludeSenderId,
    this.onlySenderId,
    this.isInParentScroll = false,
  });

  @override
  State<OrdersTabView> createState() => _OrdersTabViewState();
}

class _OrdersTabViewState extends State<OrdersTabView> {
  // Date-range filter state. `_selectedDateFilter` drives the chip row;
  // `_customRange` holds the result of the calendar picker when the
  // user picks `_OrderDateFilter.custom`.
  _OrderDateFilter _selectedDateFilter = _OrderDateFilter.all;
  DateTimeRange? _customRange;

  final chatViewController = Get.find<ChatViewController>();

  /// Returns true when [chat]'s creation timestamp falls inside the
  /// currently-selected date filter window. `createdAt` is preferred —
  /// it's the moment the order was placed, which is what the user is
  /// usually filtering on. Falls back to `updatedAt` only when the
  /// server omits `createdAt`. Unparseable / missing dates are dropped
  /// for any non-`all` filter so they don't leak into narrow windows.
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
        // End is inclusive of the picked day, so add one full day to
        // make the upper bound exclusive against the local timestamp.
        final endExclusive = DateTime(_customRange!.end.year,
                _customRange!.end.month, _customRange!.end.day)
            .add(const Duration(days: 1));
        return !date.isBefore(start) && date.isBefore(endExclusive);
      case _OrderDateFilter.all:
        return true;
    }
  }

  /// Opens the system date-range picker for `_OrderDateFilter.custom`.
  /// On confirm, switches the active filter to `custom` and stores the
  /// chosen range in `_customRange`. Cancelling leaves the previous
  /// filter in place so a stray tap doesn't clear the user's selection.
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
      helpText: 'Filter orders by date',
      saveText: 'Apply',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _selectedDateFilter = _OrderDateFilter.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Obx(() {

      return Obx(() {
        if(chatViewController.orderChatListResponse.value.status ==
            Status.COMPLETE){
          GetChatListModel? data =
              chatViewController.getOrderChatListModel?.value;
          // Three filters compose:
          //  1. `excludeSenderId` — drops chats whose `lastMessageSenderId`
          //     matches (Grocery profile screen: hide self-authored chats).
          //  2. `onlySenderId` — keeps only chats whose
          //     `lastMessageSenderId` matches (Connect screen: show only
          //     self-authored chats — the mirror of #1).
          //  3. `_selectedDateFilter` — restricts to a date window
          //     resolved against `chat.createdAt` / `updatedAt`.
          // Kept as `List<ChatList?>` to match the model's nullable shape so
          // the existing `chat?.foo` accesses below continue to compile.
          final List<ChatList?> visibleChats =
              (data?.chatList ?? <ChatList?>[])
                  .where((c) =>
                      widget.excludeSenderId == null ||
                      (c?.lastMessageSenderId ?? '') != widget.excludeSenderId)
                  .where((c) =>
                      widget.onlySenderId == null ||
                      (c?.lastMessageSenderId ?? '') == widget.onlySenderId)
                  .where(_matchesDateFilter)
                  .toList();
          // Debug aid — prints the filter inputs, the raw vs filtered
          // counts, and each chat's lastMessageSenderId. Remove once
          // filtering is verified on both screens.
          debugPrint(
              '[OrdersTabView] excludeSenderId="${widget.excludeSenderId}" '
              'onlySenderId="${widget.onlySenderId}" '
              'dateFilter=${_selectedDateFilter.label} '
              'raw=${data?.chatList?.length ?? 0} '
              'visible=${visibleChats.length} '
              'lastMessageSenderIds=${(data?.chatList ?? []).map((c) => c?.lastMessageSenderId).toList()}');
          return RefreshIndicator(
            onRefresh: () async {
              chatViewController.emitEvent(
                  ChatEmitEvents.ChatList, {ApiKeys.type: "order"});
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date filter row — preset chips (All / Today / Yesterday /
                // Last 7 days / Last 30 days) + a trailing calendar icon
                // that opens a date-range picker for `_OrderDateFilter.custom`.
                _buildDateFilterRow(),
                SizedBox(height: 10),
                // Orders List — bounded mode (Connect screen) wraps in
                // Expanded so the list fills its TabBarView slot;
                // parent-scroll mode (grocery / food / inventory Order
                // tabs) drops the Expanded so the inner shrinkWrap
                // ListView (with NeverScrollable physics applied below)
                // can size to its content under the surrounding
                // CustomScrollView.
                Builder(builder: (_) {
                  final ordersListBody = Container(
                    margin: EdgeInsets.only(bottom: SizeConfig.size70),
                    child: visibleChats.isEmpty
                        ? noChatsFound()
                        : ListView.builder(
                      itemCount: visibleChats.length,
                      shrinkWrap: true,
                      // Default ListView padding is `null`, which
                      // triggers an implicit `MediaQuery.removePadding`
                      // cycle that can leak inherited top padding into
                      // the first row when the list isn't the screen's
                      // top-most scrollable. Pin to zero.
                      padding: EdgeInsets.zero,
                      // In parent-scroll mode the surrounding
                      // CustomScrollView owns the scroll — turn this
                      // list inert so it doesn't fight the parent for
                      // drag events.
                      physics: widget.isInParentScroll
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      itemBuilder: (context, index) {
                        final chat = visibleChats[index];
                        final isInSelectionMode = chatViewController
                            .isChatListSelectionMode.value;
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
                            Navigator.push(
                                context, MaterialPageRoute(builder: (context) =>
                                OrderChatScreen(
                                  name: chat?.sender?.name ?? '',
                                  contactNo: chat?.sender?.contactNo ?? '',
                                  conversationId: chat?.conversationId ?? '',
                                  type: chat?.sender?.accountType ?? '',
                                  userId: chat?.sender?.id ?? '',
                                  profileImage:
                                      chat?.sender?.profileImage ?? '',
                                  designation: chat?.sender?.designation ?? '',
                                )));
                          },
                          onLongPress: () {
                            if (!isInSelectionMode) {
                              chatViewController
                                  .isChatListSelectionMode.value = true;
                              chatViewController
                                  .toggleChatListSelection(chat);
                              setState(() {});
                            }
                          },
                          isChatListSelected: isChatSelected,
                          onSelect: () {
                            setState(() {});
                          },
                          type: chat?.sender?.accountType ??
                              AppConstants.individual,
                          index: index,
                          chatViewController: chatViewController,
                          chat: chat,
                          theme: theme,
                          isForwardUI: false,
                          context: context,
                          showNewBadgeIfRecent: true,
                          showFlagBadge: true,
                        );
                      },
                    ),
                  );
                  return widget.isInParentScroll
                      ? ordersListBody
                      : Expanded(child: ordersListBody);
                })
                // Expanded(
                //   child: ListView.builder(
                //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                //     itemCount: orders.length,
                //     itemBuilder: (context, index) {
                //       final order = orders[index];
                //       return InkWell(
                //         onTap: (){
                //           Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderChatScreen()));
                //         },
                //         child: Container(
                //           margin: EdgeInsets.only(bottom: 22),
                //           child: Row(
                //             children: [
                //               CircleAvatar(
                //                 backgroundColor: Colors.blue,
                //                 radius: 22,
                //                 child: CustomText(
                //                     'BE',
                //                     color: Colors.white, fontWeight: FontWeight.bold
                //                 ),
                //               ),
                //               SizedBox(width: 12),
                //               Expanded(
                //                 child: Column(
                //                   crossAxisAlignment: CrossAxisAlignment.start,
                //                   children: [
                //                     CustomText(
                //                       order['title'],
                //                           fontSize: 16,
                //                         fontWeight: FontWeight.bold
                //
                //                     ),
                //                     SizedBox(height: 4),
                //                     CustomText(
                //                       order['subtitle'],
                //                           color: Colors.grey.shade600, fontSize: 14,
                //                       overflow: TextOverflow.ellipsis,
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               Column(
                //                 crossAxisAlignment: CrossAxisAlignment.end,
                //                 children: [
                //                   CustomText(
                //                     order['time'],
                //                         fontSize: 11,
                //                       color: Colors.grey
                //                   ),
                //                   SizedBox(height: 4),
                //                   Container(
                //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                //                     decoration: BoxDecoration(
                //                       color: Colors.transparent,
                //                       border: Border.all(color: order['statusColor']),
                //                       borderRadius: BorderRadius.circular(20),
                //                     ),
                //                     child: CustomText(
                //                       order['status'],
                //                         color: order['statusColor'],
                //                         fontSize: 11,
                //                         fontWeight: FontWeight.w500,
                //                     ),
                //                   )
                //                 ],
                //               ),
                //             ],
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ),
              ],
            ),
          );
        }else{
          return SizedBox();
        }

      });

    // });

  }

  /// Renders the date-range chip strip at the top of the orders list.
  /// Tapping a preset switches the active filter; tapping the trailing
  /// calendar icon launches `showDateRangePicker`. The custom chip is
  /// only shown once a range has been chosen so the strip stays compact.
  Widget _buildDateFilterRow() {
    // Order matters — drives the visual layout of the chips.
    final presets = const [
      _OrderDateFilter.all,
      _OrderDateFilter.today,
      _OrderDateFilter.yesterday,
      _OrderDateFilter.last7Days,
      _OrderDateFilter.last30Days,
    ];

    String _formatRange(DateTimeRange r) {
      String two(int n) => n.toString().padLeft(2, '0');
      final s = r.start, e = r.end;
      final sameYear = s.year == e.year;
      final left = '${two(s.day)}/${two(s.month)}'
          '${sameYear ? '' : '/${s.year}'}';
      final right = '${two(e.day)}/${two(e.month)}/${e.year}';
      return '$left – $right';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final f in presets) ...[
            _filterChip(
              label: f.label,
              selected: _selectedDateFilter == f,
              onTap: () => setState(() => _selectedDateFilter = f),
            ),
            const SizedBox(width: 8),
          ],
          // Custom-range pill — only appears once the user picks a range
          // via the calendar icon. Shows the picked range and clears on
          // its own trailing close affordance.
          if (_customRange != null) ...[
            _filterChip(
              label: _formatRange(_customRange!),
              selected: _selectedDateFilter == _OrderDateFilter.custom,
              onTap: () =>
                  setState(() => _selectedDateFilter = _OrderDateFilter.custom),
              trailing: InkWell(
                onTap: () => setState(() {
                  _customRange = null;
                  if (_selectedDateFilter == _OrderDateFilter.custom) {
                    _selectedDateFilter = _OrderDateFilter.all;
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.close, size: 14, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Calendar icon — opens the date-range picker. Highlighted when
          // the active filter is `custom` so it doubles as a status cue.
          InkWell(
            onTap: _pickCustomRange,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedDateFilter == _OrderDateFilter.custom
                    ? AppColors.buttonLiteBlue
                    : Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.date_range,
                  size: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.buttonLiteBlue : Colors.white,
          border: selected ? null : Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              label,
              color: selected ? Colors.black : AppColors.optionShowGray,
              fontSize: 14,
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}