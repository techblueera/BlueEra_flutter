import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_booking_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for `message_type: "vehicle_booking"`.
///
/// Visually mirrors [ServiceEnquiryMsgCard]: a slim header, divider-separated
/// sections (photo / selections / note), and an accept-decline / cancel /
/// status footer. Vehicle-specific behaviour lives in the sections (Intent /
/// Offer / Condition) and in the buyer-side Cancel button, which the other
/// enquiry cards don't have.
class VehicleBookingMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const VehicleBookingMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<VehicleBookingMsgCard> createState() => _VehicleBookingMsgCardState();
}

class _VehicleBookingMsgCardState extends State<VehicleBookingMsgCard> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);

  bool _isUpdating = false;

  VehicleBooking? get _b => widget.message.metadata?.booking;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  VehicleBookingStatus get _status =>
      _b?.status ?? VehicleBookingStatus.pending;
  bool get _isAccepted => _status == VehicleBookingStatus.accepted;
  bool get _isDeclined => _status == VehicleBookingStatus.declined;
  bool get _isCancelled => _status == VehicleBookingStatus.cancelled;
  bool get _isPending => _status == VehicleBookingStatus.pending;

  /// Vehicle-specific detail sections (Intent / Offer / Condition) mapped
  /// into the same `{title: [items]}` shape the reference iterates over,
  /// so the shared render code stays uniform.
  Map<String, List<String>> get _selections {
    final out = <String, List<String>>{};
    final intent = (_b?.intent.label ?? '').trim();
    if (intent.isNotEmpty) out['Intent'] = [intent];
    final offer = _b?.offerPrice;
    if (offer != null) {
      out['Offer'] = ['₹${offer.toStringAsFixed(0)}'];
    }
    final condition = (_b?.snapshot?.condition ?? '').trim();
    if (condition.isNotEmpty) out['Condition'] = [condition];
    return out;
  }

  /// Icon + tint per section — matches reference row style (38x38 badge).
  (IconData, Color) _iconAndColorFor(String title) {
    switch (title.toLowerCase()) {
      case 'intent':
        return (Icons.assignment_rounded, const Color(0xFF3B82F6));
      case 'offer':
        return (Icons.currency_rupee_rounded, const Color(0xFF22C55E));
      case 'condition':
        return (Icons.verified_rounded, const Color(0xFF8B5CF6));
      default:
        return (Icons.check_rounded, _accent);
    }
  }

  /// Booking id lives in one of three places depending on which
  /// backend surface produced the message:
  ///   1. `metadata.booking._id` — parsed into [VehicleBooking.id]
  ///   2. `metadata.vehicleBookingId` — top-level shortcut
  ///   3. `metadata._id` — some socket payloads flatten it here
  ///
  /// The old `_b?.id ?? metadata.vehicleBookingId` guard was subtly
  /// broken: [VehicleBooking.fromJson] fills `id: ''` when neither
  /// `_id` nor `id` is present, so `_b?.id` returned an empty *string*
  /// (not null) and `??` never fell through to the shortcut field.
  /// Use `_firstNonEmpty` so any non-empty candidate wins.
  String _resolveBookingId() {
    return _firstNonEmpty([
      _b?.id,
      widget.message.metadata?.vehicleBookingId,
    ]);
  }

  String _firstNonEmpty(List<String?> candidates) {
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return '';
  }

  Future<void> _updateStatus({required bool cancel, bool accept = false}) async {
    final id = _resolveBookingId();
    log('[VEHICLE BOOKING] action=${cancel ? "cancel" : (accept ? "accept" : "decline")} '
        'resolvedId=$id booking._id=${_b?.id} '
        'vehicleBookingId=${widget.message.metadata?.vehicleBookingId}');
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => VehicleController(), permanent: true);
    final ok = cancel
        ? await controller.cancelBooking(id)
        : await controller.respondToBooking(id: id, accept: accept);
    if (!mounted) return;
    if (ok) {
      widget.message.metadata?.booking?.status = cancel
          ? VehicleBookingStatus.cancelled
          : (accept
              ? VehicleBookingStatus.accepted
              : VehicleBookingStatus.declined);
    }
    setState(() => _isUpdating = false);
  }

  // ── Derived pieces used by header/subtitle/photos ───────────────────
  String get _coverImage => (_b?.snapshot?.image ?? '').trim();
  List<String> get _photos => _b?.photos ?? const <String>[];
  String get _note => (_b?.note ?? '').trim();

  /// Header subtitle: snapshot title if present, else "N items · M photos".
  String get _subtitle {
    final title = (_b?.snapshot?.title ?? '').trim();
    if (title.isNotEmpty) return title;
    final parts = <String>[];
    final count = _selections.length;
    if (count > 0) {
      parts.add(
          '$count ${count == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}');
    }
    final photoCount =
        _photos.length + (_coverImage.isNotEmpty ? 1 : 0);
    if (photoCount > 0) {
      parts.add(
          '$photoCount ${photoCount == 1 ? AppStrings.photoLabel.tr : AppStrings.photosLabel.tr}');
    }
    return parts.isEmpty ? AppStrings.customRequest.tr : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = _coverImage.isNotEmpty;
    final hasPhotos = _photos.isNotEmpty;
    final rows = _selections.entries.toList();

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (hasCover) ...[_divider(), _photoBlock(_coverImage)],
          if (hasPhotos) ...[
            for (final url in _photos) ...[_divider(), _photoBlock(url)],
          ],
          for (final entry in rows) ...[_divider(), _enquiryRow(entry)],
          if (_note.isNotEmpty) ...[_divider(), _noteSection()],
          _divider(),
          _footer(),
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
            child: const Icon(Icons.directions_car_filled_rounded,
                color: _accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.vehicleBookingTitle.tr,
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

  // ── One full-width photo block (130 high, radius 10) ────────────────
  Widget _photoBlock(String url) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: double.infinity,
          height: 130,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.whiteE5),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.whiteE5,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined,
                  size: 20, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  // ── One enquiry row — tinted icon badge + eyebrow + value ──────────
  // Vehicle sections always carry a single value, so we use the plain
  // (non-bullet) renderer from the reference card.
  Widget _enquiryRow(MapEntry<String, List<String>> entry) {
    final (icon, color) = _iconAndColorFor(entry.key);
    final value = entry.value.isNotEmpty ? entry.value.first : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(entry.key),
                const SizedBox(height: 3),
                CustomText(
                  value,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  height: 1.3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Note — tinted icon badge + eyebrow + text (row style) ───────────
  Widget _noteSection() {
    const color = Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.sticky_note_2_outlined,
                color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(AppStrings.noteLabel.tr),
                const SizedBox(height: 3),
                CustomText(
                  _note,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                  height: 1.35,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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

  // ── Footer — status band (accepted / declined / cancelled) or, while
  // pending: seller sees Accept / Decline, buyer sees a waiting sub-band
  // above a Cancel button. ─────────────────────────────────────────────
  Widget _footer() {
    if (_isAccepted) {
      return _statusBand(
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        label: AppStrings.enquiryAccepted.tr,
      );
    }
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: Colors.red,
        label: AppStrings.enquiryDeclined.tr,
      );
    }
    if (_isCancelled) {
      return _statusBand(
        icon: Icons.block_rounded,
        color: AppColors.secondaryTextColor,
        label: AppStrings.bookingStatusCancelled.tr,
      );
    }

    // Pending — seller (receiver) gets Accept / Decline + timestamp.
    if (_isPending && !_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isUpdating
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
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                widget.time,
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      );
    }

    // Pending — buyer (sender) sees waiting sub-band + Cancel button.
    if (_isPending && _isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _inlineWaitingBand(),
            const SizedBox(height: 8),
            _isUpdating
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accent),
                    ),
                  )
                : _cancelBtn(),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                widget.time,
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback — treat as generic waiting state.
    return _statusBand(
      icon: Icons.access_time_rounded,
      color: Colors.orange,
      label: AppStrings.waitingForResponse.tr,
    );
  }

  // Small tinted waiting strip shown above the buyer's Cancel button.
  Widget _inlineWaitingBand() {
    const color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              AppStrings.waitingForResponse.tr,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Full-width tinted band: status icon + label, with the message time on
  // the right (matches the reference card's footer).
  Widget _statusBand({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      color: color.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          CustomText(
            widget.time,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _acceptBtn() {
    return InkWell(
      onTap: () => _updateStatus(cancel: false, accept: true),
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
      onTap: () => _updateStatus(cancel: false, accept: false),
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

  Widget _cancelBtn() {
    return InkWell(
      onTap: () => _updateStatus(cancel: true),
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
            const Icon(Icons.block_rounded, size: 15, color: Colors.red),
            const SizedBox(width: 5),
            Text(AppStrings.cancelLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (String label, Color color) = _isAccepted
        ? (AppStrings.acceptedStatus.tr, Colors.green)
        : _isDeclined
            ? (AppStrings.declinedStatus.tr, Colors.red)
            : _isCancelled
                ? (AppStrings.bookingStatusCancelled.tr,
                    AppColors.secondaryTextColor)
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
