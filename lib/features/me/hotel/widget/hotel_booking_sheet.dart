import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_booking_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snapshot of the hotel being booked — denormalised so the sheet header
/// and (later) the in-chat card render without re-fetching the listing.
class HotelBookingListing {
  final String hotelId;
  final String ownerId;
  final String ownerName;
  final String hotelName;
  final String? coverImage;
  final String? location;

  const HotelBookingListing({
    required this.hotelId,
    required this.ownerId,
    required this.ownerName,
    required this.hotelName,
    this.coverImage,
    this.location,
  });
}

/// Customer-side bottom sheet for the hotel-**booking** flow
/// (`POST /hotel-bookings`). Distinct from [HotelEnquirySheet]: booking
/// carries `checkIn`/`checkOut` dates, `guests` count and a `roomType`
/// choice — the buyer can additionally **Cancel** the resulting card
/// while it's `pending`. See `lib/docs/enquiry-flows-ui-integration.md`
/// §2b for the wire shape.
///
/// The sheet does NOT fabricate the in-chat card client-side — the
/// backend auto-creates a `hotel_booking` chat card after the POST
/// succeeds and emits `newHotelBookingReceived`, so the customer's
/// business chat lands the card via socket + history.
class HotelBookingSheet {
  HotelBookingSheet._();

  static const List<String> _defaultRoomTypes = [
    'Standard',
    'Deluxe',
    'Suite',
    'Family',
    'Twin / Sharing',
  ];

  static void open(
    BuildContext context, {
    required HotelBookingListing listing,
    List<String>? roomTypes,
  }) {
    if (listing.ownerId.isEmpty || listing.hotelId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelBookingForm(
        listing: listing,
        roomTypes: roomTypes ?? _defaultRoomTypes,
        onSubmit: (roomType, checkIn, checkOut, guests, note, photoPaths) =>
            _submit(
                listing, roomType, checkIn, checkOut, guests, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    HotelBookingListing listing,
    String? roomType,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String note,
    List<String> photoPaths,
  ) async {
    final controller = getOrPut(() => HotelBookingController());
    final bookingId = await controller.submitHotelBooking(
      hotelId: listing.hotelId,
      roomType: roomType,
      checkIn: checkIn?.toIso8601String(),
      checkOut: checkOut?.toIso8601String(),
      guests: guests,
      note: note,
      photoPaths: photoPaths,
    );
    if (bookingId == null) return;

    final chatViewController = getOrPut(() => ChatViewController());
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: listing.ownerId,
      name: listing.hotelName.isNotEmpty
          ? listing.hotelName
          : listing.ownerName,
      profile: listing.coverImage,
      route: AppConstants.route_discover,
    );
  }
}

class _HotelBookingForm extends StatefulWidget {
  final HotelBookingListing listing;
  final List<String> roomTypes;
  final void Function(
    String? roomType,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String note,
    List<String> photoPaths,
  ) onSubmit;

  const _HotelBookingForm({
    required this.listing,
    required this.roomTypes,
    required this.onSubmit,
  });

  @override
  State<_HotelBookingForm> createState() => _HotelBookingFormState();
}

class _HotelBookingFormState extends State<_HotelBookingForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);
  static const int _maxPhotos = 5;

  String? _roomType;
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    // Server validation is minimal: hotel_id is required (always present
    // from the listing) and `checkOut` must be after `checkIn` when both
    // are given. The sheet lets the user submit with just a note or a
    // room-type pick too — matching the "loose" contract in §2b.
    if (_checkIn != null && _checkOut != null && !_checkOut!.isAfter(_checkIn!)) {
      return false;
    }
    return _roomType != null ||
        _checkIn != null ||
        _checkOut != null ||
        _noteController.text.trim().isNotEmpty ||
        _photos.isNotEmpty;
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

  Future<void> _pickDate({required bool isCheckIn}) async {
    final today = DateTime.now();
    final initial = isCheckIn
        ? (_checkIn ?? today)
        : (_checkOut ?? _checkIn?.add(const Duration(days: 1)) ?? today);
    final minDate = isCheckIn ? today : (_checkIn ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(minDate) ? minDate : initial,
      firstDate: minDate,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        // Push checkOut forward if it now precedes the new check-in.
        if (_checkOut != null && !_checkOut!.isAfter(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    // Short, locale-independent form so it renders identically to the
    // in-chat card's date row.
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _submit() {
    Navigator.of(context).pop();
    widget.onSubmit(
      _roomType,
      _checkIn,
      _checkOut,
      _guests,
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
                      _eyebrow('ROOM TYPE', _roomType == null ? 0 : 1),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.roomTypes
                            .map((r) => _checkChip(
                                  label: r,
                                  on: _roomType == r,
                                  onTap: () =>
                                      setState(() => _roomType = _roomType == r ? null : r),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                      _eyebrow('DATES', 0),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dateTile(
                              label: AppStrings.checkInLabel.tr,
                              value: _fmtDate(_checkIn),
                              onTap: () => _pickDate(isCheckIn: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dateTile(
                              label: AppStrings.checkOutLabel.tr,
                              value: _fmtDate(_checkOut),
                              onTap: () => _pickDate(isCheckIn: false),
                            ),
                          ),
                        ],
                      ),
                      if (_checkIn != null &&
                          _checkOut != null &&
                          !_checkOut!.isAfter(_checkIn!))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: CustomText(
                            'Check-out must be after check-in',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      const SizedBox(height: 22),
                      _eyebrow('GUESTS', _guests),
                      const SizedBox(height: 10),
                      _guestStepper(),
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
            child: const Icon(Icons.hotel_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.hotelBookingTitle.tr,
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

  Widget _dateTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
            const Icon(Icons.calendar_month_rounded, size: 18, color: _accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    label,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    value.isEmpty ? '—' : value,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: value.isEmpty
                        ? AppColors.secondaryTextColor
                        : AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, size: 18, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              '$_guests ${_guests == 1 ? 'guest' : 'guests'}',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
          _stepperBtn(
            icon: Icons.remove_rounded,
            onTap: _guests > 1 ? () => setState(() => _guests--) : null,
          ),
          const SizedBox(width: 8),
          _stepperBtn(
            icon: Icons.add_rounded,
            onTap: _guests < 20 ? () => setState(() => _guests++) : null,
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppColors.greyE5,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? _accent : AppColors.greyE5,
            width: 1.2,
          ),
        ),
        child: Icon(icon,
            size: 16, color: enabled ? _accent : AppColors.greyCA),
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
                  AppStrings.bookNow.tr,
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
