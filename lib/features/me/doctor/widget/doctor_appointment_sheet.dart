import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_booking_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snapshot of the doctor being booked, so the sheet header renders without
/// re-fetching the listing.
///
/// [businessId] is `Business._id` — the id the appointment keys on. Passing
/// `DoctorProfile._id` here returns `404 "Doctor listing not found"`; they are
/// different id spaces (guide §6.3).
class DoctorAppointmentListing {
  final String businessId;

  /// `Business.user_id` — the doctor's own user id, used to open the chat.
  final String ownerId;
  final String doctorName;
  final String? doctorImage;
  final String? location;

  /// Display only — "You will be charged ₹600/Visit at the clinic". There is
  /// no payment in this flow; do not wire a gateway to it (guide §6.4).
  final String? feeLabel;

  const DoctorAppointmentListing({
    required this.businessId,
    required this.ownerId,
    required this.doctorName,
    this.doctorImage,
    this.location,
    this.feeLabel,
  });
}

/// Customer-side bottom sheet for the standalone-doctor booking flow
/// (`POST hospital-service/doctor-appointments`).
///
/// This is NOT [HospitalAppointmentSheet] with the hospital bits removed: that
/// sheet is built around picking an OPD doctor out of a hospital's department
/// list, and a standalone doctor has no OPD record and no departments, so
/// there is nothing to pick — the doctor IS the listing (guide §3.3). The
/// layout is deliberately the same so the two booking flows read alike.
///
/// Opened from two places:
///   • the doctor's public profile — direct booking, no [enquiryId]
///   • an accepted DOCTOR enquiry chat card — [enquiryId] links the booking
///     back to that enquiry
///
/// The sheet does NOT fabricate the in-chat card. The backend auto-creates a
/// `healthcare_booking` card after the POST succeeds and pushes it over the
/// socket; this only opens the conversation so the customer lands on it.
class DoctorAppointmentSheet {
  DoctorAppointmentSheet._();

  static void open(
    BuildContext context, {
    required DoctorAppointmentListing listing,
    String? enquiryId,
  }) {
    if (listing.businessId.trim().isEmpty || listing.ownerId.trim().isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorAppointmentForm(
        listing: listing,
        onSubmit: (date, preferredTime, patientName, note, photoPaths) =>
            _submit(listing, enquiryId, date, preferredTime, patientName, note,
                photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    DoctorAppointmentListing listing,
    String? enquiryId,
    DateTime date,
    String? preferredTime,
    String? patientName,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => DoctorBookingController());
    final appointmentId = await controller.submitAppointment(
      businessId: listing.businessId,
      // Midnight local, so the server's calendar-day comparator lands on the
      // day the customer actually tapped regardless of their timezone.
      appointmentDate:
          DateTime(date.year, date.month, date.day).toIso8601String(),
      preferredTime: preferredTime,
      patientName: patientName,
      enquiryId: enquiryId,
      note: note,
      photoPaths: photoPaths,
    );
    // null = the POST failed and already surfaced its own message. Opening the
    // chat here would imply the booking landed.
    if (appointmentId == null) return;

    // Land the customer on the business conversation with the doctor, where
    // the server-created booking card appears. `route_discover` forces the
    // BUSINESS lane — without it an existing personal thread with the same
    // user would win and the booking card would be in the other conversation.
    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.doctorName,
      profile: listing.doctorImage,
      route: AppConstants.route_discover,
    );
  }
}

class _DoctorAppointmentForm extends StatefulWidget {
  final DoctorAppointmentListing listing;
  final void Function(
    DateTime date,
    String? preferredTime,
    String? patientName,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _DoctorAppointmentForm({
    required this.listing,
    required this.onSubmit,
  });

  @override
  State<_DoctorAppointmentForm> createState() => _DoctorAppointmentFormState();
}

class _DoctorAppointmentFormState extends State<_DoctorAppointmentForm> {
  // Same palette as the hospital sheet and the healthcare enquiry sheet, so
  // all three booking surfaces read as one flow.
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const int _maxPhotos = 5;

  /// Guide §8: ≤10 MB each, enforced client-side.
  static const int _maxPhotoBytes = 10 * 1024 * 1024;

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _patientNameController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _photos = [];

  @override
  void dispose() {
    _patientNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Only the date gates submission. `preferredTime` is optional here (unlike
  /// the hospital sheet, which requires it to disambiguate an OPD slot) — a
  /// standalone doctor's visiting hours are shown as guidance, and the doctor
  /// confirms the actual time when accepting.
  bool get _canSubmit => _date != null;

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: true,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    // Reject oversized files here rather than at upload: a 12 MB report only
    // fails after the whole multipart body has been sent, and the booking is
    // lost with it.
    final file = File(path);
    if (file.existsSync() && await file.length() > _maxPhotoBytes) {
      if (!mounted) return;
      commonSnackBar(message: AppStrings.doctorImageTooLarge.tr);
      return;
    }
    if (!mounted) return;
    setState(() => _photos.add(path));
  }

  void _removePhoto(String path) => setState(() => _photos.remove(path));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _date ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      // Past dates are unselectable — the server also rejects them with 400.
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  /// Forced to 24-hour regardless of device locale so [_fmt24] and the value
  /// the customer saw always agree.
  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _pickStartTime() async {
    final picked =
        await _pickTime(_startTime ?? const TimeOfDay(hour: 10, minute: 0));
    if (picked == null || !mounted) return;
    setState(() {
      _startTime = picked;
      // Clear a now-inverted end so we never ship "14:00 – 10:00".
      if (_endTime != null && _minutesOf(_endTime!) <= _minutesOf(picked)) {
        _endTime = null;
      }
    });
  }

  Future<void> _pickEndTime() async {
    final start = _startTime;
    final picked = await _pickTime(
      _endTime ??
          (start != null
              ? TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute)
              : const TimeOfDay(hour: 11, minute: 0)),
    );
    if (picked == null || !mounted) return;
    if (start != null && _minutesOf(picked) <= _minutesOf(start)) {
      commonSnackBar(message: AppStrings.doctorEndTimeError.tr);
      return;
    }
    setState(() => _endTime = picked);
  }

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  String _fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Empty when nothing is picked — the caller then sends no `preferredTime`.
  String _fmtRange() {
    if (_startTime == null) return '';
    final start = _fmt24(_startTime!);
    if (_endTime == null) return start;
    return '$start – ${_fmt24(_endTime!)}';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop();
    final range = _fmtRange();
    final patient = _patientNameController.text.trim();
    widget.onSubmit(
      _date!,
      range.isEmpty ? null : range,
      patient.isEmpty ? null : patient,
      _noteController.text.trim(),
      List<String>.from(_photos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _header(),
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _eyebrow(
                        '${AppStrings.doctorAppointmentDate.tr} · ${AppStrings.requiredLabel.tr}',
                        0,
                      ),
                      const SizedBox(height: 10),
                      _dateTile(),
                      const SizedBox(height: 22),
                      _eyebrow(
                        '${AppStrings.doctorPreferredTime.tr} · ${AppStrings.optionalLabel.tr}',
                        _startTime != null ? 1 : 0,
                      ),
                      const SizedBox(height: 10),
                      _timeRangeTile(),
                      const SizedBox(height: 22),
                      _eyebrow(
                        '${AppStrings.doctorPatientNameLabel.tr} · ${AppStrings.optionalLabel.tr}',
                        0,
                      ),
                      const SizedBox(height: 10),
                      CommonTextField(
                        textEditController: _patientNameController,
                        hintText: AppStrings.doctorPatientNameHint.tr,
                        isValidate: false,
                        onChange: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 22),
                      _eyebrow(
                        '${AppStrings.photoLabel.tr} · ${AppStrings.optionalLabel.tr}',
                        _photos.length,
                      ),
                      const SizedBox(height: 10),
                      _photoSection(),
                      const SizedBox(height: 22),
                      _eyebrow(
                        '${AppStrings.noteLabel.tr} · ${AppStrings.optionalLabel.tr}',
                        0,
                      ),
                      const SizedBox(height: 10),
                      CommonTextField(
                        textEditController: _noteController,
                        hintText: AppStrings.noteLabel.tr,
                        maxLine: 4,
                        minLines: 2,
                        isValidate: false,
                        onChange: (_) => setState(() {}),
                      ),
                      if ((widget.listing.feeLabel ?? '').isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _feeNotice(),
                      ],
                    ],
                  ),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentDeep, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.bookAppointment.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  widget.listing.doctorName.isNotEmpty
                      ? widget.listing.doctorName
                      : AppStrings.doctorDiscoverFallbackName.tr,
                  fontSize: 12.5,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label, int count) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: CustomText('$count',
                fontSize: 10, fontWeight: FontWeight.w800, color: _accent),
          ),
        ],
      ],
    );
  }

  Widget _dateTile() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 20, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                _date == null ? AppStrings.doctorPickDate.tr : _fmtDate(_date),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _date == null
                    ? AppColors.secondaryTextColor
                    : AppColors.mainTextColor,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _timeRangeTile() {
    return Row(
      children: [
        Expanded(
          child: _timeCell(
            label: AppStrings.from.tr,
            value: _startTime == null ? null : _fmt24(_startTime!),
            onTap: _pickStartTime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _timeCell(
            label: AppStrings.toLabel.tr,
            value: _endTime == null ? null : _fmt24(_endTime!),
            onTap: _pickEndTime,
            enabled: _startTime != null,
          ),
        ),
      ],
    );
  }

  Widget _timeCell({
    required String label,
    required String? value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final unset = value == null || value.isEmpty;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyE5),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 20, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      label,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      unset ? '--:--' : value,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: unset
                          ? AppColors.secondaryTextColor
                          : AppColors.mainTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_photos.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final path in _photos) _photoThumb(path)],
          ),
          const SizedBox(height: 10),
        ],
        if (_photos.length < _maxPhotos) _addPhotoButton(),
      ],
    );
  }

  Widget _photoThumb(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.file(File(path), width: 92, height: 92, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removePhoto(path),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoButton() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: _accent.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 26, color: _accent),
            const SizedBox(height: 6),
            CustomText(AppStrings.doctorAddPhoto.tr,
                fontSize: 13, fontWeight: FontWeight.w800, color: _accent),
          ],
        ),
      ),
    );
  }

  /// Display-only fee line. Nothing is charged in-app — the customer pays at
  /// the clinic (guide §6.4).
  Widget _feeNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: _accentDeep),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              AppStrings.doctorFeeNoticeFmt
                  .trParams({'fee': widget.listing.feeLabel ?? ''}),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _accentDeep,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.greyE5, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: _canSubmit ? _submit : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _canSubmit
                  ? const LinearGradient(colors: [_accentDeep, _accent])
                  : null,
              color: _canSubmit ? null : AppColors.greyE5,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _canSubmit
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_rounded,
                    size: 18,
                    color: _canSubmit ? Colors.white : AppColors.greyCA),
                const SizedBox(width: 8),
                CustomText(
                  AppStrings.bookAppointment.tr,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _canSubmit ? Colors.white : AppColors.greyCA,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
