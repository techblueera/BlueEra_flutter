import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// "Orders in 12 Hrs." — the customer's own recent orders, on Discover, right
/// under the ongoing-ride chip.
///
/// ## Where the data comes from
/// Ordering in this app IS a conversation: the order/enquiry card is posted
/// into a chat with the shop, which lands in the Inquiry lane. So "my recent
/// orders" is precisely "inquiry chats whose last message is recent" —
/// [recentInquiryChats] over the business chat list, which also drops the
/// orders the user RECEIVED as a seller (those belong to the Me section).
///
/// Nothing is fetched here. The Inquiry list is already loaded and kept live
/// by [ChatViewController] (socket push, local-cache first), so this rail
/// reads it and re-renders; it collapses to nothing when no order is recent,
/// which is the common case for most users on most days.
class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({super.key, this.maxRows = 3});

  /// Rows shown before the list defers to "View All" — the rail sits above the
  /// whole Discover feed and must not push it off screen.
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
      final orders = recentInquiryChats(
        chat.getBusinessChatListModel?.value.chatList,
        window: _window,
      );
      if (orders.isEmpty) return const SizedBox.shrink();

      final rows = orders.take(maxRows).toList();
      return Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        // Uniform inset now that the card ends on the last order row — the
        // tighter bottom value existed only to offset the Book-a-Ride button's
        // own padding.
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(orders.length),
            SizedBox(height: SizeConfig.size12),
            for (var i = 0; i < rows.length; i++) ...[
              _OrderRow(chat: rows[i]),
              if (i != rows.length - 1)
                Divider(height: SizeConfig.size20, color: AppColors.whiteE5),
            ],
          ],
        ),
      );
    });
  }

  Widget _header(int total) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            'Orders in ${_window.inHours} Hrs.',
            fontSize: SizeConfig.large18,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
        ),
        if (total > maxRows)
          InkWell(
            // The Inquiry tab is the full list — same rows, same lane, with
            // search and filters this rail deliberately doesn't repeat.
            onTap: () => getOrPut(() => BottomBarController()).currentIndex.value =
                _kConnectTabIndex,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: CustomText(
                'View All',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

}

/// Bottom-nav index the Connect (chat / inquiry) tab lives at.
const int _kConnectTabIndex = 2;

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.chat});

  final ChatList chat;

  @override
  Widget build(BuildContext context) {
    final unread = (chat.unreadCount ?? 0).toInt();

    return InkWell(
      onTap: () => getOrPut(() => BottomBarController()).currentIndex.value =
          _kConnectTabIndex,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatarWidget(
            imageUrl: (chat.sender?.profileImage?.isEmpty ?? true)
                ? null
                : chat.sender?.profileImage,
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
                  chat.sender?.name ?? 'Shop',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size2),
                // The last message is the order itself — the item list, the
                // shop's reply, or whatever the conversation last said.
                CustomText(
                  (chat.lastMessage?.isNotEmpty ?? false)
                      ? chat.lastMessage!
                      : 'Order placed',
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
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(100),
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
