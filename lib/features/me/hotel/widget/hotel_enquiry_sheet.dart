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
import 'package:BlueEra/features/me/hotel/controller/hotel_enquiry_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One selection group on the hotel-enquiry form. Group titles are app-
/// defined and shipped verbatim — the controller maps known titles
/// (Room Type / Purpose / Amenities / Timeline) to the snake-case keys
/// the server expects.
class HotelEnquiryGroup {
  final String title;
  final List<String> options;
  const HotelEnquiryGroup({required this.title, required this.options});
}

/// Snapshot of the hotel being enquired about — denormalised so the sheet
/// header and (later) the in-chat card render without re-fetching the
/// listing.
class HotelEnquiryListing {
  final String hotelId;
  final String ownerId;
  final String ownerName;
  final String hotelName;
  final String? coverImage;
  final String? location;

  const HotelEnquiryListing({
    required this.hotelId,
    required this.ownerId,
    required this.ownerName,
    required this.hotelName,
    this.coverImage,
    this.location,
  });
}

/// Customer-side bottom sheet for the hotel-enquiry flow
/// (`POST hotel-enquiries`). Mirrors the property / healthcare sheet shape
/// — grouped chip selections + optional note + ≤5 photos — then opens the
/// owner's business chat where the backend posts the enquiry card.
class HotelEnquirySheet {
  HotelEnquirySheet._();

  /// Default group catalog covering the common hotel-enquiry asks. Callers
  /// (e.g. the discover screen) can pass their own [groups] to override —
  /// useful when the listing already knows its own amenities.
  static const List<HotelEnquiryGroup> _defaultGroups = [
    HotelEnquiryGroup(title: 'Room Type', options: [
      'Standard',
      'Deluxe',
      'Suite',
      'Family',
      'Twin / Sharing',
    ]),
    HotelEnquiryGroup(title: 'Purpose', options: [
      'Leisure',
      'Business',
      'Event / Function',
      'Long stay',
      'Just checking availability',
    ]),
    HotelEnquiryGroup(title: 'Amenities', options: [
      'Free Wi-Fi',
      'Breakfast included',
      'Pickup / Drop',
      'Pool',
      'Parking',
      'Pet-friendly',
    ]),
    HotelEnquiryGroup(title: 'Timeline', options: [
      'This weekend',
      'Within 2 weeks',
      '1–3 months',
      'Flexible',
    ]),
  ];

  static List<HotelEnquiryGroup> defaultGroups() => _defaultGroups;

  static void open(
    BuildContext context, {
    required HotelEnquiryListing listing,
    List<HotelEnquiryGroup>? groups,
  }) {
    if (listing.ownerId.isEmpty || listing.hotelId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelEnquireForm(
        listing: listing,
        groups: groups ?? _defaultGroups,
        onSubmit: (selections, note, photoPaths) =>
            _submit(listing, selections, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    HotelEnquiryListing listing,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => HotelEnquiryController());
    final enquiryId = await controller.submitHotelEnquiry(
      hotelId: listing.hotelId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (enquiryId == null) return;

    // Re-upload the customer-picked photos via user-service presign so
    // the fabricated chat card carries public URLs (hotel-service stores
    // them but doesn't surface URLs). Failures are silently skipped.
    final photoUrls = await uploadFilesViaUserPresign(photoPaths);

    // Per Docs/backend/hotel-enquiry-card.md (revised 2026-07-01), the
    // chat backend does NOT accept `message_type: "hotel_enquiry"` on
    // `send-message-large-file` today, so the fabricated card is a
    // `service` message tagged `sub_category: "enquiry_only"` — the
    // existing `case "service"` renderer handles it and suppresses the
    // Order Now CTA. Selections + note are flattened into `message`
    // for a legible preview. The rich `hotel_enquiry` metadata / view
    // scaffolding stays in the codebase for when backend support lands.
    //
    // We DO ship `hotel_enquiry_id` alongside the flat params so the
    // owner-side service card can round-trip it via
    // `MessageMetadata.hotelEnquiryId` and expose Accept/Decline
    // buttons that call `HotelEnquiryController.updateHotelEnquiryStatus`.
    final shareParams =
        _buildShareParams(listing, enquiryId, selections, note, photoUrls);
    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.hotelName.isNotEmpty
          ? listing.hotelName
          : listing.ownerName,
      profile: listing.coverImage,
      route: AppConstants.route_discover,
      shareProductParams: shareParams,
      isWithProductSend: true,
    );
  }

  static Map<String, dynamic> _buildShareParams(
    HotelEnquiryListing listing,
    String enquiryId,
    Map<String, List<String>> selections,
    String note,
    List<String> photoUrls,
  ) {
    final urlList = photoUrls.isNotEmpty
        ? [for (final u in photoUrls) {ApiKeys.url: u}]
        : ((listing.coverImage ?? '').isNotEmpty
            ? [
                {ApiKeys.url: listing.coverImage!}
              ]
            : <Map<String, String>>[]);

    // Flatten the chip selections into the message body so the owner can
    // read everything at a glance without parsing nested metadata.
    final lines = <String>[];
    selections.forEach((title, items) {
      if (items.isEmpty) return;
      lines.add('$title: ${items.join(", ")}');
    });
    if (note.trim().isNotEmpty) lines.add('Note: ${note.trim()}');
    final messageBody = lines.isEmpty
        ? 'Hotel enquiry — ${listing.hotelName}'
        : lines.join('\n');

    return <String, dynamic>{
      ApiKeys.service_id: listing.hotelId,
      ApiKeys.price: '',
      ApiKeys.discount: '',
      ApiKeys.message: messageBody,
      ApiKeys.message_type: AppConstants.service,
      ApiKeys.title: listing.hotelName.isNotEmpty
          ? listing.hotelName
          : listing.ownerName,
      // Shared marker the chat-side renderer checks to suppress the
      // Order Now CTA and render the multi-line enquiry body.
      ApiKeys.sub_category: 'enquiry_only',
      // Enquiry id smuggled through the whitelisted `variant` field
      // (`hotelEnquiryId` / `hotel_enquiry_id` are filtered by the
      // backend chat metadata builder — `variant` survives). The
      // owner-side `case "service"` renderer decodes this prefix in
      // `_enquiryIdentity` and shows Accept / Decline. Format:
      // `<kind>|<enquiryId>` (healthcare adds `|<category>`).
      if (enquiryId.isNotEmpty) ApiKeys.variant: 'hotel|$enquiryId',
      ApiKeys.url: urlList,
    };
  }
}

class _HotelEnquireForm extends StatefulWidget {
  final HotelEnquiryListing listing;
  final List<HotelEnquiryGroup> groups;
  final void Function(
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _HotelEnquireForm({
    required this.listing,
    required this.groups,
    required this.onSubmit,
  });

  @override
  State<_HotelEnquireForm> createState() => _HotelEnquireFormState();
}

class _HotelEnquireFormState extends State<_HotelEnquireForm> {
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

  bool _isOn(String title, String s) => _selected[title]?.contains(s) ?? false;
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
                  // ClampingScrollPhysics keeps Android's stretch overscroll
                  // indicator out of this scroll view — the indicator's
                  // scrollEnd handler schedules a setState inside layout,
                  // which trips the framework "Build scheduled during frame"
                  // assertion when this sheet sits over a NestedScrollView
                  // host (e.g. the chat screen).
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
            child: const Icon(Icons.hotel_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.hotelEnquiryTitle.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  AppStrings.tellListingAboutEnquiry.tr
                      .replaceAll('{listing}',
                          widget.listing.hotelName.isNotEmpty
                              ? widget.listing.hotelName
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
