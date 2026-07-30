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
        margin: EdgeInsets.only(bottom: SizeConfig.size12, left: 12, right: 12),
        // Uniform inset now that the card ends on the last order row — the
        // tighter bottom value existed only to offset the Book-a-Ride button's
        // own padding.
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          // Glass panel, matching the rest of the redesigned Discover page: a
          // translucent white wash over the blurred profile photo behind the
          // feed, NOT a solid card. Kept high-alpha because this panel is dense
          // dark text — the folder tiles can sit at 0.22, a list of shop names
          // and messages cannot.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: _kGlassCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(orders.length),
            SizedBox(height: SizeConfig.size12),
            // Each order on its own frosted plate instead of divider-separated
            // rows: the plates read as glass-on-glass and give the tap target a
            // visible edge, which a hairline divider over a translucent panel
            // does not.
            for (var i = 0; i < rows.length; i++) ...[
              _OrderRow(chat: rows[i]),
              if (i != rows.length - 1) SizedBox(height: SizeConfig.size8),
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
            color: AppColors.white,
          ),
        ),
        if (total > maxRows)
          // Frosted pill rather than bare text, so the link reads as a control
          // on the glass panel.
          Material(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              // The Inquiry tab is the full list — same rows, same lane, with
              // search and filters this rail deliberately doesn't repeat.
              onTap: () => getOrPut(() => BottomBarController())
                  .currentIndex
                  .value = _kConnectTabIndex,
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

/// Bottom-nav index the Connect (chat / inquiry) tab lives at.
const int _kConnectTabIndex = 2;

/// Lift under the glass panel. A translucent panel has no fill of its own to
/// separate it from the photo behind the feed, so the shadow is what makes it
/// read as a pane floating above the page rather than a tint painted on it.
const List<BoxShadow> _kGlassCardShadow = [
  BoxShadow(
    color: Color(0x1F101828),
    blurRadius: 18,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x14101828),
    blurRadius: 4,
    offset: Offset(0, 1),
  ),
];

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.chat});

  final ChatList chat;

  @override
  Widget build(BuildContext context) {
    final unread = (chat.unreadCount ?? 0).toInt();

    // Material + InkWell rather than a decorated Container: the plate's fill
    // has to come from the Material itself, otherwise the tap ripple paints on
    // the Scaffold underneath and is hidden behind the plate.
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => getOrPut(() => BottomBarController()).currentIndex.value =
            _kConnectTabIndex,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10,
            vertical: SizeConfig.size10,
          ),
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
        ),
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
