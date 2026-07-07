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

/// In-chat card for `message_type: "hotel_booking"` — hero + 2×2 tile grid
/// layout. Header shows title + status pill; the body leads with the price
/// (₹X / night) and location, followed by four tinted tiles for room type,
/// guests, check-in and check-out; the footer is a status band or, while
/// pending, the accept-decline row (receiver) or waiting band + Cancel
/// button (buyer, doc §2b).
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
  bool _isUpdating = false;

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);
  static const Color _tileBg = Color(0xFFF4F6FA);

  HotelBookingModel? get _b => widget.message.metadata?.hotelBooking;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => (_b?.status ?? 'pending').toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isCancelled => _status == 'cancelled';

  String get _cover => (_b?.listingImage ?? '').trim();
  List<String> get _photos => _b?.photos ?? const [];
  String get _note => (_b?.note ?? '').trim();

  Future<void> _updateStatus({required bool cancel, bool accept = false}) async {
    final id = (_b?.bookingId ?? widget.message.metadata?.hotelBookingId ?? '').trim();
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
      widget.message.metadata?.hotelBooking?.status =
          cancel ? 'cancelled' : (accept ? 'accepted' : 'declined');
    }
    setState(() => _isUpdating = false);
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Splits an existing `priceText` like `"₹300 / night"` into the bold
  /// primary (`₹300`) + smaller suffix (`/ night`). Falls back to
  /// pricePerNight / totalAmount when no formatted string is present.
  (String, String) get _heroPrice {
    final b = _b;
    if (b == null) return ('', '');
    final priceText = (b.priceText ?? '').trim();
    if (priceText.isNotEmpty) {
      final slash = priceText.indexOf('/');
      if (slash > 0) {
        return (
          priceText.substring(0, slash).trim(),
          '/ ${priceText.substring(slash + 1).trim()}',
        );
      }
      return (priceText, '');
    }
    final ppn = b.pricePerNight ?? 0;
    if (ppn > 0) return ('₹$ppn', '/ night');
    final total = b.totalAmount ?? 0;
    if (total > 0) return ('₹$total', 'total');
    return ('', '');
  }

  List<_Tile> get _tiles {
    final b = _b;
    final out = <_Tile>[];

    final roomType = (b?.roomType ?? '').trim();
    final roomName = (b?.roomName ?? '').trim();
    final roomLabel = roomName.isNotEmpty ? roomName : roomType;
    if (roomLabel.isNotEmpty) {
      out.add(_Tile(AppStrings.roomTypeLabel.tr, roomLabel, Icons.king_bed_outlined));
    }

    final guests = b?.guests ?? 0;
    if (guests > 0) {
      out.add(_Tile(
        'Guests',
        '$guests ${guests == 1 ? 'guest' : 'guests'}',
        Icons.people_alt_outlined,
      ));
    }

    final ci = _fmtDate(b?.checkIn);
    if (ci.isNotEmpty) {
      out.add(_Tile(AppStrings.checkInLabel.tr, ci, Icons.login_rounded));
    }

    final co = _fmtDate(b?.checkOut);
    if (co.isNotEmpty) {
      out.add(_Tile(AppStrings.checkOutLabel.tr, co, Icons.logout_rounded));
    }

    return out;
  }

  String get _subtitle {
    final b = _b;
    final parts = <String>[];
    final nights = b?.nights ?? 0;
    if (nights > 0) {
      parts.add('$nights ${nights == 1 ? 'night' : 'nights'}');
    }
    final guests = b?.guests ?? 0;
    if (guests > 0) {
      parts.add('$guests ${guests == 1 ? 'guest' : 'guests'}');
    }
    if (parts.isEmpty) {
      final name = (b?.listingName ?? '').trim();
      if (name.isNotEmpty) return name;
      return AppStrings.hotelBookingTitle.tr;
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = _cover.isNotEmpty || _photos.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: SizeConfig.screenWidth * 0.72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0F001120), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _divider(),
          if (hasPhotos) ...[_photoSection(), _divider()],
          _body(),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
            child: const Icon(Icons.hotel_rounded, color: _accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.hotelBookingTitle.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                // CustomText(
                //   _subtitle,
                //   fontSize: 10.5,
                //   fontWeight: FontWeight.w500,
                //   color: AppColors.secondaryTextColor,
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                // ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  // ── Full-width cover / photos — compact strip ───────────────────────
  Widget _photoSection() {
    final imgs = <String>[
      if (_cover.isNotEmpty) _cover,
      ..._photos.where((p) => p.trim().isNotEmpty && p != _cover),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          for (int i = 0; i < imgs.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 130,
                child: CachedNetworkImage(
                  imageUrl: imgs[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.whiteE5),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.whiteE5,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Body — hero (price + location) followed by 2×2 tile grid ────────
  Widget _body() {
    final (primary, suffix) = _heroPrice;
    final loc = (_b?.location ?? '').trim();
    final tiles = _tiles;
    final hasHero = primary.isNotEmpty || loc.isNotEmpty;
    if (!hasHero && tiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (primary.isNotEmpty)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: primary,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      height: 1.15,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: ' $suffix',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
          if (loc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: AppColors.secondaryTextColor),
                const SizedBox(width: 4),
                Expanded(
                  child: CustomText(
                    loc,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (hasHero && tiles.isNotEmpty) const SizedBox(height: 14),
          if (tiles.isNotEmpty) _grid(tiles),
        ],
      ),
    );
  }

  // Renders [tiles] into a 2-per-row grid; a single dangling tile in the
  // last row takes half the width so alignment matches the paired rows
  // above it (mirrors the reference card's uniform column widths).
  Widget _grid(List<_Tile> tiles) {
    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      final a = tiles[i];
      final b = (i + 1 < tiles.length) ? tiles[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _tile(a)),
          const SizedBox(width: 10),
          Expanded(child: b != null ? _tile(b) : const SizedBox.shrink()),
        ],
      ));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _tile(_Tile t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
      decoration: BoxDecoration(
        color: _tileBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(t.icon, size: 13, color: AppColors.secondaryTextColor),
              const SizedBox(width: 5),
              Flexible(
                child: CustomText(
                  t.label,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          CustomText(
            t.value,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Note — tinted icon badge + eyebrow + text (row style) ───────────
  Widget _noteSection() {
    const color = Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sticky_note_2_outlined, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.noteLabel.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                CustomText(
                  _note,
                  fontSize: 12.5,
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

  // ── Footer — status band or pending action rows ─────────────────────
  Widget _footer() {
    if (_isUpdating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
          ),
        ),
      );
    }

    if (_isAccepted) {
      return _statusBand(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        label: "Booking Accepted",
      );
    }
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFDC2626),
        label: "Booking Decline",
      );
    }
    if (_isCancelled) {
      return _statusBand(
        icon: Icons.block_rounded,
        color: AppColors.secondaryTextColor,
        label: AppStrings.bookingStatusCancelled.tr,
      );
    }

    // Pending — provider (receiver) gets Accept / Decline + timestamp.
    if (!_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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

    // Pending — buyer (sender) sees waiting band + full-width Cancel button.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusBand(
          icon: Icons.access_time_rounded,
          color: Colors.orange,
          label: AppStrings.waitingForResponse.tr,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: _cancelBtn(),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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
          border: Border.all(color: Colors.red.withValues(alpha: 0.55), width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close_rounded, size: 15, color: Colors.red),
            const SizedBox(width: 5),
            Text(AppStrings.declineLabel.tr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.55), width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded, size: 15, color: Colors.red),
            const SizedBox(width: 5),
            Text(AppStrings.cancelLabel.tr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
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
                ? (AppStrings.cancelledStatus.tr, AppColors.secondaryTextColor)
                : (AppStrings.pendingStatus.tr, Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// One grid tile — small icon + label + bold value (matches the reference
/// card's 2×2 booking-detail grid).
class _Tile {
  final String label;
  final String value;
  final IconData icon;

  const _Tile(this.label, this.value, this.icon);
}
