import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/shared_preference_utils.dart';

/// WhatsApp-style Chat Lock — hides selected conversations behind a PIN.
/// Locked IDs are stored in Hive (per personal/business tab) and the PIN
/// lives in `flutter_secure_storage` via [SharedPreferenceUtils].
class ChatLockController extends GetxController {
  static const String _boxName = 'chatLockBox';
  static const String _personalLockedKey = 'personalLockedConversations';
  static const String _businessLockedKey = 'businessLockedConversations';
  static const String _pinKey = 'chatLockPin';

  RxSet<String> personalLockedIds = <String>{}.obs;
  RxSet<String> businessLockedIds = <String>{}.obs;

  /// Mirrors the PIN state so widgets can react with `Obx`.
  RxBool hasPin = false.obs;

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
    _loadSet(box, _personalLockedKey, personalLockedIds);
    _loadSet(box, _businessLockedKey, businessLockedIds);

    final pin = await SharedPreferenceUtils.getSecureValue(_pinKey);
    hasPin.value = pin != null && (pin as String).isNotEmpty;
  }

  void _loadSet(Box<String> box, String key, RxSet<String> target) {
    final json = box.get(key);
    if (json != null) {
      final List decoded = jsonDecode(json);
      target.addAll(decoded.cast<String>());
    }
  }

  // --- PIN ---

  /// Persist the PIN in secure storage. Stored in plain form — the storage
  /// layer is OS-backed Keychain/Keystore, so an extra hash buys nothing
  /// beyond the existing `flutter_secure_storage` guarantees.
  Future<void> setPin(String pin) async {
    await SharedPreferenceUtils.setSecureValue(_pinKey, pin);
    hasPin.value = pin.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await SharedPreferenceUtils.getSecureValue(_pinKey);
    return stored != null && stored == pin;
  }

  Future<void> clearPin() async {
    await SharedPreferenceUtils.setSecureValue(_pinKey, '');
    hasPin.value = false;
  }

  // --- Locked IDs ---

  RxSet<String> lockedIds(bool isBusiness) =>
      isBusiness ? businessLockedIds : personalLockedIds;

  String _lockedKey(bool isBusiness) =>
      isBusiness ? _businessLockedKey : _personalLockedKey;

  bool isLocked(String? conversationId, {bool isBusiness = false}) {
    if (conversationId == null) return false;
    return lockedIds(isBusiness).contains(conversationId);
  }

  Future<void> lockMultiple(List<String> ids, {bool isBusiness = false}) async {
    lockedIds(isBusiness).addAll(ids);
    await _save(_lockedKey(isBusiness), lockedIds(isBusiness));
  }

  Future<void> unlockMultiple(List<String> ids,
      {bool isBusiness = false}) async {
    lockedIds(isBusiness).removeAll(ids);
    await _save(_lockedKey(isBusiness), lockedIds(isBusiness));
  }

  Future<void> _save(String key, RxSet<String> data) async {
    final box = await _boxRef;
    await box.put(key, jsonEncode(data.toList()));
  }
}
