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

/// In-chat card for `message_type: "vehicle_booking"` — dedicated automotive
/// design. Charcoal + red palette (auto / motor feel), an intent ribbon
/// (BUY / TEST_DRIVE / EXCHANGE / INFO) driven by the booking's `intent`,
/// and priceText / condition rows from the listing snapshot.
///
/// Distinct from the four enquiry cards (business / healthcare / hotel /
/// education) in one important way: vehicle is a **booking**, not an
/// enquiry — the buyer can also **Cancel** while `pending`, on top of the
/// owner Accept / Decline. Status flips route through [VehicleController]:
/// buyer Cancel → `PUT /vehicles/bookings/:id/cancel`; owner Accept /
/// Decline → `PUT /vehicles/bookings/:id/status`. See
/// `lib/docs/enquiry-verticals-flutter-integration.md` for the wire shape.
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
  static const Color _charcoal = Color(0xFF111827);
  static const Color _charcoalDeep = Color(0xFF030712);
  static const Color _red = Color(0xFFDC2626);
  static const Color _redDeep = Color(0xFF991B1B);
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _tint = Color(0xFFF3F4F6);

  bool _isUpdating = false;

  VehicleBooking? get _b => widget.message.metadata?.booking;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  VehicleBookingStatus get _status =>
      _b?.status ?? VehicleBookingStatus.pending;
  bool get _isAccepted => _status == VehicleBookingStatus.accepted;
  bool get _isDeclined => _status == VehicleBookingStatus.declined;
  bool get _isCancelled => _status == VehicleBookingStatus.cancelled;
  bool get _isPending => _status == VehicleBookingStatus.pending;

  /// Intent-driven header icon.
  IconData get _intentIcon {
    switch (_b?.intent) {
      case VehicleBookingIntent.testDrive:
        return Icons.drive_eta_rounded;
      case VehicleBookingIntent.exchange:
        return Icons.swap_horiz_rounded;
      case VehicleBookingIntent.info:
        return Icons.info_outline_rounded;
      case VehicleBookingIntent.buy:
      default:
        return Icons.directions_car_filled_rounded;
    }
  }

  Future<void> _updateStatus({required bool cancel, bool accept = false}) async {
    final id = (_b?.id ?? widget.message.metadata?.vehicleBookingId ?? '').trim();
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

  @override
  Widget build(BuildContext context) {
    final b = _b;
    final snap = b?.snapshot;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _charcoalHeader(),
          _listingSnapshot(
            snap?.image ?? '',
            snap?.title ?? '',
            snap?.priceText ?? '',
            snap?.location ?? '',
          ),
          _detailSection(
            'Intent',
            b?.intent.label ?? '',
            Icons.assignment_rounded,
          ),
          if (b?.offerPrice != null)
            _detailSection(
              'Offer',
              '₹${b!.offerPrice!.toStringAsFixed(0)}',
              Icons.currency_rupee_rounded,
            ),
          if ((snap?.condition ?? '').isNotEmpty)
            _detailSection(
              'Condition',
              snap!.condition!,
              Icons.verified_rounded,
            ),
          if ((b?.photos ?? const []).isNotEmpty)
            _photoStrip(b!.photos),
          if ((b?.note ?? '').trim().isNotEmpty) _noteRow(b!.note!.trim()),
          _footer(),
        ],
      ),
    );
  }

  Widget _charcoalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_charcoalDeep, _charcoal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_redDeep, _red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _red.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(_intentIcon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.vehicleBookingTitle.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((_b?.intent.label ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _red.withValues(alpha: 0.55), width: 0.8),
                      ),
                      child: Text(
                        _b!.intent.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _statusBadge(),
        ],
      ),
    );
  }

  Widget _listingSnapshot(
      String image, String name, String priceText, String location) {
    final hasSnapshot = image.trim().isNotEmpty ||
        name.trim().isNotEmpty ||
        priceText.trim().isNotEmpty ||
        location.trim().isNotEmpty;
    if (!hasSnapshot) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 44,
              height: 44,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _tint),
                      errorWidget: (_, __, ___) => Container(
                        color: _tint,
                        alignment: Alignment.center,
                        child: Icon(_intentIcon, size: 20, color: _charcoal),
                      ),
                    )
                  : Container(
                      color: _tint,
                      alignment: Alignment.center,
                      child: Icon(_intentIcon, size: 20, color: _charcoal),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                if (priceText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    priceText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _red,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: _charcoal),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
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

  Widget _detailSection(String title, String value, IconData icon) {
    // ClipRRect + IntrinsicHeight lets the red accent strip run full-height
    // on the left while keeping rounded corners. `BoxDecoration.border` with
    // non-uniform side colors would assert at paint time when combined with
    // `borderRadius`.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            color: _tint,
            border: Border.all(color: _line),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: _red),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _charcoal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(icon, color: _charcoal, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _charcoalDeep,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoStrip(List<String> photos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SizedBox(
        height: 66,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: CachedNetworkImage(
              imageUrl: photos[i],
              width: 84,
              height: 66,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 84, height: 66, color: _tint),
              errorWidget: (_, __, ___) => Container(
                width: 84,
                height: 66,
                color: _tint,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined,
                    size: 16, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteRow(String note) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote_rounded, size: 15, color: _charcoal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    if (_isAccepted) {
      return _statusBand(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        label: AppStrings.enquiryAccepted.tr,
      );
    }
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: _red,
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
    // Pending — seller sees Accept / Decline, buyer sees Cancel.
    if (_isPending) {
      final loader = Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _charcoal),
          ),
        ),
      );
      if (!_isMyMessage) {
        // Seller side (received message) — Accept / Decline.
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: _isUpdating
              ? loader
              : Row(
                  children: [
                    Expanded(child: _declineBtn()),
                    const SizedBox(width: 8),
                    Expanded(child: _acceptBtn()),
                  ],
                ),
        );
      }
      // Buyer side (sent message) — Cancel + waiting band.
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: _isUpdating
            ? loader
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _inlineWaitingBand(),
                  const SizedBox(height: 8),
                  _cancelBtn(),
                ],
              ),
      );
    }
    return _statusBand(
      icon: Icons.access_time_rounded,
      color: _red,
      label: AppStrings.waitingForResponse.tr,
    );
  }

  Widget _inlineWaitingBand() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: _red, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              AppStrings.waitingForResponse.tr,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBand({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_redDeep, _red]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(AppStrings.acceptLabel.tr,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _declineBtn() {
    return InkWell(
      onTap: () => _updateStatus(cancel: false, accept: false),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _charcoal.withValues(alpha: 0.35)),
        ),
        child: Text(
          AppStrings.declineLabel.tr,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _charcoalDeep),
        ),
      ),
    );
  }

  Widget _cancelBtn() {
    return InkWell(
      onTap: () => _updateStatus(cancel: true),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _red.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded, size: 15, color: _red),
            const SizedBox(width: 5),
            Text(
              AppStrings.cancelLabel.tr,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    late final String label;
    late final Color color;
    if (_isAccepted) {
      label = AppStrings.acceptedStatus.tr;
      color = const Color(0xFF16A34A);
    } else if (_isDeclined) {
      label = AppStrings.declinedStatus.tr;
      color = _red;
    } else if (_isCancelled) {
      label = AppStrings.bookingStatusCancelled.tr;
      color = AppColors.secondaryTextColor;
    } else {
      label = AppStrings.pendingStatus.tr;
      color = _red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color == AppColors.secondaryTextColor ? Colors.white : color,
        ),
      ),
    );
  }
}
