
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/call_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/call_models.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallController _callController = getOrPut(() => CallController());
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  final RxBool _isLoading = true.obs;
  final RxList<CallModel> _calls = <CallModel>[].obs;
  final RxInt _selectedTabIndex = 0.obs;

  List<String> get _tabLabels => [
        AppStrings.all.tr,
        AppStrings.missed.tr,
        AppStrings.incoming.tr,
        AppStrings.outgoing.tr,
      ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _isLoading.value = true;
    final result =
        await _callController.fetchCallHistory(page: 1, limit: 20);
    debugPrint('[CALL_HISTORY_SCREEN] parsed ${result.length} calls');
    _calls.assignAll(result);
    _isLoading.value = false;
  }

  ChatList? _findChat(String conversationId) {
    final list = _chatViewController.getPersonalChatListModel?.value.chatList;
    if (list == null) return null;
    for (final c in list) {
      if (c?.conversationId == conversationId) return c;
    }
    return null;
  }

  bool _isMissed(CallModel c) =>
      c.status == 'missed' ||
      c.endReason == 'missed' ||
      c.status == 'declined' ||
      c.endReason == 'declined';

  bool _isOutgoing(CallModel c) => c.initiatedBy == userId;

  List<CallModel> _filteredFor(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _calls.where(_isMissed).toList();
      case 2:
        return _calls.where((c) => !_isOutgoing(c) && !_isMissed(c)).toList();
      case 3:
        return _calls.where((c) => _isOutgoing(c) && !_isMissed(c)).toList();
      default:
        return _calls.toList();
    }
  }

  String _dateHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final cd = DateTime(d.year, d.month, d.day);
    if (cd == today) return AppStrings.todayLabel.tr;
    if (cd == yesterday) return AppStrings.yesterdayLabel.tr;
    final diff = today.difference(cd).inDays;
    if (diff < 7) return AppStrings.earlierThisWeek.tr;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $ampm';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String? _otherUserIdFor(CallModel call, ChatList? chat) {
    if (call.participants != null) {
      for (final p in call.participants!) {
        if (p.userId != userId) return p.userId;
      }
    }
    return chat?.sender?.id;
  }

  /// Mirrors `_initiateCallFromChat` in component_widgets.dart:
  /// Android → launch CallActivity in a separate task (with in-app fallback).
  /// iOS → in-app call flow + navigate to /CallRoomScreen.
  Future<void> _placeCall(
      CallModel call, ChatList? chat, CallType type) async {
    final otherUserId = _otherUserIdFor(call, chat);
    if (otherUserId == null || otherUserId.isEmpty) return;
    final userName = chat?.sender?.name ?? AppStrings.userFallback.tr;
    final userImage = chat?.sender?.profileImage ?? '';
    final conversationId = call.conversationId;

    // Always place the call in-app (same activity) — no separate CallActivity.
    final success = await _callController.initiateCall(
      type: type,
      otherUserId: otherUserId,
      existingConversationId: conversationId,
      userName: userName,
      userImage: userImage,
    );
    if (success) {
      _refreshChatAfterOutgoingCall(conversationId);
      Get.toNamed('/CallRoomScreen');
    }
  }

  void _refreshChatAfterOutgoingCall(String? conversationId) {
    final id = conversationId ?? '';
    if (id.isEmpty) return;
    if (!Get.isRegistered<ChatViewController>()) return;
    final cvc = Get.find<ChatViewController>();
    void fetch() {
      cvc.emitEvent(ChatEmitEvents.messageReceived, {
        ApiKeys.conversation_id: id,
        ApiKeys.page: 1,
        ApiKeys.is_online_user: cvc.userOpenUserId.value,
        ApiKeys.per_page_message: 30,
      });
    }
    Future.delayed(const Duration(milliseconds: 500), fetch);
    Future.delayed(const Duration(milliseconds: 1500), fetch);
    Future.delayed(const Duration(milliseconds: 3000), fetch);
  }

  void _showCallPicker(CallModel call, ChatList? chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _callOptionTile(
                  icon: Icons.call,
                  iconColor: Colors.green,
                  title: AppStrings.voiceCall.tr,
                  subtitle: AppStrings.encryptedNoContactShare.tr,
                  onTap: () {
                    Navigator.pop(ctx);
                    _placeCall(call, chat, CallType.audio);
                  },
                ),
                const SizedBox(height: 10),
                _callOptionTile(
                  icon: Icons.videocam,
                  iconColor: Colors.blue,
                  title: AppStrings.videoCall.tr,
                  subtitle: AppStrings.encryptedVideoNoContactShare.tr,
                  onTap: () {
                    Navigator.pop(ctx);
                    _placeCall(call, chat, CallType.video);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _callOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xffF7F9FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    subtitle,
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Mirrors PersonalChatsList's sub-tab strip — same widget,
            // same paddings — so the Chat and Call tabs share a look.
            HorizontalTabSelector(
              horizontalMargin: 14,
              horizontalPadding: 10,
              tabs: _tabLabels,
              selectedIndex: _selectedTabIndex.value,
              onTabSelected: (index, val) {
                _selectedTabIndex.value = index;
              },
              labelBuilder: (value) => value,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabContent(_filteredFor(_selectedTabIndex.value)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabContent(List<CallModel> calls) {
    if (calls.isEmpty) return _emptyState();
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: _buildList(calls),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.phone_disabled,
                size: 36, color: AppColors.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: CustomText(
            AppStrings.noCallsYet.tr,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: CustomText(
            AppStrings.callHistoryWillAppearHere.tr,
            fontSize: 13,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<CallModel> calls) {
    final sorted = [...calls]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final grouped = <String, List<CallModel>>{};
    for (final c in sorted) {
      final h = _dateHeader(c.createdAt);
      grouped.putIfAbsent(h, () => []).add(c);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: CustomText(
              entry.key.toUpperCase(),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          ),
          ...entry.value.map(_buildCallCard),
        ];
      }).toList(),
    );
  }

  Widget _buildCallCard(CallModel call) {
    final chat = _findChat(call.conversationId);
    final missed = _isMissed(call);
    final outgoing = _isOutgoing(call);
    final isVideo = call.callType == 'video_call';
    final name = chat?.sender?.name ?? AppStrings.unknown.tr;
    final image = chat?.sender?.profileImage ?? '';
    final accent = missed ? AppColors.red : AppColors.green0B;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CachedAvatarWidget(
                imageUrl: image,
                size: 44,
                borderRadius: 22,
                showProfileOnFullScreen: false,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greyE5),
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam : Icons.call,
                    size: 10,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: missed ? AppColors.red : Colors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      missed
                          ? Icons.call_missed
                          : (outgoing
                              ? Icons.call_made
                              : Icons.call_received),
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    CustomText(
                      missed
                          ? AppStrings.missed.tr
                          : (outgoing ? AppStrings.outgoing.tr : AppStrings.incoming.tr),
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                    if (!missed && call.durationSeconds > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        _formatDuration(call.durationSeconds),
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                    const Spacer(),
                    CustomText(
                      _formatTime(call.startedAt??DateTime.now()),
                      fontSize: 11,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _callIconButton(
            icon: isVideo ? Icons.videocam : Icons.call,
            onTap: () => _showCallPicker(call, chat),
          ),
        ],
      ),
    );
  }

  Widget _callIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20),
      ),
    );
  }
}

