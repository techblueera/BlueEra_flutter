import 'dart:io';

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
      AppStrings.hotelRoomStandard,
      AppStrings.hotelRoomEconomy,
      AppStrings.hotelRoomDeluxe,
      AppStrings.hotelRoomSuperDeluxe,
      AppStrings.hotelRoomPremium,
      AppStrings.hotelRoomExecutive,
      AppStrings.hotelRoomFamily,
      AppStrings.hotelRoomSuite,
      AppStrings.hotelRoomLuxurySuite,
      AppStrings.hotelRoomStudio
    ]),
    HotelEnquiryGroup(title: 'Purpose', options: [
      'Leisure',
      'Business',
      'Event / Function',
      'Long stay',
      'Just checking availability',
    ]),
    // 'Hotel Amenities' and 'Room Amenities' are appended at runtime
    // from the hotel-amenities / room-amenities APIs — see
    // [_HotelEnquireFormState.initState].
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
        onSubmit: (selections, note, photoPaths) => _submit(listing, selections, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    HotelEnquiryListing listing,
    Map<String, List<String>> selections,
    String note,
    List<String> photoPaths,
  ) async {
    // Enquiry POST FIRST. Gating navigation on the POST result means
    // (1) failures keep the customer on the detail screen with a
    // snackbar instead of stranded on an empty chat; (2) `AppLoader`
    // blocks the detail screen, not the chat; (3) by the time we
    // navigate, the backend has already accepted the enquiry so the
    // real `hotel_enquiry` card lands over the socket
    // (`newHotelEnquiryReceived`) shortly after.
    final controller = getOrPut(() => HotelEnquiryController());
    final enquiryId = await controller.submitHotelEnquiry(
      hotelId: listing.hotelId,
      selections: selections,
      note: note,
      photoPaths: photoPaths,
    );
    if (enquiryId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.hotelName.isNotEmpty ? listing.hotelName : listing.ownerName,
      profile: listing.coverImage,
      route: AppConstants.route_discover,
    );
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

  static const String _hotelAmenitiesTitle = 'Hotel Amenities';
  static const String _roomAmenitiesTitle = 'Room Amenities';

  final Map<String, Set<String>> _selected = {};
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  // Populated async from the hotel-amenities / room-amenities APIs.
  // Empty lists (fetch failed or backend returned nothing) simply skip
  // the section — the sheet stays usable.
  List<String> _hotelAmenityOptions = const [];

  @override
  void initState() {
    super.initState();
    _loadAmenityCatalogs();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAmenityCatalogs() async {
    final controller = getOrPut(() => HotelEnquiryController());
    final results = await Future.wait([
      controller.fetchHotelAmenityKeys(),
    ]);
    if (!mounted) return;
    setState(() {
      _hotelAmenityOptions = results[0];
    });
  }

  /// `freeParking` → `Free Parking`, `wifi` → `Wifi`, `24x7Frontdesk` →
  /// `24x7 Frontdesk`. Backend-defined keys ship in mixed casing so we
  /// normalise them here rather than hardcoding a mapping.
  String _humanizeKey(String key) {
    if (key.isEmpty) return key;
    final withSpaces = key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    return withSpaces
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
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
  bool get _canSubmit => _hasSelection || _noteController.text.trim().isNotEmpty || _photos.isNotEmpty;

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
                      _eyebrow('${AppStrings.photoLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
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
                      _amenityGroup(_hotelAmenitiesTitle, _hotelAmenityOptions),
                      _eyebrow(
                          '${AppStrings.noteLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}', 0),
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
            child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 22),
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
                  AppStrings.tellListingAboutEnquiry.tr.replaceAll(
                      '{listing}',
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
              child: Icon(Icons.close_rounded, size: 18, color: AppColors.secondaryTextColor),
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
            child: CustomText('$count', fontSize: 10, fontWeight: FontWeight.w800, color: _accent),
          ),
        ],
      ],
    );
  }

  /// Renders a dynamic amenity section — keeps raw backend keys as the
  /// selection value (so the enquiry POST stays canonical) while showing
  /// humanized labels in the chip.
  Widget _amenityGroup(String title, List<String> options) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(title, _countFor(title)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in options)
                _checkChip(
                  label: _humanizeKey(key),
                  on: _isOn(title, key),
                  onTap: () => _toggle(title, key),
                ),
            ],
          ),
        ],
      ),
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
              on ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
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
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
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
          border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 28, color: _accent),
            const SizedBox(height: 6),
            CustomText(AppStrings.photoLabel.tr, fontSize: 13, fontWeight: FontWeight.w800, color: _accent),
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
              gradient: _canSubmit ? const LinearGradient(colors: [_accentDeep, _accent]) : null,
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
                Icon(Icons.send_rounded, size: 18, color: _canSubmit ? Colors.white : AppColors.greyCA),
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
