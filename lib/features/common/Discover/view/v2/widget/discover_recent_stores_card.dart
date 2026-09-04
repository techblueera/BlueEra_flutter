import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/Discover/controller/nearby_stores_controller.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_sections_models.dart';
import 'package:BlueEra/features/common/Discover/view/near_you_all_screen.dart';
import 'package:BlueEra/features/common/Discover/view/v2/widget/discover_v2_section_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Store logo, as drawn: 44x44.
const double _kRowAvatar = 44;

/// "Recent Visited Stores" — the flat row list in the v2 design.
///
/// **Two sources, in priority order.**
///
///  1. `recent_visited` from the nearby-discover endpoint: a genuine visit
///     history, server-ranked by how often and how recently this user opened
///     each store. Rows carry the shop's logo, its category and its distance.
///  2. The business chat list, which is what v1's [RecentOrdersSection] drew:
///     orders received and inquiries placed in the last 12 hours.
///
/// The fallback is the point. The API section is empty for anyone the backend
/// has no visit history for — a new account, or a deployment where the section
/// is not populated yet — and without it the card simply vanished from the
/// page, which is what the previous Discover would still have shown something
/// for. Keeping v1's source underneath means the section behaves at least as
/// well as the page it replaces, and quietly upgrades itself the moment real
/// visit history arrives.
///
/// The two are never mixed: a user with visit history sees only that, so the
/// list cannot show the same shop twice under two different subtitles.
class DiscoverRecentStoresCard extends StatelessWidget {
  const DiscoverRecentStoresCard({
    super.key,
    this.maxRows = 5,
    this.bottomGap = 0,
  });

  /// Rows before the card defers to "View All". The design draws five.
  final int maxRows;

  /// Separation from whatever follows, applied ONLY when this card actually
  /// renders. The caller cannot supply it: whether there is anything to show
  /// is decided inside the [Obx] below, so a gap added from outside would
  /// still be there on a page with no history and no orders.
  final double bottomGap;

  /// Window for the chat-list fallback, matching v1.
  static const Duration _window = Duration(hours: 12);

  @override
  Widget build(BuildContext context) {
    final nearby = getOrPut(() => NearbyStoresController());

    return Obx(() {
      final rows = _rows(nearby);
      if (rows.isEmpty) return const SizedBox.shrink();
      final shown = rows.take(maxRows).toList();

      return Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: DiscoverV2Card(
          // The server's own heading when it sent one, so a backend rename
          // reaches the UI without a release.
          title: nearby.recentTitle.value,
          trailingLabel: 'View All',
          onTrailingTap: shown.first.onViewAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i != 0)
                  const Divider(
                      height: 18, thickness: 1, color: Color(0xFFEEF2F8)),
                _StoreRow(row: shown[i]),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// Visit history if there is any, else the last 12 hours of order threads.
  ///
  /// Both observables are read on EVERY pass, before either is returned on.
  /// An `Obx` only subscribes to what it actually touches, so an early return
  /// on the API list would leave the chat list unwatched and the fallback
  /// would never repaint when a socket push lands.
  List<_RowData> _rows(NearbyStoresController nearby) {
    final visited = nearby.recentVisited.toList();
    final chatRows = _chatRows();
    if (visited.isNotEmpty) {
      return visited.map(_RowData.fromVisited).toList();
    }
    return chatRows;
  }

  List<_RowData> _chatRows() {
    // Registered by the bottom-nav shell that hosts Discover, so it is always
    // present here; guarded anyway rather than building the chat stack from a
    // Discover render.
    if (!Get.isRegistered<ChatViewController>()) return const [];
    final chat = Get.find<ChatViewController>();
    final all = chat.getBusinessChatListModel?.value.chatList;
    final received = recentReceivedOrderChats(all, window: _window);
    final placed = recentInquiryChats(all, window: _window);
    if (received.isEmpty && placed.isEmpty) return const [];

    return <_RowData>[
      ...received.map((c) => _RowData.fromChat(c, 0)),
      ...placed.map((c) => _RowData.fromChat(c, 1)),
    ]..sort((a, b) {
        final at = a.at, bt = b.at;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });
  }
}

/// One row, from either source. Flattened so the row widget never has to know
/// which list it came from.
class _RowData {
  const _RowData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.at,
    required this.distanceKm,
    required this.onTap,
    required this.onViewAll,
  });

  final String image;
  final String title;
  final String subtitle;

  /// When it happened — last opened, or the thread's last movement.
  final DateTime? at;

  /// Kilometres, or 0 when the source does not know. Drives the trailing pill.
  final double distanceKm;

  final VoidCallback onTap;

  /// Where the card's "View All" goes, which differs by source: visit history
  /// belongs to the nearby list, order threads to the Connect lane they came
  /// from.
  final VoidCallback onViewAll;

  factory _RowData.fromVisited(NearbyVisitedStore s) => _RowData(
        image: s.logo,
        title: s.businessName,
        subtitle: s.categoryName,
        at: s.lastClickedAt,
        distanceKm: s.distance,
        onTap: () {
          if (s.id.isEmpty) return;
          // `typeOfBusiness` is deliberately NOT passed: the payload carries
          // none, and openVisitProfile resolves the right screen from the
          // profile it loads. Guessing would route a Food shop to Grocery.
          openVisitProfile(
            accountType: AppConstants.business,
            businessId: s.id,
            categoryOfBusiness: s.categoryName,
          );
        },
        onViewAll: () => Get.to(() => const NearYouAllScreen()),
      );

  factory _RowData.fromChat(ChatList chat, int lane) {
    // Identity resolution mirrors [ChatListTile] and v1's order card: an order
    // thread is carried as a GROUP-shaped row, so the counterpart is
    // `group_name` / `group_profile_image`, not the embedded sender.
    final isGroupish =
        chat.type == AppConstants.group_Chat_Type || chat.isGroup == true;
    final name = isGroupish ? chat.groupName : chat.sender?.name;
    final image =
        isGroupish ? chat.groupProfileImage : chat.sender?.profileImage;

    return _RowData(
      image: image ?? '',
      title: (name?.isNotEmpty ?? false)
          ? name!
          : (lane == 0 ? 'Customer' : 'Shop'),
      // The order's line items, which is what the last message on an order
      // thread carries.
      subtitle: chat.lastMessage ?? '',
      at: _stamp(chat),
      distanceKm: 0,
      onTap: () => _openThread(chat, lane),
      onViewAll: () => _openConnectLane(lane),
    );
  }

  static DateTime? _stamp(ChatList c) {
    final raw = (c.updatedAt?.isNotEmpty ?? false) ? c.updatedAt : c.createdAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.row});

  final _RowData row;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: row.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CachedAvatarWidget(
            imageUrl: row.image.isEmpty ? null : row.image,
            // 44x44 as drawn; the radius is half of it, so the logo stays a
            // circle rather than a rounded square.
            size: _kRowAvatar,
            borderRadius: _kRowAvatar / 2,
            showProfileOnFullScreen: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  row.title,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                CustomText(
                  row.subtitle,
                  fontSize: 11.5,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                _timeLabel(),
                fontSize: 10.5,
                color: AppColors.secondaryTextColor,
              ),
              if (row.distanceKm > 0) ...[
                const SizedBox(height: 5),
                _DistancePill(km: row.distanceKm),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Clock time for something from today, a date for anything older — "9:52 PM"
  /// on a row from last week says nothing useful.
  String _timeLabel() {
    final at = row.at;
    if (at == null) return '';
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return DateFormat(sameDay ? 'h:mm a' : 'd MMM').format(at);
  }
}

/// How far the store is. Only the visit-history source knows this; order
/// threads carry no distance, so their rows simply show the time.
class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.km});

  final double km;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        km < 1
            ? '${(km * 1000).round()} m'
            : (km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km'),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
        height: 1.3,
      ),
    );
  }
}

/// Open the order's conversation. Mirrors v1's `_OrderCard._openThread` so the
/// two cannot drift on where a tap lands.
void _openThread(ChatList chat, int lane) {
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
    type: chat.sender?.accountType ?? AppConstants.business,
    contactName: chat.sender?.name,
    contactNo: chat.sender?.contactNo,
    profileImage: chat.sender?.profileImage,
  );
}

/// Bottom-nav index of the Connect tab (0=Me, 1=Discover, 2=Connect, 3=Reels).
const int _kConnectTabIndex = 2;

/// Which Connect sub-tab holds [lane]. Mirrors v1's `_connectSubTabFor` — the
/// orders sub-tab only exists for accounts that can receive orders, so lane 0
/// falls back to the first tab when it is absent.
int _connectSubTabFor(int lane) {
  if (lane == 1) return 1;
  return showsConnectOrderTab() ? 2 : 0;
}

/// Open Connect on the sub-tab holding [lane]. The index is handed over through
/// [ChatViewController.onSelectChatTab], which `ConnectMainPage.initState`
/// consumes as its initial tab — so the bottom-nav switch has to happen too, or
/// the sub-tab is set on a screen that never comes forward.
void _openConnectLane(int lane) {
  if (Get.isRegistered<ChatViewController>()) {
    Get.find<ChatViewController>().onSelectChatTab(_connectSubTabFor(lane));
  }
  getOrPut(() => BottomBarController()).currentIndex.value = _kConnectTabIndex;
}
