import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/healthcare_booking_model.dart';
import 'package:BlueEra/features/me/medical/controller/hospital_appointment_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for `message_type: "healthcare_booking"` — hospital
/// appointment booking (doc `healthcare-appointment-ui-integration.md`
/// §4). Uses the same hero + 2×2 tile grid layout as [HotelBookingMsgCard]:
/// hero shows Doctor name + department, and four tinted tiles cover date,
/// time, patient and fee. Owner (`!_isMyMessage`) sees Accept / Decline
/// while pending; customer (`_isMyMessage`) sees Cancel while pending OR
/// accepted (doc §2 customer-cancel path). All transitions land on the
/// same PUT via [HospitalAppointmentController].
class HealthcareBookingMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const HealthcareBookingMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<HealthcareBookingMsgCard> createState() =>
      _HealthcareBookingMsgCardState();
}

class _HealthcareBookingMsgCardState extends State<HealthcareBookingMsgCard> {
  bool _isUpdating = false;

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);
  static const Color _tileBg = Color(0xFFF4F6FA);

  HealthcareBookingModel? get _b => widget.message.metadata?.healthcareBooking;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => (_b?.status ?? 'pending').toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isCancelled => _status == 'cancelled';

  List<String> get _photos => _b?.photos ?? const [];
  String get _note => (_b?.note ?? '').trim();

  String get _subtitle {
    final parts = <String>[];
    final dateStr = _fmtDate(_b?.appointmentDate);
    if (dateStr.isNotEmpty) parts.add(dateStr);
    final doctor = (_b?.doctorName ?? '').trim();
    if (doctor.isNotEmpty) parts.add(doctor);
    if (_photos.isNotEmpty) {
      parts.add(
          '${_photos.length} ${_photos.length == 1 ? AppStrings.photoLabel.tr : AppStrings.photosLabel.tr}');
    }
    return parts.isEmpty ? 'Hospital Appointment' : parts.join(' · ');
  }

  /// Non-empty grid tiles in display order — mirrors the reference card's
  /// 2×2 booking-detail grid (date / time / patient / fee here).
  List<_Tile> get _tiles {
    final b = _b;
    final out = <_Tile>[];

    final dateStr = _fmtDate(b?.appointmentDate);
    if (dateStr.isNotEmpty) {
      out.add(_Tile('Date', dateStr, Icons.calendar_today_outlined));
    }

    final timeStr = (b?.preferredTime ?? '').trim();
    if (timeStr.isNotEmpty) {
      out.add(_Tile('Time', timeStr, Icons.schedule_outlined));
    }

    final patient = (b?.patientName ?? '').trim();
    if (patient.isNotEmpty) {
      out.add(_Tile('Patient', patient, Icons.person_outline_rounded));
    }

    final fees = b?.fees;
    if (fees != null && fees > 0) {
      out.add(_Tile('Fee', '₹$fees', Icons.currency_rupee_rounded));
    }

    return out;
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

  Future<void> _updateStatus({required bool cancel, bool accept = false}) async {
    final id = (_b?.appointmentId ??
            widget.message.metadata?.healthcareBookingId ??
            '')
        .trim();
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => HospitalAppointmentController());
    final ok = cancel
        ? await controller.cancelAppointment(id)
        : await controller.respondToAppointment(
            appointmentId: id, accept: accept);
    if (!mounted) return;
    if (ok) {
      widget.message.metadata?.healthcareBooking?.status =
          cancel ? 'cancelled' : (accept ? 'accepted' : 'declined');
    }
    setState(() => _isUpdating = false);
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _divider(),
          if (_photos.isNotEmpty) ...[_photoSection(), _divider()],
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
            child: const Icon(Icons.medical_services_rounded,
                color: _accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Hospital Appointment',
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

  // ── Full-width photo(s) — compact strip ─────────────────────────────
  Widget _photoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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

  // ── Body — hero (doctor + department) + 2×2 tile grid ───────────────
  Widget _body() {
    final doctor = (_b?.doctorName ?? '').trim();
    final dept = (_b?.department ?? '').trim();
    final tiles = _tiles;
    final hasHero = doctor.isNotEmpty || dept.isNotEmpty;
    if (!hasHero && tiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doctor.isNotEmpty)
            CustomText(
              doctor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              height: 1.2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (dept.isNotEmpty) ...[
            if (doctor.isNotEmpty) const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.local_hospital_outlined,
                    size: 14, color: AppColors.secondaryTextColor),
                const SizedBox(width: 4),
                Expanded(
                  child: CustomText(
                    dept,
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
              Icon(t.icon,
                  size: 13, color: AppColors.secondaryTextColor),
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
            child: const Icon(Icons.sticky_note_2_outlined,
                color: color, size: 17),
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

  // ── Footer — status band (accepted / declined / cancelled) or, while
  // pending, the accept-decline row (receiver) or the waiting band +
  // Cancel button (customer). Accepted customers can still cancel per
  // doc §2 customer-cancel path. ───────────────────────────────────────
  Widget _footer() {
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: Colors.red,
        label: 'Appointment declined',
      );
    }
    if (_isCancelled) {
      return _statusBand(
        icon: Icons.block_rounded,
        color: AppColors.secondaryTextColor,
        label: 'Appointment cancelled',
      );
    }
    if (_isAccepted) {
      final band = _statusBand(
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        label: 'Appointment accepted',
      );
      if (_isMyMessage) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            band,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: _isUpdating
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _accent),
                      ),
                    )
                  : _cancelBtn(),
            ),
          ],
        );
      }
      return band;
    }

    // Pending — provider (receiver) gets Accept / Decline + timestamp.
    if (!_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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

    // Pending — customer (sender) sees waiting band + Cancel button.
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
          child: _isUpdating
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _accent),
                  ),
                )
              : _cancelBtn(),
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

  // Cancel — buyer-side button, styled as decline (white bg / red border)
  // with a block icon per spec.
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
/// booking-detail card's 2×2 grid).
class _Tile {
  final String label;
  final String value;
  final IconData icon;

  const _Tile(this.label, this.value, this.icon);
}
