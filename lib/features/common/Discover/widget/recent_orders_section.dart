import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
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

/// "Orders in 12 Hrs." — the user's recent order conversations on Discover,
/// right under the ongoing-ride chip, in two lanes: orders they RECEIVED as a
/// seller ("Received", first and default) and orders they PLACED themselves
/// ("My Orders").
///
/// ## Where the data comes from
/// Ordering in this app IS a conversation: the order/enquiry card is posted
/// into a chat with the shop. Which side of it you're on decides the lane —
/// [recentInquiryChats] is the buyer side (the Connect screen's Inquiry tab),
/// [recentReceivedOrderChats] the seller side (the same rows the Connect
/// screen's Order tab renders via `OrdersTabBody`).
///
/// Nothing is fetched here. Both lanes come out of the one business chat list
/// already loaded and kept live by [ChatViewController] (socket push,
/// local-cache first), so this rail reads it and re-renders; it collapses to
/// nothing when neither lane has a recent order, which is the common case for
/// most users on most days. The lane switch only appears when both lanes have
/// rows — with one lane the rail looks exactly as it always has.
class RecentOrdersSection extends StatefulWidget {
  const RecentOrdersSection({super.key, this.maxRows = 3});

  /// Rows shown before the list defers to "View All" — the rail sits above the
  /// whole Discover feed and must not push it off screen.
  final int maxRows;

  @override
  State<RecentOrdersSection> createState() => _RecentOrdersSectionState();
}

class _RecentOrdersSectionState extends State<RecentOrdersSection> {
  static const Duration _window = Duration(hours: 12);

  /// Selected lane: 0 = received (orders from customers), 1 = placed (my own
  /// orders). Only honoured once the user has actually tapped the switch
  /// ([_userPicked]) — until then the rail opens on whichever lane has rows.
  int _lane = 0;
  bool _userPicked = false;

  int get _maxRows => widget.maxRows;

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
      final placed = recentInquiryChats(all, window: _window);
      final received = recentReceivedOrderChats(all, window: _window);
      if (placed.isEmpty && received.isEmpty) return const SizedBox.shrink();

      // A lane that empties out (its last order aged past the window) must not
      // strand the rail on a blank tab, so the selection is resolved against
      // what actually has rows rather than trusted outright.
      final bothLanes = placed.isNotEmpty && received.isNotEmpty;
      final int lane = bothLanes
          ? (_userPicked ? _lane : 0)
          : (received.isNotEmpty ? 0 : 1);
      final orders = lane == 0 ? received : placed;

      final rows = orders.take(_maxRows).toList();
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
            _header(total: orders.length, lane: lane),
            if (bothLanes) ...[
              SizedBox(height: SizeConfig.size10),
              _laneSwitch(
                lane: lane,
                placedCount: placed.length,
                receivedCount: received.length,
              ),
            ],
            SizedBox(height: SizeConfig.size12),
            // Each order on its own frosted plate instead of divider-separated
            // rows: the plates read as glass-on-glass and give the tap target a
            // visible edge, which a hairline divider over a translucent panel
            // does not.
            for (var i = 0; i < rows.length; i++) ...[
              _OrderRow(chat: rows[i], lane: lane),
              if (i != rows.length - 1) SizedBox(height: SizeConfig.size8),
            ],
          ],
        ),
      );
    });
  }

  Widget _header({required int total, required int lane}) {
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
        if (total > _maxRows)
          // Frosted pill rather than bare text, so the link reads as a control
          // on the glass panel.
          Material(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              // The matching Connect tab is the full list — same rows, same
              // lane, with the search and filters this rail deliberately
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

  /// Segmented switch between the two lanes. Rendered only when both have
  /// rows, so it never degrades into a single decorative pill.
  Widget _laneSwitch({
    required int lane,
    required int placedCount,
    required int receivedCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          _laneChip(
            label: 'Received',
            count: receivedCount,
            selected: lane == 0,
            onTap: () => setState(() {
              _lane = 0;
              _userPicked = true;
            }),
          ),
          SizedBox(width: SizeConfig.size6),
          _laneChip(
            label: 'My Orders',
            count: placedCount,
            selected: lane == 1,
            onTap: () => setState(() {
              _lane = 1;
              _userPicked = true;
            }),
          ),
        ],
      ),
    );
  }

  Widget _laneChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        // Selected reads as an opaque plate on the glass; unselected keeps the
        // panel showing through so only one chip ever competes with the rows.
        color: selected
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: CustomText(
              '$label ($count)',
              textAlign: TextAlign.center,
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryColor : AppColors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-nav index the Connect (chat / inquiry / order) screen lives at.
const int _kConnectTabIndex = 2;

/// Server marker an order thread carries as its last message — the row's real
/// identity sits in `group_name` / `group_profile_image` when it's present
/// (same rule `ChatListTile` applies).
const String _kOrderMessageMarker = 'Order Message';

/// Connect sub-tab each lane belongs to: placed orders (lane 1) are the
/// Inquiry tab (index 1), received orders (lane 0) the Order tab (index 2 —
/// the merchant-style tab `ConnectMainPage` only builds for business / social
/// / skill-worker profiles; anyone else has Call there, so those fall back to
/// Chat).
int _connectSubTabFor(int lane) {
  if (lane == 1) return 1;
  final showsOrderTab = isBusinessUser() ||
      userProfileTypeGlobal == SOCIAL_PROFILE ||
      userProfileTypeGlobal == SKILL_WORKER;
  return showsOrderTab ? 2 : 0;
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
  const _OrderRow({required this.chat, required this.lane});

  final ChatList chat;

  /// 0 = order I received, 1 = order I placed — decides which Connect sub-tab
  /// the row opens and whose name the row shows.
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

    // Material + InkWell rather than a decorated Container: the plate's fill
    // has to come from the Material itself, otherwise the tap ripple paints on
    // the Scaffold underneath and is hidden behind the plate.
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openConnectLane(lane),
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
