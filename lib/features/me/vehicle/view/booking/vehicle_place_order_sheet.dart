import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_booking_models.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Buyer-facing "Place Order" sheet (`POST /vehicles/bookings`).
///
/// Connect-style: the buyer picks an [VehicleBookingIntent], optionally
/// adds an offer price, a note and up to 10 photos, then submits. On
/// success the sheet pops with the created [VehicleBooking]; otherwise it
/// stays open and the controller surfaces the server's error message.
class VehiclePlaceOrderSheet extends StatefulWidget {
  final Vehicle vehicle;

  const VehiclePlaceOrderSheet({super.key, required this.vehicle});

  /// Presents the sheet modally and resolves with the created booking
  /// (or null if the buyer dismissed / it failed).
  static Future<VehicleBooking?> show(
    BuildContext context, {
    required Vehicle vehicle,
  }) {
    return showModalBottomSheet<VehicleBooking>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehiclePlaceOrderSheet(vehicle: vehicle),
    );
  }

  @override
  State<VehiclePlaceOrderSheet> createState() => _VehiclePlaceOrderSheetState();
}

class _VehiclePlaceOrderSheetState extends State<VehiclePlaceOrderSheet> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);
  final _offerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();

  static const int _maxPhotos = 10;

  VehicleBookingIntent _intent = VehicleBookingIntent.buy;
  // Public URLs of photos already uploaded to S3 and ready to attach.
  final List<String> _photoUrls = [];
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _offerCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_photoUrls.length >= _maxPhotos) {
      commonSnackBar(
          message: AppStrings.bookingPhotosLimitFmt.trParams(
              {'max': '$_maxPhotos'}));
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      final remaining = _maxPhotos - _photoUrls.length;
      final toUpload = picked.take(remaining).toList();
      setState(() => _uploadingPhoto = true);
      for (final x in toUpload) {
        final url = await _ctrl.uploadFile(File(x.path));
        if (url != null) _photoUrls.add(url);
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    final inventoryId = (widget.vehicle.id ?? '').trim();
    if (inventoryId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    final offer = double.tryParse(_offerCtrl.text.trim().replaceAll(',', ''));
    final booking = await _ctrl.placeBooking(
      inventoryId: inventoryId,
      intent: _intent,
      offerPrice: offer,
      note: _noteCtrl.text,
      photos: _photoUrls,
    );
    if (booking != null && mounted) {
      Navigator.of(context).pop(booking);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SizeConfig.size20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size16,
            SizeConfig.size12,
            SizeConfig.size16,
            SizeConfig.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              CustomText(
                AppStrings.bookingPlaceOrderTitle.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size12),

              _listingSummary(),
              SizedBox(height: SizeConfig.size16),

              // ── Intent ───────────────────────────────────────────
              CustomText(
                AppStrings.bookingIntentLabel.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              Wrap(
                spacing: SizeConfig.size8,
                runSpacing: SizeConfig.size8,
                children: VehicleBookingIntent.values
                    .map((i) => _intentChip(i))
                    .toList(),
              ),
              SizedBox(height: SizeConfig.size16),

              // ── Offer price (optional) ───────────────────────────
              CommonTextField(
                textEditController: _offerCtrl,
                title: AppStrings.bookingOfferOptionalLabel.tr,
                hintText: AppStrings.bookingOfferHint.tr,
                keyBoardType: TextInputType.number,
                isOptionalFiled: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
              SizedBox(height: SizeConfig.size12),

              // ── Note (optional) ──────────────────────────────────
              CommonTextField(
                textEditController: _noteCtrl,
                title: AppStrings.bookingNoteOptionalLabel.tr,
                hintText: AppStrings.bookingNoteHint.tr,
                maxLine: 4,
                maxLength: 2000,
                isOptionalFiled: true,
              ),
              SizedBox(height: SizeConfig.size12),

              // ── Photos (optional) ────────────────────────────────
              CustomText(
                AppStrings.bookingPhotosOptionalLabel.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              _photosRow(),

              SizedBox(height: SizeConfig.size20),
              Obx(() => CustomBtn(
                    onTap: _ctrl.isPlacingBooking.value ? () {} : _submit,
                    isValidate: !_ctrl.isPlacingBooking.value,
                    isLoading: _ctrl.isPlacingBooking.value,
                    title: AppStrings.bookingSendRequest.tr,
                    bgColor: AppColors.primaryColor,
                    radius: SizeConfig.size12,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listingSummary() {
    final v = widget.vehicle;
    final image = (v.coverImage ?? (v.images.isNotEmpty ? v.images.first : ''))
        .toString()
        .trim();
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SizeConfig.size8),
            child: image.isEmpty
                ? Container(
                    width: 52,
                    height: 52,
                    color: AppColors.greyE5,
                    child: Icon(Icons.directions_car_rounded,
                        color: AppColors.secondaryTextColor),
                  )
                : CachedNetworkImage(
                    imageUrl: image,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: AppColors.greyE5,
                      child: Icon(Icons.directions_car_rounded,
                          color: AppColors.secondaryTextColor),
                    ),
                  ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  v.name.trim().isEmpty ? AppStrings.vehicle.tr : v.name.trim(),
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (v.price != null) ...[
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    '₹${v.price!.toStringAsFixed(0)}',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _intentChip(VehicleBookingIntent intent) {
    final selected = _intent == intent;
    return GestureDetector(
      onTap: () => setState(() => _intent = intent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : AppColors.greyE5,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: CustomText(
          intent.label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: selected
              ? AppColors.primaryColor
              : AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _photosRow() {
    return Wrap(
      spacing: SizeConfig.size8,
      runSpacing: SizeConfig.size8,
      children: [
        for (var i = 0; i < _photoUrls.length; i++) _photoThumb(i),
        if (_photoUrls.length < _maxPhotos) _addPhotoTile(),
      ],
    );
  }

  Widget _photoThumb(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SizeConfig.size8),
          child: CachedNetworkImage(
            imageUrl: _photoUrls[index],
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: () => setState(() => _photoUrls.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
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
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _uploadingPhoto ? null : _pickPhotos,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.fillColor,
          borderRadius: BorderRadius.circular(SizeConfig.size8),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: _uploadingPhoto
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(Icons.add_a_photo_outlined,
                color: AppColors.secondaryTextColor, size: 22),
      ),
    );
  }
}
