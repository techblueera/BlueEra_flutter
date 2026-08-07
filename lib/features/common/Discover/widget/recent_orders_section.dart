import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/widget/ongoing_style_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Recent order conversations on Discover, right under the ongoing-ride chip,
/// as TWO separate glass cards stacked in order:
///   1. "Orders in 12 Hrs." — orders RECEIVED as a seller
///   2. "My Orders in 12 Hrs." — orders the user PLACED themselves
/// Each card stands on its own and disappears independently when its side has
/// nothing recent, so no tab or switch is involved.
///
/// ## Where the data comes from
/// Ordering in this app IS a conversation: the order/enquiry card is posted
/// into a chat with the shop. Which side of it you're on decides the card —
/// [recentInquiryChats] is the buyer side (the Connect screen's Inquiry tab),
/// [recentReceivedOrderChats] the seller side (the same rows the Connect
/// screen's Order tab renders via `OrdersTabBody`).
///
/// Nothing is fetched here. Both cards come out of the one business chat list
/// already loaded and kept live by [ChatViewController] (socket push,
/// local-cache first), so this rail reads it and re-renders; it collapses to
/// nothing when neither side has a recent order, which is the common case for
/// most users on most days.
class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({super.key, this.maxRows = 3});

  /// Rows shown per card before it defers to "View All" — the rail sits above
  /// the whole Discover feed and must not push it off screen.
  final int maxRows;

  static const Duration _window = Duration(hours: 12);

  @override
  Widget build(BuildContext context) {
    // Registered by the bottom-nav shell that hosts Discover, so it is always
    // present here; guarded anyway rather than constructing the chat stack
    // from a Discover render.
    if (!Get.isRegistered<ChatViewController>()) return const SizedBox.shrink();
    final chat = Get.find<ChatViewController>();

    return Obx(() {
      // Read inside the Obx so a socket push repaints the rail.
      final all = chat.getBusinessChatListModel?.value.chatList;
      final received = recentReceivedOrderChats(all, window: _window);
      final placed = recentInquiryChats(all, window: _window);
      if (received.isEmpty && placed.isEmpty) return const SizedBox.shrink();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (received.isNotEmpty)
            _card(
              title: 'Orders in ${_window.inHours} Hrs.',
              orders: received,
              lane: 0,
            ),
          if (placed.isNotEmpty)
            _card(
              title: 'My Orders in ${_window.inHours} Hrs.',
              orders: placed,
              lane: 1,
            ),
        ],
      );
    });
  }

  /// A lane: its title + "View All", then ONE card per order.
  ///
  /// Each order is its own card in the same shape as the ongoing-ride chip
  /// above ([OngoingStyleCard]) rather than a row inside a shared glass panel.
  /// Everything the customer has in flight then reads as one stack of
  /// equal-weight cards down the top of Discover — the ride, then each order —
  /// instead of one prominent chip followed by a list that looked like a
  /// different kind of thing.
  Widget _card({
    required String title,
    required List<ChatList> orders,
    required int lane,
  }) {
    final rows = orders.take(maxRows).toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: SizeConfig.size12,
        left: SizeConfig.size12,
        right: SizeConfig.size12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _header(title: title, total: orders.length, lane: lane),
          SizedBox(height: SizeConfig.size10),
          for (var i = 0; i < rows.length; i++) ...[
            _OrderCard(chat: rows[i], lane: lane),
            if (i != rows.length - 1) SizedBox(height: SizeConfig.size8),
          ],
        ],
      ),
    );
  }

  Widget _header({
    required String title,
    required int total,
    required int lane,
  }) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            title,
            fontSize: SizeConfig.large18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (total > maxRows)
          // Frosted pill rather than bare text, so the link reads as a control
          // on the glass panel.
          Material(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              // The matching Connect tab is the full list — same rows, same
              // side, with the search and filters this rail deliberately
              // doesn't repeat.
              onTap: () => _openConnectLane(lane),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: CustomText(
                  'View All',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom-nav index the Connect (chat / inquiry / order) screen lives at.
const int _kConnectTabIndex = 2;

/// How recent an order's last message has to be for the row to carry the
/// "New" tag. Much tighter than the 12-hour card window: the tag is for an
/// order that just landed, not for everything on the card.
const Duration _kFreshWindow = Duration(minutes: 6);

/// Green of the "New" tag — deliberately not the brand blue the unread badge
/// uses, so the two badges stay distinguishable when a row carries both.
const Color _kFreshGreen = Color(0xFF1FB35A);

/// Server marker an order thread carries as its last message — the row's real
/// identity sits in `group_name` / `group_profile_image` when it's present
/// (same rule `ChatListTile` applies).
const String _kOrderMessageMarker = 'Order Message';

/// Connect sub-tab each lane belongs to: placed orders (lane 1) are the
/// Inquiry tab (index 1), received orders (lane 0) the Order tab (index 2 —
/// the merchant-style tab `ConnectMainPage` only builds for the profiles
/// [showsConnectOrderTab] covers; anyone else has Call there, so those fall
/// back to Chat).
int _connectSubTabFor(int lane) {
  if (lane == 1) return 1;
  return showsConnectOrderTab() ? 2 : 0;
}

/// Opens the Connect screen on the sub-tab holding [lane]. The sub-tab index
/// is handed over through [ChatViewController.onSelectChatTab], which
/// `ConnectMainPage.initState` consumes as its initial tab.
void _openConnectLane(int lane) {
  if (Get.isRegistered<ChatViewController>()) {
    Get.find<ChatViewController>().onSelectChatTab(_connectSubTabFor(lane));
  }
  getOrPut(() => BottomBarController()).currentIndex.value = _kConnectTabIndex;
}

/// One recent order, as its own card in the same shape as the ongoing-ride
/// chip above it.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.chat, required this.lane});

  final ChatList chat;

  /// 0 = order I received, 1 = order I placed — decides which Connect sub-tab
  /// the card opens and whose name it shows.
  final int lane;

  @override
  Widget build(BuildContext context) {
    final unread = (chat.unreadCount ?? 0).toInt();

    // Identity resolution mirrors [ChatListTile]: an order thread is carried as
    // a group-shaped row, so on those the counterpart is `group_name` /
    // `group_profile_image`, not the embedded sender.
    final isGroupish = chat.type == AppConstants.group_Chat_Type ||
        chat.isGroup == true ||
        chat.lastMessage == _kOrderMessageMarker;
    final name = isGroupish ? chat.groupName : chat.sender?.name;
    final image = isGroupish ? chat.groupProfileImage : chat.sender?.profileImage;

    return OngoingStyleCard(
      onTap: () => _openConnectLane(lane),
      accent: OngoingStyleCard.orderAccent,
      gradient: OngoingStyleCard.orderGradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatarWidget(
            imageUrl: (image?.isEmpty ?? true) ? null : image,
            size: SizeConfig.size44,
            borderRadius: SizeConfig.size22,
            showProfileOnFullScreen: false,
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  (name?.isNotEmpty ?? false)
                      ? name!
                      : (lane == 0 ? 'Customer' : 'Shop'),
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size2),
                // The last message is the order itself — the item list, the
                // shop's reply, or whatever the conversation last said. The
                // "Order Message" marker is plumbing, not a preview, so it
                // reads as the placed/received order instead.
                CustomText(
                  _preview(),
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                _timeLabel(chat),
                fontSize: SizeConfig.small11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              // Just-landed marker. Green so it never reads as the blue
              // unread badge below it — this one is about age, not about
              // whether the user has opened the thread.
              if (_isFresh) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kFreshGreen,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331FB35A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CustomText(
                    AppStrings.newTag.tr,
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: SizeConfig.size4),
              ],
              if (unread > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(100),
                    // Solid brand blue is the one opaque thing on the panel —
                    // it's the alert, so it stays loud against the glass.
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x330086FF),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CustomText(
                    '$unread new',
                    fontSize: SizeConfig.extraSmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// True while the row's last message is under [_kFreshWindow] old — what
  /// the "New" tag marks. Built off the same timestamp the row prints, and
  /// false on a missing/unparseable one (and on a future-dated row) rather
  /// than guessing.
  bool get _isFresh {
    final raw =
        (chat.updatedAt?.isNotEmpty ?? false) ? chat.updatedAt : chat.createdAt;
    if (raw == null || raw.isEmpty) return false;
    try {
      final at = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(at);
      return !diff.isNegative && diff < _kFreshWindow;
    } catch (_) {
      return false;
    }
  }

  /// Row subtitle — the last message, with the internal order marker and the
  /// empty case replaced by a lane-appropriate label.
  String _preview() {
    final last = chat.lastMessage ?? '';
    if (last.isEmpty || last == _kOrderMessageMarker) {
      return lane == 0 ? 'New order received' : 'Order placed';
    }
    return last;
  }

  /// `9:52 PM` for the last message. Falls back to empty rather than showing a
  /// wrong time when the row carries no parseable timestamp.
  String _timeLabel(ChatList chat) {
    final raw =
        (chat.updatedAt?.isNotEmpty ?? false) ? chat.updatedAt : chat.createdAt;
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat('h:mm a').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '';
    }
  }
}
