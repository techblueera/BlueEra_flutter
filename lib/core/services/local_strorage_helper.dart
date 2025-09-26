import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  Future<String> _downloadAndSaveImage(String imageUrl, String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw Exception('Invalid userId for image filename');
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$userId.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      print('Failed to download image: $e');
    }
    return '';
  }

  Future<String> _downloadAndSaveMediaFile(String url, String uniqueId,String mediaType) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = "$uniqueId-${DateTime.now().millisecondsSinceEpoch}.${mediaType}";
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      print("Download error: $e");
    }
    return '';
  }

  Future<void> saveChatList(List<ChatList?> chats, String type) async {
    List<Map<String, dynamic>> modifiedChats = [];

    for (var chat in chats) {
      final sender = chat?.sender;
      String? localPath;

      if (sender?.profileImage != null) {
        localPath = await _downloadAndSaveImage(
          sender?.profileImage ?? '',
          sender?.id ?? '',
        );
      }

      final chatMap = chat?.toJson();
      if (localPath != null && localPath.isNotEmpty) {
        chatMap?['sender']['profile_image'] = localPath;
      }

      modifiedChats.add(chatMap??{});
    }

    final encoded = jsonEncode(modifiedChats);
    final box = await Hive.openBox<String>('chatListJsonBox');

    // Save separately using type as key
    await box.put('${type}_chat_list', encoded);
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
            message.id ?? DateTime.now().millisecondsSinceEpoch.toString(),media.name?.split(".")[1]??''
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
}
