import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_booking_models.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Customer-side bottom sheet for the vehicle-booking flow
/// (`POST /vehicles/bookings`) styled to match the unified enquiry sheets
/// (Hotel / Education / Healthcare). Same REST contract as the legacy
/// [VehiclePlaceOrderSheet] — intent is mandatory, offer price is shown
/// only for BUY / EXCHANGE, note + ≤5 photos are optional — but the
/// header, chip language and Send Enquiry CTA now read as an *enquiry*,
/// not a checkout. See `lib/docs/enquiry-flows-ui-integration.md` §1.
///
/// After a successful POST the backend persists the booking and
/// auto-creates the `vehicle_booking` chat card; the sheet opens the
/// buyer↔seller business chat where that card lands, so the buyer sees
/// their request and the seller's accept/decline in one place.
class VehicleEnquirySheet {
  VehicleEnquirySheet._();

  /// Opens the sheet for [vehicle]. The sheet pops on submit; the [open]
  /// future resolves once the chat has been opened (or the sheet was
  /// dismissed without submitting).
  static Future<void> open(BuildContext context, {required Vehicle vehicle}) {
    final ownerId = (vehicle.userId ?? '').trim();
    if (ownerId.isEmpty || (vehicle.id ?? '').trim().isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return Future.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehicleEnquireForm(vehicle: vehicle),
    );
  }
}

class _VehicleEnquireForm extends StatefulWidget {
  final Vehicle vehicle;
  const _VehicleEnquireForm({required this.vehicle});

  @override
  State<_VehicleEnquireForm> createState() => _VehicleEnquireFormState();
}

class _VehicleEnquireFormState extends State<_VehicleEnquireForm> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _surface = Color(0xFFF4F6FA);

  /// Server caps photos at 5 (see §"Notes for the chat card widget" in
  /// the integration guide). The legacy place-order sheet allowed 10 but
  /// the chat-card contract is the authoritative cap.
  static const int _maxPhotos = 5;

  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  VehicleBookingIntent _intent = VehicleBookingIntent.buy;
  final _offerController = TextEditingController();
  final _noteController = TextEditingController();

  // Local file paths picked from the device; uploaded to S3 on submit.
  final List<String> _photoPaths = [];
  bool _isSubmitting = false;

  /// Offer price only makes sense for BUY / EXCHANGE — for TEST_DRIVE /
  /// INFO the buyer isn't proposing a number. Mirrors the rule from the
  /// legacy place-order sheet so the wire payload stays identical.
  bool get _offerVisible =>
      _intent == VehicleBookingIntent.buy ||
      _intent == VehicleBookingIntent.exchange;

  bool get _canSubmit => !_isSubmitting;

  @override
  void dispose() {
    _offerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= _maxPhotos) return;
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.photoLabel.tr,
      isOnlyCamera: true,
      isGallery: true,
    );
    if (path == null || path.isEmpty || !mounted) return;
    setState(() => _photoPaths.add(path));
  }

  void _removePhoto(String path) =>
      setState(() => _photoPaths.remove(path));

  /// Client-side card fabrication: `POST /vehicles/bookings` returns the
  /// booking record but does not itself push a chat message to the
  /// buyer↔seller thread. So after the POST succeeds the sheet sends a
  /// `vehicle_booking` chat message carrying the booking metadata; the
  /// chat backend persists it (see `_overlayFabricatedEnquiryMetadata` in
  /// chat_view_controller.dart:2562 for the paired echo-safety patch)
  /// and emits `newVehicleBookingReceived` to the seller. Shape mirrors
  /// what `_buildVehicleBookingView` (message_card.dart) reads:
  /// `metadata.booking` + `metadata.vehicleBookingId` (the enquiry_id).
  Map<String, dynamic> _buildBookingMetadata(VehicleBooking b) {
    final snap = b.snapshot;
    return {
      'vehicleBookingId': b.id,
      'booking': {
        '_id': b.id,
        'buyerId': b.buyerId,
        'sellerId': b.sellerId,
        'sellerType': b.sellerType,
        'inventoryId': b.inventoryId,
        'variantId': b.variantId,
        'intent': b.intent.wire,
        'offerPrice': b.offerPrice,
        'note': b.note,
        'photos': b.photos,
        if (snap != null)
          'snapshot': {
            'title': snap.title,
            'image': snap.image,
            'priceText': snap.priceText,
            'condition': snap.condition,
            'location': snap.location,
          },
        'status': b.status.wire,
        'created_at': b.createdAt?.toIso8601String(),
        'updated_at': b.updatedAt?.toIso8601String(),
      },
    };
  }

  Future<void> _submit() async {
    final inventoryId = (widget.vehicle.id ?? '').trim();
    if (inventoryId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // Upload any photos to S3 first — the booking endpoint wants public
      // URLs in the body, not multipart files. Failures are silently
      // skipped so the enquiry still goes through with the photos that
      // did upload (mirrors the legacy sheet's behaviour).
      final photoUrls = <String>[];
      for (final path in _photoPaths) {
        final url = await _ctrl.uploadFile(File(path));
        if (url != null && url.isNotEmpty) photoUrls.add(url);
      }
      final offer = _offerVisible
          ? double.tryParse(_offerController.text.trim().replaceAll(',', ''))
          : null;
      log('[ENQUIRY] vehicle submit → POST vehicle-service/vehicles/bookings '
          'inventoryId=$inventoryId intent=${_intent.wire} '
          'offerPrice=$offer photos=${photoUrls.length} '
          'note="${_noteController.text.trim()}"');
      final booking = await _ctrl.placeBooking(
        inventoryId: inventoryId,
        intent: _intent,
        offerPrice: offer,
        note: _noteController.text,
        photos: photoUrls,
      );
      log('[ENQUIRY] vehicle response: '
          'bookingId=${booking?.id} status=${booking?.status.wire}');
      if (booking == null || !mounted) return;
      // Pop the sheet before navigating so the chat is the new top route.
      Navigator.of(context).pop();
      commonSnackBar(message: AppStrings.bookingRequestSent.tr);
      final targetUserId = (widget.vehicle.userId ?? '').trim();
      if (targetUserId.isEmpty) return;

      // Fabricate the `vehicle_booking` chat card: send a chat message
      // whose `message_type` + `metadata` match what
      // `_buildVehicleBookingView` reads, so the shared EnquiryMsgCard
      // renders on both sides. `checkChatConnectionAndOpenChat` handles
      // the "which conversation?" resolution and the message send.
      final shareParams = <String, dynamic>{
        ApiKeys.message: AppStrings.vehicleBookingTitle.tr,
        ApiKeys.message_type: 'vehicle_booking',
        ApiKeys.metadata: _buildBookingMetadata(booking),
      };
      final chat = getOrPut(() => ChatViewController());
      await chat.checkChatConnectionAndOpenChat(
        userId: targetUserId,
        name: widget.vehicle.name.trim().isNotEmpty
            ? widget.vehicle.name.trim()
            : null,
        profile: (widget.vehicle.coverImage ?? '').trim().isNotEmpty
            ? widget.vehicle.coverImage
            : null,
        route: AppConstants.route_discover,
        shareProductParams: shareParams,
        isWithProductSend: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                          AppStrings.bookingIntentLabel.tr.toUpperCase(),
                          _intent == VehicleBookingIntent.buy ? 0 : 1),
                      const SizedBox(height: 10),
                      _intentChips(),
                      const SizedBox(height: 20),
                      if (_offerVisible) ...[
                        _eyebrow(
                            AppStrings.bookingOfferOptionalLabel.tr
                                .toUpperCase(),
                            _offerController.text.trim().isNotEmpty ? 1 : 0),
                        const SizedBox(height: 10),
                        _offerField(),
                        const SizedBox(height: 20),
                      ],
                      _eyebrow(
                          '${AppStrings.photoLabel.tr.toUpperCase()} · ${AppStrings.optionalLabel.tr}',
                          _photoPaths.length),
                      const SizedBox(height: 12),
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
    final vehicleName = widget.vehicle.name.trim();
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
            child: const Icon(Icons.directions_car_filled_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.vehicleBookingTitle.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  AppStrings.tellListingAboutEnquiry.tr
                      .replaceAll('{listing}',
                          vehicleName.isNotEmpty
                              ? vehicleName
                              : AppStrings.vehicleBookingTitle.tr),
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

  /// Intent is single-select (the API only accepts one), so picking a
  /// chip clears the previous selection rather than toggling.
  Widget _intentChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VehicleBookingIntent.values
          .map((intent) => _intentChip(intent))
          .toList(),
    );
  }

  Widget _intentChip(VehicleBookingIntent intent) {
    final on = _intent == intent;
    return InkWell(
      onTap: () => setState(() => _intent = intent),
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
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: on ? _accent : AppColors.greyCA,
            ),
            const SizedBox(width: 6),
            CustomText(
              intent.label,
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? _accent : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerField() {
    return CommonTextField(
      textEditController: _offerController,
      hintText: AppStrings.bookingOfferHint.tr,
      isValidate: false,
      keyBoardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
      ],
      onChange: (_) => setState(() {}),
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_photoPaths.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final path in _photoPaths) _photoThumb(path)],
          ),
          const SizedBox(height: 10),
        ],
        if (_photoPaths.length < _maxPhotos) _addPhotoButton(),
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
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded,
                          size: 18,
                          color: _canSubmit
                              ? Colors.white
                              : AppColors.greyCA),
                      const SizedBox(width: 8),
                      CustomText(
                        AppStrings.sendEnquiryLabel.tr,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color:
                            _canSubmit ? Colors.white : AppColors.greyCA,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
