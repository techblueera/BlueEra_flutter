import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ChatPinArchiveController extends GetxController {
  static const String _boxName = 'chatPinArchiveBox';

  // Personal
  static const String _personalPinnedKey = 'personalPinnedConversations';
  static const String _personalArchivedKey = 'personalArchivedConversations';

  // Business
  static const String _businessPinnedKey = 'businessPinnedConversations';
  static const String _businessArchivedKey = 'businessArchivedConversations';

  RxSet<String> personalPinnedIds = <String>{}.obs;
  RxSet<String> personalArchivedIds = <String>{}.obs;
  RxSet<String> businessPinnedIds = <String>{}.obs;
  RxSet<String> businessArchivedIds = <String>{}.obs;

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

    _loadSet(box, _personalPinnedKey, personalPinnedIds);
    _loadSet(box, _personalArchivedKey, personalArchivedIds);
    _loadSet(box, _businessPinnedKey, businessPinnedIds);
    _loadSet(box, _businessArchivedKey, businessArchivedIds);

    // Migrate old shared keys if they exist
    final oldPinned = box.get('pinnedConversations');
    if (oldPinned != null) {
      final List decoded = jsonDecode(oldPinned);
      personalPinnedIds.addAll(decoded.cast<String>());
      await _save(_personalPinnedKey, personalPinnedIds);
      await box.delete('pinnedConversations');
    }
    final oldArchived = box.get('archivedConversations');
    if (oldArchived != null) {
      final List decoded = jsonDecode(oldArchived);
      personalArchivedIds.addAll(decoded.cast<String>());
      await _save(_personalArchivedKey, personalArchivedIds);
      await box.delete('archivedConversations');
    }
  }

  void _loadSet(Box<String> box, String key, RxSet<String> target) {
    final json = box.get(key);
    if (json != null) {
      final List decoded = jsonDecode(json);
      target.addAll(decoded.cast<String>());
    }
  }

  // --- Helpers to get the right set ---

  RxSet<String> pinnedIds(bool isBusiness) =>
      isBusiness ? businessPinnedIds : personalPinnedIds;

  RxSet<String> archivedIds(bool isBusiness) =>
      isBusiness ? businessArchivedIds : personalArchivedIds;

  String _pinnedKey(bool isBusiness) =>
      isBusiness ? _businessPinnedKey : _personalPinnedKey;

  String _archivedKey(bool isBusiness) =>
      isBusiness ? _businessArchivedKey : _personalArchivedKey;

  // --- Pin ---

  bool isPinned(String? conversationId, {bool isBusiness = false}) {
    if (conversationId == null) return false;
    return pinnedIds(isBusiness).contains(conversationId);
  }

  Future<void> togglePin(String conversationId, {bool isBusiness = false}) async {
    final set = pinnedIds(isBusiness);
    if (set.contains(conversationId)) {
      set.remove(conversationId);
    } else {
      set.add(conversationId);
    }
    await _save(_pinnedKey(isBusiness), set);
  }

  Future<void> pinMultiple(List<String> ids, {bool isBusiness = false}) async {
    pinnedIds(isBusiness).addAll(ids);
    await _save(_pinnedKey(isBusiness), pinnedIds(isBusiness));
  }

  Future<void> unpinMultiple(List<String> ids, {bool isBusiness = false}) async {
    pinnedIds(isBusiness).removeAll(ids);
    await _save(_pinnedKey(isBusiness), pinnedIds(isBusiness));
  }

  // --- Archive ---

  bool isArchived(String? conversationId, {bool isBusiness = false}) {
    if (conversationId == null) return false;
    return archivedIds(isBusiness).contains(conversationId);
  }

  Future<void> toggleArchive(String conversationId, {bool isBusiness = false}) async {
    final archived = archivedIds(isBusiness);
    final pinned = pinnedIds(isBusiness);
    if (archived.contains(conversationId)) {
      archived.remove(conversationId);
    } else {
      archived.add(conversationId);
      if (pinned.contains(conversationId)) {
        pinned.remove(conversationId);
        await _save(_pinnedKey(isBusiness), pinned);
      }
    }
    await _save(_archivedKey(isBusiness), archived);
  }

  Future<void> archiveMultiple(List<String> ids, {bool isBusiness = false}) async {
    archivedIds(isBusiness).addAll(ids);
    pinnedIds(isBusiness).removeAll(ids);
    await _save(_pinnedKey(isBusiness), pinnedIds(isBusiness));
    await _save(_archivedKey(isBusiness), archivedIds(isBusiness));
  }

  Future<void> unarchiveMultiple(List<String> ids, {bool isBusiness = false}) async {
    archivedIds(isBusiness).removeAll(ids);
    await _save(_archivedKey(isBusiness), archivedIds(isBusiness));
  }

  // --- Persist ---

  Future<void> _save(String key, RxSet<String> data) async {
    final box = await _boxRef;
    await box.put(key, jsonEncode(data.toList()));
  }
}
