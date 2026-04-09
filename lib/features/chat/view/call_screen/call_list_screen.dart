import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── Dummy data for UI preview ───
class _DummyContact {
  final String name;
  final String phone;
  final String? imageUrl;
  final String status;
  _DummyContact({
    required this.name,
    required this.phone,
    this.imageUrl,
    this.status = 'Available',
  });
}

class _DummyCallLog {
  final String name;
  final String? imageUrl;
  final String time;
  final bool isOutgoing;
  final bool isMissed;
  final bool isVideo;
  final String duration;
  _DummyCallLog({
    required this.name,
    this.imageUrl,
    required this.time,
    required this.isOutgoing,
    this.isMissed = false,
    this.isVideo = false,
    this.duration = '',
  });
}

final List<_DummyContact> _dummyContacts = [
  _DummyContact(name: 'Rahul Sharma', phone: '+91 98765 43210', imageUrl: '', status: 'Hey there! I am using BlueEra'),
  _DummyContact(name: 'Priya Singh', phone: '+91 87654 32109', imageUrl: '', status: 'Busy'),
  _DummyContact(name: 'Amit Kumar', phone: '+91 76543 21098', status: 'At work'),
  _DummyContact(name: 'Sneha Patel', phone: '+91 65432 10987', status: 'Available'),
  _DummyContact(name: 'Vikram Reddy', phone: '+91 54321 09876', status: 'In a meeting'),
  _DummyContact(name: 'Ananya Gupta', phone: '+91 43210 98765', status: 'Available'),
  _DummyContact(name: 'Karthik Nair', phone: '+91 32109 87654'),
  _DummyContact(name: 'Divya Menon', phone: '+91 21098 76543', status: 'Urgent calls only'),
  _DummyContact(name: 'Rajesh Verma', phone: '+91 10987 65432'),
  _DummyContact(name: 'Meera Joshi', phone: '+91 99887 76655', status: 'Available'),
  _DummyContact(name: 'Arjun Das', phone: '+91 88776 65544'),
  _DummyContact(name: 'Pooja Iyer', phone: '+91 77665 54433', status: 'Do not disturb'),
];

final List<_DummyCallLog> _dummyCallLogs = [
  _DummyCallLog(name: 'Rahul Sharma', imageUrl: '', time: 'Today, 2:30 PM', isOutgoing: true, duration: '5:23', isVideo: false),
  _DummyCallLog(name: 'Priya Singh', imageUrl: '', time: 'Today, 1:15 PM', isOutgoing: false, isMissed: true),
  _DummyCallLog(name: 'Amit Kumar', time: 'Today, 11:42 AM', isOutgoing: false, duration: '12:45', isVideo: true),
  _DummyCallLog(name: 'Sneha Patel', time: 'Yesterday, 9:00 PM', isOutgoing: true, duration: '3:10'),
  _DummyCallLog(name: 'Vikram Reddy', time: 'Yesterday, 6:30 PM', isOutgoing: true, isMissed: true),
  _DummyCallLog(name: 'Ananya Gupta', time: 'Yesterday, 4:00 PM', isOutgoing: false, duration: '8:32', isVideo: true),
  _DummyCallLog(name: 'Karthik Nair', time: 'Mar 8, 3:20 PM', isOutgoing: true, duration: '1:05'),
  _DummyCallLog(name: 'Divya Menon', time: 'Mar 8, 10:15 AM', isOutgoing: false, isMissed: true, isVideo: true),
  _DummyCallLog(name: 'Rajesh Verma', time: 'Mar 7, 8:45 PM', isOutgoing: false, duration: '15:20'),
  _DummyCallLog(name: 'Meera Joshi', time: 'Mar 7, 2:00 PM', isOutgoing: true, duration: '7:55', isVideo: true),
];

// ─── Colors matching WhatsApp dark theme from call screens ───
const _kDarkBg = Color(0xFF0B141A);
const _kDarkCard = Color(0xFF1A2E35);
const _kGreen = Color(0xFF00A884);
const _kRed = Color(0xFFEA4335);
const _kSubtext = Color(0xFF8696A0);
const _kDivider = Color(0xFF1F2C34);
const _kSearchBg = Color(0xFF1F2C34);

class CallListScreen extends StatefulWidget {
  const CallListScreen({super.key});

  @override
  State<CallListScreen> createState() => _CallListScreenState();
}

class _CallListScreenState extends State<CallListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (!Get.isRegistered<ChatViewController>()) {
      Get.put(ChatViewController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Real contact fetching (used when real data is available) ───
  List<ChatList> _getRealContacts() {
    final chatController = Get.find<ChatViewController>();
    final List<ChatList> allContacts = [];

    final personalChats =
        chatController.getPersonalChatListModel?.value.chatList;
    if (personalChats != null) {
      for (final chat in personalChats) {
        if (chat != null && chat.isGroup != true && chat.sender != null) {
          allContacts.add(chat);
        }
      }
    }

    final businessChats =
        chatController.getBusinessChatListModel?.value.chatList;
    if (businessChats != null) {
      for (final chat in businessChats) {
        if (chat != null && chat.isGroup != true && chat.sender != null) {
          allContacts.add(chat);
        }
      }
    }

    final seen = <String>{};
    final unique = <ChatList>[];
    for (final chat in allContacts) {
      final senderId = chat.sender?.id ?? '';
      if (senderId.isNotEmpty && seen.add(senderId)) {
        unique.add(chat);
      }
    }

    final query = _searchQuery.value.toLowerCase();
    if (query.isEmpty) return unique;
    return unique
        .where((c) =>
            (c.sender?.name?.toLowerCase().contains(query) ?? false) ||
            (c.sender?.contactNo?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  List<_DummyContact> _getFilteredDummyContacts() {
    final query = _searchQuery.value.toLowerCase();
    if (query.isEmpty) return _dummyContacts;
    return _dummyContacts
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query))
        .toList();
  }

  void _initiateCallFromChat(ChatList chat, CallType type) {
    final callController = Get.find<CallController>();
    final sender = chat.sender!;
    callController.initiateCall(
      type: type,
      otherUserId: sender.id,
      existingConversationId: chat.conversationId,
      userName: sender.name ?? 'Unknown',
      userImage: sender.profileImage ?? '',
    );
    Get.toNamed('/CallRoomScreen');
  }

  void _initiateCallFromDummy(_DummyContact contact, CallType type) {
    // For dummy data — initiate call with dummy info
    // In production this uses real ChatList data via _initiateCallFromChat
    final callController = Get.find<CallController>();
    callController.initiateCall(
      type: type,
      userName: contact.name,
      userImage: contact.imageUrl ?? '',
    );
    Get.toNamed('/CallRoomScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsTab(),
          _buildCallHistoryTab(),
        ],
      ),
      // FAB to start a new call
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kGreen,
        onPressed: () {
          // Switch to contacts tab & focus search
          _tabController.animateTo(0);
          Future.delayed(const Duration(milliseconds: 300), () {
            FocusScope.of(context).requestFocus(FocusNode());
          });
        },
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kDarkCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: CustomText(
        AppStrings.callsTab.tr,
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'OpenSans',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
          onPressed: () {
            _tabController.animateTo(0);
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: _kGreen,
        unselectedLabelColor: _kSubtext,
        indicatorColor: _kGreen,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: 'OpenSans',
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          fontFamily: 'OpenSans',
        ),
        tabs: [
          Tab(text: AppStrings.contactsTab.tr),
          Tab(text: AppStrings.recentTab.tr),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CONTACTS TAB
  // ════════════════════════════════════════════════════════════
  Widget _buildContactsTab() {
    return Column(
      children: [
        // Search bar
        Container(
          color: _kDarkBg,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _searchQuery.value = val,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: _kGreen,
            decoration: InputDecoration(
              hintText: AppStrings.searchNameOrNumber.tr,
              hintStyle: const TextStyle(color: _kSubtext, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: _kSubtext, size: 20),
              suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: _kSubtext),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery.value = '';
                      },
                    )
                  : const SizedBox.shrink()),
              filled: true,
              fillColor: _kSearchBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Contact list
        Expanded(
          child: Obx(() {
            _searchQuery.value; // trigger rebuild

            // Try real data first, fallback to dummy
            final realContacts = _getRealContacts();
            final useDummy = realContacts.isEmpty;
            final dummyContacts = _getFilteredDummyContacts();

            if (useDummy && dummyContacts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.people_outline_rounded,
                title: AppStrings.noContactsFound.tr,
              );
            }

            if (!useDummy && realContacts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.people_outline_rounded,
                title: _searchQuery.value.isNotEmpty
                    ? AppStrings.noContactsFound.tr
                    : AppStrings.noContactsYet.tr,
                subtitle: _searchQuery.value.isEmpty
                    ? AppStrings.startChattingToSee.tr
                    : null,
              );
            }

            final itemCount = useDummy ? dummyContacts.length : realContacts.length;

            return ListView.separated(
              itemCount: itemCount,
              padding: const EdgeInsets.only(top: 4, bottom: 80),
              separatorBuilder: (_, __) => const Divider(
                color: _kDivider,
                height: 1,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                if (useDummy) {
                  return _buildDummyContactTile(dummyContacts[index]);
                } else {
                  return _buildRealContactTile(realContacts[index]);
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDummyContactTile(_DummyContact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(name: contact.name, imageUrl: contact.imageUrl),
          const SizedBox(width: 14),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: 'OpenSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  contact.status,
                  style: const TextStyle(color: _kSubtext, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Audio call
          _buildCallIconButton(
            icon: Icons.call_rounded,
            onTap: () => _initiateCallFromDummy(contact, CallType.audio),
          ),
          const SizedBox(width: 4),
          // Video call
          _buildCallIconButton(
            icon: Icons.videocam_rounded,
            onTap: () => _initiateCallFromDummy(contact, CallType.video),
          ),
        ],
      ),
    );
  }

  Widget _buildRealContactTile(ChatList chat) {
    final sender = chat.sender!;
    final name = sender.name ?? 'Unknown';
    final image = sender.profileImage ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _buildAvatar(name: name, imageUrl: image.isNotEmpty ? image : null),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: 'OpenSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sender.contactNo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sender.contactNo!,
                    style: const TextStyle(color: _kSubtext, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCallIconButton(
            icon: Icons.call_rounded,
            onTap: () => _initiateCallFromChat(chat, CallType.audio),
          ),
          const SizedBox(width: 4),
          _buildCallIconButton(
            icon: Icons.videocam_rounded,
            onTap: () => _initiateCallFromChat(chat, CallType.video),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  CALL HISTORY TAB (Recent)
  // ════════════════════════════════════════════════════════════
  Widget _buildCallHistoryTab() {
    // Show dummy call logs for UI preview
    // When real API data arrives, this can switch to FutureBuilder
    return ListView.separated(
      itemCount: _dummyCallLogs.length,
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      separatorBuilder: (_, __) => const Divider(
        color: _kDivider,
        height: 1,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        return _buildCallLogTile(_dummyCallLogs[index]);
      },
    );
  }

  Widget _buildCallLogTile(_DummyCallLog log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(name: log.name, imageUrl: log.imageUrl),
          const SizedBox(width: 14),
          // Name + call info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.name,
                  style: TextStyle(
                    color: log.isMissed ? _kRed : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: 'OpenSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // Direction arrow
                    Icon(
                      log.isOutgoing
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      size: 14,
                      color: log.isMissed ? _kRed : _kGreen,
                    ),
                    const SizedBox(width: 4),
                    // Time
                    Expanded(
                      child: Text(
                        log.isMissed
                            ? '${log.time} - Missed'
                            : '${log.time}${log.duration.isNotEmpty ? ' (${log.duration})' : ''}',
                        style: const TextStyle(color: _kSubtext, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Call type icon (re-call)
          _buildCallIconButton(
            icon: log.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            onTap: () {
              // Re-call: uses real flow when available
              // For dummy, show outgoing call screen
              final contact = _dummyContacts.firstWhere(
                (c) => c.name == log.name,
                orElse: () => _DummyContact(name: log.name, phone: ''),
              );
              _initiateCallFromDummy(
                contact,
                log.isVideo ? CallType.video : CallType.audio,
              );
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ════════════════════════════════════════════════════════════
  Widget _buildAvatar({required String name, String? imageUrl}) {
    // Generate a consistent color from name
    final colors = [
      const Color(0xFF6B5CE7),
      const Color(0xFF00A884),
      const Color(0xFFE74C5C),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    final colorIndex = name.codeUnits.fold<int>(0, (a, b) => a + b) % colors.length;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[colorIndex].withValues(alpha: 0.2),
        image: imageUrl != null && imageUrl.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null || imageUrl.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: colors[colorIndex],
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  fontFamily: 'OpenSans',
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCallIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: _kGreen, size: 22),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _kSubtext.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          CustomText(
            title,
            color: _kSubtext,
            fontSize: 15,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CustomText(
                subtitle,
                color: _kSubtext.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}
