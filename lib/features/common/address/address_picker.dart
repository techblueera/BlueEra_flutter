import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/address_cache_service.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/controller/address_controller.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/features/common/address/view/add_edit_address_screen.dart';
import 'package:BlueEra/features/common/address/view/saved_address_list_screen.dart';
import 'package:get/get.dart';

/// The one entry point every other feature should use for addresses.
///
/// ```dart
/// final address = await AddressPicker.pick(
///   onSelected: (a) => controller.deliveryAddress.value = a,
/// );
/// ```
///
/// Both channels are available on purpose: `onSelected` for callers that want
/// a callback (a cart controller updating itself), the awaited return value
/// for callers that prefer straight-line code. Whatever the user picks is
/// also remembered — see [selectedAddress] — so a screen that just needs
/// "the current address" never has to open the picker at all.
class AddressPicker {
  const AddressPicker._();

  /// Opens the saved-address list. Resolves with the confirmed address, or
  /// `null` if the user backed out.
  static Future<UserAddress?> pick({
    AddressSelectedCallback? onSelected,
  }) async {
    return await Get.to<UserAddress?>(
      () => SavedAddressListScreen(onAddressSelected: onSelected),
    );
  }

  /// Opens the list in manage-only mode (no "use this address" bar) — for a
  /// profile/settings entry where nothing is waiting on a selection.
  static Future<void> manage() async {
    await Get.to(() => const SavedAddressListScreen(isSelectionMode: false));
  }

  /// Skips the list and opens the form directly. Resolves with the saved
  /// address, or `null` if the user left without saving.
  static Future<UserAddress?> addNew() async {
    return await Get.to<UserAddress?>(() => const AddEditAddressScreen());
  }

  /// The address the user last confirmed, without opening anything.
  ///
  /// Reads the live controller when one is registered, else the Hive cache
  /// written on every fetch/selection — so this is safe to call from a cold
  /// screen before any address UI has been shown.
  static UserAddress? get selectedAddress {
    if (Get.isRegistered<AddressController>()) {
      final live = Get.find<AddressController>().selectedAddress.value;
      if (live != null) return live;
    }
    return AddressCacheService().getSelectedAddress(userId);
  }

  /// All saved addresses (max five), from the live controller or the cache.
  static List<UserAddress> get savedAddresses {
    if (Get.isRegistered<AddressController>()) {
      final live = Get.find<AddressController>().addresses;
      if (live.isNotEmpty) return live.toList();
    }
    return AddressCacheService().getAddresses(userId);
  }

  /// Warm the list up front (e.g. on entering a checkout flow) so the picker
  /// paints instantly when it is finally opened.
  static Future<void> preload() async {
    final controller = getOrPut(() => AddressController());
    if (controller.addresses.isEmpty) await controller.fetchAddresses();
  }
}
