import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/address_cache_service.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/repo/address_repo.dart';
import 'package:get/get.dart';

/// Owns the saved-address list, the CRUD calls behind it and the
/// "currently selected" address.
///
/// Registered with [getOrPut] by the picker so a single instance is shared by
/// every screen that needs the user's addresses; the selection is also
/// mirrored into [AddressCacheService] so it survives a restart and can be
/// read from anywhere without this controller being alive.
class AddressController extends GetxController {
  final AddressRepo _repo = AddressRepo();
  final AddressCacheService _cache = AddressCacheService();

  /// Product rule: a user may keep at most five saved addresses.
  static const int maxAddressLimit = AddressCacheService.maxAddresses;

  final Rx<ApiResponse> addressListResponse = ApiResponse.initial('Initial').obs;
  final RxList<UserAddress> addresses = <UserAddress>[].obs;
  final Rxn<UserAddress> selectedAddress = Rxn<UserAddress>();
  final RxBool isDeleting = false.obs;

  bool get canAddMore => addresses.length < maxAddressLimit;

  int get remainingSlots => (maxAddressLimit - addresses.length).clamp(0, maxAddressLimit);

  @override
  void onInit() {
    super.onInit();
    // Cache only — the network fetch is driven by whoever opens the list
    // (or by `AddressPicker.preload`), so a re-opened screen re-syncs and
    // a first open doesn't fire two requests.
    _loadFromCache();
  }

  /// Paint the last known list immediately; the network call replaces it.
  void _loadFromCache() {
    try {
      final cached = _cache.getAddresses(userId);
      if (cached.isEmpty) return;
      addresses.assignAll(cached);
      selectedAddress.value = _cache.getSelectedAddress(userId);
      addressListResponse.value = ApiResponse.complete(cached);
    } catch (e) {
      logs('AddressController: cache read failed → $e');
    }
  }

  /// `GET user-service/addresses`
  Future<void> fetchAddresses({bool showProgress = false}) async {
    try {
      if (addresses.isEmpty) {
        addressListResponse.value = ApiResponse.loading('Loading');
      }

      final ResponseModel response =
          await _repo.getAddresses(showProgress: showProgress);

      if (response.isSuccess) {
        final list = UserAddress.listFrom(response.response?.data);

        addresses.assignAll(list);
        _restoreSelection();
        addressListResponse.value = ApiResponse.complete(list);
        await _cache.saveAddresses(userId, list);
      } else {
        addressListResponse.value = ApiResponse.error(
            response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs('AddressController.fetchAddresses → $e');
      addressListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  /// `GET user-service/addresses/:id` — single fetch for callers that only
  /// hold an id (deep link, order detail, re-validating a stale selection).
  Future<UserAddress?> fetchAddressById(String addressId) async {
    try {
      final ResponseModel response = await _repo.getAddress(addressId);
      if (response.isSuccess) {
        return UserAddress.oneFrom(response.response?.data);
      }
    } catch (e) {
      logs('AddressController.fetchAddressById → $e');
    }
    return null;
  }

  /// `DELETE user-service/addresses/:id`
  Future<bool> deleteAddress(String addressId) async {
    if (addressId.isEmpty) return false;
    try {
      isDeleting.value = true;
      final ResponseModel response = await _repo.deleteAddress(addressId);

      if (response.isSuccess) {
        addresses.removeWhere((a) => a.id == addressId);
        if (selectedAddress.value?.id == addressId) {
          selectedAddress.value = addresses.isNotEmpty ? addresses.first : null;
        }
        await _cache.deleteAddress(userId, addressId);
        addressListResponse.value = ApiResponse.complete(addresses.toList());
        commonSnackBar(message: response.message ?? 'Address deleted');
        return true;
      }

      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      logs('AddressController.deleteAddress → $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Mark [address] as the one to use, and remember it across sessions.
  Future<void> selectAddress(UserAddress address) async {
    selectedAddress.value = address;
    final id = address.id;
    if (id != null && id.isNotEmpty) {
      await _cache.saveSelectedAddressId(userId, id);
    }
  }

  /// Keep the previous selection pointing at the freshly fetched row, else
  /// fall back to the server default, else the first address.
  void _restoreSelection() {
    if (addresses.isEmpty) {
      selectedAddress.value = null;
      return;
    }

    final previousId =
        selectedAddress.value?.id ?? _cache.getSelectedAddressId(userId);

    final match =
        addresses.firstWhereOrNull((a) => a.id != null && a.id == previousId);
    if (match != null) {
      selectedAddress.value = match;
      return;
    }

    selectedAddress.value =
        addresses.firstWhereOrNull((a) => a.isDefault == true) ??
            addresses.first;
  }
}
