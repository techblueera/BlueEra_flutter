import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/widget/ongoing_style_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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

  /// Laid out to the SAME grammar as the ongoing-ride chip
  /// (`ongoing_booking_chip.dart` → `_ChipCard`), so the stack down the top of
  /// Discover reads as one family instead of a rich card followed by what looks
  /// like a chat row that wandered in:
  ///
  ///   avatar · [ what it is / who it's with · when ] · status pill · action
  ///
  /// The ride card puts WHAT IT IS on the title line ("Your Ongoing Ride") and
  /// WHO on the subtitle. This now does the same — "Your Order" over the shop's
  /// name — rather than leading with the name and leaving the reader to work
  /// out what kind of row they are looking at.
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
    final counterparty =
        (name?.isNotEmpty ?? false) ? name! : (lane == 0 ? 'Customer' : 'Shop');
    final time = _timeLabel(chat);
    final store = _nearbyStore();
    final address = _addressLabel(store);
    final distance = _distanceLabel(store);

    return OngoingStyleCard(
      onTap: _openThread,
      accent: OngoingStyleCard.orderAccent,
      gradient: OngoingStyleCard.orderGradient,
      child: Row(
        children: [
          CachedAvatarWidget(
            imageUrl: (image?.isEmpty ?? true) ? null : image,
            size: 46,
            borderRadius: 23,
            showProfileOnFullScreen: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The SHOP is the title. It is the one thing that identifies
                // the row at a glance — "Your Order" was true of every card in
                // the stack and told the reader nothing they couldn't see from
                // the card's own tint.
                CustomText(
                  counterparty,
                  fontSize: SizeConfig.size15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // address · distance · time — the same "|"-separated metadata
                // line the ride card uses for captain · fare · distance. Each
                // part drops out on its own when unknown, so the row never
                // shows a dangling separator.
                Row(
                  children: [
                    if (address != null) ...[
                      Flexible(
                        child: CustomText(
                          address,
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distance != null || time.isNotEmpty)
                        CustomText(
                          '  |  ',
                          fontSize: SizeConfig.size12,
                          color: AppColors.grayText,
                        ),
                    ],
                    if (distance != null) ...[
                      Icon(Icons.location_on,
                          size: 13, color: AppColors.primaryColor),
                      const SizedBox(width: 2),
                      CustomText(
                        distance,
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                        maxLines: 1,
                      ),
                      if (time.isNotEmpty)
                        CustomText(
                          '  |  ',
                          fontSize: SizeConfig.size12,
                          color: AppColors.grayText,
                        ),
                    ],
                    if (time.isNotEmpty)
                      CustomText(
                        time,
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Same slot the ride card gives the OTP / Customer Care pill,
                // and the same pill geometry — so the two cards are the same
                // height and the eye finds the status in the same place on both.
                _OrderStatusPill(
                  label: _preview(),
                  isFresh: _isFresh,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _trailing(unread),
        ],
      ),
    );
  }

  /// Circle action + a small label under it, exactly as the ride card's
  /// trailing column works. The action opens the thread's Connect lane; the
  /// label carries the unread count, which is the one number worth surfacing
  /// outside the card body.
  Widget _trailing(int unread) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openThread,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A101828),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            // The app's own chat glyph rather than the Material bubble — this
            // row opens the same thread the Connect tab does, and it should be
            // wearing the same icon that tab wears.
            child: Center(
              child: LocalAssets(
                imagePath: AppIconAssets.chat,
                height: 20,
                width: 20,
                imgColor: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        if (unread > 0) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(100),
              // Solid brand blue is the one opaque thing on the panel — it's
              // the alert, so it stays loud against the glass.
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
      ],
    );
  }

  /// Open THIS order's conversation — the shop's own thread — rather than the
  /// Connect tab's list.
  ///
  /// The card already names one specific shop, so landing on a list and making
  /// the customer find that shop again is a step that answers nothing. It goes
  /// straight in, the way tapping the same row inside Connect does.
  ///
  /// Deliberately routed through the SAME controller methods the chat list's
  /// own rows use ([ChatViewController.openChatFromChatList] /
  /// [ChatViewController.openGroupFromChatList], see `ChatListTile`'s default
  /// `onTap` in component_widgets.dart) — they hydrate the local conversation
  /// cache and pick the business-vs-personal screen before navigating, and
  /// re-implementing that here would be a second way into the same thread with
  /// its own bugs.
  ///
  /// Order threads arrive group-shaped, which is why the group branch exists
  /// and why it has to be checked the same way `ChatListTile` checks it — on
  /// `type` / `isGroup` only. (The `lastMessage == 'Order Message'` marker
  /// identifies an order row for DISPLAY purposes, but is not what decides
  /// which screen opens.)
  ///
  /// Falls back to the Connect lane when the chat stack isn't registered — the
  /// old behaviour, and still better than a dead tap.
  void _openThread() {
    if (!Get.isRegistered<ChatViewController>()) {
      _openConnectLane(lane);
      return;
    }
    final chatCtrl = Get.find<ChatViewController>();

    if (chat.type == AppConstants.group_Chat_Type || chat.isGroup == true) {
      chatCtrl.openGroupFromChatList(chat);
      return;
    }

    final senderId = chat.sender?.id ?? '';
    final conversationId = chat.conversationId ?? '';
    // With neither id there is no thread to open; the list is the honest
    // fallback rather than a screen that would come up blank.
    if (senderId.isEmpty && conversationId.isEmpty) {
      _openConnectLane(lane);
      return;
    }

    chatCtrl.openChatFromChatList(
      userId: senderId,
      conversationId: conversationId,
      // Same default the chat list applies — these rows live in the business
      // lane, which is where ordering happens.
      type: chat.sender?.accountType ?? AppConstants.business,
      contactName: chat.sender?.name,
      contactNo: chat.sender?.contactNo,
      profileImage: chat.sender?.profileImage,
    );
  }

  /// The nearby-store record for this order's shop, or null.
  ///
  /// **The chat list carries no address and no coordinates** — `Sender` has a
  /// name, a number, a businessId and a photo, and `ChatList` adds nothing
  /// geographic. So the address and distance on this card cannot come from the
  /// row itself; they are looked up in [NearbyStoresController], which already
  /// holds the nearby-discover response (business id, user id, address, and a
  /// server-computed `distance` in km) and keeps it in a Hive cache across
  /// launches.
  ///
  /// Matched on the merchant's USER id first and the business id second,
  /// because the chat row identifies its counterpart by whichever it happens to
  /// have: an order thread carries `businessOwnerUserId`, a plain business chat
  /// the sender's `businessId`.
  ///
  /// Null is the normal outcome for a shop the customer ordered from but that
  /// is not in the current nearby radius — they moved, or it was always
  /// further out. The card then simply omits both fields rather than showing a
  /// guess, which is why every part of the metadata line drops out on its own.
  NearbyStoreCard? _nearbyStore() {
    // Seller-side rows are orders the user RECEIVED — the counterpart is a
    // customer, not a shop, so there is no store to look up.
    if (lane == 0) return null;
    if (!Get.isRegistered<NearbyStoresController>()) return null;

    final ownerId = chat.businessOwnerUserId ?? '';
    final businessId = chat.sender?.businessId ?? '';
    if (ownerId.isEmpty && businessId.isEmpty) return null;

    final stores = Get.find<NearbyStoresController>().stores;
    for (final store in stores) {
      if (ownerId.isNotEmpty && store.userId == ownerId) return store;
      if (businessId.isNotEmpty && store.id == businessId) return store;
    }
    return null;
  }

  /// Street line for the shop, trimmed to the one line the row can hold.
  String? _addressLabel(NearbyStoreCard? store) {
    final address = store?.address.trim() ?? '';
    return address.isEmpty ? null : address;
  }

  /// `1.4 km` / `3 km`, using the server's own distance so this card and the
  /// Discover store rails can never disagree about how far a shop is.
  ///
  /// Sub-kilometre keeps a decimal (0.4 km reads as walkable, "0 km" reads as
  /// broken); beyond that the decimal is noise.
  String? _distanceLabel(NearbyStoreCard? store) {
    final km = store?.distance ?? 0;
    if (km <= 0) return null;
    return km < 1
        ? '${km.toStringAsFixed(1)} km'
        : '${km.toStringAsFixed(0)} km';
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

/// The order's current line, in the slot and geometry the ride card gives its
/// OTP / Customer Care pill.
///
/// It is the LAST MESSAGE, not an order status — the chat list is the only
/// source this rail has, and it carries no status, no item count and no total.
/// See the note at the top of this file: a real status pill needs an order
/// endpoint behind it, and inventing one from the message text would be a guess
/// dressed as a fact.
///
/// [isFresh] tints it green for an order that landed in the last few minutes,
/// which is the one piece of state the timestamps genuinely support.
class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({required this.label, required this.isFresh});

  final String label;
  final bool isFresh;

  @override
  Widget build(BuildContext context) {
    final accent = isFresh ? _kFreshGreen : const Color(0xFF5B6B7F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFresh
                ? Icons.fiber_new_rounded
                : Icons.receipt_long_rounded,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 5),
          // Bounded: the last message can be an entire item list, and this pill
          // sits inside an already-constrained column.
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w700,
              color: accent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
