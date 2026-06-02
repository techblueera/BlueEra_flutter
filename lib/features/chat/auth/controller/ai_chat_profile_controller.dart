import 'package:get/get.dart';

import '../../../../core/services/local_strorage_helper.dart';

/// Holds the locally-personalized state (custom name, profile image, mute and
/// language) for the AI chat that is currently open. Backed by
/// [AiChatProfileStorage] so values survive app restarts but reset on
/// reinstall. The AppBar binds to these reactive fields via Obx.
class AiChatProfileController extends GetxController {
  /// The AI chat type currently loaded (e.g. 'personal' / 'business').
  final RxString currentType = ''.obs;

  /// User-overridden display name. Empty → fall back to the default name.
  final RxString customName = ''.obs;

  /// User-picked local profile image path. Empty → fall back to the default.
  final RxString customImagePath = ''.obs;

  /// Whether AI greeting notifications for this chat are muted.
  final RxBool isMuted = false.obs;

  /// Active AI reply language label (e.g. "Tamil"). Drives the AppBar badge.
  /// Empty until the user selects one. Kept in sync with the backend's
  /// per-conversation language lock echoed on each reply.
  final RxString language = ''.obs;

  /// Load all persisted values for [type] into the reactive fields.
  Future<void> loadForType(String type) async {
    currentType.value = type;
    customName.value = (await AiChatProfileStorage.getName(type)) ?? '';
    customImagePath.value = (await AiChatProfileStorage.getImagePath(type)) ?? '';
    isMuted.value = await AiChatProfileStorage.isMuted(type);
    language.value = (await AiChatProfileStorage.getLanguage(type)) ?? '';
  }

  Future<void> saveName(String type, String name) async {
    await AiChatProfileStorage.saveName(type, name);
    customName.value = name;
  }

  Future<void> saveImage(String type, String path) async {
    await AiChatProfileStorage.saveImagePath(type, path);
    customImagePath.value = path;
  }

  Future<void> toggleMute(String type) async {
    final next = !isMuted.value;
    await AiChatProfileStorage.setMuted(type, next);
    isMuted.value = next;
  }

  Future<void> setLanguage(String type, String code) async {
    await AiChatProfileStorage.setLanguage(type, code);
    language.value = code;
  }
}
