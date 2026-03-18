import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../features/chat/auth/model/GetChatListModel.dart';
import '../../features/chat/auth/model/GetListOfMessageData.dart';

class LocalStorageHelper {
  static final LocalStorageHelper _instance = LocalStorageHelper._internal();

  factory LocalStorageHelper() => _instance;

  LocalStorageHelper._internal();

  // ── Cached box references (avoid repeated openBox calls) ──
  Box<String>? _conversationBox;
  Box<String>? _userImagesBox;

  // ── Cached app documents directory ──
  Directory? _appDocDir;

  Future<Directory> get _appDocDirectory async {
    _appDocDir ??= await getApplicationDocumentsDirectory();
    return _appDocDir!;
  }

  Future<Box<String>> get _conversationBoxRef async {
    if (_conversationBox != null && _conversationBox!.isOpen) return _conversationBox!;
    _conversationBox = Hive.isBoxOpen('conversationBox')
        ? Hive.box<String>('conversationBox')
        : await Hive.openBox<String>('conversationBox');
    return _conversationBox!;
  }

  Future<Box<String>> get _userImagesBoxRef async {
    if (_userImagesBox != null && _userImagesBox!.isOpen) return _userImagesBox!;
    _userImagesBox = Hive.isBoxOpen('userImages')
        ? Hive.box<String>('userImages')
        : await Hive.openBox<String>('userImages');
    return _userImagesBox!;
  }

  Future<void> putConversation(String newMessage) async {
    final box = await _conversationBoxRef;

    final jsonString = box.get('openedConversationList');
    List<String> conversationList = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        conversationList = decoded.cast<String>();
      } catch (e) {
        debugPrint("Error decoding openedConversationList: $e");
      }
    }

    if (!conversationList.contains(newMessage)) {
      conversationList.add(newMessage);
      await box.put('openedConversationList', jsonEncode(conversationList));
    }
  }

  Future<List<String>> getConversation() async {
    final box = await _conversationBoxRef;
    final jsonString = box.get('openedConversationList');

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      debugPrint("Error decoding openedConversationList: $e");
      return [];
    }
  }

  Future<String> _downloadAndSaveImage(String imageUrl, String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw Exception('Invalid userId for image filename');
      }

      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final directory = await _appDocDirectory;

        final originalPath = '${directory.path}/$userId-original.jpg';
        final compressedPath = '${directory.path}/$userId-compressed.jpg';

        final originalFile = File(originalPath);
        await originalFile.writeAsBytes(response.bodyBytes);

        final compressedBytes = await FlutterImageCompress.compressWithFile(
          originalFile.path,
          quality: 60,
          minWidth: 300,
          minHeight: 300,
          format: CompressFormat.jpeg,
        );

        if (compressedBytes != null) {
          final compressedFile = File(compressedPath);
          await compressedFile.writeAsBytes(compressedBytes);

          if (await originalFile.exists()) {
            await originalFile.delete();
          }

          return compressedPath;
        } else {
          return originalPath;
        }
      }
    } catch (e) {
      debugPrint('Failed to download/compress image: $e');
    }

    return '';
  }


  Future<void> saveChatList(List<ChatList?> chats, String type) async {
    return;
  }

  Future<String> getOrDownloadUserImage(String url, String userId) async {
    if (userId.isEmpty || url.isEmpty) return url;
    final box = await _userImagesBoxRef;
    return _getOrDownloadUserImageWithBox(url, userId, box);
  }

  Future<String> _getOrDownloadUserImageWithBox(String url, String userId, Box<String> box) async {
    if (userId.isEmpty || url.isEmpty) return url;

    final existing = box.get(userId);
    if (existing != null && existing.isNotEmpty && File(existing).existsSync()) {
      return existing;
    }

    final savedPath = await _downloadAndSaveImage(url, userId);

    if (savedPath.isNotEmpty) {
      await box.put(userId, savedPath);
      return savedPath;
    }

    return url;
  }

  Future<List<ChatList>> getChatListFromLocal(String type) async {
    return [];
  }

  Future<Map<String, List<ChatList>>> getAllChatListsFromLocal() async {
    return {};
  }


  Future<void> saveMessagesByConversationId(String conversationId, List<Messages> messages) async {
    return;
  }

  Future<void> saveSingleMessageToConversationId(
      String conversationId,
      Messages newMessage, {
        String sendStatus = "",
      }) async {
    return;
  }

  Future<List<Map<String, dynamic>>> getUnsentMessages(String conversationId) async {
    return [];
  }

  Future<void> markMessageAsSent(String conversationId, String messageId) async {
    return;
  }

  Future<List<Messages>> getMessagesByConversationId(String conversationId) async {
    return [];
  }

  Future<List<Messages>> getMediaMessagesByConversationId(String conversationId) async {
    return [];
  }

}
class AiChatLocalStorage {
  static const String _boxName = "aiChatBox";

  static const String keyPersonalConversationId = "personalConversationId";
  static const String keyBusinessConversationId = "businessConversationId";
  static const String keyAiSearchConversationId = "keyAiSearchConversationId";
  static const String keyInventoryConversationId = "keyInventoryConversationId";
  static const String keyFoodConversationId = "keyFoodConversationId";
  static const String keyServicesConversationId = "keyServicesConversationId";
  static const String keyHealthCareConversationId = "keyHealthCareConversationId";
  static const String keyEducationConversationId = "keyEducationConversationId";
  static const String keyHomeServiceConversationId = "keyHomeServiceConversationId";
  static const String keyTravelStayConversationId = "keyTravelStayConversationId";
  static const String keyConsultingTalkConversationId = "keyConsultingTalkConversationId";

  static Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    } else {
      return await Hive.openBox<String>(_boxName);
    }
  }

  /// Save Conversation ID for given type (personal/business)
  static Future<void> saveConversationIdIfEmpty({
    required String type,
    required String id,
  }) async {
    final box = await _openBox();

    String key = _getKey(type);
    String? existingId = box.get(key);

    if (existingId == null || existingId.isEmpty) {
      await box.put(key, id);
    }
  }

  /// Get Conversation ID for given type
  static Future<String?> getConversationId(String type) async {
    final box = await _openBox();
    String key = _getKey(type);
    return box.get(key);
  }

  /// Clear Conversation ID for given type
  static Future<void> clearConversationId(String type) async {
    final box = await _openBox();
    String key = _getKey(type);
    await box.delete(key);
  }

  /// Internal: Map type to storage key
  static String _getKey(String type) {
    switch (type) {
      case AppConstants.personal_Chat_Type:
        return keyPersonalConversationId;
      case AppConstants.business_Chat_Type:
        return keyBusinessConversationId;
      case AppConstants.search_Chat_Type:
        return keyAiSearchConversationId;
      case AppConstants.askInventory_Chat_Type:
        return keyInventoryConversationId;
      case AppConstants.askFood_Chat_Type:
        return keyFoodConversationId;
      case AppConstants.askService_Chat_Type:
        return keyServicesConversationId;
      case AppConstants.askHealthCare_Chat_Type:
        return keyHealthCareConversationId;
      case AppConstants.askEducation_Chat_Type:
        return keyEducationConversationId;
      case AppConstants.askHomeService_Chat_Type:
        return keyHomeServiceConversationId;
      case AppConstants.askTravelStay_Chat_Type:
        return keyTravelStayConversationId;
      case AppConstants.askConsultingTalk_Chat_Type:
        return keyConsultingTalkConversationId;
      default:
        throw Exception("Invalid type.");
    }
  }
}
class UserImageStorage {
  static const _boxName = "userImagesBox";

  static Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  // Save
  static Future<void> saveUserImage(String userId, String filePath) async {
    final box = await _openBox();
    await box.put(userId, filePath);
  }

  // Get
  static Future<String?> getUserImage(String userId) async {
    final box = await _openBox();
    return box.get(userId);
  }
}
