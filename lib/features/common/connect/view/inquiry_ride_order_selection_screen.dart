import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetChatListModel.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'multi_pickup_rider_booking_screen.dart';

/// Step shown after the rider drop-location sheet is confirmed (Inquiry tab).
///
/// Lists the inquiry (business) conversations whose last message landed within
/// the last 12 hours — i.e. the still-active orders — and lets the user
/// multi-select which of them should be picked up. The Submit button just opens
/// the [MultiPickupRiderBookingScreen]; no API call is made here.
class InquiryRideOrderSelectionScreen extends StatefulWidget {
  const InquiryRideOrderSelectionScreen({
    super.key,
    required this.dropAddress,
  });

  /// The drop location chosen in the preceding bottom sheet.
  final SavedAddress dropAddress;

  @override
  State<InquiryRideOrderSelectionScreen> createState() =>
      _InquiryRideOrderSelectionScreenState();
}

class _InquiryRideOrderSelectionScreenState
    extends State<InquiryRideOrderSelectionScreen> {
  final chatViewController = Get.find<ChatViewController>();

  /// Conversation ids the user has ticked.
  final Set<String> _selectedIds = {};

  /// Inquiry chats whose last message is within the last 12 hours, newest
  /// first. Mirrors the Inquiry-tab routing (`bucketChat == chats`).
  List<ChatList> get _recentInquiries {
    final all = chatViewController.getBusinessChatListModel?.value.chatList ?? [];
    final cutoff = DateTime.now().subtract(const Duration(hours: 12));
    final result = <ChatList>[];
    for (final c in all) {
      if (c == null) continue;
      if (bucketChat(c) != ChatBucket.chats) continue;
      final raw = (c.updatedAt?.isNotEmpty ?? false) ? c.updatedAt : c.createdAt;
      if (raw == null || raw.isEmpty) continue;
      DateTime dt;
      try {
        dt = DateTime.parse(raw).toLocal();
      } catch (_) {
        continue;
      }
      if (dt.isAfter(cutoff)) result.add(c);
    }
    result.sort((a, b) => (b.updatedAt ?? '').compareTo(a.updatedAt ?? ''));
    return result;
  }

  void _toggle(String? id) {
    if (id == null || id.isEmpty) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _onSubmit(List<ChatList> inquiries) {
    final selected = inquiries
        .where((c) => _selectedIds.contains(c.conversationId))
        .toList();
    if (selected.isEmpty) return;
    Get.to(() => MultiPickupRiderBookingScreen(
          pickups: selected,
          dropAddress: widget.dropAddress,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = _recentInquiries;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: 'Select Orders to Pick Up'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: CustomBtn(
            height: 44,
            isValidate: _selectedIds.isNotEmpty,
            onTap: () => _onSubmit(inquiries),
            title:
                'Submit${_selectedIds.isEmpty ? '' : ' (${_selectedIds.length})'}',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drop-location summary banner.
            _buildDropBanner(),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: CustomText(
                'Active inquiries (last 12 hours)',
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ),

            Expanded(
              child: inquiries.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      itemCount: inquiries.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFE5E5E5)),
                      itemBuilder: (context, index) =>
                          _inquiryRow(inquiries[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.red00, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Drop location',
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  widget.dropAddress.fullAddress.isNotEmpty
                      ? widget.dropAddress.fullAddress
                      : widget.dropAddress.label,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inquiryRow(ChatList chat) {
    final id = chat.conversationId ?? '';
    final isSelected = _selectedIds.contains(id);
    final name = chat.sender?.name ?? 'Unknown';
    final image = chat.sender?.profileImage ?? '';

    return InkWell(
      onTap: () => _toggle(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 10),
            CachedAvatarWidget(
              imageUrl: image,
              size: 46,
              borderRadius: 23,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          name,
                          fontSize: SizeConfig.size14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        _timeAgo(chat.updatedAt ?? chat.createdAt),
                        fontSize: SizeConfig.size10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _orderTypeChip(chat.lastMessageType),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          _lastMessagePreview(chat),
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeChip(String? type) {
    final label = _orderTypeLabel(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.size10,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            CustomText(
              'No active inquiries in the last 12 hours',
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _lastMessagePreview(ChatList chat) {
    final msg = chat.lastMessage ?? '';
    if (msg.isNotEmpty) return msg;
    return _orderTypeLabel(chat.lastMessageType) == 'Inquiry'
        ? 'New message'
        : '${_orderTypeLabel(chat.lastMessageType)} order';
  }

  String _orderTypeLabel(String? type) {
    switch (type) {
      case 'food_selfpickup':
        return 'Food';
      case 'product_selfpickup':
        return 'Product';
      case 'selfpickup':
        return 'Grocery';
      case 'order_request':
      case 'rider':
      case 'rider_map':
      case 'rider_association':
        return 'Order';
      default:
        return 'Inquiry';
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    DateTime dt;
    try {
      dt = DateTime.parse(raw).toLocal();
    } catch (_) {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }
}
