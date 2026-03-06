import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../model/chat_flag_model.dart';

class ChatFlagController extends GetxController {
  static const String _flagsBoxName = 'chatFlagsBox';
  static const String _customFlagsKey = 'customFlags';
  static const String _conversationFlagsKey = 'conversationFlags';

  RxList<ChatFlagModel> allFlags = <ChatFlagModel>[].obs;
  RxMap<String, ConversationFlag> conversationFlags = <String, ConversationFlag>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFlags();
  }

  Future<Box<String>> get _boxRef async {
    if (Hive.isBoxOpen(_flagsBoxName)) {
      return Hive.box<String>(_flagsBoxName);
    }
    return await Hive.openBox<String>(_flagsBoxName);
  }

  Future<void> _loadFlags() async {
    final box = await _boxRef;

    // Load custom flags
    final customFlagsJson = box.get(_customFlagsKey);
    List<ChatFlagModel> customFlags = [];
    if (customFlagsJson != null) {
      final List decoded = jsonDecode(customFlagsJson);
      customFlags = decoded.map((e) => ChatFlagModel.fromJson(e)).toList();
    }

    allFlags.value = [...ChatFlagModel.defaultFlags, ...customFlags];

    // Load conversation flags
    final convFlagsJson = box.get(_conversationFlagsKey);
    if (convFlagsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(convFlagsJson);
      conversationFlags.value = decoded.map(
        (key, value) => MapEntry(key, ConversationFlag.fromJson(value)),
      );
    }
  }

  Future<void> addCustomFlag(ChatFlagModel flag) async {
    final box = await _boxRef;
    final customFlagsJson = box.get(_customFlagsKey);
    List<ChatFlagModel> customFlags = [];
    if (customFlagsJson != null) {
      final List decoded = jsonDecode(customFlagsJson);
      customFlags = decoded.map((e) => ChatFlagModel.fromJson(e)).toList();
    }
    customFlags.add(flag);
    await box.put(_customFlagsKey, jsonEncode(customFlags.map((e) => e.toJson()).toList()));
    allFlags.add(flag);
  }

  Future<void> assignFlagToConversation(String conversationId, ChatFlagModel flag) async {
    final convFlag = ConversationFlag(conversationId: conversationId, flag: flag);
    conversationFlags[conversationId] = convFlag;
    await _saveConversationFlags();
  }

  Future<void> removeFlagFromConversation(String conversationId) async {
    conversationFlags.remove(conversationId);
    await _saveConversationFlags();
  }

  Future<void> _saveConversationFlags() async {
    final box = await _boxRef;
    final map = conversationFlags.map((key, value) => MapEntry(key, value.toJson()));
    await box.put(_conversationFlagsKey, jsonEncode(map));
  }

  ChatFlagModel? getFlagForConversation(String? conversationId) {
    if (conversationId == null) return null;
    return conversationFlags[conversationId]?.flag;
  }

  List<String> get flaggedConversationIds => conversationFlags.keys.toList();
}
