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
import 'package:cached_network_image/cached_network_image.dart';
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

/// One selectable room in the booking sheet — a slim projection of the
/// discover screen's `Rooms` model (see
/// `lib/features/common/Discover/model/hotel_search_model.dart`) so this
/// widget doesn't couple to the search-response shape.
///
/// When the customer picks a room the booking becomes **room-level**
/// (doc §2.1): the id is sent as `room_id`, dates become required, and
/// `roomName`/`roomType`/`pricePerNight` are derived by the server from
/// the Room doc — so we never need to send them ourselves.
class HotelBookingRoomOption {
  final String id;
  final String name;
  final String type;
  final String? image;
  final int? pricePerDay;
  final String? bedType;
  final String? maxOccupancy;

  const HotelBookingRoomOption({
    required this.id,
    required this.name,
    required this.type,
    this.image,
    this.pricePerDay,
    this.bedType,
    this.maxOccupancy,
  });
}

/// Customer-side bottom sheet for the hotel-**booking** flow
/// (`POST /hotel-bookings`). Distinct from [HotelEnquirySheet]: booking
/// carries `checkIn`/`checkOut` dates, `guests` count and a `roomType`
/// choice — the buyer can additionally **Cancel** the resulting card
/// while it's `pending`. See
/// `lib/docs/UI_INTEGRATION_HOTEL_ENQUIRY_BOOKING.md` §2 for the wire
/// shape.
///
/// The sheet does NOT fabricate the in-chat card client-side — the
/// backend auto-creates a `hotel_booking` chat card after the POST
/// succeeds and emits `newHotelBookingReceived`, so the customer's
/// business chat lands the card via socket + history.
///
/// Two levels of booking (doc §2):
///  - **Type-level** — no [roomId]; the customer proposes a free-text
///    room type + optional dates.
///  - **Room-level** — [roomId] pins a specific Room of the hotel; dates
///    become required and the server enforces availability against
///    `Room.totalRooms`. `roomName`/`roomType`/`pricePerNight` are
///    derived from the Room doc by the server (echoed back on the card).
///
/// [enquiryId] is set only when the sheet is opened from an already-
/// accepted hotel-enquiry card (enquiry-first flow, doc §2 intro).
class HotelBookingSheet {
  HotelBookingSheet._();

  static const List<String> _defaultRoomTypes = [
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
  ];

  /// In-memory cache of a hotel's rooms keyed by hotelId.
  ///
  /// Populated by callers that already know the hotel's rooms (e.g. the
  /// discover screen, which received them in the hotel-search response)
  /// so the enquiry-first flow — where the booking sheet is opened from
  /// the chat card, which doesn't itself hold the rooms — can still
  /// render a real room picker instead of the text-chip fallback.
  ///
  /// This is a session cache: it's OK to lose it on app restart. If the
  /// entry is missing when [open] runs, the sheet gracefully falls back
  /// to the [_defaultRoomTypes] chip picker.
  static final Map<String, List<HotelBookingRoomOption>> _roomsCache = {};

  /// Register the rooms for [hotelId] so subsequent [open] calls that
  /// don't pass `availableRooms` can still render the real room picker.
  /// Call this right before triggering the enquiry (discover screen)
  /// or any other pre-booking navigation.
  static void cacheRoomsForHotel(
      String hotelId, List<HotelBookingRoomOption> rooms) {
    final id = hotelId.trim();
    if (id.isEmpty) return;
    if (rooms.isEmpty) {
      _roomsCache.remove(id);
    } else {
      _roomsCache[id] = List.unmodifiable(rooms);
    }
  }

  static void open(
    BuildContext context, {
    required HotelBookingListing listing,
    List<String>? roomTypes,
    String? roomId,
    String? enquiryId,
    List<HotelBookingRoomOption>? availableRooms,
  }) {
    if (listing.ownerId.isEmpty || listing.hotelId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return;
    }
    // Prefer the direct param; otherwise look up the discover-side cache.
    final rooms = (availableRooms != null && availableRooms.isNotEmpty)
        ? availableRooms
        : _roomsCache[listing.hotelId.trim()];

    // Room-level mode is decided either by the explicit `roomId` (caller
    // already picked a room) or, later, by the customer picking one from
    // the rich picker inside the form.
    final preselectedRoomId =
        (roomId != null && roomId.trim().isNotEmpty) ? roomId.trim() : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelBookingForm(
        listing: listing,
        roomTypes: roomTypes ?? _defaultRoomTypes,
        availableRooms: rooms,
        preselectedRoomId: preselectedRoomId,
        onSubmit: (roomType, checkIn, checkOut, guests, note, photoPaths,
                pickedRoomId) =>
            _submit(listing, pickedRoomId ?? preselectedRoomId, enquiryId,
                roomType, checkIn, checkOut, guests, note, photoPaths),
      ),
    );
  }

  static Future<void> _submit(
    HotelBookingListing listing,
    String? roomId,
    String? enquiryId,
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
      roomId: roomId,
      enquiryId: enquiryId,
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
      name: listing.hotelName.isNotEmpty ? listing.hotelName : listing.ownerName,
      profile: listing.coverImage,
      route: AppConstants.route_discover,
    );
  }
}

class _HotelBookingForm extends StatefulWidget {
  final HotelBookingListing listing;

  /// Text-chip fallback labels — shown only when [availableRooms] is
  /// null/empty (no real rooms known for this hotel).
  final List<String> roomTypes;

  /// Actual rooms belonging to the hotel (from the discover search
  /// response, cached by hotelId). When present the sheet shows a rich
  /// picker keyed to real Rooms; selection turns the booking into a
  /// room-level one (doc §2.1).
  final List<HotelBookingRoomOption>? availableRooms;

  /// Room preselected by the caller. When non-null the picker starts
  /// on that room and behaves as room-level from the first frame.
  final String? preselectedRoomId;

  /// Signature carries the pickedRoomId so the parent can send the
  /// right `room_id` when the customer selects a Room from the rich
  /// picker.
  final void Function(
    String? roomType,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String note,
    List<String> photoPaths,
    String? pickedRoomId,
  ) onSubmit;

  const _HotelBookingForm({
    required this.listing,
    required this.roomTypes,
    required this.availableRooms,
    required this.preselectedRoomId,
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
  /// When a real room is picked from [widget.availableRooms] we go
  /// room-level (doc §2.1): server derives roomName/roomType/price from
  /// the Room doc, dates are required.
  String? _pickedRoomId;
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  final List<String> _photos = [];
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickedRoomId = widget.preselectedRoomId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// True when we have a Rooms list to show as a real picker.
  bool get _hasRealRooms =>
      widget.availableRooms != null && widget.availableRooms!.isNotEmpty;

  /// Room-level = the customer (or caller) picked a specific Room.
  bool get _isRoomLevel =>
      _pickedRoomId != null && _pickedRoomId!.trim().isNotEmpty;

  bool get _canSubmit {
    // Server validation is minimal: hotel_id is required (always present
    // from the listing) and `checkOut` must be after `checkIn` when both
    // are given. Type-level bookings can go through with just a note or
    // a room-type pick — matching the loose contract in doc §2.1.
    if (_checkIn != null && _checkOut != null && !_checkOut!.isAfter(_checkIn!)) {
      return false;
    }
    // Room-level bookings (doc §2.1): both dates are required.
    if (_isRoomLevel) {
      return _checkIn != null && _checkOut != null;
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
    final initial =
        isCheckIn ? (_checkIn ?? today) : (_checkOut ?? _checkIn?.add(const Duration(days: 1)) ?? today);
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _submit() {
    Navigator.of(context).pop();
    widget.onSubmit(
      // When a real room is picked, don't send `roomType` — the server
      // ignores it and derives it from the Room doc (doc §2.1). Passing
      // it anyway is harmless but the wire is cleaner without it.
      _isRoomLevel ? null : _roomType,
      _checkIn,
      _checkOut,
      _guests,
      _noteController.text.trim(),
      List<String>.from(_photos),
      _pickedRoomId,
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
                      _eyebrow('${AppStrings.photoLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          _photos.length),
                      const SizedBox(height: 12),
                      _photoSection(),
                      // Show a real Rooms picker when the caller supplied
                      // rooms (doc §2.1 room-level flow). Otherwise fall
                      // back to the free-text room-type chips.
                      if (_hasRealRooms) ...[
                        const SizedBox(height: 22),
                        _eyebrow(
                            'SELECT ROOM', _isRoomLevel ? 1 : 0),
                        const SizedBox(height: 10),
                        _roomsPicker(),
                      ] else ...[
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
                                    onTap: () => setState(
                                        () => _roomType = _roomType == r ? null : r),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _eyebrow(_isRoomLevel ? 'DATES · REQUIRED' : 'DATES', 0),
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
                      if (_checkIn != null && _checkOut != null && !_checkOut!.isAfter(_checkIn!))
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

  /// Horizontal picker of real Rooms belonging to this hotel. Selection
  /// toggles the picked room; tapping the same card again clears it and
  /// drops the booking back to type-level.
  ///
  /// Height picked to fit the image band (78px) + a 3-line text block +
  /// padding without the outer Column trimming a fractional pixel off
  /// the bottom row (the 0.375-px overflow we saw with 148).
  Widget _roomsPicker() {
    final rooms = widget.availableRooms!;
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _roomCard(rooms[i]),
      ),
    );
  }

  Widget _roomCard(HotelBookingRoomOption r) {
    final selected = _pickedRoomId == r.id;
    return InkWell(
      onTap: () => setState(() {
        _pickedRoomId = selected ? null : r.id;
        // A real room implies the server-derived type — clear any
        // fallback text pick so we don't send a stale `roomType`.
        if (!selected) _roomType = null;
      }),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 190,
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
              height: 78,
              child: (r.image != null && r.image!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: r.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _surface),
                      errorWidget: (_, __, ___) => Container(
                        color: _surface,
                        alignment: Alignment.center,
                        child: Icon(Icons.hotel_rounded,
                            color: AppColors.greyCA, size: 22),
                      ),
                    )
                  : Container(
                      color: _surface,
                      alignment: Alignment.center,
                      child: Icon(Icons.hotel_rounded,
                          color: AppColors.greyCA, size: 22),
                    ),
            ),
            // Flexible so if the text column ever runs taller than the
            // remaining space, the last line clips instead of the whole
            // Column throwing a RenderFlex overflow. Belt-and-braces
            // alongside the picker's 156-px height.
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
                            r.name.isNotEmpty ? r.name : r.type,
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
                    if ((r.pricePerDay ?? 0) > 0) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        '₹${r.pricePerDay}/night',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _accentDeep,
                      ),
                    ],
                    if ((r.bedType ?? '').isNotEmpty ||
                        (r.maxOccupancy ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      CustomText(
                        [
                          if ((r.bedType ?? '').isNotEmpty) r.bedType!,
                          if ((r.maxOccupancy ?? '').isNotEmpty)
                            r.maxOccupancy!,
                        ].join(' · '),
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
                    color: value.isEmpty ? AppColors.secondaryTextColor : AppColors.mainTextColor,
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
        child: Icon(icon, size: 16, color: enabled ? _accent : AppColors.greyCA),
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
