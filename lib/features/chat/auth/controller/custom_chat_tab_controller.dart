import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../model/custom_chat_tab_model.dart';

/// Locally persists user-created chat sub-tabs ("lists") and the conversations
/// assigned to each. Mirrors the Hive-JSON pattern of
/// [ChatPinArchiveController]/[StarredMessageController]. Nothing is sent to
/// the server — these tabs live only on this device.
class CustomChatTabController extends GetxController {
  static const String _boxName = 'customChatTabsBox';
  static const String _tabsKey = 'customChatTabs';

  /// All custom tabs, in creation order, observable for the UI.
  RxList<CustomChatTab> tabs = <CustomChatTab>[].obs;

  /// Id of the currently-selected custom tab, or null when a built-in tab
  /// (All / Group / Pinned / …) is active.
  final RxnString selectedTabId = RxnString();

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
    final json = box.get(_tabsKey);
    if (json != null) {
      final List decoded = jsonDecode(json);
      tabs.value = decoded
          .map((e) => CustomChatTab.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  CustomChatTab? get selectedTab {
    final id = selectedTabId.value;
    if (id == null) return null;
    final i = tabs.indexWhere((t) => t.id == id);
    return i >= 0 ? tabs[i] : null;
  }

  /// Create a new tab and return it. Selection is left untouched.
  Future<CustomChatTab> addTab(String name) async {
    final tab = CustomChatTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    tabs.add(tab);
    await _save();
    return tab;
  }

  Future<void> renameTab(String id, String name) async {
    final i = tabs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tabs[i].name = name.trim();
    tabs.refresh();
    await _save();
  }

  Future<void> removeTab(String id) async {
    tabs.removeWhere((t) => t.id == id);
    if (selectedTabId.value == id) selectedTabId.value = null;
    await _save();
  }

  bool isInTab(String tabId, String conversationId) {
    final i = tabs.indexWhere((t) => t.id == tabId);
    return i >= 0 && tabs[i].conversationIds.contains(conversationId);
  }

  /// Replace the full conversation set for [tabId] (used by the picker).
  Future<void> setConversations(String tabId, List<String> ids) async {
    final i = tabs.indexWhere((t) => t.id == tabId);
    if (i < 0) return;
    tabs[i].conversationIds
      ..clear()
      ..addAll(ids);
    tabs.refresh();
    await _save();
  }

  Future<void> removeConversation(String tabId, String conversationId) async {
    final i = tabs.indexWhere((t) => t.id == tabId);
    if (i < 0) return;
    tabs[i].conversationIds.remove(conversationId);
    tabs.refresh();
    await _save();
  }

  Future<void> _save() async {
    final box = await _boxRef;
    await box.put(
      _tabsKey,
      jsonEncode(tabs.map((e) => e.toJson()).toList()),
    );
  }
}
