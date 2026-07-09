import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_booking_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snapshot of the laboratory being booked with. Denormalised so the
/// sheet header (and the eventual chat card) renders without a fetch.
class LabBookingListing {
  final String laboratoryId; // LaboratoryProfile._id — required by API
  final String ownerId; // opens the customer↔lab chat after submit
  final String labName;
  final String? labImage;
  final String? location;

  const LabBookingListing({
    required this.laboratoryId,
    required this.ownerId,
    required this.labName,
    this.labImage,
    this.location,
  });
}

/// One selectable test in the picker — slim projection of [PathologyTest]
/// so the widget doesn't couple to the model tree. Server-side snapshots
/// name/price/reportHours from the `PathologyTest._id`, so only `id` is
/// mandatory on the wire.
class LabBookingTestOption {
  final String id;
  final String name;
  final int? price;
  final int? reportHours;
  final String? category;

  const LabBookingTestOption({
    required this.id,
    required this.name,
    this.price,
    this.reportHours,
    this.category,
  });

  factory LabBookingTestOption.fromPathology(PathologyTest t) =>
      LabBookingTestOption(
        id: (t.id ?? '').trim(),
        name: (t.testName ?? '').trim(),
        price: t.customerPrice,
        reportHours: t.estimatedReportHours,
        category: t.collection,
      );
}

/// Customer-side bottom sheet for the lab-**booking** flow
/// (`POST /laboratory-bookings`). Opened from:
///   • the accepted `healthcare_enquiry` chat card on a LABORATORY
///     enquiry (enquiry-first flow — `enquiryId` is threaded through), or
///   • a direct "Book Test" CTA on the lab detail screen.
///
/// The sheet does not fabricate the in-chat card — the backend produces
/// `CREATE_HEALTHCARE_BOOKING` after POST succeeds.
class LabBookingSheet {
  LabBookingSheet._();

  /// Session cache of a lab's tests, keyed by laboratoryId. Filled by
  /// callers that already have the catalog (e.g. the lab detail screen)
  /// so the enquiry-first flow — where the sheet is opened from a chat
  /// card that doesn't itself hold the tests — can still render a real
  /// picker instead of an empty state.
  static final Map<String, List<LabBookingTestOption>> _testsCache = {};

  static void cacheTestsForLab(
      String laboratoryId, List<LabBookingTestOption> tests) {
    final id = laboratoryId.trim();
    if (id.isEmpty) return;
    if (tests.isEmpty) {
      // Don't blow away a good cache with an empty list.
      if (!_testsCache.containsKey(id)) _testsCache[id] = const [];
    } else {
      _testsCache[id] = List.unmodifiable(tests);
    }
    log('[LAB_BOOKING] cacheTestsForLab labId=$id '
        'tests=${tests.length} (cache size=${_testsCache.length})');
  }

  /// On-demand fetch for the enquiry-first flow (cold start from a chat
  /// card): hits `getPathologyTestsByLab(labId, '')` and maps into the
  /// slim option shape.
  static Future<List<LabBookingTestOption>> _fetchTestsForLab({
    required String laboratoryId,
  }) async {
    final key = laboratoryId.trim();
    if (key.isEmpty) return const [];
    final cached = _testsCache[key];
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final res = await LabTestRepo().getPathologyTestsByLab(key, '');
      if (!res.isSuccess) {
        log('[LAB_BOOKING] _fetchTestsForLab labId=$key '
            'failed: ${res.message}');
        return const [];
      }
      final data = res.response?.data;
      final list = (data is Map ? data['data'] : null);
      if (list is! List) return const [];
      final options = list
          .whereType<Map>()
          .map((m) => LabBookingTestOption.fromPathology(
              PathologyTest.fromJson(Map<String, dynamic>.from(m))))
          .where((o) => o.id.isNotEmpty)
          .toList();
      cacheTestsForLab(key, options);
      return options;
    } catch (e, s) {
      log('[LAB_BOOKING] _fetchTestsForLab error labId=$key: $e\n$s');
      return const [];
    }
  }

  static void open(
    BuildContext context, {
    required LabBookingListing listing,
    String? enquiryId,
    String? preselectedTestId,
    List<LabBookingTestOption>? availableTests,
  }) {
    if (listing.ownerId.isEmpty || listing.laboratoryId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    final key = listing.laboratoryId.trim();
    final cached = _testsCache[key];
    final tests = (availableTests != null && availableTests.isNotEmpty)
        ? availableTests
        : (cached ?? const <LabBookingTestOption>[]);
    log('[LAB_BOOKING] open labId=$key '
        'availableTests=${availableTests?.length ?? 0} '
        'cachedTests=${cached?.length ?? -1}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LabBookingForm(
        listing: listing,
        tests: tests,
        preselectedTestId: preselectedTestId,
        onSubmit: (t, date, time, mode, address, patient, note, photos) =>
            _submit(listing, enquiryId, t, date, time, mode, address,
                patient, note, photos),
      ),
    );
  }

  static Future<void> _submit(
    LabBookingListing listing,
    String? enquiryId,
    String testId,
    DateTime date,
    String preferredTime,
    String collectionMode,
    String? address,
    String? patientName,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => LabBookingController());
    final bookingId = await controller.submitLabBooking(
      laboratoryId: listing.laboratoryId,
      testId: testId,
      // Send the date at midnight local so the server-side calendar-day
      // comparator lands on the intended day regardless of the customer's
      // tz. Same convention the hospital appointment flow uses.
      appointmentDate:
          DateTime(date.year, date.month, date.day).toIso8601String(),
      preferredTime: preferredTime,
      collectionMode: collectionMode,
      address: address,
      patientName: patientName,
      enquiryId: enquiryId,
      note: note,
      photoPaths: photoPaths,
    );
    if (bookingId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.labName,
      profile: listing.labImage,
      route: AppConstants.route_discover,
    );
  }
}

class _LabBookingForm extends StatefulWidget {
  final LabBookingListing listing;
  final List<LabBookingTestOption> tests;
  final String? preselectedTestId;
  final void Function(
    String testId,
    DateTime date,
    String preferredTime,
    String collectionMode,
    String? address,
    String? patientName,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _LabBookingForm({
    required this.listing,
    required this.tests,
    required this.preselectedTestId,
    required this.onSubmit,
  });

  @override
  State<_LabBookingForm> createState() => _LabBookingFormState();
}

class _LabBookingFormState extends State<_LabBookingForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const int _maxPhotos = 5;

  String? _pickedTestId;
  DateTime? _date;
  TimeOfDay? _time;
  String _collectionMode = 'AT_LAB'; // doc default
  final _addressController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _photos = [];

  late List<LabBookingTestOption> _tests;
  bool _isLoadingTests = false;

  @override
  void initState() {
    super.initState();
    _pickedTestId = widget.preselectedTestId;
    _tests = widget.tests;
    _applyAutoSelect();

    if (_tests.isEmpty && widget.listing.laboratoryId.trim().isNotEmpty) {
      _loadTests();
    }
  }

  Future<void> _loadTests() async {
    setState(() => _isLoadingTests = true);
    final fetched = await LabBookingSheet._fetchTestsForLab(
      laboratoryId: widget.listing.laboratoryId,
    );
    if (!mounted) return;
    setState(() {
      _tests = fetched;
      _isLoadingTests = false;
      _applyAutoSelect();
    });
  }

  void _applyAutoSelect() {
    if (_pickedTestId == null && _tests.length == 1) {
      _pickedTestId = _tests.first.id;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _patientNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isHome => _collectionMode == 'HOME';

  bool get _canSubmit {
    if (_pickedTestId == null || _pickedTestId!.trim().isEmpty) return false;
    if (_date == null) return false;
    if (_time == null) return false;
    if (_isHome && _addressController.text.trim().isEmpty) return false;
    return true;
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

  /// 24-hour dial time picker — same shape the hospital appointment
  /// sheet uses. `MediaQuery` override forces the picker into 24-hour
  /// regardless of device locale so the emitted `preferredTime` is
  /// always `HH:mm`, matching the server regex.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  String _fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
      _pickedTestId!,
      _date!,
      _fmt24(_time!),
      _collectionMode,
      _isHome ? _addressController.text.trim() : null,
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
                      _eyebrow('SELECT TEST · REQUIRED',
                          _pickedTestId == null ? 0 : 1),
                      const SizedBox(height: 10),
                      _testsPicker(),
                      const SizedBox(height: 22),
                      _eyebrow('COLLECTION MODE · REQUIRED', 1),
                      const SizedBox(height: 10),
                      _collectionModeToggle(),
                      if (_isHome) ...[
                        const SizedBox(height: 22),
                        _eyebrow('ADDRESS · REQUIRED',
                            _addressController.text.trim().isEmpty ? 0 : 1),
                        const SizedBox(height: 10),
                        _plainField(
                          controller: _addressController,
                          hint: 'Home address for sample collection',
                        ),
                      ],
                      const SizedBox(height: 22),
                      _eyebrow('APPOINTMENT DATE · REQUIRED',
                          _date == null ? 0 : 1),
                      const SizedBox(height: 10),
                      _dateTile(),
                      const SizedBox(height: 22),
                      _eyebrow('PREFERRED TIME · REQUIRED',
                          _time == null ? 0 : 1),
                      const SizedBox(height: 10),
                      _timeTile(),
                      const SizedBox(height: 22),
                      _eyebrow(
                          'PATIENT NAME · ${AppStrings.optionalLabel.tr}',
                          0),
                      const SizedBox(height: 10),
                      _plainField(
                        controller: _patientNameController,
                        hint: 'Who is the test for?',
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
            child: const Icon(Icons.biotech_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Book Test',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  widget.listing.labName,
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

  Widget _testsPicker() {
    if (_isLoadingTests) {
      return _pickerSurface(
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
              'Loading tests…',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      );
    }
    if (_tests.isEmpty) {
      return _pickerSurface(
        child: CustomText(
          "This lab hasn't listed any tests yet — please open the lab profile and try again.",
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
          textAlign: TextAlign.center,
          maxLines: 3,
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tests.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _testCard(_tests[i]),
      ),
    );
  }

  Widget _pickerSurface({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _testCard(LabBookingTestOption t) {
    final selected = _pickedTestId == t.id;
    return InkWell(
      onTap: () => setState(
          () => _pickedTestId = selected ? null : t.id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 220,
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    t.name.isEmpty ? 'Test' : t.name,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: _accent),
              ],
            ),
            if ((t.category ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              CustomText(
                t.category!,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            Row(
              children: [
                if (t.price != null)
                  CustomText(
                    '₹${t.price}',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _accentDeep,
                  ),
                if (t.price != null && (t.reportHours ?? 0) > 0)
                  const SizedBox(width: 8),
                if ((t.reportHours ?? 0) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green00.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      '${t.reportHours}h',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green00,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectionModeToggle() {
    Widget cell(String value, IconData icon, String label) {
      final on = _collectionMode == value;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _collectionMode = value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: on ? _accent.withValues(alpha: 0.10) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: on ? _accent : AppColors.greyE5,
                width: on ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: on ? _accent : AppColors.greyCA),
                const SizedBox(width: 6),
                CustomText(
                  label,
                  fontSize: 12.5,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? _accent : AppColors.mainTextColor,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('AT_LAB', Icons.storefront_rounded, 'At Lab'),
        const SizedBox(width: 10),
        cell('HOME', Icons.home_rounded, 'Home Sample'),
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

  Widget _timeTile() {
    final unset = _time == null;
    return InkWell(
      onTap: _pickTime,
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
            const Icon(Icons.access_time_rounded, size: 20, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                unset ? 'Pick a time (24-hour)' : _fmt24(_time!),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: unset
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
                  'Book Test',
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
