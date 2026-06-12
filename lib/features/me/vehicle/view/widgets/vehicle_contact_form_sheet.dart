import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Add / edit form for a single [VehicleContact]. Presented as a full-page
/// screen — the layout mirrors `HospitalBranchDetailsFormScreen`
/// (CommonBackAppBar + CommonCardWidget + inline-error CommonTextFields +
/// CustomBtn submit) so the look and feel matches the rest of the app's
/// Contact-us flows. Pops with a [VehicleContact] on submit, `null` on
/// cancel; the caller then runs the controller's `addContact` /
/// `updateContact` against the result, so the surrounding screen and its
/// existing call sites (`Navigator.push<VehicleContact>(MaterialPageRoute(…))`)
/// keep working unchanged.
class VehicleContactFormSheet extends StatefulWidget {
  final VehicleContact? initial;

  const VehicleContactFormSheet({super.key, this.initial});

  @override
  State<VehicleContactFormSheet> createState() =>
      _VehicleContactFormSheetState();
}

class _VehicleContactFormSheetState extends State<VehicleContactFormSheet> {
  // ─── Field controllers ─────────────────────────────────────────────
  final _locationNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  bool _isPrimary = false;

  // Lat/Lng captured from the location picker; pre-filled from initial so
  // an unchanged edit preserves the originally-saved coordinates.
  double? _selectedLat;
  double? _selectedLng;

  // ─── Per-field error messages ──────────────────────────────────────
  // Driven by `_validate()` and rendered under each field via
  // `_buildErrorText`, mirroring `HospitalBranchDetailsFormScreen`.
  String _locationNameError = '';
  String _pincodeError = '';
  String _phoneError = '';
  String _altPhoneError = '';
  String _emailError = '';
  String _websiteError = '';
  String _mapLinkError = '';
  bool _isFormValid = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _locationNameCtrl.text = c?.locationName ?? '';
    _addressCtrl.text = c?.address ?? '';
    _cityCtrl.text = c?.city ?? '';
    _stateCtrl.text = c?.state ?? '';
    _countryCtrl.text = c?.country ?? '';
    _pincodeCtrl.text = c?.pincode?.toString() ?? '';
    _phoneCtrl.text = c?.phoneNumber?.number ?? '';
    _altPhoneCtrl.text = c?.alternatePhoneNumber?.number ?? '';
    _emailCtrl.text = c?.email ?? '';
    _websiteCtrl.text = c?.website ?? '';
    _hoursCtrl.text = c?.openingHours ?? '';
    _mapLinkCtrl.text = c?.mapLink ?? '';
    _isPrimary = c?.isPrimary ?? false;
    _selectedLat = c?.lat;
    _selectedLng = c?.lon;

    // Run an initial validation pass so the submit button reflects the
    // form's pre-filled state on edit (already valid → button is active).
    WidgetsBinding.instance.addPostFrameCallback((_) => _validate());
  }

  @override
  void dispose() {
    for (final c in [
      _locationNameCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _countryCtrl,
      _pincodeCtrl,
      _phoneCtrl,
      _altPhoneCtrl,
      _emailCtrl,
      _websiteCtrl,
      _hoursCtrl,
      _mapLinkCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Validation ────────────────────────────────────────────────────
  // Runs on every keystroke (`onChange: (_) => _validate()`) so error
  // messages and the submit button's `isValidate` colour update inline,
  // matching the hospital flow.
  void _validate() {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final urlRegex =
        RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+.*$', caseSensitive: false);

    String phoneCheck(String v) {
      if (v.trim().isEmpty) return '';
      final digits = v.replaceAll(RegExp(r'\D'), '');
      return (digits.length < 6 || digits.length > 15)
          ? AppStrings.enterValidPhoneErr.tr
          : '';
    }

    setState(() {
      _locationNameError = _locationNameCtrl.text.trim().isEmpty
          ? AppStrings.locationNameRequiredErr.tr
          : '';

      _pincodeError = _pincodeCtrl.text.trim().isNotEmpty &&
              !RegExp(r'^\d{4,8}$').hasMatch(_pincodeCtrl.text.trim())
          ? AppStrings.enterValidPincodeErr.tr
          : '';

      _phoneError = phoneCheck(_phoneCtrl.text);
      _altPhoneError = phoneCheck(_altPhoneCtrl.text);

      _emailError = _emailCtrl.text.trim().isNotEmpty &&
              !emailRegex.hasMatch(_emailCtrl.text.trim())
          ? AppStrings.enterValidEmailErr.tr
          : '';

      _websiteError = _websiteCtrl.text.trim().isNotEmpty &&
              !urlRegex.hasMatch(_websiteCtrl.text.trim())
          ? AppStrings.enterValidWebsiteUrlErr.tr
          : '';

      _mapLinkError = _mapLinkCtrl.text.trim().isNotEmpty &&
              !urlRegex.hasMatch(_mapLinkCtrl.text.trim())
          ? AppStrings.enterValidMapLinkErr.tr
          : '';

      _isFormValid = _locationNameError.isEmpty &&
          _pincodeError.isEmpty &&
          _phoneError.isEmpty &&
          _altPhoneError.isEmpty &&
          _emailError.isEmpty &&
          _websiteError.isEmpty &&
          _mapLinkError.isEmpty;
    });
  }

  /// Returns the first non-empty validation error, or null if all valid.
  String? _firstError() {
    for (final e in [
      _locationNameError,
      _pincodeError,
      _phoneError,
      _altPhoneError,
      _emailError,
      _websiteError,
      _mapLinkError,
    ]) {
      if (e.isNotEmpty) return e;
    }
    return null;
  }

  void _handleSubmit() {
    _validate();
    if (!_isFormValid) {
      final err = _firstError();
      if (err != null) commonSnackBar(message: err);
      return;
    }

    String? trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();
    final phone = trimOrNull(_phoneCtrl.text);
    final altPhone = trimOrNull(_altPhoneCtrl.text);

    final patched = VehicleContact(
      id: widget.initial?.id,
      userId: widget.initial?.userId,
      businessId: widget.initial?.businessId,
      locationName: _locationNameCtrl.text.trim(),
      address: trimOrNull(_addressCtrl.text),
      city: trimOrNull(_cityCtrl.text),
      state: trimOrNull(_stateCtrl.text),
      country: trimOrNull(_countryCtrl.text),
      pincode: int.tryParse(_pincodeCtrl.text.trim()),
      lat: _selectedLat ?? widget.initial?.lat,
      lon: _selectedLng ?? widget.initial?.lon,
      phoneNumber: phone == null
          ? null
          : VehiclePhoneNumber(
              // Default Indian dial code; the form doesn't expose a
              // country-code picker yet — easy to wire later without
              // reshaping the model.
              pre: widget.initial?.phoneNumber?.pre ?? 91,
              number: phone,
            ),
      alternatePhoneNumber: altPhone == null
          ? null
          : VehiclePhoneNumber(
              pre: widget.initial?.alternatePhoneNumber?.pre ?? 91,
              number: altPhone,
            ),
      email: trimOrNull(_emailCtrl.text),
      website: trimOrNull(_websiteCtrl.text),
      openingHours: trimOrNull(_hoursCtrl.text),
      mapLink: trimOrNull(_mapLinkCtrl.text),
      isPrimary: _isPrimary,
      isActive: widget.initial?.isActive ?? true,
    );
    Navigator.pop(context, patched);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.contactUs.tr),
      body: CommonCardWidget(
        padding: 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(AppStrings.location.tr),
              CommonTextField(
                textEditController: _locationNameCtrl,
                hintText: AppStrings.locationNameHintExample.tr,
                title: AppStrings.locationNameLabel.tr,
                onChange: (_) => _validate(),
              ),
              if (_locationNameError.isNotEmpty)
                _buildErrorText(_locationNameError),
              const SizedBox(height: 12),
              CommonLocationSearchField(
                controller: _addressCtrl,
                title: AppStrings.location.tr,
                hintText: AppStrings.searchAddressHint.tr,
                onSelected: (placeId, lat, lng, address) {
                  _addressCtrl.text = address;
                  _selectedLat = lat;
                  _selectedLng = lng;
                  _validate();
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: CommonTextField(
                    textEditController: _cityCtrl,
                    hintText: AppStrings.city.tr,
                    title: AppStrings.city.tr,
                    onChange: (_) => _validate(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonTextField(
                    textEditController: _stateCtrl,
                    hintText: AppStrings.state.tr,
                    title: AppStrings.state.tr,
                    onChange: (_) => _validate(),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: CommonTextField(
                    textEditController: _countryCtrl,
                    hintText: AppStrings.countryLabel.tr,
                    title: AppStrings.countryLabel.tr,
                    onChange: (_) => _validate(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonTextField(
                    textEditController: _pincodeCtrl,
                    hintText: AppStrings.pincodeLabel.tr,
                    title: AppStrings.pincodeLabel.tr,
                    keyBoardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    onChange: (_) => _validate(),
                  ),
                ),
              ]),
              if (_pincodeError.isNotEmpty) _buildErrorText(_pincodeError),
              const SizedBox(height: 12),
              HttpsTextField(
                controller: _mapLinkCtrl,
                hintText: AppStrings.mapLinkHintExample.tr,
                title: AppStrings.mapLinkOptionalLabel.tr,
                onChange: (_) => _validate(),
              ),
              if (_mapLinkError.isNotEmpty) _buildErrorText(_mapLinkError),

              const SizedBox(height: 24),
              _buildHeader(AppStrings.contactUs.tr),
              CommonTextField(
                textEditController: _phoneCtrl,
                hintText: AppStrings.phoneNumberHintExample.tr,
                title: AppStrings.phoneNumber.tr,
                keyBoardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                onChange: (_) => _validate(),
              ),
              if (_phoneError.isNotEmpty) _buildErrorText(_phoneError),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: _altPhoneCtrl,
                hintText: AppStrings.phoneNumberHintExample.tr,
                title: AppStrings.alternatePhoneLabel.tr,
                keyBoardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                onChange: (_) => _validate(),
              ),
              if (_altPhoneError.isNotEmpty) _buildErrorText(_altPhoneError),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: _emailCtrl,
                hintText: AppStrings.emailHintExample.tr,
                title: AppStrings.enterEmailAddress.tr,
                keyBoardType: TextInputType.emailAddress,
                onChange: (_) => _validate(),
              ),
              if (_emailError.isNotEmpty) _buildErrorText(_emailError),
              const SizedBox(height: 12),
              HttpsTextField(
                controller: _websiteCtrl,
                hintText: AppStrings.websiteUrlHintExample.tr,
                title: AppStrings.website.tr,
                onChange: (_) => _validate(),
              ),
              if (_websiteError.isNotEmpty) _buildErrorText(_websiteError),
              const SizedBox(height: 12),
              CommonTextField(
                textEditController: _hoursCtrl,
                hintText: AppStrings.openingHoursHintExample.tr,
                title: AppStrings.openingHoursLabel.tr,
                onChange: (_) => _validate(),
              ),

              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v),
                title: CustomText(
                  AppStrings.primaryContactLabel.tr,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                subtitle: CustomText(
                  AppStrings.shownFirstOnProfile.tr,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ),

              const SizedBox(height: 32),
              CustomBtn(
                onTap: () => _handleSubmit(),
                title: _isEdit ? AppStrings.saveChanges.tr : AppStrings.submit.tr,
                isValidate: _isFormValid,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomText(
          error,
          fontSize: 12,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: CustomText(
          text,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
      ),
    );
  }
}
