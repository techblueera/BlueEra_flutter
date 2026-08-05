import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../model/GetListOfMessageData.dart';
import '../model/starred_message_model.dart';

/// Locally persists messages the user has starred (long-press → Star) along
/// with the originating conversation details. Mirrors the Hive-JSON pattern of
/// [ChatFlagController]/[ChatPinArchiveController]. Nothing is sent to the
/// server — starred messages live only on this device.
class StarredMessageController extends GetxController {
  static const String _boxName = 'starredMessagesBox';
  static const String _starredKey = 'starredMessages';

  /// Newest-first list of starred messages, observable for the UI.
  RxList<StarredMessage> starredMessages = <StarredMessage>[].obs;

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
    final json = box.get(_starredKey);
    if (json != null) {
      final List decoded = jsonDecode(json);
      starredMessages.value = decoded
          .map((e) => StarredMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  String _keyFor(Messages message, {String? conversationId}) =>
      message.id ??
      '${conversationId ?? message.conversationId ?? ''}_${message.createdAt ?? ''}';

  bool isStarred(Messages message, {String? conversationId}) {
    final key = _keyFor(message, conversationId: conversationId);
    return starredMessages.any((s) => s.key == key);
  }

  /// Star the message if it isn't starred yet, otherwise un-star it. Returns
  /// `true` when the message ends up starred.
  Future<bool> toggleStar(
    Messages message, {
    String? conversationId,
    String? conversationName,
    String? conversationProfileImage,
    String? userId,
  }) async {
    final key = _keyFor(message, conversationId: conversationId);
    final existing = starredMessages.indexWhere((s) => s.key == key);
    if (existing >= 0) {
      starredMessages.removeAt(existing);
      await _save();
      return false;
    }
    starredMessages.insert(
      0,
      StarredMessage(
        message: message,
        conversationId: conversationId ?? message.conversationId,
        conversationName: conversationName,
        conversationProfileImage: conversationProfileImage,
        userId: userId,
        starredAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _save();
    return true;
  }

  Future<void> removeStar(StarredMessage starred) async {
    starredMessages.removeWhere((s) => s.key == starred.key);
    await _save();
  }

  Future<void> clearAll() async {
    starredMessages.clear();
    await _save();
  }

  Future<void> _save() async {
    final box = await _boxRef;
    await box.put(
      _starredKey,
      jsonEncode(starredMessages.map((e) => e.toJson()).toList()),
    );
  }
}
