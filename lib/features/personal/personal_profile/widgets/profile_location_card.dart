import 'dart:convert';
import 'dart:ui' as ui;

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/common/address/address_picker.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileLocationCard extends StatelessWidget {
  /// Outer margin override. Defaults match the other Overview cards'
  /// horizontal padding.
  final EdgeInsetsGeometry margin;

  const ProfileLocationCard({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final viewCtrl = Get.find<ViewPersonalDetailsController>();
    return Container(
      margin: margin,
      child: Obx(() {
        final user = viewCtrl.personalProfileDetails.value.user;
        final address = (user?.address ?? '').trim();
        final lat = user?.userLocation?.lat ?? 0.0;
        final lon = user?.userLocation?.lon ?? 0.0;
        final displayName = _capitalise(user?.name ?? '');
        final hasMap = lat != 0.0 && lon != 0.0;
        final hasAny = address.isNotEmpty || hasMap;
        return _LocationTile(
          address: address,
          lat: lat,
          lon: lon,
          hasMap: hasMap,
          hasAny: hasAny,
          displayName: displayName,
          onEdit: () => _openEditSheet(context),
        );
      }),
    );
  }

  String _capitalise(String s) {
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LocationEditSheet(),
    );
  }
}

// ─── Display Tile ─────────────────────────────────────────────────
// Split out so the build method stays focused; this widget owns the
// spec-sheet rhythm — heading row, then map, then ADDRESS / COORDS
// rows — matching the other Overview cards (Bio, QR, etc.).
class _LocationTile extends StatelessWidget {
  final String address;
  final double lat;
  final double lon;
  final bool hasMap;
  final bool hasAny;
  final String displayName;
  final VoidCallback onEdit;

  const _LocationTile({
    required this.address,
    required this.lat,
    required this.lon,
    required this.hasMap,
    required this.hasAny,
    required this.displayName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — uppercase eyebrow + Add/Edit action chip, same
          // shape as the bio/QR cards' headers.
          Row(
            children: [
              Expanded(
                  child: _eyebrow(AppStrings.locationLabel.tr.toUpperCase())),
              _actionChip(),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          if (hasMap) ...[
            // Rounded map preview slotted into the padded card body —
            // no more full-bleed bleed-to-edges treatment.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                child: BusinessLocationMapWidget(
                  key: ValueKey('loc-card-$lat-$lon'),
                  latitude: lat,
                  longitude: lon,
                  businessName: displayName.isEmpty
                      ? AppStrings.youLabel.tr
                      : displayName,
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size12),
          ],
          if (address.isNotEmpty) _specRows() else if (!hasMap) _emptyPrompt(),
        ],
      ),
    );
  }

  // Spec-sheet body — ADDRESS row → hairline → COORDS row.
  Widget _specRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _eyebrow(AppStrings.addressLabel.tr.toUpperCase()),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          address,
          fontSize: SizeConfig.medium,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w600,
        ),
        /*  if (hasMap) ...[
          SizedBox(height: SizeConfig.size12),
          Container(
            height: 1,
            color: const Color(0xFFEDEFF4),
          ),
          // SizedBox(height: SizeConfig.size12),
          // _eyebrow(AppStrings.coordsLabel.tr.toUpperCase()),
          // SizedBox(height: SizeConfig.size6),
          // Text(
          //   _formatCoords(lat, lon),
          //   style: TextStyle(
          //     fontFamily: AppConstants.OpenSans,
          //     fontSize: 13,
          //     fontWeight: FontWeight.w700,
          //     color: AppColors.secondaryTextColor,
          //     letterSpacing: 0.4,
          //     fontFeatures: const [ui.FontFeature.tabularFigures()],
          //   ),
          // ),
        ],*/
      ],
    );
  }

  Widget _emptyPrompt() {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size14,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.add_location_alt_outlined,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    AppStrings.pinYourLocation.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    AppStrings.addAddressHint.tr,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _eyebrow(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppConstants.OpenSans,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.secondaryTextColor,
        letterSpacing: 1.6,
      ),
    );
  }

  /// Single Add/Edit action chip in the card header. Matches the
  /// bio/QR action chips visually so the whole Overview reads with
  /// one chip vocabulary.
  Widget _actionChip() {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAny ? Icons.edit_outlined : Icons.add_location_alt_outlined,
              size: 12,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            CustomText(
              hasAny ? AppStrings.edit.tr : AppStrings.add.tr,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a lat/lon pair into a human-readable directional readout
  /// (`22.3010°N · 88.4560°E`). Tabular figures keep the digits
  /// aligned across rebuilds.
  String _formatCoords(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir  ·  ${lon.abs().toStringAsFixed(4)}°$lonDir';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Edit Sheet — numbered 01 / 02 / 03 sections.
// ═══════════════════════════════════════════════════════════════════
class _LocationEditSheet extends StatefulWidget {
  const _LocationEditSheet();

  @override
  State<_LocationEditSheet> createState() => _LocationEditSheetState();
}

class _LocationEditSheetState extends State<_LocationEditSheet> {
  final TextEditingController _addressController = TextEditingController();
  final ViewPersonalDetailsController _viewCtrl =
      Get.find<ViewPersonalDetailsController>();
  final PersonalCreateProfileController _personalCtrl =
      Get.find<PersonalCreateProfileController>();
  final LocationController _locationCtrl = Get.find<LocationController>();

  double _lat = 0.0;
  double _lon = 0.0;
  String? _pincode;
  bool _isSaving = false;

  /// The address staged for saving, and where it came from. `_addressController`
  /// is only the payload holder — these drive what section 02 renders, so the
  /// tile can't fall back to showing the profile's pre-existing address as if
  /// the user had just picked it.
  UserAddress? _pickedAddress;
  bool _pickedFromGps = false;

  @override
  void initState() {
    super.initState();
    final user = _viewCtrl.personalProfileDetails.value.user;
    _addressController.text = user?.address ?? '';
    _lat = user?.userLocation?.lat ?? 0.0;
    _lon = user?.userLocation?.lon ?? 0.0;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  /// "Use my current location" — runs the standard reverse-geocode
  /// pipeline and fills the address + coords + pincode in one tap.
  Future<void> _useCurrentLocation() async {
    final data = await _locationCtrl.checkPermissionAndSetData();
    if (data == null || !mounted) return;
    setState(() {
      if (data.fullAddress.isNotEmpty) {
        _addressController.text = data.fullAddress;
      }
      _lat = double.tryParse(data.lat) ?? _lat;
      _lon = double.tryParse(data.long) ?? _lon;
      if (data.pinCode.isNotEmpty) _pincode = data.pinCode;
      // GPS wins over any earlier book pick.
      _pickedAddress = null;
      _pickedFromGps = true;
    });
  }

  /// Opens the saved-address book. Whatever the user confirms there comes
  /// back as a [UserAddress] — its formatted address, coordinates and
  /// pincode become what this sheet will save.
  Future<void> _pickSavedAddress() async {
    final picked = await AddressPicker.pick();
    if (picked == null || !mounted) return;

    final formatted = picked.formattedAddress.trim();
    setState(() {
      _pickedAddress = picked;
      _pickedFromGps = false;
      if (formatted.isNotEmpty) _addressController.text = formatted;
      _lat = picked.lat?.toDouble() ?? _lat;
      _lon = picked.long?.toDouble() ?? _lon;
      final pin = picked.pincode?.trim() ?? '';
      if (pin.isNotEmpty) _pincode = pin;
    });
  }

  Future<void> _save() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      commonSnackBar(message: AppStrings.pleaseAddYourAddress.tr);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final params = <String, dynamic>{
        ApiKeys.user_cordinates: jsonEncode({
          ApiKeys.lat: _lat,
          ApiKeys.lon: _lon,
        }),
        ApiKeys.address: address,
        if (_pincode != null && _pincode!.isNotEmpty) ApiKeys.pincode: _pincode,
      };
      // showProgress: false → the sheet shows its own inline loader
      // on the Update CTA. We don't want the global progress overlay
      // competing with the bottom-sheet's modal.
      await _personalCtrl.updateUserProfileDetails(
        params: params,
        isFromProfileOnly: true,
        showProgress: false,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _viewCtrl.personalProfileDetails.value.user;
    final displayName = (user?.name ?? '').trim();
    final hasMap = _lat != 0.0 && _lon != 0.0;
    final isValid = _addressController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: SizeConfig.size14,
          right: SizeConfig.size14,
          top: SizeConfig.size10,
          bottom: SizeConfig.size20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            _header(),
            SizedBox(height: SizeConfig.size16),

            // 01 — quick-fill via geolocation
            _Section(
              index: 1,
              label: AppStrings.useMyLocationLabel.tr.toUpperCase(),
              child: _useCurrentTile(),
            ),
            SizedBox(height: SizeConfig.size18),

            // 02 — pick one of the addresses the user already saved
            _Section(
              index: 2,
              label: 'OR PICK A SAVED ADDRESS',
              child: _savedAddressTile(),
            ),
            SizedBox(height: SizeConfig.size18),

            // 03 — live preview confirms what'll be saved
            _Section(
              index: 3,
              label: AppStrings.previewLabel.tr.toUpperCase(),
              child: hasMap
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BusinessLocationMapWidget(
                        key: ValueKey('loc-edit-$_lat-$_lon'),
                        latitude: _lat,
                        longitude: _lon,
                        businessName: displayName.isEmpty
                            ? AppStrings.youLabel.tr
                            : displayName,
                      ),
                    )
                  : _previewPlaceholder(),
            ),

            SizedBox(height: SizeConfig.paddingL),
            CustomBtn(
              radius: 10,
              title: _isSaving ? null : AppStrings.update.tr,
              isLoading: _isSaving,
              onTap: _save,
              isValidate: isValid,
            ),
            SizedBox(height: SizeConfig.paddingXSL),
          ],
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.secondaryTextColor,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.yourLocationLabel.tr.toUpperCase(),
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              letterSpacing: 1.6,
            ),
          ),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.close_rounded,
                size: 20, color: AppColors.secondaryTextColor),
          ),
        ),
      ],
    );
  }

  // Primary-tinted tile that doubles as the geolocation CTA. The
  // pulsing crosshair on the right turns into a spinner during the
  // fetch so users see the action's state without a layout shift.
  Widget _useCurrentTile() {
    return Obx(() {
      final fetching = _locationCtrl.isFetchingAddress.value;
      return InkWell(
        onTap: fetching ? null : _useCurrentLocation,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.10),
                AppColors.primaryColor.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: fetching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      fetching
                          ? AppStrings.pinningYouOnMap.tr
                          : AppStrings.detectAutomatically.tr,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      fetching
                          ? AppStrings.readingYourGps.tr
                          : AppStrings.pullsCurrentGpsAddress.tr,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              if (!fetching)
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.primaryColor),
            ],
          ),
        ),
      );
    });
  }

  // Section 02 — opens the saved-address book. Shows the address that is
  // currently staged so the user can see what tapping "Update" will save.
  Widget _savedAddressTile() {
    final picked = _pickedAddress;
    final currentText = _addressController.text.trim();

    // Three states: a fresh pick from the book, a GPS/existing address
    // already staged, or nothing yet.
    final String title;
    final String subtitle;
    final bool hasSelection = picked != null;

    if (picked != null) {
      title = picked.typeLabel;
      subtitle = picked.formattedAddress.trim().isEmpty
          ? currentText
          : picked.formattedAddress.trim();
    } else if (currentText.isNotEmpty) {
      title = _pickedFromGps ? 'Current location' : 'Address on your profile';
      subtitle = currentText;
    } else {
      title = 'Choose from saved addresses';
      subtitle = 'Home, Office or any address you saved';
    }

    return InkWell(
      onTap: _pickSavedAddress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelection
                ? AppColors.primaryColor.withValues(alpha: 0.28)
                : const Color(0xFFE6E8EE),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Icon(
                hasSelection
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    title,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    subtitle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: subtitle.isEmpty
                        ? AppColors.secondaryTextColor
                        : AppColors.mainTextColor,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  // Placeholder shown in section 03 when no coords have been picked
  // yet — keeps the section vertical rhythm consistent.
  Widget _previewPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 0.8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined,
              size: 22, color: AppColors.secondaryTextColor),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            AppStrings.pickLocationToPreview.tr,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

/// One numbered section in the edit sheet — `01` index pill on the
/// left + tracked uppercase label + child content indented under it.
/// Mirrors the rhythm the Service Type / Working Hours sheets use.
class _Section extends StatelessWidget {
  final int index;
  final String label;
  final Widget child;

  const _Section({
    required this.index,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.22),
                  width: 0.6,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        // Indent the body so it visually hangs under the index badge,
        // echoing the numbered-row spec sheet pattern used elsewhere.
        Padding(
          padding: EdgeInsets.only(left: 36),
          child: child,
        ),
      ],
    );
  }
}
