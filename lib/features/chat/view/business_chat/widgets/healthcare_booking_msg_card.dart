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

/// In-chat card for `message_type: "healthcare_booking"` — the hospital
/// appointment booking (doc `healthcare-appointment-ui-integration.md`
/// §4). Same amber palette as the healthcare-enquiry card so the two
/// stack cleanly in the same conversation.
///
/// Owner (`!_isMyMessage`) sees Accept / Decline while pending. Customer
/// (`_isMyMessage`) sees Cancel while **pending OR accepted** (doc §2
/// customer-cancel path). All three transitions land on the same PUT
/// endpoint via [HospitalAppointmentController].
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
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _accentDeep = Color(0xFFD97706);
  static const Color _line = Color(0xFFF3E7CE);
  static const Color _tint = Color(0xFFFFF8EC);

  bool _isUpdating = false;

  HealthcareBookingModel? get _b => widget.message.metadata?.healthcareBooking;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => (_b?.status ?? 'pending').toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isCancelled => _status == 'cancelled';
  bool get _isPending => !_isAccepted && !_isDeclined && !_isCancelled;

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
          _header(),
          _doctorRow(b),
          if ((b?.appointmentDate ?? '').isNotEmpty)
            _row(Icons.calendar_month_rounded, 'Appointment',
                _fmtDate(b!.appointmentDate)),
          if ((b?.preferredTime ?? '').isNotEmpty)
            _row(Icons.access_time_rounded, 'Preferred Time',
                b!.preferredTime!),
          if ((b?.patientName ?? '').isNotEmpty)
            _row(Icons.person_outline_rounded, 'Patient', b!.patientName!),
          if ((b?.note ?? '').trim().isNotEmpty) _noteRow(b!.note!.trim()),
          if ((b?.photos ?? const []).isNotEmpty)
            _photoStrip(b!.photos ?? const []),
          _footer(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentDeep, _accent],
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
            child: const Icon(Icons.medical_services_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hospital Appointment',
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

  Widget _doctorRow(HealthcareBookingModel? b) {
    final name = (b?.doctorName ?? '').trim();
    final dept = (b?.department ?? '').trim();
    final image = (b?.doctorImage ?? '').trim();
    final fees = b?.fees;
    if (name.isEmpty && dept.isEmpty && image.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 48,
              height: 48,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _tint),
                      errorWidget: (_, __, ___) => Container(
                        color: _tint,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_rounded,
                            size: 22, color: _accent),
                      ),
                    )
                  : Container(
                      color: _tint,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_rounded,
                          size: 22, color: _accent),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  CustomText(
                    name,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (dept.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    dept,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if ((fees ?? 0) > 0) ...[
                  const SizedBox(height: 3),
                  CustomText(
                    '₹$fees',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accentDeep,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _accentDeep, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label.toUpperCase(),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  value,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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

  Widget _noteRow(String note) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: _tint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 14, color: _accentDeep),
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

  Widget _photoStrip(List<String> photos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photos[i],
              width: 80,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 80, height: 60, color: _tint),
              errorWidget: (_, __, ___) => Container(
                width: 80,
                height: 60,
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

  Widget _footer() {
    // Terminal status → status band, no actions.
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFDC2626),
        label: 'Appointment declined',
      );
    }
    if (_isCancelled) {
      return _statusBand(
        icon: Icons.block_rounded,
        color: const Color(0xFF6B7280),
        label: 'Appointment cancelled',
      );
    }
    // Owner: Accept / Decline while pending.
    if (_isPending && !_isMyMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: _isUpdating
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accentDeep),
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
    // Customer: Cancel while pending OR accepted (doc §2).
    if (_isMyMessage && (_isPending || _isAccepted)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAccepted)
              _statusBand(
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                label: 'Appointment accepted',
              ),
            if (_isAccepted) const SizedBox(height: 10),
            _isUpdating
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accentDeep),
                    ),
                  )
                : _cancelBtn(),
          ],
        ),
      );
    }
    // Owner side, accepted → status band only (no actions left).
    if (_isAccepted) {
      return _statusBand(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        label: 'Appointment accepted',
      );
    }
    // Fallback: pending on the customer's own message with the sheet
    // not yet fabricated — waiting for owner.
    return _statusBand(
      icon: Icons.access_time_rounded,
      color: _accentDeep,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accentDeep, _accent]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Accept',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  Widget _declineBtn() {
    return InkWell(
      onTap: () => _updateStatus(cancel: false, accept: false),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accentDeep.withValues(alpha: 0.35)),
        ),
        child: const Text(
          'Decline',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: _accentDeep),
        ),
      ),
    );
  }

  Widget _cancelBtn() {
    return InkWell(
      onTap: () => _updateStatus(cancel: true),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDC2626)),
        ),
        child: const Text(
          'Cancel appointment',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFDC2626)),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final (String label, Color color) = _isAccepted
        ? ('ACCEPTED', const Color(0xFF16A34A))
        : _isDeclined
            ? ('DECLINED', const Color(0xFFDC2626))
            : _isCancelled
                ? ('CANCELLED', const Color(0xFF6B7280))
                : ('PENDING', Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _isPending ? Colors.white.withValues(alpha: 0.28) : color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
