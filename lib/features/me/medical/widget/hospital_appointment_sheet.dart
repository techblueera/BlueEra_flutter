import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/medical/controller/hospital_appointment_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snapshot of the hospital the customer is booking with. Denormalised
/// so the sheet header and (later) the in-chat card render without
/// re-fetching the source listing.
class HospitalAppointmentListing {
  final String hospitalId;
  final String ownerId;
  final String ownerName;
  final String hospitalName;
  final String? coverImage;
  final String? location;

  const HospitalAppointmentListing({
    required this.hospitalId,
    required this.ownerId,
    required this.ownerName,
    required this.hospitalName,
    this.coverImage,
    this.location,
  });
}

/// One selectable doctor in the appointment sheet — slim projection of
/// [OpdDoctor] so this widget doesn't couple to the OPD model.
///
/// The doc §1 requires `opd_id`; everything else on the card (doctor
/// name, department, fees, image) is snapshotted server-side from the
/// OPD record — no need to send them.
class HospitalAppointmentDoctorOption {
  final String id;
  final String name;
  final String? department;
  final int? fees;
  final String? image;
  final String? timing;
  final String? position;

  const HospitalAppointmentDoctorOption({
    required this.id,
    required this.name,
    this.department,
    this.fees,
    this.image,
    this.timing,
    this.position,
  });
}

/// Customer-side bottom sheet for the hospital-**appointment** flow
/// (`POST /hospital-appointments`). Opened from the accepted
/// healthcare-enquiry chat card (enquiry-first flow) — [enquiryId] is
/// threaded through so the resulting booking links back to the enquiry.
///
/// The sheet does NOT fabricate the in-chat card — the backend
/// auto-creates a `healthcare_booking` card after POST succeeds and
/// pushes it via `newHealthcareBookingReceived`.
class HospitalAppointmentSheet {
  HospitalAppointmentSheet._();

  /// In-memory cache of a hospital's doctors keyed by hospitalId.
  ///
  /// Populated by callers that already have the doctor list (e.g. the
  /// hospital-detail screen from discover) so the enquiry-first flow —
  /// where this sheet is opened from a chat card that doesn't itself
  /// hold the doctors — can still render a real picker instead of an
  /// empty state.
  ///
  /// Session cache: OK to lose on app restart; sheet still opens but
  /// shows an empty picker + prompts the customer to go back through
  /// the hospital screen.
  static final Map<String, List<HospitalAppointmentDoctorOption>>
      _doctorsCache = {};

  /// Register the doctors for [hospitalId]. Call this right before
  /// opening the enquiry sheet from the hospital detail screen so the
  /// eventual appointment sheet can find them. Safe to call multiple
  /// times — later calls overwrite the entry.
  static void cacheDoctorsForHospital(
      String hospitalId, List<HospitalAppointmentDoctorOption> doctors) {
    final id = hospitalId.trim();
    if (id.isEmpty) return;
    if (doctors.isEmpty) {
      // Don't blow away a good cache with an empty list — the hospital
      // screen sometimes caches lazily on tap (before the merge lands)
      // and again after merge. Keep whichever list is non-empty.
      if (!_doctorsCache.containsKey(id)) {
        // No prior entry → still record the empty so lookups know we
        // tried; the sheet will fall through to its empty state.
        _doctorsCache[id] = const [];
      }
    } else {
      _doctorsCache[id] = List.unmodifiable(doctors);
    }
    log('[APPOINTMENT] cacheDoctorsForHospital hospitalId=$id '
        'doctors=${doctors.length} (cache size=${_doctorsCache.length})');
  }

  /// Fetches the hospital's OPD doctors on demand when the session cache is
  /// empty — happens when the sheet is opened from the accepted-enquiry chat
  /// card without a prior hospital-screen visit (e.g. cold start, deep link,
  /// notification). Mirrors `discover_hospital_home_screen.dart`'s
  /// `viewBusinessProfileById → HospitalFullData → flatten` pipeline, then
  /// seeds the same session cache used by the discover flow.
  ///
  /// Returns whatever it finds (possibly empty) so the picker can fall
  /// through to its empty state on genuine failure.
  static Future<List<HospitalAppointmentDoctorOption>> _fetchDoctorsForHospital({
    required String hospitalId,
  }) async {
    final key = hospitalId.trim();
    if (key.isEmpty) return const [];
    final cached = _doctorsCache[key];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final res = await BusinessProfileRepo().viewBusinessProfileById(key);
      if (!res.isSuccess) {
        log('[APPOINTMENT] _fetchDoctorsForHospital hospitalId=$key '
            'profile fetch failed: ${res.message}');
        return const [];
      }
      final hospitalJson = _extractHospitalJson(res.response?.data);
      if (hospitalJson == null) {
        log('[APPOINTMENT] _fetchDoctorsForHospital hospitalId=$key '
            'no hospital JSON in profile response');
        return const [];
      }
      final data = HospitalFullData.fromJson(hospitalJson);
      final doctors = _flattenDoctors(data);
      log('[APPOINTMENT] _fetchDoctorsForHospital hospitalId=$key '
          'fetched ${doctors.length} doctor(s)');
      cacheDoctorsForHospital(key, doctors);
      return doctors;
    } catch (e, s) {
      log('[APPOINTMENT] _fetchDoctorsForHospital error hospitalId=$key: $e\n$s');
      return const [];
    }
  }

  /// Field names read by [HospitalFullData.fromJson]. Duplicated from
  /// discover_hospital_home_screen.dart to keep the two flows independent.
  static const _hospitalKeys = <String>[
    '_id',
    'name',
    'description',
    'userId',
    'location',
    'coverUrl',
    'logoUrl',
    'visionMission',
    'history',
    'management',
    'departments',
    'emergencyCare',
    'otherFacilities',
    'emergencyContact',
    'gallery',
    'contacts',
  ];

  /// Builds a flat hospital-JSON map from the business-profile response.
  /// Sections may live at the root, under `data`, or under `vertical_profile`
  /// — pull each key from the first container that carries it. Mirrors the
  /// discover screen's extractor.
  static Map<String, dynamic>? _extractHospitalJson(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    final vp = raw['vertical_profile'];
    final containers = <Map>[
      if (vp is Map && vp['data'] is Map) vp['data'],
      if (vp is Map) vp,
      if (raw['hospital'] is Map) raw['hospital'],
      if (raw['hospitalDetails'] is Map) raw['hospitalDetails'],
      if (data is Map && data['hospital'] is Map) data['hospital'],
      if (data is Map && data['hospitalDetails'] is Map)
        data['hospitalDetails'],
      if (data is Map) data,
      raw,
    ];
    final merged = <String, dynamic>{};
    for (final key in _hospitalKeys) {
      for (final c in containers) {
        if (c.containsKey(key) && c[key] != null) {
          merged[key] = c[key];
          break;
        }
      }
    }
    return merged.isEmpty ? null : merged;
  }

  /// Flattens `departments[].opd[]` into the sheet's slim doctor shape.
  /// Iterates every department (not just `type == 'OPD'`) — the backend
  /// sometimes leaves `type` blank on OPD-only entries.
  static List<HospitalAppointmentDoctorOption> _flattenDoctors(
      HospitalFullData? data) {
    final out = <HospitalAppointmentDoctorOption>[];
    for (final dept in data?.departments ?? const <IpdOpdDepartments>[]) {
      final deptName = (dept.name ?? '').trim();
      for (final doc in dept.opd ?? const <Opd>[]) {
        final id = (doc.id ?? '').trim();
        if (id.isEmpty) continue;
        out.add(HospitalAppointmentDoctorOption(
          id: id,
          name: (doc.name ?? '').trim(),
          department: deptName.isNotEmpty ? deptName : null,
          image: doc.imageUrl,
          timing: doc.timing,
        ));
      }
    }
    return out;
  }

  static void open(
    BuildContext context, {
    required HospitalAppointmentListing listing,
    String? enquiryId,
    String? preselectedDoctorId,
    List<HospitalAppointmentDoctorOption>? availableDoctors,
  }) {
    if (listing.ownerId.isEmpty || listing.hospitalId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    final key = listing.hospitalId.trim();
    final cached = _doctorsCache[key];
    final doctors = (availableDoctors != null && availableDoctors.isNotEmpty)
        ? availableDoctors
        : (cached ?? const <HospitalAppointmentDoctorOption>[]);
    log('[APPOINTMENT] open hospitalId=$key '
        'availableDoctors=${availableDoctors?.length ?? 0} '
        'cachedDoctors=${cached?.length ?? -1} '
        'cacheKeys=${_doctorsCache.keys.toList()}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HospitalAppointmentForm(
        listing: listing,
        doctors: doctors,
        preselectedDoctorId: preselectedDoctorId,
        onSubmit: (opdId, date, preferredTime, patientName, note, photoPaths) =>
            _submit(listing, enquiryId, opdId, date, preferredTime,
                patientName, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    HospitalAppointmentListing listing,
    String? enquiryId,
    String opdId,
    DateTime date,
    String? preferredTime,
    String? patientName,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => HospitalAppointmentController());
    final appointmentId = await controller.submitAppointment(
      hospitalId: listing.hospitalId,
      opdId: opdId,
      // Doc §1: today or later, calendar-day comparison. Send the day
      // at midnight so the server-side calendar-day comparator lands on
      // the intended date regardless of the customer's tz.
      appointmentDate:
          DateTime(date.year, date.month, date.day).toIso8601String(),
      preferredTime: preferredTime,
      patientName: patientName,
      enquiryId: enquiryId,
      note: note,
      photoPaths: photoPaths,
    );
    if (appointmentId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.hospitalName.isNotEmpty
          ? listing.hospitalName
          : listing.ownerName,
      profile: listing.coverImage,
      route: AppConstants.route_discover,
    );
  }
}

class _HospitalAppointmentForm extends StatefulWidget {
  final HospitalAppointmentListing listing;
  final List<HospitalAppointmentDoctorOption> doctors;
  final String? preselectedDoctorId;
  final void Function(
    String opdId,
    DateTime date,
    String? preferredTime,
    String? patientName,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _HospitalAppointmentForm({
    required this.listing,
    required this.doctors,
    required this.preselectedDoctorId,
    required this.onSubmit,
  });

  @override
  State<_HospitalAppointmentForm> createState() =>
      _HospitalAppointmentFormState();
}

class _HospitalAppointmentFormState extends State<_HospitalAppointmentForm> {
  // Palette aligned with the healthcare-enquiry sheet so the booking form
  // reads as the same flow (BlueEra primary + deep-blue accent).
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const int _maxPhotos = 5;

  String? _pickedOpdId;
  DateTime? _date;
  // Preferred time is now a required 24-hour value. Two pickers back an
  // optional range — start is required; end is optional so a
  // point-in-time slot ("10:00") is also valid.
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _patientNameController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _photos = [];

  /// Local mutable copy so an on-demand fetch (empty session cache) can
  /// update the picker without rebuilding the whole sheet.
  late List<HospitalAppointmentDoctorOption> _doctors;
  bool _isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _pickedOpdId = widget.preselectedDoctorId;
    _doctors = widget.doctors;
    _applyAutoSelect();

    // Session cache miss (enquiry-first flow entered from anywhere other
    // than the hospital detail screen — chat inbox on cold start, deep
    // link, notification) → fetch on demand so the picker isn't stuck on
    // the empty state.
    if (_doctors.isEmpty && widget.listing.hospitalId.trim().isNotEmpty) {
      _loadDoctors();
    }
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoadingDoctors = true);
    final fetched = await HospitalAppointmentSheet._fetchDoctorsForHospital(
      hospitalId: widget.listing.hospitalId,
    );
    if (!mounted) return;
    setState(() {
      _doctors = fetched;
      _isLoadingDoctors = false;
      _applyAutoSelect();
    });
  }

  /// Preselect the single doctor case — nothing else the customer could
  /// pick. Called after the initial widget doctors are set AND after an
  /// on-demand fetch lands.
  void _applyAutoSelect() {
    if (_pickedOpdId == null && _doctors.length == 1) {
      _pickedOpdId = _doctors.first.id;
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    // Doc §1 requires opd_id + appointmentDate (hospital_id is on the
    // listing). We additionally require preferredTime here per the
    // product ask — no ambiguous "any time" bookings.
    return _pickedOpdId != null &&
        _pickedOpdId!.trim().isNotEmpty &&
        _date != null &&
        _startTime != null;
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: true,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() => _photos.add(path));
  }

  void _removePhoto(String path) => setState(() => _photos.remove(path));

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final initial = _date ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  /// Open a 24-hour time picker. Same shape as the school availability
  /// form's `_pickTime` — default dial input, no forced text-entry — but
  /// wraps the child in a `MediaQuery` override so the picker always
  /// renders 24-hour regardless of the device locale. Output is
  /// formatted downstream via [_fmt24] as `HH:mm`.
  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
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
    final picked = await _pickTime(
      _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startTime = picked;
      // If end < start after the change, clear it so we don't ship a
      // nonsense range like "14:00 – 10:00".
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
              ? TimeOfDay(
                  hour: (start.hour + 1) % 24,
                  minute: start.minute,
                )
              : const TimeOfDay(hour: 11, minute: 0)),
    );
    if (picked == null || !mounted) return;
    if (start != null && _minutesOf(picked) <= _minutesOf(start)) {
      commonSnackBar(message: 'End time must be after start time');
      return;
    }
    setState(() => _endTime = picked);
  }

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  /// `HH:mm` — 24-hour, always two-digit. Independent of device locale.
  String _fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Human-readable label for the tile. Empty when nothing picked yet.
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
    Navigator.of(context).pop();
    widget.onSubmit(
      _pickedOpdId!,
      _date!,
      // 24-hour range string per doc §1 (`preferredTime` is free text).
      _fmtRange(),
      _patientNameController.text.trim().isEmpty
          ? null
          : _patientNameController.text.trim(),
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
                      _eyebrow('SELECT DOCTOR · REQUIRED',
                          _pickedOpdId == null ? 0 : 1),
                      const SizedBox(height: 10),
                      _doctorsPicker(),
                      const SizedBox(height: 22),
                      _eyebrow('APPOINTMENT DATE · REQUIRED', 0),
                      const SizedBox(height: 10),
                      _dateTile(),
                      const SizedBox(height: 22),
                      _eyebrow(
                          'PREFERRED TIME · REQUIRED',
                          _startTime != null ? 1 : 0),
                      const SizedBox(height: 10),
                      _timeRangeTile(),
                      const SizedBox(height: 22),
                      _eyebrow(
                          'PATIENT NAME · ${AppStrings.optionalLabel.tr}',
                          0),
                      const SizedBox(height: 10),
                      _plainField(
                        controller: _patientNameController,
                        hint: 'Who is the appointment for?',
                      ),
                      const SizedBox(height: 22),
                      _eyebrow(
                          '${AppStrings.photoLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          _photos.length),
                      const SizedBox(height: 10),
                      _photoSection(),
                      const SizedBox(height: 22),
                      _eyebrow(
                          '${AppStrings.noteLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          0),
                      const SizedBox(height: 10),
                      _noteField(),
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
                  'Book Appointment',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  widget.listing.hospitalName.isNotEmpty
                      ? widget.listing.hospitalName
                      : widget.listing.ownerName,
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
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.secondaryTextColor,
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

  /// Horizontal picker of real Doctors belonging to this hospital.
  /// Tapping the same card again clears the selection. While the on-demand
  /// fetch is in flight (cache miss), a slim loader replaces the picker so
  /// the customer isn't tricked into thinking the hospital has no doctors.
  Widget _doctorsPicker() {
    if (_isLoadingDoctors) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _accentDeep),
            ),
            const SizedBox(width: 10),
            CustomText(
              'Loading doctors…',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      );
    }
    if (_doctors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5),
        ),
        alignment: Alignment.center,
        child: CustomText(
          'No doctors available — please open the hospital screen and try again.',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
          maxLines: 3,
        ),
      );
    }
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _doctors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _doctorCard(_doctors[i]),
      ),
    );
  }

  Widget _doctorCard(HospitalAppointmentDoctorOption d) {
    final selected = _pickedOpdId == d.id;
    return InkWell(
      onTap: () => setState(
          () => _pickedOpdId = selected ? null : d.id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : AppColors.greyE5,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 88,
              child: (d.image != null && d.image!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: d.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _surface),
                      errorWidget: (_, __, ___) => Container(
                        color: _surface,
                        alignment: Alignment.center,
                        child: Icon(Icons.person_rounded,
                            color: AppColors.greyCA, size: 26),
                      ),
                    )
                  : Container(
                      color: _surface,
                      alignment: Alignment.center,
                      child: Icon(Icons.person_rounded,
                          color: AppColors.greyCA, size: 26),
                    ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            d.name,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: _accent),
                      ],
                    ),
                    if ((d.department ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        d.department!,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if ((d.fees ?? 0) > 0) ...[
                      const SizedBox(height: 3),
                      CustomText(
                        '₹${d.fees}',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _accentDeep,
                      ),
                    ],
                    if ((d.timing ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      CustomText(
                        d.timing!,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            const Icon(Icons.calendar_month_rounded,
                size: 20, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                _fmtDate(_date).isEmpty ? 'Pick a date' : _fmtDate(_date),
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

  /// Two side-by-side pickers for start / end (end optional). Both stamp
  /// their value in `HH:mm` — the picker itself is forced to 24-hour via
  /// [_pickTime] so no locale-driven AM/PM ever leaks in.
  Widget _timeRangeTile() {
    return Row(
      children: [
        Expanded(child: _timeCell(
          label: 'From',
          value: _startTime == null ? null : _fmt24(_startTime!),
          onTap: _pickStartTime,
        )),
        const SizedBox(width: 10),
        Expanded(child: _timeCell(
          label: 'To',
          value: _endTime == null ? null : _fmt24(_endTime!),
          onTap: _pickEndTime,
          enabled: _startTime != null,
        )),
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
              const Icon(Icons.access_time_rounded,
                  size: 20, color: _accent),
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

  Widget _plainField({
    required TextEditingController controller,
    required String hint,
  }) {
    return CommonTextField(
      textEditController: controller,
      hintText: hint,
      isValidate: false,
      onChange: (_) => setState(() {}),
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
          border: Border.all(
              color: _accent.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 26, color: _accent),
            const SizedBox(height: 6),
            CustomText(AppStrings.photoLabel.tr,
                fontSize: 13, fontWeight: FontWeight.w800, color: _accent),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return CommonTextField(
      textEditController: _noteController,
      hintText: AppStrings.noteLabel.tr,
      maxLine: 4,
      minLines: 2,
      isValidate: false,
      onChange: (_) => setState(() {}),
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
                  'Book Appointment',
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
