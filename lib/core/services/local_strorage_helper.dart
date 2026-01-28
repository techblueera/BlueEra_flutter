import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../../features/chat/auth/model/GetChatListModel.dart';
import '../../features/chat/auth/model/GetListOfMessageData.dart';

class LocalStorageHelper {
  static final LocalStorageHelper _instance = LocalStorageHelper._internal();

  factory LocalStorageHelper() => _instance;

  LocalStorageHelper._internal();

  Future<void> putConversation(String newMessage) async {
    final box = await Hive.openBox<String>('conversationBox');

    // Get existing list from Hive
    final jsonString = box.get('openedConversationList');
    List<String> conversationList = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        conversationList = decoded.cast<String>();
      } catch (e) {
        print("Error decoding openedConversationList: $e");
      }
    }

    // Append new message
    conversationList.add(newMessage);

    // Save back to Hive
    await box.put('openedConversationList', jsonEncode(conversationList));
  }



  Future<List<String>> getConversation() async {
    final box = await Hive.openBox<String>('conversationBox');
    final jsonString = box.get('openedConversationList');

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      print("Error decoding openedConversationList: $e");
      return [];
    }
  }
  // Future<String> downloadAndSaveUserImageWithUId(String compressedPath, String userId) async {
  //   await UserImageStorage.saveUserImage(userId, compressedPath);
  //   return compressedPath;
  // }

  Future<String> _downloadAndSaveImage(String imageUrl, String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw Exception('Invalid userId for image filename');
      }

      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();

        final originalPath = '${directory.path}/$userId-original.jpg';
        final compressedPath = '${directory.path}/$userId-compressed.jpg';

        // Save original image first
        final originalFile = File(originalPath);
        await originalFile.writeAsBytes(response.bodyBytes);

        // ---- COMPRESS IMAGE HERE ----
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          originalFile.path,
          quality: 60,        // 0–100 (60 is good balance)
          minWidth: 300,      // reduce resolution
          minHeight: 300,
          format: CompressFormat.jpeg,
        );

        if (compressedBytes != null) {
          final compressedFile = File(compressedPath);
          await compressedFile.writeAsBytes(compressedBytes);

          // remove original large file
          if (await originalFile.exists()) {
            await originalFile.delete();
          }

          return compressedPath;
        } else {
          return originalPath;
        }
      }
    } catch (e) {
      print('Failed to download/compress image: $e');
    }

    return '';
  }


  Future<String> _downloadAndSaveMediaFile(String url, String uniqueId, String mediaType) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();

        final fileName =
            "$uniqueId-${DateTime.now().millisecondsSinceEpoch}.$mediaType";

        final filePath = '${dir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // ----------------------------------------------------
        // 🔥 IMAGE COMPRESSION
        // ----------------------------------------------------
        if (mediaType.toLowerCase() == "jpg" ||
            mediaType.toLowerCase() == "jpeg" ||
            mediaType.toLowerCase() == "png") {
          return await _compressImageFile(filePath, uniqueId);
        }

        // ----------------------------------------------------
        // 🔥 VIDEO COMPRESSION
        // ----------------------------------------------------
        if (mediaType.toLowerCase() == "mp4" ||
            mediaType.toLowerCase() == "mov" ||
            mediaType.toLowerCase() == "mkv") {
          return await _compressVideoFile(filePath, uniqueId);
        }

        // ----------------------------------------------------
        // Other documents (PDF, MP3, ZIP, etc.)
        // ----------------------------------------------------
        return filePath;
      }
    } catch (e) {
      print("Download error: $e");
    }
    return '';
  }

  Future<String> _compressImageFile(String filePath, String uniqueId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final outPath = '${dir.path}/$uniqueId-img-compressed.jpg';

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        filePath,
        quality: 60,
        minWidth: 300,
        minHeight: 300,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes != null) {
        final file = File(outPath);
        await file.writeAsBytes(compressedBytes);

        // Delete original image
        File(filePath).delete();

        return outPath;
      }
    } catch (e) {
      print("Image compression error: $e");
    }

    return filePath;
  }
  Future<String> _compressVideoFile(String filePath, String uniqueId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final outPath = '${dir.path}/$uniqueId-video-compressed.mp4';

      final compressedVideo = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // delete manually
      );

      if (compressedVideo != null && compressedVideo.file != null) {
        final compressedFile = compressedVideo.file!;
        await compressedFile.copy(outPath);

        // delete original video
        File(filePath).delete();

        return outPath;
      }
    } catch (e) {
      print("Video compression error: $e");
    }

    return filePath;
  }

  Future<void> saveChatList(List<ChatList?> chats, String type) async {
    List<Map<String, dynamic>> modifiedChats = [];

    for (var chat in chats) {
      final sender = chat?.sender;

      if (sender != null && sender.profileImage != null && sender.id != null) {

        final localPath = await getOrDownloadUserImage(
          sender.profileImage!,
          sender.id!,
        );

        // Replace URL with local path
        sender.profileImage = localPath;
      }

      modifiedChats.add(chat?.toJson() ?? {});
    }

    final encoded = jsonEncode(modifiedChats);
    final box = await Hive.openBox<String>('chatListJsonBox');

    // Save based on type
    await box.put('${type}_chat_list', encoded);
  }

  Future<String> getOrDownloadUserImage(String url, String userId) async {
    if (userId.isEmpty || url.isEmpty) return url;

    final box = await Hive.openBox<String>('userImages');

    // 1️⃣ Already stored?
    final existing = box.get(userId);
    if (existing != null && existing.isNotEmpty && File(existing).existsSync()) {
      return existing;
    }

    // 2️⃣ Not stored → download & compress
    final savedPath = await _downloadAndSaveImage(url, userId);

    // 3️⃣ Save to Hive for future use
    if (savedPath.isNotEmpty) {
      await box.put(userId, savedPath);
      return savedPath;
    }

    return url;
  }

  Future<List<ChatList>> getChatListFromLocal(String type) async {
    final box = await Hive.openBox<String>('chatListJsonBox');
    final jsonString = box.get('${type}_chat_list'); // <- separate key

    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;

    return decoded.map((e) => ChatList.fromJson(e)).toList();
  }


  Future<void> saveMessagesByConversationId(String conversationId, List<Messages> messages) async {
    final modifiedMessages = <Map<String, dynamic>>[];

    for (var message in messages) {
      final mediaList = message.url ?? [];
      final localUrls = <Map<String, dynamic>>[];

      for (var media in mediaList) {
        if (media.url != null && media.url!.startsWith("http")) {
          final filePath = await _downloadAndSaveMediaFile(
            media.url!,
            message.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              media.name?.split(".")[1]??''
          );

          if (filePath.isNotEmpty) {
            localUrls.add({
              "url": filePath,
              "type": media.type,
              "name": media.name,
              "size": media.size,
              "mimetype": media.mimetype,
              "_id": media.id
            });
          }
        }
      }

      final messageMap = message.toJson();
      messageMap['url'] = localUrls;
      modifiedMessages.add(messageMap);
    }

    final box = await Hive.openBox<String>('messagesBox');

    await box.put(conversationId, jsonEncode(modifiedMessages));
  }

  Future<void> saveSingleMessageToConversationId(
      String conversationId,
      Messages newMessage, {
        String sendStatus = "",
        //pending
      }) async {
    final box = await Hive.openBox<String>('messagesBox');

    // 1. Get existing messages
    final jsonString = box.get(conversationId);
    List<Map<String, dynamic>> existingMessages = [];

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        existingMessages = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        print("Error decoding existing messages: $e");
      }
    }

    // 2. Download & replace media URLs with local file paths
    final mediaList = newMessage.url ?? [];
    final localUrls = <Map<String, dynamic>>[];

    for (var media in mediaList) {
      if (media.url != null && media.url!.startsWith("http")) {
        final filePath = await _downloadAndSaveMediaFile(
          media.url!,
          newMessage.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          media.name?.split(".").last ?? '',
        );

        if (filePath.isNotEmpty) {
          localUrls.add({
            "url": filePath,
            "type": media.type,
            "name": media.name,
            "size": media.size,
            "mimetype": media.mimetype,
            "_id": media.id,
          });
        }
      }else{
        localUrls.add({
          "url": media.url,
          "type": media.type,
          "name": media.name,
          "size": media.size,
          "mimetype": media.mimetype,
          "_id": media.id,
        });
      }
    }

    // 3. Convert to map & add send status
    final newMessageMap = newMessage.toJson();
    newMessageMap['url'] = localUrls;
    newMessageMap['sendStatus'] = sendStatus; // 👈 ADDED HERE

    // 4. Save message
    existingMessages.add(newMessageMap);
    await box.put(conversationId, jsonEncode(existingMessages));
  }

  Future<List<Map<String, dynamic>>> getUnsentMessages(String conversationId) async {
    final box = await Hive.openBox<String>('messagesBox');
    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    final messages = decoded.cast<Map<String, dynamic>>();

    return messages.where((msg) => msg['sendStatus'] == 'pending').toList();
  }

  Future<void> markMessageAsSent(String conversationId, String messageId) async {
    final box = await Hive.openBox<String>('messagesBox');
    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) return;

    final List<dynamic> decoded = jsonDecode(jsonString);
    final messages = decoded.cast<Map<String, dynamic>>();

    for (var msg in messages) {
      if (msg['_id'] == messageId) {
        msg['sendStatus'] = 'sent'; // 👈 mark it as sent
        break;
      }
    }

    await box.put(conversationId, jsonEncode(messages));
  }

  Future<List<Messages>> getMessagesByConversationId(String conversationId) async {

    final box = await Hive.openBox<String>('messagesBox');
    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    // try {
      final List<dynamic> jsonList = jsonDecode(jsonString);

      return jsonList.map((item) => Messages.fromJson(item)).toList();
    // } catch (e) {
    //   print("Error decoding messages: $e");
    //   return [];
    // }
  }
  Future<List<Messages>> getMediaMessagesByConversationId(String conversationId) async {
    final box = await Hive.openBox<String>('messagesBox');
    final jsonString = box.get(conversationId);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);

    // Convert to Messages
    List<Messages> allMessages =
    jsonList.map((item) => Messages.fromJson(item)).toList();

    // FILTER: keep only messages with media
    List<Messages> filtered = allMessages.where((msg) {
      return (msg.messageType =="image"||msg.messageType =="video"||msg.messageType =="document") ;  // url exists + contains media list
    }).toList();

    return filtered;
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
