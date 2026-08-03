import 'dart:convert';

import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:hive/hive.dart';

/// Hive-based local storage for user delivery addresses.
///
/// Stores up to [maxAddresses] addresses as JSON, keyed by user ID.
/// Also persists the "selected delivery address" id for the cart screen.
class AddressCacheService {
  static const String _boxName = 'address_cache_box';
  static const String _addressListKey = 'address_list';
  static const String _selectedAddressIdKey = 'selected_address_id';
  static const int maxAddresses = 5;

  static final AddressCacheService _instance = AddressCacheService._internal();
  factory AddressCacheService() => _instance;
  AddressCacheService._internal();

  Box? _box;

  /// Must be called once during app startup (e.g. in main.dart).
  static Future<void> init() async {
    final instance = AddressCacheService();
    instance._box = await Hive.openBox(_boxName);
  }

  Box get _safeBox {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box(_boxName);
    }
    return _box!;
  }

  // ─── Read ──────────────────────────────────────────────────────

  /// Retrieve all saved addresses for [currentUserId].
  List<UserAddress> getAddresses(String currentUserId) {
    try {
      final raw = _safeBox.get('${currentUserId}_$_addressListKey');
      if (raw == null) return [];
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => UserAddress.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get the currently selected delivery address, or the default, or first.
  UserAddress? getSelectedAddress(String currentUserId) {
    final addresses = getAddresses(currentUserId);
    if (addresses.isEmpty) return null;

    final savedId = getSelectedAddressId(currentUserId);
    if (savedId != null) {
      final match = addresses.where((a) => a.id == savedId).toList();
      if (match.isNotEmpty) return match.first;
    }

    // Fallback: default > first
    final def = addresses.where((a) => a.isDefault == true).toList();
    return def.isNotEmpty ? def.first : addresses.first;
  }

  // ─── Write ─────────────────────────────────────────────────────

  /// Save a list of addresses to Hive.
  Future<void> _persist(List<UserAddress> addresses, String currentUserId) async {
    final jsonList = addresses.map((a) => a.toJson()).toList();
    await _safeBox.put('${currentUserId}_$_addressListKey', jsonEncode(jsonList));
  }

  /// Replace the whole cached list with what the server just returned.
  ///
  /// Used after `GET user-service/addresses` so the list screen can paint
  /// instantly on the next open (and stay usable offline) without the local
  /// id/default bookkeeping that [addAddress] does for locally-created rows.
  Future<void> saveAddresses(
      String currentUserId, List<UserAddress> addresses) async {
    await _persist(addresses, currentUserId);
  }

  /// Add a new address. Returns `false` if max limit reached.
  Future<bool> addAddress(String currentUserId, UserAddress address) async {
    final addresses = getAddresses(currentUserId);
    if (addresses.length >= maxAddresses) return false;

    // Generate a local ID
    address.id = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // If this is first address or marked default, clear others' default
    if (addresses.isEmpty || address.isDefault == true) {
      for (var a in addresses) {
        a.isDefault = false;
      }
      address.isDefault = true;
    }

    addresses.add(address);
    await _persist(addresses, currentUserId);

    // Auto-select newly added address
    await saveSelectedAddressId(currentUserId, address.id!);
    return true;
  }

  /// Update an existing address by id.
  Future<void> updateAddress(String currentUserId, UserAddress updated) async {
    final addresses = getAddresses(currentUserId);
    final idx = addresses.indexWhere((a) => a.id == updated.id);
    if (idx < 0) return;

    if (updated.isDefault == true) {
      for (var a in addresses) {
        a.isDefault = false;
      }
    }

    addresses[idx] = updated;
    await _persist(addresses, currentUserId);
  }

  /// Delete an address by id.
  Future<void> deleteAddress(String currentUserId, String addressId) async {
    final addresses = getAddresses(currentUserId);
    addresses.removeWhere((a) => a.id == addressId);

    // If we deleted the default, make the first one default
    if (addresses.isNotEmpty &&
        !addresses.any((a) => a.isDefault == true)) {
      addresses.first.isDefault = true;
    }

    await _persist(addresses, currentUserId);

    // Clear selection if deleted was selected
    if (getSelectedAddressId(currentUserId) == addressId) {
      if (addresses.isNotEmpty) {
        await saveSelectedAddressId(currentUserId, addresses.first.id ?? '');
      } else {
        await _safeBox.delete('${currentUserId}_$_selectedAddressIdKey');
      }
    }
  }

  // ─── Selection ─────────────────────────────────────────────────

  Future<void> saveSelectedAddressId(String currentUserId, String addressId) async {
    await _safeBox.put('${currentUserId}_$_selectedAddressIdKey', addressId);
  }

  String? getSelectedAddressId(String currentUserId) {
    return _safeBox.get('${currentUserId}_$_selectedAddressIdKey');
  }

  // ─── Cleanup ───────────────────────────────────────────────────

  Future<void> clearCache(String currentUserId) async {
    await _safeBox.delete('${currentUserId}_$_addressListKey');
    await _safeBox.delete('${currentUserId}_$_selectedAddressIdKey');
  }

  Future<void> clearAll() async {
    await _safeBox.clear();
  }
}
