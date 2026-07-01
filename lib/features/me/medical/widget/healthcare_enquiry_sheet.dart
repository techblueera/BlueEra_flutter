import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/utils/photo_presign_uploader.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/medical/controller/healthcare_enquiry_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One selection group on the healthcare enquiry form. Lives at the top level
/// so callers building category-specific groups don't reach into private
/// types. [title] is what the user (and the in-chat card) sees as the
/// section label; the same string is sent back to the server as the
/// selections-map key so the card can render it verbatim.
class HealthcareEnquiryGroup {
  final String title;
  final List<String> options;

  const HealthcareEnquiryGroup({
    required this.title,
    required this.options,
  });
}

/// Snapshot of the listing being enquired about. Denormalised into the form
/// (and onto the eventual chat card) so the customer / owner sees a header
/// without an extra fetch. Pass the same values whether the listing is a
/// Hospital (HOSPITAL category) or a Business (any non-hospital category).
class HealthcareEnquiryListing {
  final String listingId;
  final String ownerId;
  final String ownerName;
  final String listingName;
  final String? listingImage;
  final String? location;

  const HealthcareEnquiryListing({
    required this.listingId,
    required this.ownerId,
    required this.ownerName,
    required this.listingName,
    this.listingImage,
    this.location,
  });
}

/// Customer-side enquiry sheet for the **unified healthcare flow**. One
/// parameterized sheet covers every category because the doc settles on a
/// single card / event contract — the only thing that varies per category is
/// the [groups] list ("Departments / Purpose / Timeline" for hospitals,
/// "Test Types / Purpose" for labs, etc.). See
/// `lib/docs/healthcare-enquiry-ui-integration.md`.
///
/// The sheet drives the [HealthcareEnquiryController], which branches between
/// the hospital and business endpoints under the hood, then opens the
/// business chat with the owner — the backend posts the enquiry card into
/// that conversation, so we never seed any chat text.
class HealthcareEnquirySheet {
  HealthcareEnquirySheet._();

  /// Default group catalogs for each known healthcare category. Optional
  /// helper — callers that want a different layout per listing can pass
  /// their own [groups] to [open] directly. Keys are matched
  /// case-insensitively against the canonical category strings used on the
  /// chat card (HOSPITAL / DOCTOR / LAB / PHARMACY / SURGICAL).
  static const Map<String, List<HealthcareEnquiryGroup>> _defaultGroups = {
    'HOSPITAL': [
      HealthcareEnquiryGroup(title: 'Departments', options: [
        'Cardiology',
        'Orthopedics',
        'Neurology',
        'Pediatrics',
        'Gynecology',
        'General Medicine',
        'Dermatology',
        'ENT',
      ]),
      HealthcareEnquiryGroup(title: 'Purpose', options: [
        'Consultation',
        'Admission / IPD',
        'Surgery',
        'Emergency',
        'Second opinion',
      ]),
      HealthcareEnquiryGroup(title: 'Timeline', options: [
        'Today',
        'This week',
        'Within 15 days',
        'Flexible',
      ]),
    ],
    'DOCTOR': [
      HealthcareEnquiryGroup(title: 'Specialization', options: [
        'General Physician',
        'Cardiologist',
        'Orthopedic',
        'Pediatrician',
        'Gynecologist',
        'Dermatologist',
        'ENT',
        'Psychiatrist',
      ]),
      HealthcareEnquiryGroup(title: 'Purpose', options: [
        'Consultation',
        'Follow-up',
        'Second opinion',
        'Prescription refill',
      ]),
      HealthcareEnquiryGroup(title: 'Timeline', options: [
        'Today',
        'This week',
        'Within 15 days',
        'Flexible',
      ]),
    ],
    'LAB': [
      HealthcareEnquiryGroup(title: 'Test Types', options: [
        'Blood Test',
        'Urine Test',
        'X-Ray',
        'MRI',
        'CT Scan',
        'Ultrasound',
        'ECG',
        'Full Body Checkup',
      ]),
      HealthcareEnquiryGroup(title: 'Purpose', options: [
        'Home collection',
        'Visit lab',
        'Report consultation',
      ]),
    ],
    'PHARMACY': [
      HealthcareEnquiryGroup(title: 'Product Type', options: [
        'Prescription medicine',
        'OTC medicine',
        'Surgical / Wellness',
        'Ayurvedic',
        'Baby / Mother care',
      ]),
      HealthcareEnquiryGroup(title: 'Purpose', options: [
        'Home delivery',
        'Visit pharmacy',
        'Check availability',
        'Price quote',
      ]),
    ],
    'SURGICAL': [
      HealthcareEnquiryGroup(title: 'Product Type', options: [
        'Equipment',
        'Disposables',
        'Implants',
        'Diagnostic devices',
      ]),
      HealthcareEnquiryGroup(title: 'Purpose', options: [
        'Bulk order',
        'Price quote',
        'Catalog request',
      ]),
    ],
  };

  /// Lookup default groups for [category]. Returns an empty list for unknown
  /// categories so the sheet still opens (caller likely passed [groups]
  /// explicitly in that case).
  static List<HealthcareEnquiryGroup> defaultGroupsFor(String category) =>
      _defaultGroups[category.toUpperCase()] ?? const [];

  /// Open the enquiry sheet. [category] is the canonical category string
  /// (HOSPITAL / DOCTOR / LAB / PHARMACY / SURGICAL / … — anything not
  /// equal to HOSPITAL routes through the non-hospital business endpoint).
  /// [groups] defaults to [defaultGroupsFor] but callers can override.
  static void open(
    BuildContext context, {
    required String category,
    required HealthcareEnquiryListing listing,
    List<HealthcareEnquiryGroup>? groups,
  }) {
    if (listing.ownerId.isEmpty || listing.listingId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    final effectiveGroups =
        groups ?? defaultGroupsFor(category);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HealthcareEnquireForm(
        listing: listing,
        groups: effectiveGroups,
        onSubmit: (selections, note, photoPaths) =>
            _submit(category, listing, selections, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    String category,
    HealthcareEnquiryListing listing,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => HealthcareEnquiryController());
    final enquiryId = await controller.submitHealthcareEnquiry(
      category: category,
      listingId: listing.listingId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (enquiryId == null) return;

    // Re-upload the customer-picked photos via user-service presign so
    // the fabricated chat card carries public URLs (hospital-service /
    // business-enquiries store them but don't surface the URLs).
    // Failures are silently skipped.
    final photoUrls = await uploadFilesViaUserPresign(photoPaths);

    // Per Docs/backend/healthcare-enquiry-card.md (revised 2026-07-01),
    // the chat backend does NOT accept
    // `message_type: "healthcare_enquiry"` on `send-message-large-file`
    // today, so the fabricated card is a `service` message tagged
    // `sub_category: "enquiry_only"`.
    //
    // We DO ship `healthcare_enquiry_id` + `category` alongside the
    // flat params so the owner-side service card can round-trip them
    // via `MessageMetadata.healthcareEnquiryId` and expose Accept/
    // Decline buttons that call
    // `HealthcareEnquiryController.updateHealthcareEnquiryStatus`
    // (which branches HOSPITAL vs business by category).
    final shareParams = _buildShareParams(
        category, listing, enquiryId, selections, note, photoUrls);
    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.listingName.isNotEmpty
          ? listing.listingName
          : listing.ownerName,
      profile: listing.listingImage,
      route: AppConstants.route_discover,
      shareProductParams: shareParams,
      isWithProductSend: true,
    );
  }

  static Map<String, dynamic> _buildShareParams(
    String category,
    HealthcareEnquiryListing listing,
    String enquiryId,
    Map<String, List<String>> selections,
    String note,
    List<String> photoUrls,
  ) {
    final urlList = photoUrls.isNotEmpty
        ? [for (final u in photoUrls) {ApiKeys.url: u}]
        : ((listing.listingImage ?? '').isNotEmpty
            ? [
                {ApiKeys.url: listing.listingImage!}
              ]
            : <Map<String, String>>[]);

    final lines = <String>[];
    selections.forEach((title, items) {
      if (items.isEmpty) return;
      lines.add('$title: ${items.join(", ")}');
    });
    if (note.trim().isNotEmpty) lines.add('Note: ${note.trim()}');
    final messageBody = lines.isEmpty
        ? 'Healthcare enquiry — ${listing.listingName}'
        : lines.join('\n');

    return <String, dynamic>{
      ApiKeys.service_id: listing.listingId,
      ApiKeys.price: '',
      ApiKeys.discount: '',
      ApiKeys.message: messageBody,
      ApiKeys.message_type: AppConstants.service,
      ApiKeys.title: listing.listingName.isNotEmpty
          ? listing.listingName
          : listing.ownerName,
      // Shared marker the chat-side renderer checks to suppress the
      // Order Now CTA and render the multi-line enquiry body.
      ApiKeys.sub_category: 'enquiry_only',
      // Enquiry id + category smuggled through the whitelisted
      // `variant` field — the backend chat metadata builder drops
      // `healthcare_enquiry_id` / `category` but preserves `variant`.
      // Format: `hc|<category>|<enquiryId>`. The owner-side
      // `case "service"` renderer decodes this in `_enquiryIdentity`
      // and routes Accept / Decline via
      // `HealthcareEnquiryController.updateHealthcareEnquiryStatus`
      // (which branches HOSPITAL vs business by category).
      if (enquiryId.isNotEmpty)
        ApiKeys.variant: 'hc|${category.isEmpty ? '-' : category}|$enquiryId',
      ApiKeys.url: urlList,
    };
  }
}

class _HealthcareEnquireForm extends StatefulWidget {
  final HealthcareEnquiryListing listing;
  final List<HealthcareEnquiryGroup> groups;
  final void Function(
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _HealthcareEnquireForm({
    required this.listing,
    required this.groups,
    required this.onSubmit,
  });

  @override
  State<_HealthcareEnquireForm> createState() => _HealthcareEnquireFormState();
}

class _HealthcareEnquireFormState extends State<_HealthcareEnquireForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);

  /// Server caps photos at 5 (see §1 "Rules" in the integration guide).
  static const int _maxPhotos = 5;

  // Selection state keyed by the group's display title (which is also the
  // selections-map key sent to the server).
  final Map<String, Set<String>> _selected = {};
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggle(String groupTitle, String value) {
    setState(() {
      final set = _selected.putIfAbsent(groupTitle, () => <String>{});
      if (!set.add(value)) set.remove(value);
    });
  }

  bool _isOn(String groupTitle, String value) =>
      _selected[groupTitle]?.contains(value) ?? false;

  int _countFor(String groupTitle) => _selected[groupTitle]?.length ?? 0;

  bool get _hasSelection => _selected.values.any((s) => s.isNotEmpty);

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
    final selections = <String, List<String>>{};
    _selected.forEach((title, set) {
      if (set.isNotEmpty) selections[title] = set.toList();
    });
    final note = _noteController.text.trim();
    Navigator.of(context).pop();
    widget.onSubmit(selections, note, List<String>.from(_photos));
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
                  // See [HotelEnquirySheet] for the rationale: keeps
                  // Android's stretch overscroll indicator out of this
                  // scroll view so it can't fire setState during layout
                  // when the sheet sits over a NestedScrollView host.
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
                      for (final group in widget.groups) ...[
                        _eyebrow(group.title, _countFor(group.title)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: group.options
                              .map((s) => _checkChip(
                                    label: s,
                                    on: _isOn(group.title, s),
                                    onTap: () => _toggle(group.title, s),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
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
                  AppStrings.healthcareEnquiry.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  AppStrings.tellListingAboutEnquiry.tr
                      .replaceAll('{listing}', widget.listing.ownerName),
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
