import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One reusable in-chat enquiry / booking card. Per the doc
/// (`lib/docs/enquiry-flows-ui-integration.md`) every enquiry/booking flow
/// — Vehicle, Hotel, Education, Hospital, Pharmacy — produces the same
/// card shape (listing snapshot + selections + photos + note + status +
/// owner-side Accept/Decline + optional buyer-side Cancel).
///
/// The [MessageCard] switch builds an [EnquiryCardView] from the typed
/// metadata model and hands it to this widget. The card itself stays
/// dumb — it only knows how to render rows, call the supplied [onUpdate]
/// callback, and reflect the new status in place.
class EnquiryMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final EnquiryCardView view;

  const EnquiryMsgCard({
    super.key,
    required this.message,
    required this.time,
    required this.view,
  });

  @override
  State<EnquiryMsgCard> createState() => _EnquiryMsgCardState();
}

class _EnquiryMsgCardState extends State<EnquiryMsgCard> {
  bool _isUpdating = false;

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);

  // Selection-row palette cycled by index so distinct groups get distinct
  // tints without the card needing to know group names in advance.
  static const List<Color> _groupPalette = [
    Color(0xFF0EA5E9),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
  ];

  EnquiryCardView get _v => widget.view;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => _v.status.toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isCancelled => _status == 'cancelled';
  bool get _isPending => !_isAccepted && !_isDeclined && !_isCancelled;

  Map<String, List<String>> get _selections {
    final out = <String, List<String>>{};
    _v.selections.forEach((k, v) {
      final items = v.where((s) => s.trim().isNotEmpty).toList();
      if (items.isNotEmpty) out[k] = items;
    });
    return out;
  }

  int get _totalCount {
    final seen = <String>{};
    var n = 0;
    for (final group in _selections.values) {
      for (final item in group) {
        if (seen.add(item.toLowerCase())) n++;
      }
    }
    return n;
  }

  String get _subtitle {
    final parts = <String>[];
    if (_totalCount > 0) {
      parts.add(
          '$_totalCount ${_totalCount == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}');
    }
    if (_v.photos.isNotEmpty) {
      parts.add(
          '${_v.photos.length} ${_v.photos.length == 1 ? AppStrings.photoLabel.tr : AppStrings.photosLabel.tr}');
    }
    return parts.isEmpty ? AppStrings.customRequest.tr : parts.join(' · ');
  }

  Future<void> _updateStatus(String status) async {
    final enquiryId = (_v.enquiryId ?? '').trim();
    if (enquiryId.isEmpty) {
      // Empty id means the create-enquiry response didn't return one
      // (or the backend didn't echo the fabricated card's metadata).
      // Surface the failure instead of silently swallowing the tap —
      // otherwise users see a broken button with no feedback.
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }

    setState(() => _isUpdating = true);
    final ok = await _v.onUpdate(enquiryId, status);
    if (ok) {
      _v.applyStatusInPlace(status);
    }
    if (mounted) setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasSnapshot = _v.listingName.trim().isNotEmpty ||
        _v.listingImage.trim().isNotEmpty ||
        _v.location.trim().isNotEmpty ||
        _v.priceText.trim().isNotEmpty;

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
          if (hasSnapshot) ...[_divider(), _listingSnapshot()],
          if (_v.photos.isNotEmpty) ...[_divider(), _photoSection()],
          for (final entry
              in _selections.entries.toList().asMap().entries) ...[
            _divider(),
            _selectionRow(
              title: entry.value.key,
              items: entry.value.value,
              color: _groupPalette[entry.key % _groupPalette.length],
            ),
          ],
          if (_v.note.trim().isNotEmpty) ...[_divider(), _noteSection()],
          _divider(),
          _footer(),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: _line);

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
            child: Icon(_v.headerIcon, color: _accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  _v.title,
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
          _statusBadge(),
        ],
      ),
    );
  }

  Widget _listingSnapshot() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _v.listingImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _v.listingImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.whiteE5),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.whiteE5,
                        alignment: Alignment.center,
                        child: Icon(_v.headerIcon,
                            size: 18, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: AppColors.whiteE5,
                      alignment: Alignment.center,
                      child: Icon(_v.headerIcon,
                          size: 18, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_v.listingName.isNotEmpty)
                  CustomText(
                    _v.listingName,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_v.priceText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    _v.priceText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ],
                if (_v.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.secondaryTextColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: CustomText(
                          _v.location,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          for (int i = 0; i < _v.photos.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 130,
                child: CachedNetworkImage(
                  imageUrl: _v.photos[i],
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

  Widget _selectionRow({
    required String title,
    required List<String> items,
    required Color color,
  }) {
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
            child:
                Icon(Icons.check_circle_outline, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(title),
                const SizedBox(height: 3),
                if (items.length == 1)
                  CustomText(
                    items.first,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    height: 1.3,
                  )
                else
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 7),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.mainTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CustomText(
                              item,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                  _v.note,
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
        icon: Icons.do_not_disturb_alt_rounded,
        color: AppColors.grayText,
        label: AppStrings.enquiryCancelled.tr,
      );
    }

    // Pending — owner sees Accept/Decline. Buyer sees waiting (+ Cancel,
    // for flows where the view enables it: vehicle, hotel-booking).
    if (!_isMyMessage) {
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

    // Buyer's pending card.
    if (_v.canBuyerCancel && _isPending) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusBandInline(
              icon: Icons.access_time_rounded,
              color: Colors.orange,
              label: AppStrings.waitingForResponse.tr,
            ),
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
          ],
        ),
      );
    }

    return _statusBand(
      icon: Icons.access_time_rounded,
      color: Colors.orange,
      label: AppStrings.waitingForResponse.tr,
    );
  }

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

  Widget _statusBandInline({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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

  Widget _cancelBtn() {
    return InkWell(
      onTap: () => _updateStatus('cancelled'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.grayText.withValues(alpha: 0.55), width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.do_not_disturb_alt_rounded,
                size: 15, color: AppColors.grayText),
            const SizedBox(width: 5),
            Text(AppStrings.cancelLabel.tr,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grayText)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final (String label, Color color) = _isAccepted
        ? (AppStrings.acceptedStatus.tr, Colors.green)
        : _isDeclined
            ? (AppStrings.declinedStatus.tr, Colors.red)
            : _isCancelled
                ? (AppStrings.cancelledStatus.tr, AppColors.grayText)
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

/// Read-only adapter passed to [EnquiryMsgCard] by [MessageCard]. One
/// instance per rendered message; values are pulled from the typed
/// metadata model (healthcareEnquiry / hotelEnquiry / booking / …) by
/// the caller, so the card stays metadata-agnostic.
///
/// [canBuyerCancel] is `true` only for flows where the buyer can cancel
/// a still-pending request (Vehicle bookings, Hotel bookings) per the
/// integration guide; for enquiry-only flows it must be `false`.
class EnquiryCardView {
  final String? enquiryId;
  final String status; // 'pending' | 'accepted' | 'declined' | 'cancelled'
  final String title; // e.g. "Healthcare Enquiry", "Hotel Enquiry", "Vehicle Booking"
  final IconData headerIcon;
  final String listingName;
  final String listingImage;
  final String location;
  final String priceText;
  final Map<String, List<String>> selections;
  final List<String> photos;
  final String note;
  final bool canBuyerCancel;

  /// Called when the owner taps Accept / Decline (or the buyer taps
  /// Cancel where [canBuyerCancel]). Resolves to `true` on success; the
  /// card then calls [applyStatusInPlace] to flip its visible state.
  final Future<bool> Function(String enquiryId, String status) onUpdate;

  /// Mutates the underlying metadata model so a rebuild keeps showing
  /// the new status (the socket event also drives this independently,
  /// but the optimistic update keeps the UI snappy).
  final void Function(String status) applyStatusInPlace;

  const EnquiryCardView({
    required this.enquiryId,
    required this.status,
    required this.title,
    required this.headerIcon,
    required this.listingName,
    required this.listingImage,
    required this.location,
    required this.priceText,
    required this.selections,
    required this.photos,
    required this.note,
    required this.onUpdate,
    required this.applyStatusInPlace,
    this.canBuyerCancel = false,
  });
}
