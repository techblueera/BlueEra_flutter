import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_enquiry_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snapshot of the laboratory being enquired about. Denormalised into
/// the form (and onto the eventual chat card) so the customer and owner
/// see a header without an extra fetch.
class LabEnquiryListing {
  final String laboratoryId; // LaboratoryProfile._id — required by API
  final String ownerId; // opens the customer↔lab chat
  final String labName;
  final String? labImage;
  final String? location;

  const LabEnquiryListing({
    required this.laboratoryId,
    required this.ownerId,
    required this.labName,
    this.labImage,
    this.location,
  });
}

/// Customer-side laboratory enquiry sheet.
///
/// Kept in the laboratory feature folder (rather than the shared
/// healthcare sheet) so lab-specific tuning — the tests chip pool being
/// derived from the lab's actual catalog, the dedicated `/laboratory-
/// enquiries` producer, per-lab microcopy — can happen without ripple
/// into hospital/pharmacy flows.
class LabEnquirySheet {
  LabEnquirySheet._();

  /// Fallback chip pools. `tests` should ideally be sourced from the
  /// lab's real catalog — callers can pass [tests] to override.
  static const List<String> _defaultTests = [
    'CBC',
    'Lipid Profile',
    'Blood Sugar',
    'Thyroid (TFT)',
    'Liver Function (LFT)',
    'Kidney Function (KFT)',
    'Urine Routine',
    'X-Ray',
    'Ultrasound',
    'Full Body Checkup',
  ];
  static const List<String> _defaultPurpose = [
    'Home sample collection',
    'Visit lab',
    'Report consultation',
    'Price quote',
  ];
  static const List<String> _defaultTimeline = [
    'Today',
    'Tomorrow',
    'Within 2 days',
    'This week',
    'Flexible',
  ];

  /// Open the sheet. Pass [tests] to override the fallback pool with the
  /// lab's actual catalog names.
  static void open(
    BuildContext context, {
    required LabEnquiryListing listing,
    List<String>? tests,
    List<String>? purpose,
    List<String>? timeline,
  }) {
    if (listing.laboratoryId.isEmpty || listing.ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LabEnquiryForm(
        listing: listing,
        tests: tests ?? _defaultTests,
        purpose: purpose ?? _defaultPurpose,
        timeline: timeline ?? _defaultTimeline,
        onSubmit: (t, p, tl, note, photos) =>
            _submit(listing, t, p, tl, note, photos),
      ),
    );
  }

  static Future<void> _submit(
    LabEnquiryListing listing,
    List<String> tests,
    List<String> purpose,
    List<String> timeline,
    String note,
    List<String> photoPaths,
  ) async {
    // Submit FIRST so a POST failure keeps the user on the detail screen
    // with a snackbar instead of stranded on an empty chat. The
    // in-chat card lands over the socket once the backend consumes the
    // Kafka event.
    final controller = getOrPut(() => LabEnquiryController());
    final enquiryId = await controller.submitLaboratoryEnquiry(
      laboratoryId: listing.laboratoryId,
      tests: tests,
      purpose: purpose,
      timeline: timeline,
      note: note,
      photoPaths: photoPaths,
    );
    if (enquiryId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.labName,
      profile: listing.labImage,
      route: AppConstants.route_discover,
    );
  }
}

class _LabEnquiryForm extends StatefulWidget {
  final LabEnquiryListing listing;
  final List<String> tests;
  final List<String> purpose;
  final List<String> timeline;
  final void Function(
    List<String> tests,
    List<String> purpose,
    List<String> timeline,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _LabEnquiryForm({
    required this.listing,
    required this.tests,
    required this.purpose,
    required this.timeline,
    required this.onSubmit,
  });

  @override
  State<_LabEnquiryForm> createState() => _LabEnquiryFormState();
}

class _LabEnquiryFormState extends State<_LabEnquiryForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);

  /// Server caps photos at 5.
  static const int _maxPhotos = 5;

  final Set<String> _selectedTests = <String>{};
  final Set<String> _selectedPurpose = <String>{};
  final Set<String> _selectedTimeline = <String>{};
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggle(Set<String> bucket, String value) {
    setState(() {
      if (!bucket.add(value)) bucket.remove(value);
    });
  }

  bool get _hasSelection =>
      _selectedTests.isNotEmpty ||
      _selectedPurpose.isNotEmpty ||
      _selectedTimeline.isNotEmpty;

  bool get _canSubmit =>
      _hasSelection ||
      _noteController.text.trim().isNotEmpty ||
      _photos.isNotEmpty;

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
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

  void _submit() {
    Navigator.of(context).pop();
    widget.onSubmit(
      _selectedTests.toList(),
      _selectedPurpose.toList(),
      _selectedTimeline.toList(),
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
                          '${AppStrings.photoLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          _photos.length),
                      const SizedBox(height: 12),
                      _photoSection(),
                      const SizedBox(height: 22),
                      _chipGroup(
                        title: 'Tests',
                        options: widget.tests,
                        selected: _selectedTests,
                      ),
                      const SizedBox(height: 20),
                      _chipGroup(
                        title: 'Purpose',
                        options: widget.purpose,
                        selected: _selectedPurpose,
                      ),
                      const SizedBox(height: 20),
                      _chipGroup(
                        title: 'Timeline',
                        options: widget.timeline,
                        selected: _selectedTimeline,
                      ),
                      const SizedBox(height: 20),
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

  Widget _chipGroup({
    required String title,
    required List<String> options,
    required Set<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(title, selected.length),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((s) => _checkChip(
                    label: s,
                    on: selected.contains(s),
                    onTap: () => _toggle(selected, s),
                  ))
              .toList(),
        ),
      ],
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
                  'Laboratory Enquiry',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  'Tell ${widget.listing.labName} what you need',
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
            child: CustomText(
              '$count',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _accent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _checkChip({
    required String label,
    required bool on,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: on ? _accent.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? _accent : AppColors.greyE5,
            width: on ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              size: 16,
              color: on ? _accent : AppColors.greyCA,
            ),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? _accent : AppColors.mainTextColor,
            ),
          ],
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
            children: [
              for (final path in _photos) _photoThumb(path),
            ],
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
          Image.file(
            File(path),
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
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
        height: 110,
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
            Icon(Icons.add_a_photo_outlined, size: 28, color: _accent),
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
                Icon(Icons.send_rounded,
                    size: 18,
                    color: _canSubmit ? Colors.white : AppColors.greyCA),
                const SizedBox(width: 8),
                CustomText(
                  AppStrings.sendEnquiryLabel.tr,
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
