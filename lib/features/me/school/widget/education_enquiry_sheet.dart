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
import 'package:BlueEra/features/me/school/controller/education_enquiry_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One selection group on the education-enquiry form. Titles are
/// app-defined; the controller maps known display titles (Courses /
/// Admission For / Requirements / Timeline) to the snake-case keys the
/// server expects, and ships unknown titles verbatim.
class EducationEnquiryGroup {
  final String title;
  final List<String> options;
  const EducationEnquiryGroup({required this.title, required this.options});
}

/// Snapshot of the education listing (school/college) being enquired
/// about. Denormalised so the sheet header — and the eventual in-chat
/// card — renders without re-fetching the listing.
class EducationEnquiryListing {
  final String listingId;
  final String ownerId;
  final String ownerName;
  final String listingName;
  final String? listingImage;
  final String? location;

  const EducationEnquiryListing({
    required this.listingId,
    required this.ownerId,
    required this.ownerName,
    required this.listingName,
    this.listingImage,
    this.location,
  });
}

/// Customer-side bottom sheet for the education-enquiry flow
/// (`POST education-enquiries`). Mirrors the hotel / healthcare sheets:
/// grouped chip selections + optional note + ≤5 photos, then opens the
/// owner's business chat where the backend posts the enquiry card.
class EducationEnquirySheet {
  EducationEnquirySheet._();

  static const List<EducationEnquiryGroup> _defaultGroups = [
    EducationEnquiryGroup(title: 'Courses', options: [
      'Pre-Primary / KG',
      'Primary',
      'Secondary',
      'Higher Secondary',
      'Undergraduate',
      'Postgraduate',
      'Diploma / Certificate',
      'Coaching / Tuition',
    ]),
    EducationEnquiryGroup(title: 'Admission For', options: [
      'My child',
      'Myself',
      'Sibling',
      'Other',
    ]),
    EducationEnquiryGroup(title: 'Requirements', options: [
      'Fee details',
      'Course / curriculum details',
      'Campus visit',
      'Admission process',
      'Scholarship / financial aid',
      'Hostel / transport',
    ]),
    EducationEnquiryGroup(title: 'Timeline', options: [
      'Immediate',
      'This term',
      'Next academic year',
      'Flexible',
    ]),
  ];

  static List<EducationEnquiryGroup> defaultGroups() => _defaultGroups;

  static void open(
    BuildContext context, {
    required EducationEnquiryListing listing,
    List<EducationEnquiryGroup>? groups,
  }) {
    if (listing.ownerId.isEmpty || listing.listingId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EducationEnquireForm(
        listing: listing,
        groups: groups ?? _defaultGroups,
        onSubmit: (selections, note, photoPaths) =>
            _submit(listing, selections, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    EducationEnquiryListing listing,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => EducationEnquiryController());
    final ok = await controller.submitEducationEnquiry(
      listingId: listing.listingId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (!ok) return;

    // Upload the customer-picked photos to S3 so they can land as URLs
    // on the in-chat card. The controller's own multipart submit above
    // sent the same files to education-service, but those URLs aren't
    // surfaced back to us — uploading once more via the shared
    // user-service presign helper is the cheapest way to get URLs the
    // chat card can render. Photos that fail to upload are silently
    // skipped.
    final photoUrls = await uploadFilesViaUserPresign(photoPaths);

    // Mirror the Book Home Service redirect: build a chat-message payload
    // from the just-submitted enquiry and pass it to
    // checkChatConnectionAndOpenChat with isWithProductSend:true so the
    // message lands in the in-memory list BEFORE we navigate — the chat
    // opens already populated. Same approach as every ask_*_msg_card.dart
    // in lib/features/chat/view/ai_chat/widget/.
    //
    // education-service's own async card-creation may also fire; if it
    // lands the conversation simply holds both. We prefer a duplicate
    // over an empty screen.
    final shareParams = _buildShareParams(listing, selections, note, photoUrls);
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

  /// Chat-service send-message payload for an education enquiry. Shape
  /// mirrors `ask_home_service_msg_card.dart` so the existing chat
  /// renderer (case "service" in [MessageCard]) treats it as a service
  /// card. [photoUrls] are the customer's uploaded inquiry photos
  /// (rendered on the card); we fall back to the listing image when
  /// no photos were attached so the card isn't blank.
  static Map<String, dynamic> _buildShareParams(
    EducationEnquiryListing listing,
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
        ? 'Education enquiry — ${listing.listingName}'
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
      // 'enquiry_only' marker — see VehicleEnquirySheet and
      // lib/features/chat/view/widget/message_card.dart for the contract.
      ApiKeys.sub_category: 'enquiry_only',
      ApiKeys.url: urlList,
    };
  }
}

class _EducationEnquireForm extends StatefulWidget {
  final EducationEnquiryListing listing;
  final List<EducationEnquiryGroup> groups;
  final void Function(
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _EducationEnquireForm({
    required this.listing,
    required this.groups,
    required this.onSubmit,
  });

  @override
  State<_EducationEnquireForm> createState() =>
      _EducationEnquireFormState();
}

class _EducationEnquireFormState extends State<_EducationEnquireForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const int _maxPhotos = 5;

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

  bool _isOn(String title, String s) =>
      _selected[title]?.contains(s) ?? false;
  int _countFor(String title) => _selected[title]?.length ?? 0;
  bool get _hasSelection => _selected.values.any((s) => s.isNotEmpty);
  bool get _canSubmit =>
      _hasSelection ||
      _noteController.text.trim().isNotEmpty ||
      _photos.isNotEmpty;

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
                  // scroll view so it can't fire setState during layout.
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
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.educationEnquiryTitle.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  AppStrings.tellListingAboutEnquiry.tr
                      .replaceAll('{listing}',
                          widget.listing.listingName.isNotEmpty
                              ? widget.listing.listingName
                              : widget.listing.ownerName),
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
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _accent),
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
