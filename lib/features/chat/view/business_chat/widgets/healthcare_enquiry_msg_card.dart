import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/healthcare_enquiry_model.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_appointment_sheet.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_booking_sheet.dart';
import 'package:BlueEra/features/me/medical/controller/healthcare_enquiry_controller.dart';
import 'package:BlueEra/features/me/medical/widget/hospital_appointment_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-chat card for `message_type: "healthcare_enquiry"`.
///
/// Visual language mirrors [ServiceEnquiryMsgCard] — slim header, divider-
/// separated sections (photo / selections / note), and an accept-decline or
/// status footer — so healthcare / vehicle / hotel / education enquiry cards
/// all render identically in the chat stream. The provider (receiver) can
/// Accept / Decline while pending; the customer (sender) sees a waiting
/// state, then a "Book Appointment" CTA on HOSPITAL-category enquiries once
/// accepted (enquiry-first hospital flow).
class HealthcareEnquiryMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const HealthcareEnquiryMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<HealthcareEnquiryMsgCard> createState() =>
      _HealthcareEnquiryMsgCardState();
}

class _HealthcareEnquiryMsgCardState extends State<HealthcareEnquiryMsgCard> {
  bool _isUpdating = false;

  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFF0F2F5);

  HealthcareEnquiryModel? get _e =>
      widget.message.metadata?.healthcareEnquiry;
  bool get _isMyMessage => widget.message.myMessage ?? false;
  String get _status => (_e?.status ?? 'pending').toLowerCase();
  bool get _isAccepted => _status == 'accepted';
  bool get _isDeclined => _status == 'declined';
  bool get _isPending => !_isAccepted && !_isDeclined;

  /// Non-empty selection groups, in their backend-declared order — each is
  /// rendered as one enquiry row with its own tinted icon.
  Map<String, List<String>> get _selections {
    final out = <String, List<String>>{};
    (_e?.selections ?? const <String, List<String>>{}).forEach((k, v) {
      final items = v.where((s) => s.trim().isNotEmpty).toList();
      if (items.isNotEmpty) out[k] = items;
    });
    return out;
  }

  List<String> get _photos => _e?.photos ?? const [];

  String get _note => _e?.note ?? '';

  int get _totalCount => _e?.allSelections.length ?? 0;

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

  /// Rows for the selection groups. Healthcare enquiries use a free-form
  /// `selections` map (departments / test types / purpose / timeline / …),
  /// so we key icon+color off the section title with sensible fallbacks —
  /// keeping the reference card's palette of tinted 38×38 badges.
  List<_EnquiryRow> get _rows {
    final out = <_EnquiryRow>[];
    _selections.forEach((title, items) {
      final (icon, color) = _iconAndColorFor(title);
      out.add(_EnquiryRow(title, items, icon, color));
    });
    return out;
  }

  (IconData, Color) _iconAndColorFor(String title) {
    switch (title.toLowerCase().trim()) {
      case 'category':
      case 'type of care':
      case 'care type':
        return (Icons.category_rounded, const Color(0xFF0EA5E9));
      case 'departments':
      case 'department':
      case 'specialization':
      case 'specializations':
      case 'specialties':
      case 'specialty':
      case 'services':
      case 'services offered':
        return (Icons.health_and_safety_rounded, const Color(0xFF22C55E));
      case 'symptoms':
      case 'conditions':
      case 'condition':
      case 'complaints':
        return (Icons.sick_rounded, const Color(0xFFEF4444));
      case 'urgency':
      case 'when':
      case 'timeline':
      case 'preferred time':
      case 'preferred date':
        return (Icons.priority_high_rounded, const Color(0xFFF59E0B));
      case 'doctor':
      case 'doctor preference':
      case 'preferred doctor':
        return (Icons.person_rounded, const Color(0xFF8B5CF6));
      case 'test types':
      case 'tests':
        return (Icons.biotech_outlined, const Color(0xFF0EA5E9));
      case 'product type':
      case 'products':
      case 'medication':
      case 'medications':
        return (Icons.medication_outlined, const Color(0xFF22C55E));
      case 'purpose':
        return (Icons.assignment_outlined, const Color(0xFF8B5CF6));
      default:
        return (Icons.local_hospital_outlined, const Color(0xFF0EA5E9));
    }
  }

  Future<void> _updateStatus(String status) async {
    final id = (_e?.enquiryId ??
            widget.message.metadata?.healthcareEnquiryId ??
            '')
        .trim();
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isUpdating = true);
    final controller = getOrPut(() => HealthcareEnquiryController());
    final ok = await controller.updateHealthcareEnquiryStatus(
      enquiryId: id,
      category: _e?.category ?? '',
      status: status,
    );
    if (!mounted) return;
    if (ok) widget.message.metadata?.healthcareEnquiry?.status = status;
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
          if (_photos.isNotEmpty) ...[_divider(), _photoSection()],
          for (final row in _rows) ...[_divider(), _enquiryRow(row)],
          if (_note.trim().isNotEmpty) ...[_divider(), _noteSection()],
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
            child: const Icon(Icons.medical_services_rounded,
                color: _accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.healthcareEnquiry.tr,
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

  // ── One enquiry row — tinted icon badge + eyebrow + value(s) ────────
  Widget _enquiryRow(_EnquiryRow row) {
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
              color: row.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(row.icon, color: row.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(row.title),
                const SizedBox(height: 3),
                if (row.items.length == 1)
                  CustomText(
                    row.items.first,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    height: 1.3,
                  )
                else
                  for (final item in row.items)
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

  // ── Footer — status band (waiting / accepted / declined) or, for the
  // provider while pending, the Accept / Decline actions. Accepted state
  // on a HOSPITAL-category enquiry appends the Book Appointment CTA and
  // on a LABORATORY-category enquiry appends the Book Test CTA (both
  // enquiry-first flows). ────────────────────────────────────────────
  Widget _footer() {
    if (_isAccepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusBand(
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            label: AppStrings.enquiryAccepted.tr,
          ),
          if (_isMyMessage && _canOpenAppointmentSheet) _bookAppointmentRow(),
          if (_isMyMessage && _canOpenLabBookingSheet) _bookTestRow(),
          if (_isMyMessage && _canOpenDoctorBookingSheet)
            _bookDoctorAppointmentRow(),
        ],
      );
    }
    if (_isDeclined) {
      return _statusBand(
        icon: Icons.cancel_rounded,
        color: Colors.red,
        label: AppStrings.enquiryDeclined.tr,
      );
    }

    // Pending — provider (receiver) gets Accept / Decline + timestamp.
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

    // Pending — customer (sender) waits for the provider's response.
    return _statusBand(
      icon: Icons.access_time_rounded,
      color: Colors.orange,
      label: AppStrings.waitingForResponse.tr,
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

  /// Enquiry-first hook: only wire the CTA when
  ///  1. the enquiry is on a HOSPITAL listing (appointment endpoint is
  ///     hospital-only),
  ///  2. we have a hospital id + owner id + enquiry id to send.
  /// Any missing → hide the button rather than opening a broken sheet.
  bool get _canOpenAppointmentSheet {
    final e = _e;
    if (e == null) return false;
    if ((e.category ?? '').toUpperCase() != 'HOSPITAL') return false;
    return (e.listingId ?? '').trim().isNotEmpty &&
        (e.ownerId ?? '').trim().isNotEmpty &&
        (e.enquiryId ?? '').trim().isNotEmpty;
  }

  void _openAppointmentSheet() {
    final e = _e!;
    HospitalAppointmentSheet.open(
      context,
      listing: HospitalAppointmentListing(
        hospitalId: (e.listingId ?? '').trim(),
        ownerId: (e.ownerId ?? '').trim(),
        // The enquiry card doesn't carry a separate ownerName — the
        // sheet header falls back to hospitalName when ownerName is
        // empty, so an empty string is fine here.
        ownerName: '',
        hospitalName: (e.listingName ?? '').trim(),
        coverImage: (e.listingImage ?? '').trim(),
        location: (e.location ?? '').trim(),
      ),
      enquiryId: (e.enquiryId ?? '').trim(),
    );
  }

  Widget _bookAppointmentRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: InkWell(
        onTap: _openAppointmentSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentDeep, _accent]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available_rounded,
                  size: 15, color: Colors.white),
              const SizedBox(width: 5),
              const Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Laboratory booking (LABORATORY-category enquiry-first flow) ────

  /// Only wire the CTA when
  ///  1. the enquiry is on a LABORATORY listing (booking endpoint is
  ///     lab-service only),
  ///  2. we have a laboratory id + owner id + enquiry id to send.
  /// Any missing → hide the button rather than opening a broken sheet.
  bool get _canOpenLabBookingSheet {
    final e = _e;
    if (e == null) return false;
    if ((e.category ?? '').toUpperCase() != 'LABORATORY') return false;
    return (e.listingId ?? '').trim().isNotEmpty &&
        (e.ownerId ?? '').trim().isNotEmpty &&
        (e.enquiryId ?? '').trim().isNotEmpty;
  }

  void _openLabBookingSheet() {
    final e = _e!;
    LabBookingSheet.open(
      context,
      listing: LabBookingListing(
        laboratoryId: (e.listingId ?? '').trim(),
        ownerId: (e.ownerId ?? '').trim(),
        labName: (e.listingName ?? '').trim(),
        labImage: (e.listingImage ?? '').trim(),
        location: (e.location ?? '').trim(),
      ),
      enquiryId: (e.enquiryId ?? '').trim(),
    );
  }

  // ── Standalone-doctor booking (DOCTOR/DOCTORS enquiry-first flow) ──

  /// The third vertical. Before this the card handled only HOSPITAL and
  /// LABORATORY, so a doctor enquiry matched neither branch and the customer
  /// hit a dead end right after the doctor accepted (guide §3.2).
  ///
  /// The category string is the trap here. The ENQUIRY record carries
  /// `"DOCTORS"` (plural — copied from `Business.category_Of_Business`) while
  /// the BOOKING record carries `"DOCTOR"` (singular). Matching only one of
  /// them leaves the button permanently hidden with no error anywhere, so
  /// both are accepted, case-insensitively.
  static const Set<String> _doctorCategories = {'DOCTOR', 'DOCTORS'};

  bool get _canOpenDoctorBookingSheet {
    final e = _e;
    if (e == null) return false;
    if (!_doctorCategories.contains((e.category ?? '').trim().toUpperCase())) {
      return false;
    }
    // Any missing id → hide the button rather than open a sheet that can only
    // fail. Same guard style as the two branches above.
    return (e.listingId ?? '').trim().isNotEmpty &&
        (e.ownerId ?? '').trim().isNotEmpty &&
        (e.enquiryId ?? '').trim().isNotEmpty;
  }

  void _openDoctorBookingSheet() {
    final e = _e!;
    DoctorAppointmentSheet.open(
      context,
      listing: DoctorAppointmentListing(
        // The enquiry's `listingId` IS `Business._id` — the same id the
        // booking keys on.
        businessId: (e.listingId ?? '').trim(),
        ownerId: (e.ownerId ?? '').trim(),
        doctorName: (e.listingName ?? '').trim(),
        doctorImage: (e.listingImage ?? '').trim(),
        location: (e.location ?? '').trim(),
        // The enquiry record carries no fee, so the sheet's fee notice is
        // simply omitted on this path.
      ),
      enquiryId: (e.enquiryId ?? '').trim(),
    );
  }

  Widget _bookDoctorAppointmentRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: InkWell(
        onTap: _openDoctorBookingSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentDeep, _accent]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_available_rounded,
                  size: 15, color: Colors.white),
              const SizedBox(width: 5),
              CustomText(
                AppStrings.bookAppointment.tr,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookTestRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: InkWell(
        onTap: _openLabBookingSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentDeep, _accent]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.biotech_rounded,
                  size: 15, color: Colors.white),
              const SizedBox(width: 5),
              const Text(
                'Book Test',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One enquiry detail row's data — label, value(s), and its tinted icon.
class _EnquiryRow {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _EnquiryRow(this.title, this.items, this.icon, this.color);
}
