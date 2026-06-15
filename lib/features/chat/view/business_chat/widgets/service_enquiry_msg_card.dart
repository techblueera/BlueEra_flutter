import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/service_enquiry_model.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// In-chat card for a `messageType: "service_enquiry"` message — the Discover
/// self-profession counterpart of [SelfPickupMsgCard]. Compact layout: a slim
/// header, divider-separated sections (photo / selections / note), and an
/// accept-decline or status footer. The provider (receiver) can Accept /
/// Decline while pending; the customer (sender) sees a waiting/decision state.
class ServiceEnquiryMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final String? conversationId;

  const ServiceEnquiryMsgCard({
    super.key,
    required this.message,
    required this.time,
    this.conversationId,
  });

  @override
  State<ServiceEnquiryMsgCard> createState() => _ServiceEnquiryMsgCardState();
}

class _ServiceEnquiryMsgCardState extends State<ServiceEnquiryMsgCard> {
  bool _isUpdating = false;

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);

  bool get _isMyMessage => widget.message.myMessage ?? false;

  String get _status =>
      (widget.message.metadata?.serviceEnquiry?.status ?? 'pending')
          .toLowerCase();

  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';

  ServiceEnquiryModel? get _enquiry => widget.message.metadata?.serviceEnquiry;

  /// Non-empty selection groups, in display order.
  List<MapEntry<String, List<String>>> get _groups {
    final e = _enquiry;
    final out = <MapEntry<String, List<String>>>[];
    void add(String title, List<String>? items) {
      final list =
          (items ?? const <String>[]).where((s) => s.trim().isNotEmpty).toList();
      if (list.isNotEmpty) out.add(MapEntry(title, list));
    }

    add(AppStrings.serviceType.tr, e?.serviceType);
    add(AppStrings.typeOfWork.tr, e?.typesOfWork);
    add(AppStrings.workCategories.tr, e?.workCategories);
    add(AppStrings.servicesOffered.tr, e?.servicesOffered);
    add(AppStrings.requestType.tr, e?.requestType);
    return out;
  }

  int get _totalCount => _enquiry?.allSelections.length ?? 0;

  List<String> get _photos => _enquiry?.photos ?? const [];

  String get _note => _enquiry?.note ?? '';

  String get _subtitle {
    final parts = <String>[];
    if (_totalCount > 0) {
      parts.add(
          '$_totalCount ${_totalCount == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}');
    }
    if (_photos.isNotEmpty) {
      parts.add(
          '${_photos.length} ${_photos.length == 1 ? AppStrings.photoLabel.tr : AppStrings.photosLabel.tr}');
    }
    return parts.isEmpty ? AppStrings.customRequest.tr : parts.join(' · ');
  }

  Future<void> _updateStatus(String status) async {
    final enquiryId = widget.message.metadata?.serviceEnquiry?.enquiryId ??
        widget.message.metadata?.serviceEnquiryId ??
        '';
    if (enquiryId.isEmpty) return;

    setState(() => _isUpdating = true);
    final controller = getOrPut(() => DiscoverController());
    final ok = await controller.updateServiceEnquiryStatus(
      enquiryId: enquiryId,
      status: status,
    );
    if (ok) {
      widget.message.metadata?.serviceEnquiry?.status = status;
    }
    if (mounted) setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F001120), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (_photos.isNotEmpty) ...[_divider(), _photoSection()],
          if (_groups.isNotEmpty) ...[_divider(), _groupsSection()],
          if (_note.trim().isNotEmpty) ...[_divider(), _noteSection()],
          _divider(),
          _buildActionSection(),
          Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 6, top: 1),
            child: Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                widget.time,
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _line);

  // ── Slim header — small tinted icon + title/subtitle + status pill ──
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.handyman_rounded, color: _accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.serviceEnquiry.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                CustomText(
                  _subtitle,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  // ── Full-width photo(s) — compact strip ─────────────────────────────
  Widget _photoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          for (int i = 0; i < _photos.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 130,
                child: CachedNetworkImage(
                  imageUrl: _photos[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.whiteE5),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.whiteE5,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Grouped selections — eyebrow label + chips ──────────────────────
  Widget _groupsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int g = 0; g < _groups.length; g++) ...[
            if (g > 0) const SizedBox(height: 8),
            _eyebrow(_groups[g].key),
            const SizedBox(height: 5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _groups[g].value.map(_chip).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Note — eyebrow label + text ─────────────────────────────────────
  Widget _noteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(AppStrings.noteLabel.tr),
          const SizedBox(height: 4),
          CustomText(
            _note,
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor,
            height: 1.35,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  // ── Action / status section ─────────────────────────────────────────
  Widget _buildActionSection() {
    // Resolved (accepted / declined) — show the outcome to both sides.
    if (_isAccepted || _isDeclined) {
      final accepted = _isAccepted;
      final Color c = accepted ? Colors.green : Colors.red;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(accepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: c, size: 16),
            const SizedBox(width: 6),
            CustomText(
              accepted ? AppStrings.enquiryAccepted.tr : AppStrings.enquiryDeclined.tr,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ],
        ),
      );
    }

    // Pending. Provider (receiver) gets Accept / Decline; customer waits.
    if (!_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: _isUpdating
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                ),
              )
            : Row(
                children: [
                  Expanded(child: _declineBtn()),
                  const SizedBox(width: 8),
                  Expanded(child: _acceptBtn()),
                ],
              ),
      );
    }

    // Customer side (my message): waiting for the provider's response.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          const SizedBox(width: 7),
          CustomText(
            AppStrings.waitingForResponse.tr,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _acceptBtn() {
    return InkWell(
      onTap: () => _updateStatus('accepted'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentDeep, _accent]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(AppStrings.acceptLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _declineBtn() {
    return InkWell(
      onTap: () => _updateStatus('declined'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.red.withValues(alpha: 0.55), width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close_rounded, size: 15, color: Colors.red),
            const SizedBox(width: 5),
            Text(AppStrings.declineLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.20), width: 0.8),
      ),
      child: CustomText(
        label,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: _accent,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (String label, Color color) = _isAccepted
        ? (AppStrings.acceptedStatus.tr, Colors.green)
        : _isDeclined
            ? (AppStrings.declinedStatus.tr, Colors.red)
            : (AppStrings.pendingStatus.tr, Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
