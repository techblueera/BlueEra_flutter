import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

typedef FetchContactsCallback = Future<List<Map<String, String>>> Function();

class HiveContactService {
  static const String _boxName = 'contactBox';
  static const String _contactKey = 'formatted_contacts';

  static Box? _box;

  /// Ensure box is opened
  static Future<Box> _openBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
    return _box!;
  }

  /// GET contacts
  static Future<List<Map<String, String>>> getContacts() async {
    final box = await _openBox();
    final data = box.get(_contactKey);

    if (data == null || data.toString().isEmpty) return [];

    final List decoded = jsonDecode(data);
    return decoded
        .map<Map<String, String>>(
          (e) => Map<String, String>.from(e),
    )
        .toList();
  }

  /// STORE contacts
  static Future<void> saveContacts(
      List<Map<String, String>> contacts,
      ) async {
    final box = await _openBox();
    await box.put(_contactKey, jsonEncode(contacts));
  }

  /// MAIN METHOD (Get → If empty → Refetch → Save)
  static Future<List<Map<String, String>>> getOrFetchContacts({
    required FetchContactsCallback onFetch,
     bool? inFirst,
  }) async {
    // 1. Try cache
    // final cachedContacts = await getContacts();
    // if(inFirst!=null){
    //   if (cachedContacts.isNotEmpty) {
    //     return cachedContacts;
    //   }
    // }


    // 2. Cache empty → refetch
    final freshContacts = await onFetch();

    if (freshContacts.isNotEmpty) {
      await saveContacts(freshContacts);
    }

    return freshContacts;
  }

  /// Clear cache (optional)
  static Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_contactKey);
  }
}
