import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../model/saved_address_model.dart';

/// Locally persists the user's saved drop/delivery addresses (used by the ride
/// drop-location sheet). Mirrors the Hive-JSON pattern of the other local-only
/// chat controllers — nothing is sent to the server.
class SavedAddressController extends GetxController {
  static const String _boxName = 'savedAddressesBox';
  static const String _addressesKey = 'savedAddresses';

  /// Newest-first list of saved addresses, observable for the UI.
  RxList<SavedAddress> addresses = <SavedAddress>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<Box<String>> get _boxRef async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }


  Future<void> _load() async {
    final box = await _boxRef;
    final json = box.get(_addressesKey);
    if (json != null) {
      final List decoded = jsonDecode(json);
      addresses.value = decoded
          .map((e) => SavedAddress.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  /// Save a new address and return it. Newest entries surface first.
  Future<SavedAddress> addAddress({
    required String label,
    required String address,
    String houseNo = '',
    String landmark = '',
    double? lat,
    double? lng,
  }) async {
    final entry = SavedAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.trim(),
      address: address.trim(),
      houseNo: houseNo.trim(),
      landmark: landmark.trim(),
      lat: lat,
      lng: lng,
    );
    addresses.insert(0, entry);
    await _save();
    return entry;
  }

  Future<void> removeAddress(String id) async {
    addresses.removeWhere((a) => a.id == id);
    await _save();
  }

  Future<void> _save() async {
    final box = await _boxRef;
    await box.put(
      _addressesKey,
      jsonEncode(addresses.map((e) => e.toJson()).toList()),
    );
  }
}
