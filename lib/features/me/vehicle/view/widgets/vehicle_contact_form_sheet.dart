import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
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

/// Add / edit form for a single [VehicleContact] — mirrors the visual
/// layout of `OtherBranchDetailsFormScreen` (Branch section + Department
/// section, location search field, validated submit). The persistence
/// path stays on vehicle-service: the form pops back a [VehicleContact]
/// and the caller (`VehicleOwnerActions.addContact / editContact`) runs
/// `VehicleController.addContact` / `updateContact` against it.
///
/// `VehicleContact` is flat (no department column), so the Department
/// field is concatenated into `locationName` using `" — "` as the
/// separator and split back out on edit, so the field round-trips
/// without losing data.
class VehicleContactFormSheet extends StatefulWidget {
  final VehicleContact? initial;

  const VehicleContactFormSheet({super.key, this.initial});

  @override
  State<VehicleContactFormSheet> createState() =>
      _VehicleContactFormSheetState();
}

class _VehicleContactFormSheetState extends State<VehicleContactFormSheet> {
  // Separator used to encode Branch + Department inside the flat
  // `VehicleContact.locationName` field. Picked to match the visual
  // dash used in the Other overview's contact card, and unlikely to
  // appear inside an organic branch name.
  static const String _branchDeptSeparator = ' — ';

  // ─── Field controllers (mirroring OtherBranchDetailsFormScreen) ────
  final _branchNameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;
  bool _isSubmitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    if (c != null) {
      // Split locationName back into branch + department on edit so
      // the two fields show the right values independently.
      final parts = c.locationName.split(_branchDeptSeparator);
      _branchNameCtrl.text = parts.first;
      _departmentCtrl.text = parts.length > 1 ? parts.sublist(1).join(_branchDeptSeparator) : '';
      _websiteCtrl.text = c.website ?? '';
      _addressCtrl.text = c.address ?? '';
      _emailCtrl.text = c.email ?? '';
      _phoneCtrl.text = c.phoneNumber?.number ?? '';
      _selectedLat = c.lat;
      _selectedLng = c.lon;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _branchNameCtrl,
      _websiteCtrl,
      _addressCtrl,
      _departmentCtrl,
      _emailCtrl,
      _phoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    String? trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();

    final branch = _branchNameCtrl.text.trim();
    final dept = _departmentCtrl.text.trim();
    final locationName =
        dept.isEmpty ? branch : '$branch$_branchDeptSeparator$dept';

    final phone = trimOrNull(_phoneCtrl.text);

    final patched = VehicleContact(
      id: widget.initial?.id,
      userId: widget.initial?.userId,
      businessId: widget.initial?.businessId,
      locationName: locationName,
      address: trimOrNull(_addressCtrl.text),
      lat: _selectedLat ?? widget.initial?.lat,
      lon: _selectedLng ?? widget.initial?.lon,
      phoneNumber: phone == null
          ? null
          : VehiclePhoneNumber(
              // Default Indian dial code; the form doesn't expose a
              // country-code picker yet — easy to add later without
              // reshaping the model.
              pre: widget.initial?.phoneNumber?.pre ?? 91,
              number: phone,
            ),
      email: trimOrNull(_emailCtrl.text),
      website: trimOrNull(_websiteCtrl.text),
      isPrimary: widget.initial?.isPrimary ?? false,
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
              _buildHeader(AppStrings.branch.tr),
              CommonTextField(
                textEditController: _branchNameCtrl,
                hintText: AppStrings.hotelHintBranchName.tr,
                title: AppStrings.otherBranchNameTitle.tr,
              ),
              SizedBox(height: 12),
              HttpsTextField(
                controller: _websiteCtrl,
                hintText: AppStrings.hotelHintBranchUrl.tr,
                title: AppStrings.otherWebsiteUrlTitle.tr,
              ),
              SizedBox(height: 12),
              CommonLocationSearchField(
                controller: _addressCtrl,
                title: AppStrings.location.tr,
                onSelected: (placeId, lat, lng, address) async {
                  _addressCtrl.text = address;
                  try {
                    final detailsResponse = await PlaceRepo()
                        .getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails =
                        PlaceDetailsResponse.fromJson(detailsData);
                    logs("detailsData=== $detailsData");
                    _selectedLat =
                        placeDetails.result?.geometry?.location?.lat ?? 0.0;
                    _selectedLng =
                        placeDetails.result?.geometry?.location?.lng ?? 0.0;
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }
                },
              ),

              SizedBox(height: 24),
              _buildHeader(AppStrings.department.tr),

              CommonTextField(
                textEditController: _departmentCtrl,
                hintText: AppStrings.otherHintAdmissionCell.tr,
                title: AppStrings.otherDepartmentRoleTitle.tr,
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: _emailCtrl,
                hintText: AppStrings.hotelEmailExampleHint.tr,
                title: AppStrings.otherEmailAddressTitle.tr,
              ),
              SizedBox(height: 12),
              CommonTextField(
                textEditController: _phoneCtrl,
                hintText: AppStrings.hotelPhoneExampleHint.tr,
                title: AppStrings.phoneNumber.tr,
                maxLength: 10,
                keyBoardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),

              SizedBox(height: 32),

              CustomBtn(
                isLoading: _isSubmitting,
                onTap: _handleSubmit,
                title: _isEdit ? AppStrings.saveChanges.tr : AppStrings.submit.tr,
                isValidate: true,
              ),
            ],
          ),
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
