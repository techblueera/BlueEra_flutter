import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/hotel_booking_model.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_booking_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for `message_type: "hotel_booking"` — dedicated hotel
/// booking design mirroring [HotelEnquiryMsgCard] but tuned for the
/// booking payload: dates + guests + room type rows, plus a buyer-side
/// **Cancel** action while `pending` (the doc §2b booking-only extra
/// transition). Same warm amber palette as the hotel enquiry card.
///
/// Distinct from [VehicleBookingMsgCard] because the underlying REST
/// path, socket names and metadata key (`metadata.hotelBooking` / id at
/// `metadata.hotelBookingId`) differ. See
/// `lib/docs/enquiry-flows-ui-integration.md` §2b for the wire shape.
class HotelBookingMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const HotelBookingMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<HotelBookingMsgCard> createState() => _HotelBookingMsgCardState();
}

class _HotelBookingMsgCardState extends State<HotelBookingMsgCard> {
  static const Color _amber = Color(0xFFB45309);
  static const Color _amberDeep = Color(0xFF78350F);
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _tint = Color(0xFFFEF3C7);

  bool _isUpdating = false;

  HotelBookingModel? get _b => widget.message.metadata?.hotelBooking;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => (_b?.status ?? 'pending').toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isCancelled => _status == 'cancelled';
  bool get _isPending => !_isAccepted && !_isDeclined && !_isCancelled;

  Future<void> _updateStatus({required bool cancel, bool accept = false}) async {
    final id = (_b?.bookingId ??
            widget.message.metadata?.hotelBookingId ??
            '')
        .trim();
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => HotelBookingController());
    final ok = cancel
        ? await controller.cancelBooking(id)
        : await controller.respondToBooking(bookingId: id, accept: accept);
    if (!mounted) return;
    if (ok) {
      widget.message.metadata?.hotelBooking?.status = cancel
          ? 'cancelled'
          : (accept ? 'accepted' : 'declined');
    }
    setState(() => _isUpdating = false);
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
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
          _amberHeader(),
          _listingSnapshot(b?.listingImage ?? '', b?.listingName ?? '',
              b?.priceText ?? '', b?.location ?? ''),
          if ((b?.roomType ?? '').isNotEmpty)
            _row(Icons.bed_rounded, 'Room Type', b!.roomType!),
          if ((b?.checkIn ?? '').isNotEmpty)
            _row(Icons.login_rounded, AppStrings.checkInLabel.tr,
                _fmtDate(b!.checkIn)),
          if ((b?.checkOut ?? '').isNotEmpty)
            _row(Icons.logout_rounded, AppStrings.checkOutLabel.tr,
                _fmtDate(b!.checkOut)),
          if ((b?.guests ?? 0) > 0)
            _row(Icons.groups_rounded, 'Guests',
                '${b!.guests} ${b.guests == 1 ? 'guest' : 'guests'}'),
          if ((b?.photos ?? const []).isNotEmpty)
            _photoStrip(b!.photos ?? const []),
          if ((b?.note ?? '').trim().isNotEmpty) _noteRow(b!.note!.trim()),
          _footer(),
        ],
      ),
    );
  }

  Widget _amberHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_amberDeep, _amber],
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 0.8),
            ),
            child: const Icon(Icons.hotel_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.hotelBookingTitle.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
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
                        child: const Icon(Icons.hotel_rounded,
                            size: 20, color: _amber),
                      ),
                    )
                  : Container(
                      color: _tint,
                      alignment: Alignment.center,
                      child: const Icon(Icons.hotel_rounded,
                          size: 20, color: _amber),
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
                      color: _amber,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: _amber),
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

  Widget _row(IconData icon, String title, String value) {
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
                Container(width: 3, color: _amber),
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
                            color: _amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(icon, color: _amber, size: 15),
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
                                  color: _amberDeep,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _amberDeep,
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
            const Icon(Icons.format_quote_rounded, size: 15, color: _amber),
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
        color: const Color(0xFFDC2626),
        label: AppStrings.enquiryDeclined.tr,
      );
    }
    if (_isCancelled) {
      return _statusBand(
        icon: Icons.block_rounded,
        color: AppColors.secondaryTextColor,
        label: AppStrings.enquiryCancelled.tr,
      );
    }
    if (_isPending) {
      final loader = Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
          ),
        ),
      );
      if (!_isMyMessage) {
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
      // Buyer side (sent) — Cancel + waiting band.
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
      color: _amber,
      label: AppStrings.waitingForResponse.tr,
    );
  }

  Widget _inlineWaitingBand() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: _amber, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              AppStrings.waitingForResponse.tr,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _amber,
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
          gradient: const LinearGradient(colors: [_amberDeep, _amber]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _amber.withValues(alpha: 0.35),
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
          border: Border.all(color: _amber.withValues(alpha: 0.45)),
        ),
        child: Text(
          AppStrings.declineLabel.tr,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _amberDeep),
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
          border: Border.all(color: _amber.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded, size: 15, color: _amber),
            const SizedBox(width: 5),
            Text(
              AppStrings.cancelLabel.tr,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _amber),
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
      color = const Color(0xFFDC2626);
    } else if (_isCancelled) {
      label = AppStrings.cancelledStatus.tr;
      color = AppColors.secondaryTextColor;
    } else {
      label = AppStrings.pendingStatus.tr;
      color = Colors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color == Colors.white
            ? Colors.white.withValues(alpha: 0.20)
            : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: color == Colors.white
                ? Colors.white.withValues(alpha: 0.55)
                : color.withValues(alpha: 0.55),
            width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color == Colors.white ? Colors.white : color,
        ),
      ),
    );
  }
}
