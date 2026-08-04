import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/repo/address_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Backs the add / edit address form.
///
/// Created fresh per form open (and disposed with the screen) so a half-typed
/// address never leaks into the next one — the long-lived list state stays in
/// `AddressController`.
class AddressFormController extends GetxController {
  AddressFormController({this.editingAddress});

  /// Non-null when the form was opened to edit an existing address.
  final UserAddress? editingAddress;

  final AddressRepo _repo = AddressRepo();
  final PlaceRepo _placeRepo = PlaceRepo();

  final searchController = TextEditingController();
  final line1Controller = TextEditingController();
  final line2Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pinCodeController = TextEditingController();
  final otherTypeController = TextEditingController();

  /// Which type chip is active — one of [AddressTypeOption.selectable].
  final RxString selectedType = AddressTypeOption.home.obs;

  /// Picked floor — one of [FloorNumberOption.selectable], null until chosen.
  final RxnString selectedFloor = RxnString();

  final RxBool isSaving = false.obs;
  final RxBool isFetchingPlace = false.obs;

  /// Filled from the picked place's geometry; sent as `lat` / `long`.
  num? latitude;
  num? longitude;
  String country = 'India';

  bool get isEditMode => editingAddress != null;

  @override
  void onInit() {
    super.onInit();
    final address = editingAddress;
    if (address == null) return;

    line1Controller.text = address.addressLine1 ?? '';
    line2Controller.text = address.addressLine2 ?? '';
    cityController.text = address.city ?? '';
    stateController.text = address.state ?? '';
    pinCodeController.text = address.pincode ?? '';
    latitude = address.lat;
    longitude = address.long;
    country = (address.country?.trim().isNotEmpty ?? false)
        ? address.country!.trim()
        : country;

    selectedFloor.value = FloorNumberOption.selectionFor(address.floorNo);
    selectedType.value = AddressTypeOption.selectionFor(address.addressType);
    otherTypeController.text =
        AddressTypeOption.customLabelFor(address.addressType) ?? '';
  }

  @override
  void onClose() {
    searchController.dispose();
    line1Controller.dispose();
    line2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    pinCodeController.dispose();
    otherTypeController.dispose();
    super.onClose();
  }

  // ─── Google Places ────────────────────────────────────────────────

  /// Called when the user taps a Google autocomplete suggestion.
  ///
  /// [details] is the raw `place/details` body the suggestion widget already
  /// fetched — parsing it here means one billed Places Details request per
  /// pick, not two. When it is null (no place id, or the lookup failed) we
  /// retry once ourselves and, failing that, fall back to the suggestion
  /// text.
  Future<void> applyPlaceSelection({
    required String placeId,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    try {
      isFetchingPlace.value = true;

      Map<String, dynamic>? body = details;
      if (body == null && placeId.isNotEmpty) {
        final ResponseModel response =
            await _placeRepo.getCompletePlaceDetails(placeId: placeId);
        final data = response.response?.data;
        if (response.isSuccess && data is Map) {
          body = Map<String, dynamic>.from(data);
        }
      }

      final result =
          body == null ? null : PlaceDetailsResponse.fromJson(body).result;

      if (result == null) {
        _fillLine1FromDescription(description);
        return;
      }

      _applyComponents(result, description);
    } catch (e) {
      logs('AddressFormController.applyPlaceSelection → $e');
      _fillLine1FromDescription(description);
    } finally {
      isFetchingPlace.value = false;
    }
  }

  void _applyComponents(Result result, String description) {
    String premise = '';
    String streetNumber = '';
    String route = '';
    String subLocality = '';
    String locality = '';
    String adminArea2 = '';
    String adminArea3 = '';
    String state = '';
    String postalCode = '';
    String countryName = '';

    for (final component in result.addressComponents ?? <AddressComponent>[]) {
      final types = component.types ?? const <String>[];
      final value = component.longName ?? '';
      if (value.isEmpty) continue;

      if (types.contains('premise') || types.contains('subpremise')) {
        premise = premise.isEmpty ? value : premise;
      }
      if (types.contains('street_number')) streetNumber = value;
      if (types.contains('route')) route = value;
      if (subLocality.isEmpty &&
          (types.contains('sublocality_level_1') ||
              types.contains('sublocality') ||
              types.contains('neighborhood'))) {
        subLocality = value;
      }
      if (types.contains('locality')) locality = value;
      if (types.contains('administrative_area_level_3')) adminArea3 = value;
      if (types.contains('administrative_area_level_2')) adminArea2 = value;
      if (types.contains('administrative_area_level_1')) state = value;
      if (types.contains('postal_code')) postalCode = value;
      if (types.contains('country')) countryName = value;
    }

    // Line 1 = the most specific part Google gave us (building + street).
    final line1 = [premise, streetNumber, route]
        .where((e) => e.isNotEmpty)
        .join(' ')
        .trim();

    if (line1.isNotEmpty) {
      line1Controller.text = line1;
    } else {
      _fillLine1FromDescription(description);
    }

    if (subLocality.isNotEmpty) line2Controller.text = subLocality;

    final city = [locality, adminArea3, adminArea2]
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (city.isNotEmpty) cityController.text = city;
    if (state.isNotEmpty) stateController.text = state;
    if (postalCode.isNotEmpty) pinCodeController.text = postalCode;
    if (countryName.isNotEmpty) country = countryName;

    final location = result.geometry?.location;
    if (location?.lat != null) latitude = location!.lat;
    if (location?.lng != null) longitude = location!.lng;

    // Keep the search box showing what the user picked.
    searchController.text = result.formattedAddress ?? description;
  }

  /// Fallback when Google returns no usable components: the first chunk of
  /// the suggestion text is almost always the building / street line.
  void _fillLine1FromDescription(String description) {
    if (description.trim().isEmpty) return;
    if (line1Controller.text.trim().isNotEmpty) return;
    line1Controller.text = description.split(',').first.trim();
  }

  // ─── Save ─────────────────────────────────────────────────────────

  /// The string persisted on `addressType`: a preset, or the user's own label.
  String get resolvedType {
    if (selectedType.value != AddressTypeOption.other) return selectedType.value;
    final custom = otherTypeController.text.trim();
    return custom.isEmpty ? AddressTypeOption.other : custom;
  }

  /// `lat` / `long` are part of the request contract, but a user who types
  /// the address by hand never picks a suggestion — forward-geocode what they
  /// typed so the record still carries coordinates. Best effort: on failure
  /// the fields stay null and the API decides.
  Future<void> _resolveLatLngFromForm() async {
    final query = [
      line1Controller.text.trim(),
      line2Controller.text.trim(),
      cityController.text.trim(),
      stateController.text.trim(),
      pinCodeController.text.trim(),
      country,
    ].where((e) => e.isNotEmpty).join(', ');

    if (query.isEmpty) return;

    try {
      final ResponseModel response =
          await _placeRepo.getGeoCodeFromAddress(address: query);
      final body = response.response?.data;
      if (!response.isSuccess || body is! Map) return;

      final results = body['results'];
      if (results is! List || results.isEmpty) return;

      final location = results.first?['geometry']?['location'];
      final lat = location?['lat'];
      final lng = location?['lng'];
      if (lat is num) latitude = lat;
      if (lng is num) longitude = lng;
    } catch (e) {
      logs('AddressFormController._resolveLatLngFromForm → $e');
    }
  }

  /// The form as the API wants it — `addressLine1`, `addressLine2`, `lat`,
  /// `long`, `city`, `state`, `country`, `pincode`, `addressType`.
  UserAddress _buildAddress() {
    return UserAddress(
      id: editingAddress?.id,
      addressLine1: line1Controller.text.trim(),
      addressLine2: line2Controller.text.trim(),
      lat: latitude,
      long: longitude,
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: country,
      pincode: pinCodeController.text.trim(),
      addressType: resolvedType,
      floorNo: selectedFloor.value,
    );
  }

  /// `POST` on create, `PUT /:id` on edit. Returns the saved address on
  /// success so the caller can select it straight away, else `null`.
  Future<UserAddress?> save() async {
    if (isSaving.value) return null;

    try {
      isSaving.value = true;
      if (latitude == null || longitude == null) {
        await _resolveLatLngFromForm();
      }
      final address = _buildAddress();
      final payload = address.toRequestJson();

      final ResponseModel response = isEditMode
          ? await _repo.updateAddress(editingAddress!.id ?? '', payload)
          : await _repo.createAddress(payload);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ??
                (isEditMode ? 'Address updated' : 'Address saved'));
        // Prefer the server's row (it carries the id); fall back to what we
        // just sent so the caller still gets a usable object when the API
        // answers with a bare message.
        return UserAddress.oneFrom(response.response?.data) ?? address;
      }

      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return null;
    } catch (e) {
      logs('AddressFormController.save → $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      isSaving.value = false;
    }
  }
}
